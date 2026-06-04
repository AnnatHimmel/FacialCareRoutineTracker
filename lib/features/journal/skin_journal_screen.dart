import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/l10n/hebrew_date_strings.dart' show HebrewDateStrings, EnglishDateStrings;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/skin_log_entry.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';

class SkinJournalScreen extends ConsumerWidget {
  const SkinJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final allLogsAsync = ref.watch(_allSkinLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: allLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (logs) {
          final withPhotos = logs
              .where((entry) => entry.photoPaths.isNotEmpty)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (withPhotos.isEmpty) {
            return _EmptyJournalState(
              onAddEntry: () => context.push('/skin-log/new'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: withPhotos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final log = withPhotos[index];
              return _JournalEntryCard(
                log: log,
                onTap: () => context.push('/skin-log/${log.date}'),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single journal entry card
// ---------------------------------------------------------------------------

class _JournalEntryCard extends ConsumerWidget {
  final SkinLogEntry log;
  final VoidCallback onTap;

  const _JournalEntryCard({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final formattedDate = _formatDate(log.date, l);
    final hasNote = log.notes != null && log.notes!.isNotEmpty;

    return GlowCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              formattedDate,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          _PhotoGrid(photoPaths: log.photoPaths, date: log.date),

          if (hasNote) ...[
            const SizedBox(height: 12),
            Text(
              log.notes!,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.start,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String date, AppLocalizations l) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = parts[0];
    if (month < 1 || month > 12) return date;
    final isEn = l.localeName == 'en';
    final monthName = isEn ? EnglishDateStrings.months[month - 1] : HebrewDateStrings.months[month - 1];
    final dayStr = isEn ? EnglishDateStrings.ordinal(day) : '$day';
    return l.journalDateFormat(dayStr, monthName, year);
  }
}

// ---------------------------------------------------------------------------
// Photo grid inside a card (max 4 shown, rest collapsed)
// ---------------------------------------------------------------------------

class _PhotoGrid extends StatelessWidget {
  final List<String> photoPaths;
  final String date;

  const _PhotoGrid({required this.photoPaths, required this.date});

  @override
  Widget build(BuildContext context) {
    final display = photoPaths.take(4).toList();
    final overflow = photoPaths.length - display.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = display.length == 1 ? 1 : 2;
        final itemSize = cols == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / 2;

        final rows = <Widget>[];
        for (var i = 0; i < display.length; i += cols) {
          final rowItems = <Widget>[];
          for (var c = 0; c < cols; c++) {
            final idx = i + c;
            if (idx < display.length) {
              final Widget thumb = _PhotoThumb(
                photoPath: display[idx],
                size: itemSize,
                overflowCount:
                    (overflow > 0 && idx == display.length - 1) ? overflow : 0,
              );
              rowItems.add(thumb);
            } else {
              rowItems.add(SizedBox(width: itemSize, height: itemSize));
            }
            if (c < cols - 1) rowItems.add(const SizedBox(width: 8));
          }
          rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: rowItems,
          ));
          if (i + cols < display.length) rows.add(const SizedBox(height: 8));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Single photo thumbnail (lazy-loads bytes via PhotoRepository)
// ---------------------------------------------------------------------------

class _PhotoThumb extends ConsumerStatefulWidget {
  final String photoPath;
  final double size;
  final int overflowCount;

  const _PhotoThumb({
    required this.photoPath,
    required this.size,
    this.overflowCount = 0,
  });

  @override
  ConsumerState<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends ConsumerState<_PhotoThumb> {
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
    Widget image;

    if (!_loaded) {
      image = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_bytes != null) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _bytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      image = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.outlineVariant,
        ),
      );
    }

    if (widget.overflowCount > 0) {
      return Stack(
        children: [
          image,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.onSurface.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '+${widget.overflowCount}',
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return image;
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyJournalState extends StatelessWidget {
  final VoidCallback onAddEntry;

  const _EmptyJournalState({required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
                boxShadow: AppColors.glow,
              ),
              child: const Icon(
                Icons.photo_album_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              l.journalNoPhotos,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              l.journalEmptyInstruction,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAddEntry,
                child: Text(l.journalStartDocumenting),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _allSkinLogsProvider = StreamProvider<List<SkinLogEntry>>(
  (ref) =>
      ref.watch(userDataRepositoryProvider).watchAllSkinLogs(),
);
