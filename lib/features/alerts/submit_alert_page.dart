import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:intl/intl.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/place.dart';
import '../../core/services/alerts_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';
import '../map/address_picker.dart';

// ==============================================================================
// SUBMIT — a report, a piece of community news, an event or a job. Every kind is auto-checked, then
// reviewed by a moderator or admin before it appears. Photos (up to 3) are re-encoded on the phone,
// which removes any location data inside them. Reports/jobs treat the place as optional; an event
// requires a venue (pinned, typed, or both).
// ==============================================================================
class SubmitAlertPage extends StatefulWidget {
  /// 'report', 'news', 'event' or 'job'
  final String kind;
  const SubmitAlertPage({super.key, this.kind = 'report'});

  @override
  State<SubmitAlertPage> createState() => _SubmitAlertPageState();
}

class _SubmitAlertPageState extends State<SubmitAlertPage> {
  static const _reportCategories = ['road', 'electricity', 'water', 'govt'];
  static const _newsCategories = ['traffic', 'civic', 'health', 'education', 'community', 'other'];
  static const _eventCategories = ['cultural', 'sports', 'education', 'religious', 'government', 'business', 'other'];
  static const _jobCategories = ['full_time', 'part_time', 'contract', 'internship', 'daily_wage', 'other'];

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _employerCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _payCtrl = TextEditingController();
  late String _category = _categories.first;
  final List<Uint8List> _photos = [];
  PickedLocation? _location;
  bool _emergency = false;
  bool _submitting = false;
  bool _addingPhoto = false;
  String? _status; // "Uploading photos…"
  String? _error;

  // event
  DateTime? _startsAt;
  DateTime? _endsAt; // events: optional end; jobs: closing date (required)
  bool _allDay = false;
  bool _isPaid = false;

