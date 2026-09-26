import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
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
// SUBMIT — a report (road, electricity, water, government) or a piece of community news.
// Either way it is auto-checked, then reviewed by a moderator or admin before it appears.
// Photos (up to 3) are re-encoded on the phone, which removes any location data inside them.
// The place is optional: pin it on the map, type it, or use the current location.
// ==============================================================================
class SubmitAlertPage extends StatefulWidget {
  /// 'report' or 'news'
  final String kind;
  const SubmitAlertPage({super.key, this.kind = 'report'});

  @override
  State<SubmitAlertPage> createState() => _SubmitAlertPageState();
}

class _SubmitAlertPageState extends State<SubmitAlertPage> {
  static const _reportCategories = ['road', 'electricity', 'water', 'govt'];
  static const _newsCategories = ['traffic', 'civic', 'health', 'education', 'community', 'other'];

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  late String _category = isNews ? 'community' : 'road';
  final List<Uint8List> _photos = [];
  PickedLocation? _location;
  bool _emergency = false;
  bool _submitting = false;
  bool _addingPhoto = false;
  String? _status; // "Uploading photos…"
  String? _error;

  bool get isNews => widget.kind == 'news';
  List<String> get _categories => isNews ? _newsCategories : _reportCategories;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

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
    if (title.length < 5) return setState(() => _error = t.titleMin);
    if (body.length < 10) return setState(() => _error = t.detailsMin);
    if (isNews && link.isNotEmpty && !_validLink(link)) return setState(() => _error = t.linkInvalid);

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
      linkUrl: isNews ? link : null,
      imagePaths: uploaded,
      location: _location,
      emergencyTagged: !isNews && _emergency,
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
      messenger.showSnackBar(SnackBar(content: Text(isNews ? t.submittedNewsMsg : t.submittedMsg), duration: const Duration(seconds: 4)));
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
        title: Text(isNews ? t.submitNewsTitle : t.submitTitle),
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
                      if (isNews)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: TextField(
                            controller: _linkCtrl,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            style: AppTextStyles.body,
                            decoration: _bare(t.linkOptional).copyWith(prefixIcon: const Icon(Icons.link_rounded, color: AppColors.tertiaryLabel)),
                          ),
                        ),
                    ],
                  ),
                  _photoSection(t),
                  GroupedSection(
                    footer: isNews ? null : (canEmergency ? t.emergencyNote : t.emergencyRevoked),
                    dividerIndent: 58,
                    children: [
                      GroupedRow(
                        icon: Icons.place_rounded,
                        iconColor: AppColors.danger,
                        title: t.locationOptional,
                        value: (_location == null || _location!.isEmpty) ? t.noLocation : _location!.label,
                        chevron: true,
                        onTap: () async {
                          final picked = await pickLocation(context, initial: _location);
                          if (picked != null) setState(() => _location = picked.isEmpty ? null : picked);
                        },
                      ),
                      if (!isNews)
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
                  PrimaryButton(label: isNews ? t.submitNewsBtn : t.submitReport, loading: _submitting, onPressed: _submit),
                ],
              ),
            ),
          ],
        ),
      ),
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
