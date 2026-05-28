import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/skin_log_entry.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';

const _uuid = Uuid();
final _picker = ImagePicker();

class SkinLogEntryScreen extends ConsumerStatefulWidget {
  final String date;

  const SkinLogEntryScreen({super.key, required this.date});

  @override
  ConsumerState<SkinLogEntryScreen> createState() =>
      _SkinLogEntryScreenState();
}

class _SkinLogEntryScreenState extends ConsumerState<SkinLogEntryScreen> {
  late final TextEditingController _notesController;
  bool _dirty = false;
  bool _saving = false;
  // Loaded photo bytes keyed by photoPath
  final Map<String, Uint8List?> _photoCache = {};

  // Skin-state chip selection — backed by in-memory state only (no new persisted field)
  String? _selectedSkinState;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _notesController.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initFromEntry(SkinLogEntry entry) {
    if (!_dirty) {
      _notesController.text = entry.notes ?? '';
      _selectedSkinState = entry.skinState;
    }
  }

  Future<void> _loadPhoto(String path) async {
    if (_photoCache.containsKey(path)) return;
    final bytes = await ref.read(photoRepositoryProvider).readPhoto(path);
    if (mounted) setState(() => _photoCache[path] = bytes);
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    final source =
        fromCamera ? ImageSource.camera : ImageSource.gallery;
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    final key =
        'skin_${widget.date}_${DateTime.now().millisecondsSinceEpoch}';

    await ref.read(photoRepositoryProvider).savePhoto(key, bytes);

    final existingEntry = await ref
        .read(userDataRepositoryProvider)
        .watchSkinLog(widget.date)
        .first;

    final entry = existingEntry ??
        SkinLogEntry(
          id: _uuid.v4(),
          date: widget.date,
          photoPaths: [],
          lastModified: DateTime.now(),
        );

    await ref.read(userDataRepositoryProvider).upsertSkinLog(
          entry.copyWith(
            photoPaths: [...entry.photoPaths, key],
            lastModified: DateTime.now(),
          ),
        );

    setState(() => _photoCache[key] = bytes);
  }

  Future<void> _deletePhoto(SkinLogEntry entry, String photoPath) async {
    await ref.read(photoRepositoryProvider).deletePhoto(photoPath);
    final updated = List<String>.from(entry.photoPaths)
      ..remove(photoPath);
    await ref.read(userDataRepositoryProvider).upsertSkinLog(
          entry.copyWith(
            photoPaths: updated,
            lastModified: DateTime.now(),
          ),
        );
    setState(() => _photoCache.remove(photoPath));
  }