  bool get isNews => widget.kind == 'news';
  bool get isEvent => widget.kind == 'event';
  bool get isJob => widget.kind == 'job';
  List<String> get _categories => switch (widget.kind) {
        'news' => _newsCategories,
        'event' => _eventCategories,
        'job' => _jobCategories,
        _ => _reportCategories,
      };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _linkCtrl.dispose();
    _employerCtrl.dispose();
    _contactCtrl.dispose();
    _payCtrl.dispose();
    super.dispose();
  }

  // ── date & time ──────────────────────────────────────────────────────────────

  Future<void> _pickStarts() async {
    final picked = await _pickDateTime(_startsAt);
    if (picked != null) setState(() => _startsAt = picked);
  }

  Future<void> _pickEnds() async {
    final picked = await _pickDateTime(_endsAt ?? _startsAt);
    if (picked != null) setState(() => _endsAt = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final t = context.t;
    final now = DateTime.now();
    final base = initial != null && initial.isAfter(now) ? initial : now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
      fieldLabelText: t.pickDate,
      helpText: t.pickDate,
    );
    if (date == null || !mounted) return null;
    if (_allDay) return DateTime(date.year, date.month, date.day);
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base), helpText: t.pickTime);
    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime d) => _allDay && isEvent
      ? DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(d)
      : DateFormat.yMMMd(Localizations.localeOf(context).languageCode).add_jm().format(d);

  // ── photos ────────────────────────────────────────────────────────────────────

  Future<void> _addPhoto() async {
    final t = context.t;
    if (_photos.length >= PhotoService.maxPhotos) return setState(() => _error = t.photoLimit);
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_camera_rounded), title: Text(t.photoFromCamera), onTap: () => Navigator.pop(ctx, 'camera')),
            ListTile(leading: const Icon(Icons.photo_library_rounded), title: Text(t.photoFromGallery), onTap: () => Navigator.pop(ctx, 'gallery')),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() {
      _addingPhoto = true;
      _error = null;
    });
    final room = PhotoService.maxPhotos - _photos.length;
    final List<XFile> picked;
    if (source == 'camera') {
      final shot = await PhotoService.takePhoto();
      picked = shot == null ? const [] : [shot];
    } else {
      picked = await PhotoService.pickFromGallery(limit: room);
    }
    var failed = false;
    for (final file in picked.take(room)) {
      final bytes = await PhotoService.prepare(file);
      if (bytes == null) {
        failed = true;
        continue;
      }
      _photos.add(bytes);
    }
    if (!mounted) return;
    setState(() {
      _addingPhoto = false;
      if (failed) _error = t.photoFailed;
    });
  }

  // ── submit ────────────────────────────────────────────────────────────────────

  /// https only; the database checks the same rule.
  bool _validLink(String v) {
    final uri = parseSafeUri(v);
    return uri != null && uri.scheme == 'https';
  }

  Future<void> _submit() async {
    final t = context.t;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final link = _linkCtrl.text.trim();
    final hasLink = isNews || isEvent || isJob;
    if (title.length < 5) return setState(() => _error = t.titleMin);
    if (body.length < 10) return setState(() => _error = t.detailsMin);
    if (hasLink && link.isNotEmpty && !_validLink(link)) return setState(() => _error = t.linkInvalid);
    if (isEvent && _startsAt == null) return setState(() => _error = t.errStartsRequired);
    if (isEvent && (_location == null || _location!.isEmpty)) return setState(() => _error = t.errVenueRequired);
    if (isJob && (_employerCtrl.text.trim().isEmpty || _contactCtrl.text.trim().isEmpty)) {
      return setState(() => _error = t.errEmployerContactRequired);
    }
    if (isJob && (_endsAt == null || !_endsAt!.isAfter(DateTime.now()))) {
      return setState(() => _error = t.errClosingRequired);
    }

    setState(() {
      _submitting = true;
      _error = null;
      _status = _photos.isEmpty ? null : t.uploadingPhotos;
    });

    final uploaded = <String>[];
    for (final bytes in _photos) {
      final path = await PhotoService.upload(bytes);
      if (path == null) {
        for (final p in uploaded) {
          PhotoService.discard(p);
        }
        if (!mounted) return;
        return setState(() {
          _submitting = false;
          _status = null;
          _error = t.photoFailed;
        });
      }
      uploaded.add(path);
    }

    final outcome = await AlertsService.submitAlert(
      kind: widget.kind,
      category: _category,
      title: title,
      body: body,
      linkUrl: hasLink ? link : null,
      imagePaths: uploaded,
      location: _location,
      emergencyTagged: widget.kind == 'report' && _emergency,
      startsAt: isEvent ? _startsAt : null,
      endsAt: isEvent || isJob ? _endsAt : null,
      allDay: isEvent && _allDay,
      isPaid: isEvent && _isPaid,
      employer: isJob ? _employerCtrl.text : null,
      payText: isJob ? _payCtrl.text : null,
      contactText: isJob ? _contactCtrl.text : null,
    );
    final stored = outcome == SubmitOutcome.submitted || outcome == SubmitOutcome.autoRejected;
    if (!stored) {
      for (final p in uploaded) {
        PhotoService.discard(p); // the post did not go through: do not leave the files behind
      }
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _status = null;
    });

    if (outcome == SubmitOutcome.submitted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      final msg = switch (widget.kind) {
        'news' => t.submittedNewsMsg,
        'event' => t.submittedEventMsg,
        'job' => t.submittedJobMsg,
        _ => t.submittedMsg,
      };
      messenger.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
    } else {
      setState(() => _error = switch (outcome) {
            SubmitOutcome.autoRejected => t.errAutoRejected,
            SubmitOutcome.rateLimited => t.errRateLimited,
            SubmitOutcome.cooldown => t.errCooldown,
            SubmitOutcome.restricted => t.errRestricted,
            SubmitOutcome.invalidImage => t.errPhoto,
            SubmitOutcome.invalid => t.errInvalidLength,
            SubmitOutcome.accountIssue => t.errAccount,
            _ => t.errSubmitFailed,
          });
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canEmergency = AuthService.currentProfile.hasEmergencyPrivilege;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 100,
        leading: Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel))),
        title: Text(switch (widget.kind) {
          'news' => t.submitNewsTitle,
          'event' => t.submitEventTitle,
          'job' => t.submitJobTitle,
          _ => t.submitTitle,
        }),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                children: [
                  GroupedSection(
                    header: t.categoryLabel,
                    dividerIndent: 58,
                    children: [
                      for (final c in _categories)
                        GroupedRow(
                          icon: c.categoryIconData,
                          iconColor: c.categoryColor,
                          title: context.categoryName(c),
                          trailing: AnimatedOpacity(
                            duration: const Duration(milliseconds: 160),
                            opacity: _category == c ? 1 : 0,
                            child: const Icon(Icons.check_rounded, color: AppColors.primary),
                          ),
                          onTap: () => setState(() => _category = c),
                        ),
                    ],
                  ),
                  GroupedSection(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: TextField(
                          controller: _titleCtrl,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.sentences,
                          style: AppTextStyles.headline,
                          decoration: _bare(t.titleHint),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: TextField(
                          controller: _bodyCtrl,
                          maxLength: 500,
                          minLines: 4,
                          maxLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                          style: AppTextStyles.body,
                          decoration: _bare(t.detailsHint),
                        ),
                      ),
                      if (isNews || isEvent || isJob)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: TextField(
                            controller: _linkCtrl,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            style: AppTextStyles.body,
                            decoration: _bare(isEvent ? t.eventRegLink : (isJob ? t.jobApplyLink : t.linkOptional))
                                .copyWith(prefixIcon: const Icon(Icons.link_rounded, color: AppColors.tertiaryLabel)),
                          ),
                        ),
                    ],
                  ),
                  if (isEvent) _eventSection(t),
                  if (isJob) _jobSection(t),
                  _photoSection(t),
                  GroupedSection(
                    footer: isEvent
                        ? (_location == null || _location!.isEmpty ? t.eventVenueRequired : null)
                        : (widget.kind == 'report' ? (canEmergency ? t.emergencyNote : t.emergencyRevoked) : null),
                    dividerIndent: 58,
                    children: [
                      GroupedRow(
                        icon: Icons.place_rounded,
                        iconColor: AppColors.danger,
                        title: isEvent ? t.eventVenueLabel : t.locationOptional,
                        value: (_location == null || _location!.isEmpty) ? t.noLocation : _location!.label,
                        chevron: true,
                        onTap: () async {
                          final picked = await pickLocation(context, initial: _location);
                          if (picked != null) setState(() => _location = picked.isEmpty ? null : picked);
                        },
                      ),
                      if (widget.kind == 'report')
                        GroupedRow(
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.danger,
                          title: t.markEmergency,
                          trailing: Switch.adaptive(
                            value: _emergency && canEmergency,
                            activeTrackColor: AppColors.danger,
                            onChanged: canEmergency ? (v) => setState(() => _emergency = v) : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Column(
                children: [
                  if (_status != null)
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_status!, style: AppTextStyles.footnote)),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger)),
                    ),
                  PrimaryButton(
                    label: switch (widget.kind) {
                      'news' => t.submitNewsBtn,
                      'event' => t.submitEventBtn,
                      'job' => t.submitJobBtn,
                      _ => t.submitReport,
                    },
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventSection(AppLocalizations t) {
    return GroupedSection(
      dividerIndent: 58,
      children: [
        GroupedRow(
          icon: Icons.event_rounded,
          iconColor: AppColors.primary,
          title: t.eventStarts,
          value: _startsAt == null ? t.pickDate : _formatDateTime(_startsAt!),
          chevron: true,
          onTap: _pickStarts,
        ),
        GroupedRow(
          icon: Icons.event_available_rounded,
          iconColor: AppColors.tertiaryLabel,
          title: t.eventEnds,
          value: _endsAt == null ? t.notSet : _formatDateTime(_endsAt!),
          chevron: true,
          onTap: _pickEnds,
        ),
        GroupedRow(
          icon: Icons.today_rounded,
          iconColor: AppColors.tertiaryLabel,
          title: t.eventAllDay,
          trailing: Switch.adaptive(value: _allDay, onChanged: (v) => setState(() => _allDay = v)),
        ),
        GroupedRow(
          icon: Icons.confirmation_number_outlined,
          iconColor: AppColors.tertiaryLabel,
          title: t.eventPaid,
          trailing: Switch.adaptive(value: _isPaid, onChanged: (v) => setState(() => _isPaid = v)),
        ),
      ],
    );
  }

  Widget _jobSection(AppLocalizations t) {
    return GroupedSection(
      footer: t.jobScamWarning,
      dividerIndent: 58,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(controller: _employerCtrl, maxLength: 100, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: t.jobEmployer)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: TextField(controller: _contactCtrl, maxLength: 200, decoration: InputDecoration(labelText: t.jobContact)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(controller: _payCtrl, maxLength: 100, decoration: InputDecoration(labelText: t.jobPay)),
        ),
        GroupedRow(
          icon: Icons.event_busy_rounded,
          iconColor: AppColors.danger,
          title: t.jobClosing,
          value: _endsAt == null ? t.pickDate : _formatDateTime(_endsAt!),
          chevron: true,
          onTap: _pickEnds,
        ),
      ],
    );
  }

  Widget _photoSection(AppLocalizations t) {
    return GroupedSection(
      header: t.photosLabel,
      footer: t.photosNote,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _photos.length; i++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipPath(
                      clipper: ShapeBorderClipper(shape: squircle(14)),
                      child: Image.memory(_photos[i], width: 84, height: 84, fit: BoxFit.cover, gaplessPlayback: true),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Semantics(
                        button: true,
                        label: t.removePhoto,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_photos.length < PhotoService.maxPhotos)
                Pressable(
                  onTap: _addingPhoto || _submitting ? null : _addPhoto,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: ShapeDecoration(color: AppColors.fill, shape: squircle(14)),
                    child: _addingPhoto
                        ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2)))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.add_a_photo_rounded, color: AppColors.primary),
                            const SizedBox(height: 4),
                            Text(t.addPhoto, style: AppTextStyles.caption1.copyWith(color: AppColors.primary)),
                          ]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _bare(String hint) => InputDecoration(
        hintText: hint,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        counterStyle: AppTextStyles.caption2,
      );
}
