import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/skin_log_entry.dart';
import '../../shared/providers/root_providers.dart';

class SkinJournalScreen extends ConsumerWidget {
  const SkinJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allLogsAsync = ref.watch(_allSkinLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('יומן עור', style: AppTypography.headlineMd),
      ),
      body: allLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (logs) {
          final withPhotos = logs
              .where((l) => l.photoPaths.isNotEmpty)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (withPhotos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_album_outlined,
                    size: 64,
                    color: AppColors.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'אין תמונות עדיין',
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'הוסף תמונות ביומן העור היומי',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: withPhotos.fold<int>(
              0,
              (sum, l) => sum + l.photoPaths.length,
            ),
            itemBuilder: (context, index) {
              // Find which entry and photo index correspond to this grid index
              int offset = 0;
              for (final log in withPhotos) {
                if (index < offset + log.photoPaths.length) {
                  final photoPath = log.photoPaths[index - offset];
                  return _JournalPhotoTile(
                    photoPath: photoPath,
                    date: log.date,
                    onTap: () => context.push('/skin-log/${log.date}'),
                  );
                }
                offset += log.photoPaths.length;
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _JournalPhotoTile extends ConsumerStatefulWidget {
  final String photoPath;
  final String date;
  final VoidCallback onTap;

  const _JournalPhotoTile({
    required this.photoPath,
    required this.date,
    required this.onTap,
  });

  @override
  ConsumerState<_JournalPhotoTile> createState() =>
      _JournalPhotoTileState();
}

class _JournalPhotoTileState extends ConsumerState<_JournalPhotoTile> {
  Uint8List? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await ref
        .read(photoRepositoryProvider)
        .readPhoto(widget.photoPath);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: !_loaded
            ? Container(
                color: AppColors.surfaceContainer,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _bytes != null
                ? Image.memory(
                    _bytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(
                    color: AppColors.surfaceContainer,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.outlineVariant,
                    ),
                  ),
      ),
    );
  }
}

final _allSkinLogsProvider = StreamProvider<List<SkinLogEntry>>(
  (ref) =>
      ref.watch(userDataRepositoryProvider).watchAllSkinLogs(),
);
