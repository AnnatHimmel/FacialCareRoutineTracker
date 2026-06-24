import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/skin_log_entry.dart';
import '../../../shared/providers/root_providers.dart';
import '../../../shared/widgets/glow_card.dart';

const _uuid = Uuid();
final _picker = ImagePicker();

/// Weekly skin-tracking reminder shown near the top of the Daily Home screen
/// (S4). Prompts the user to photograph and note her skin once a week.
///
/// Capture is inline: picking a photo appends it (plus any typed note) to
/// today's skin-log entry. The host screen owns the show/hide rule — once a
/// skin-log photo exists within the last 7 days the host stops rendering this
/// card. [onDismiss] snoozes the card for the remainder of today.
class WeeklySkinReminderCard extends ConsumerStatefulWidget {
  final String dateStr;
  final VoidCallback onDismiss;
  final VoidCallback onNeverShow;

  const WeeklySkinReminderCard({
    super.key,
    required this.dateStr,
    required this.onDismiss,
    required this.onNeverShow,
  });

  @override
  ConsumerState<WeeklySkinReminderCard> createState() =>
      _WeeklySkinReminderCardState();
}

class _WeeklySkinReminderCardState
    extends ConsumerState<WeeklySkinReminderCard> {
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onCaptureTap() {
    if (_saving) return;
    if (kIsWeb) {
      _pickAndSave(fromCamera: false);
      return;
    }
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l.skinLogTakePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSave(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l.skinLogGallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSave(fromCamera: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSave({required bool fromCamera}) async {
    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final bytes = await file.readAsBytes();
      final key =
          'skin_${widget.dateStr}_${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(photoRepositoryProvider).savePhoto(key, bytes);

      final repo = ref.read(userDataRepositoryProvider);
      final existing = await repo.watchSkinLog(widget.dateStr).first;
      final note = _notesController.text.trim();

      final entry = existing ??
          SkinLogEntry(
            id: _uuid.v4(),
            date: widget.dateStr,
            photoPaths: const [],
            lastModified: DateTime.now(),
          );

      await repo.upsertSkinLog(
        entry.copyWith(
          photoPaths: [...entry.photoPaths, key],
          notes: note.isEmpty ? entry.notes : note,
          lastModified: DateTime.now(),
        ),
      );
      // The host screen watches skin logs and will hide this card now that a
      // photo exists for today — no explicit dismiss needed.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return GlowCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title block hugs the right edge; camera badge sits to its left
          // (the right side of the card), per the reference mockup.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Eyebrow — same size as the slot header ("Morning Routine").
                    Text(
                      l.weeklyReminderBadge,
                      textAlign: TextAlign.start,
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.weeklyReminderTitle,
                      textAlign: TextAlign.start,
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Camera badge — rounded square, on the right side.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.glowSm,
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 22,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.weeklyReminderBody,
            textAlign: TextAlign.start,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CaptureBox(
                  label: l.weeklyReminderCapture,
                  sublabel: l.weeklyReminderBrowse,
                  saving: _saving,
                  onTap: _onCaptureTap,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.top,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: l.weeklyReminderNotesHint,
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryContainer,
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.fromLTRB(14, 16, 14, 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DismissPillButton(
                  label: l.weeklyReminderDismiss,
                  onTap: widget.onDismiss,
                ),
              ),
              const SizedBox(width: 12),
              _NeverShowButton(
                label: l.weeklyReminderNeverShow,
                onTap: widget.onNeverShow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaptureBox extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool saving;
  final VoidCallback onTap;

  const _CaptureBox({
    required this.label,
    required this.sublabel,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 122,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: saving
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Soft-peach pill CTA — "אחר כך" (snooze for the day) with a clock icon.
class _DismissPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DismissPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain text link — "אל תציג שוב" (turn the weekly reminder off for good).
class _NeverShowButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NeverShowButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
