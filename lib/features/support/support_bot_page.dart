import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/support_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';
import 'support_faq.dart';

// ==============================================================================
// SUPPORT CHAT. Guided and free-text help from the built-in FAQ (works offline, English and Tamil).
// If that does not solve it, the person can ask the AI assistant (signed in, 10 a day) or send an e-mail to
// the team that is prefilled with the details they need. The AI is never used unless the person taps for it.
// ==============================================================================
class SupportBotPage extends StatefulWidget {
  const SupportBotPage({super.key});

  @override
  State<SupportBotPage> createState() => _SupportBotPageState();
}

enum _Who { bot, user }

class _Msg {
  final _Who who;
  final String text;
  final String? note; // small print under a bot message (the AI disclaimer)
  const _Msg(this.who, this.text, {this.note});
}

class _Chip {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const _Chip(this.label, this.onTap, {this.icon});
}

class _SupportBotPageState extends State<SupportBotPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  List<_Chip> _chips = [];
  String? _lastQuestion;
  bool _thinking = false;
  bool _started = false;

  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _messages.add(_Msg(_Who.bot, context.t.supportGreeting));
    _chips = _topicChips();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── flow ─────────────────────────────────────────────────────────────────────

  List<_Chip> _topicChips() => [
        for (final tp in supportTopics) _Chip(_lang == 'ta' ? tp.$3 : tp.$2, () => _pickTopic(tp)),
        _Chip(context.t.supportEmail, _email, icon: Icons.mail_rounded),
      ];

  void _say(_Msg m, {List<_Chip>? chips}) {
    setState(() {
      _messages.add(m);
      _chips = chips ?? const [];
    });
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  void _pickTopic((String, String, String) topic) {
    final label = _lang == 'ta' ? topic.$3 : topic.$2;
    setState(() => _messages.add(_Msg(_Who.user, label)));
    _say(
      _Msg(_Who.bot, context.t.supportPickQuestion),
      chips: [
        for (final e in faqForTopic(topic.$1)) _Chip(e.question(_lang), () => _answer(e, asked: e.question(_lang))),
        _Chip(context.t.supportTopicsBtn, _backToTopics, icon: Icons.arrow_back_rounded),
      ],
    );
  }

  void _answer(FaqEntry e, {required String asked}) {
    final t = context.t;
    _lastQuestion = asked;
    if (_messages.isEmpty || _messages.last.who != _Who.user || _messages.last.text != asked) {
      setState(() => _messages.add(_Msg(_Who.user, asked)));
    }
    _say(
      _Msg(_Who.bot, e.answer(_lang)),
      chips: [
        _Chip(t.supportYes, _helped, icon: Icons.thumb_up_alt_outlined),
        _Chip(t.supportNo, _notHelped, icon: Icons.thumb_down_alt_outlined),
      ],
    );
  }

  void _helped() {
    setState(() => _messages.add(_Msg(_Who.user, context.t.supportYes)));
    _say(_Msg(_Who.bot, context.t.supportGlad), chips: _topicChips());
  }

  void _notHelped() {
    setState(() => _messages.add(_Msg(_Who.user, context.t.supportNo)));
    _offerMore(context.t.supportMoreHelp);
  }

  void _backToTopics() => _say(_Msg(_Who.bot, context.t.supportGreeting), chips: _topicChips());

  void _offerMore(String text) {
    final t = context.t;
    _say(_Msg(_Who.bot, text), chips: [
      _Chip(t.supportAskAi, _askAi, icon: Icons.auto_awesome_rounded),
      _Chip(t.supportEmail, _email, icon: Icons.mail_rounded),
      _Chip(t.supportTopicsBtn, _backToTopics, icon: Icons.arrow_back_rounded),
    ]);
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    _lastQuestion = text;
    setState(() => _messages.add(_Msg(_Who.user, text)));
    final match = bestFaqMatch(text);
    if (match != null) {
      _answer(match, asked: text);
    } else {
      _offerMore(context.t.supportNoMatch);
    }
  }

  Future<void> _askAi() async {
    final t = context.t;
    final q = _lastQuestion;
    if (q == null || q.isEmpty) {
      _say(_Msg(_Who.bot, t.supportNeedQuestion), chips: _topicChips());
      return;
    }
    setState(() {
      _thinking = true;
      _chips = const [];
      _messages.add(_Msg(_Who.bot, t.supportAiThinking));
    });
    _toBottom();
    final res = await SupportService.askAi(q, lang: _lang);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages.removeLast(); // the "thinking" bubble
    });
    final more = [
      _Chip(t.supportEmail, _email, icon: Icons.mail_rounded),
      _Chip(t.supportTopicsBtn, _backToTopics, icon: Icons.arrow_back_rounded),
    ];
    switch (res.status) {
      case AiStatus.ok:
        _say(_Msg(_Who.bot, res.text!, note: t.supportAiNote), chips: more);
      case AiStatus.rateLimited:
        _say(_Msg(_Who.bot, t.supportAiRate), chips: more);
      case AiStatus.busy:
        _say(_Msg(_Who.bot, t.supportAiBusy), chips: more);
      case AiStatus.offline:
        _say(_Msg(_Who.bot, t.supportAiOffline), chips: more);
      case AiStatus.unavailable:
        _say(_Msg(_Who.bot, t.supportAiDown), chips: more);
    }
  }

  Future<void> _email() async {
    final t = context.t;
    final profile = AuthService.currentProfile;
    final link = await SupportService.buildSupportMailto(
      profile: profile,
      accountEmail: profile.email.isNotEmpty ? profile.email : (AuthService.currentUser?.email ?? ''),
      language: _lang,
      intro: t.supportMailIntro,
      autoHeader: t.supportMailAuto,
      subject: t.supportMailSubject,
    );
    final ok = await safeLaunch(link);
    if (!mounted) return;
    if (!ok) _say(_Msg(_Who.bot, t.supportMailFailed), chips: _topicChips());
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t.supportChat)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  for (final m in _messages) _Bubble(msg: m),
                  if (_chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in _chips)
                            ActionChip(
                              avatar: c.icon == null ? null : Icon(c.icon, size: 18, color: AppColors.primary),
                              label: Text(c.label),
                              labelStyle: AppTextStyles.subheadline.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0x1F000000)),
                              shape: const StadiumBorder(),
                              onPressed: _thinking ? null : c.onTap,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0x14000000)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(hintText: t.supportInputHint, counterText: '', filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    tooltip: t.send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    onPressed: _thinking ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final bot = msg.who == _Who.bot;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.82;
    return Align(
      alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: ShapeDecoration(color: bot ? Colors.white : AppColors.primary, shape: squircle(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(msg.text, style: AppTextStyles.body.copyWith(color: bot ? AppColors.ink : Colors.white, height: 1.35)),
            if (msg.note != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(msg.note!, style: AppTextStyles.caption1)),
          ],
        ),
      ),
    );
  }
}
