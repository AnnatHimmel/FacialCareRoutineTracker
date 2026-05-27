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
      appBar: AppBar(
        title: Text('יומן עור', style: AppTypography.headlineMd),
        actions: [
          if (_dirty)
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: () =>
                        _saveNotes(skinLogAsync.valueOrNull),
                    child: Text(
                      'שמור',
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
        ],
      ),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Notes input
              TextField(
                controller: _notesController,
                maxLines: 5,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'הערות על העור היום...',
                  hintStyle: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  alignLabelWithHint: true,
                ),
                onEditingComplete: () =>
                    _saveNotes(skinLogAsync.valueOrNull),
              ),

              const SizedBox(height: 24),

              // Photo section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('תמונות', style: AppTypography.headlineMd),
                  Row(
                    children: [
                      if (!kIsWeb)
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: () =>
                              _pickPhoto(fromCamera: true),
                          color: AppColors.primary,
                          tooltip: 'צלם תמונה',
                        ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined),
                        onPressed: () =>
                            _pickPhoto(fromCamera: false),
                        color: AppColors.primary,
                        tooltip: 'בחר מהגלריה',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Photo grid
              if (entry != null && entry.photoPaths.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: entry.photoPaths.length,
                  itemBuilder: (context, index) {
                    final path = entry.photoPaths[index];
                    final bytes = _photoCache[path];
                    return _PhotoTile(
                      bytes: bytes,
                      onDelete: () => _deletePhoto(entry, path),
                    );
                  },
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'אין תמונות עדיין',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

              // Web storage warning
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'תמונות בדפדפן עשויות להימחק על ידי Safari. גבה את הנתונים שלך.',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onDelete;

  const _PhotoTile({required this.bytes, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: bytes != null
              ? Image.memory(
                  bytes!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: AppColors.surfaceContainer,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        ),
        Positioned(
          top: 4,
          left: 4,
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
    );
  }
}

final _skinLogProvider =
    StreamProvider.family<SkinLogEntry?, String>(
  (ref, date) =>
      ref.watch(userDataRepositoryProvider).watchSkinLog(date),
);