  Future<void> _saveNotes(SkinLogEntry? existingEntry) async {
    if (!_dirty) return;
    setState(() => _saving = true);
    try {
      final entry = existingEntry ??
          SkinLogEntry(
            id: _uuid.v4(),
            date: widget.date,
            photoPaths: [],
            lastModified: DateTime.now(),
          );
      await ref.read(userDataRepositoryProvider).upsertSkinLog(
            entry.copyWith(
              notes: _notesController.text.isEmpty
                  ? null
                  : _notesController.text,
              skinState: _selectedSkinState,
              lastModified: DateTime.now(),
            ),
          );
      if (mounted) setState(() => _dirty = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skinLogAsync = ref.watch(_skinLogProvider(widget.date));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(showBack: true),
      body: skinLogAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (entry) {
          if (entry != null) _initFromEntry(entry);

          // Trigger loading for all photo paths
          if (entry != null) {
            for (final path in entry.photoPaths) {
              _loadPhoto(path);
            }
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  // ── Notes card ─────────────────────────────────────────
                  GlowCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mood,
                                size: 20,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'מצב העור היום',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 5,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'הערות על העור היום...',
                            hintStyle: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primaryContainer,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                            alignLabelWithHint: true,
                          ),
                          onEditingComplete: () =>
                              _saveNotes(skinLogAsync.valueOrNull),
                        ),
                        const SizedBox(height: 12),
                        // Skin-state chips (in-memory selection only)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            _SkinStateChip(
                              label: 'רגוע',
                              selected: _selectedSkinState == 'calm',
                              background: AppColors.tertiaryFixed,
                              foreground: AppColors.onTertiaryContainer,
                              selectedBackground:
                                  AppColors.tertiaryContainer,
                              onTap: () => setState(() {
                                _selectedSkinState =
                                    _selectedSkinState == 'calm'
                                        ? null
                                        : 'calm';
                                _dirty = true;
                              }),
                            ),
                            _SkinStateChip(
                              label: 'לח',
                              selected: _selectedSkinState == 'moist',
                              background: AppColors.secondaryFixed,
                              foreground: AppColors.onSecondaryContainer,
                              selectedBackground:
                                  AppColors.secondaryContainer,
                              onTap: () => setState(() {
                                _selectedSkinState =
                                    _selectedSkinState == 'moist'
                                        ? null
                                        : 'moist';
                                _dirty = true;
                              }),
                            ),
                            _SkinStateChip(
                              label: 'שמני',
                              selected: _selectedSkinState == 'oily',
                              background: AppColors.primaryFixed,
                              foreground: AppColors.primary,
                              selectedBackground:
                                  AppColors.primaryFixedDim,
                              onTap: () => setState(() {
                                _selectedSkinState =
                                    _selectedSkinState == 'oily'
                                        ? null
                                        : 'oily';
                                _dirty = true;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Photos card ────────────────────────────────────────
                  GlowCard(
                    padding: const EdgeInsets.all(16),
                    border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.4),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    color: AppColors.primaryFixed.withOpacity(0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Section title
                        Text(
                          'תמונות',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // Photo grid + add button
                        _buildPhotoGrid(entry),

                        // Web storage warning
                        if (kIsWeb) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'תמונות בדפדפן עשויות להימחק על ידי Safari. גבה את הנתונים שלך.',
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.primary,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),

              // ── Sticky bottom CTA ──────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: AppColors.navGlow,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: _saving
                        ? FilledButton(
                            onPressed: null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              shape: const StadiumBorder(),
                            ),
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          )
                        : FilledButton(
                            onPressed: _dirty
                                ? () => _saveNotes(skinLogAsync.valueOrNull)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _dirty
                                  ? AppColors.primary
                                  : AppColors.outlineVariant,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'שמור',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid(SkinLogEntry? entry) {
    final photos = entry?.photoPaths ?? [];

    // Build grid children: existing photos + add button
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        // Add photo button (dashed, circular peach icon)
        _AddPhotoButton(
          onPickFromCamera:
              kIsWeb ? null : () => _pickPhoto(fromCamera: true),
          onPickFromGallery: () => _pickPhoto(fromCamera: false),
        ),
        // Existing photos
        for (final path in photos)
          _PhotoTile(
            bytes: _photoCache[path],
            onDelete: entry != null
                ? () => _deletePhoto(entry, path)
                : null,
          ),
      ],
    );
  }
}

// ── Skin-state choice chip ──────────────────────────────────────────────────

class _SkinStateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color background;
  final Color foreground;
  final Color selectedBackground;
  final VoidCallback onTap;

  const _SkinStateChip({
    required this.label,
    required this.selected,
    required this.background,
    required this.foreground,
    required this.selectedBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : background,
          borderRadius: BorderRadius.circular(9999),
          border: selected
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Add-photo dashed card ───────────────────────────────────────────────────

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback? onPickFromCamera;
  final VoidCallback onPickFromGallery;

  const _AddPhotoButton({
    required this.onPickFromCamera,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    // Single tap → gallery (or camera on web); long-press → camera on Android
    return GestureDetector(
      onTap: onPickFromGallery,
      onLongPress: onPickFromCamera,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed.withOpacity(0.25),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryContainer.withOpacity(0.6),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'הוסף תמונה',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo tile ──────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback? onDelete;

  const _PhotoTile({required this.bytes, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: bytes != null
                ? Image.memory(
                    bytes!,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
          if (onDelete != null)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final _skinLogProvider =
    StreamProvider.family<SkinLogEntry?, String>(
  (ref, date) =>
      ref.watch(userDataRepositoryProvider).watchSkinLog(date),
);
