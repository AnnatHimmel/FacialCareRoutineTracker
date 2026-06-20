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
import '../../shared/widgets/pro_tag.dart';
import '../../core/config/feature_flags.dart';

class SkinJournalScreen extends ConsumerWidget {
  const SkinJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final allLogsAsync = ref.watch(_allSkinLogsProvider);
    final today = ref.watch(effectiveDateProvider);

    // Build a set of date strings that have skin-log entries.
    final skinLogDates = allLogsAsync.whenOrNull(
      data: (logs) => logs.map((e) => e.date).toSet(),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(
        title: l.navJournal,
        action: IconButton(
          icon: const Icon(Icons.calendar_today_rounded, size: 24),
          color: AppColors.primary,
          onPressed: () => context.push('/calendar'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () => context.push('/skin-log/new'),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGlowGradient,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: AppColors.glowLg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_a_photo_rounded,
                  size: 20,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  l.journalNewEntry,
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: allLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (logs) {
          final withPhotos = logs
              .where((entry) => entry.photoPaths.isNotEmpty)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          // Always show ListView with adherence card
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              _AdherenceCard(
                today: today,
                skinLogDates: skinLogDates ?? const {},
              ),
              const SizedBox(height: 24),
              if (withPhotos.isEmpty) ...[
                _EmptyTimelineState(
                  onAddEntry: () => context.push('/skin-log/new'),
                ),
              ] else ...[
                _JournalSectionHeader(),
                const SizedBox(height: 12),
                ..._buildTimeline(context, withPhotos, today),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTimeline(
    BuildContext context,
    List<SkinLogEntry> logs,
    DateTime today,
  ) {
    return [
      for (final log in logs)
        _ProgressEntry(
          log: log,
          today: today,
          onTap: () => context.push('/skin-log/${log.date}'),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Adherence summary card
// ---------------------------------------------------------------------------

class _AdherenceCard extends StatelessWidget {
  final DateTime today;
  final Set<String> skinLogDates;

  const _AdherenceCard({
    required this.today,
    required this.skinLogDates,
  });

  /// Returns Sunday of the current week.
  DateTime _weekStart(DateTime date) {
    final weekday = date.weekday % 7; // Sunday = 0, Mon = 1, ...
    return DateTime(date.year, date.month, date.day - weekday);
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');
  String _dateStr(DateTime d) =>
      '${d.year}-${_twoDigit(d.month)}-${_twoDigit(d.day)}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEn = l.localeName == 'en';
    final sunday = _weekStart(today);

    final monthName = isEn
        ? EnglishDateStrings.months[today.month - 1]
        : HebrewDateStrings.months[today.month - 1];

    // Day-letter abbreviations Sunday-first
    final dayLetters = isEn
        ? const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        : const ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

    return GlowCard(
      padding: const EdgeInsets.all(16),
      shadow: AppColors.glow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row — month name + "חודש מלא" calendar link
          Row(
            children: [
              Text(
                monthName,
                style: AppTypography.labelMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/calendar'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'חודש מלא',
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 7-column grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = sunday.add(Duration(days: i));
              final dayStr = _dateStr(day);
              final todayStr = _dateStr(today);
              final isFuture = day.isAfter(today);
              final isToday = dayStr == todayStr;
              final hasEntry = skinLogDates.contains(dayStr);

              Color fillColor;
              Color textColor;
              List<BoxShadow>? shadow;

              if (isFuture) {
                // future: bg-surface-high/60, muted text
                fillColor = AppColors.surfaceHigh.withAlpha(153);
                textColor = AppColors.onSurfaceVariant.withAlpha(128);
                shadow = null;
              } else if (isToday) {
                // today: bg-primary text-white shadow-glow-sm
                fillColor = AppColors.primary;
                textColor = AppColors.onPrimary;
                shadow = AppColors.glowSm;
              } else if (hasEntry) {
                // done (has skin-log entry): bg-secondary-fixed/80 text-on-secondary-container
                fillColor = AppColors.secondaryFixed.withAlpha(204);
                textColor = AppColors.onSecondaryContainer;
                shadow = null;
              } else {
                // no entry (past, no log): surface-high/60, muted text
                fillColor = AppColors.surfaceHigh.withAlpha(153);
                textColor = AppColors.onSurfaceVariant.withAlpha(128);
                shadow = null;
              }

              return Column(
                children: [
                  Text(
                    dayLetters[i],
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: fillColor,
                      shape: BoxShape.circle,
                      boxShadow: shadow,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Journal section header
// ---------------------------------------------------------------------------

class _JournalSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          l.journalProgressTitle,
          style: AppTypography.bodyLg.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const Spacer(),
        if (kProFeaturesEnabled) const ProTag(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline entry (left spine + right card)
// ---------------------------------------------------------------------------

class _ProgressEntry extends ConsumerWidget {
  final SkinLogEntry log;
  final DateTime today;
  final VoidCallback onTap;

  const _ProgressEntry({
    required this.log,
    required this.today,
    required this.onTap,
  });

  String _relativeLabel(String date, AppLocalizations l) {
    final parts = date.split('-');
    if (parts.length != 3) return '';
    final entryDate = DateTime.tryParse(date);
    if (entryDate == null) return '';
    final todayDate =
        DateTime(today.year, today.month, today.day);
    final entryDay =
        DateTime(entryDate.year, entryDate.month, entryDate.day);
    final diff = todayDate.difference(entryDay).inDays;
    if (diff == 0) return l.localeName == 'en' ? 'Today' : 'היום';
    if (diff == 1) return l.localeName == 'en' ? 'Yesterday' : 'אתמול';
    return l.localeName == 'en'
        ? '$diff days ago'
        : 'לפני $diff ימים';
  }

  String _formatDate(String date, AppLocalizations l) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = parts[0];
    if (month < 1 || month > 12) return date;
    final isEn = l.localeName == 'en';
    final monthName = isEn
        ? EnglishDateStrings.months[month - 1]
        : HebrewDateStrings.months[month - 1];
    final dayStr =
        isEn ? EnglishDateStrings.ordinal(day) : '$day';
    return l.journalDateFormat(dayStr, monthName, year);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final hasNote = log.notes != null && log.notes!.isNotEmpty;
    final formattedDate = _formatDate(log.date, l);
    final relLabel = _relativeLabel(log.date, l);

    final hasSkinState =
        log.skinState != null && log.skinState!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left padding for the dot+spine column (15px dot centred in 22px)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 22),
            child: GlowCard(
              radius: 24,
              padding: const EdgeInsets.all(16),
              shadow: AppColors.glowSm,
              border: Border.all(
                color: AppColors.outlineVariant.withAlpha(51),
              ),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: AppTypography.labelMd.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relLabel,
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant.withAlpha(204),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (hasSkinState) ...[
                    const SizedBox(height: 8),
                    _ConditionChip(label: log.skinState!),
                  ],
                  const SizedBox(height: 12),
                  _PhotoGrid(
                    photoPaths: log.photoPaths,
                    date: log.date,
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 12),
                    Text(
                      log.notes!,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Spine — runs from dot downward, behind the dot
          PositionedDirectional(
            start: 7,
            top: 14,
            bottom: -18,
            child: Container(
              width: 1,
              color: AppColors.primaryFixed,
            ),
          ),
          // Dot — 15px, primaryContainer fill, 3px white border, glowSm shadow
          PositionedDirectional(
            start: 0,
            top: 6,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.onPrimary,
                  width: 3,
                ),
                boxShadow: AppColors.glowSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Condition chip (from skinState field)
// ---------------------------------------------------------------------------

class _ConditionChip extends StatelessWidget {
  final String label;

  const _ConditionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
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
// Empty timeline state (shown below adherence card when no photos exist)
// ---------------------------------------------------------------------------

class _EmptyTimelineState extends StatelessWidget {
  final VoidCallback onAddEntry;
  const _EmptyTimelineState({required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JournalSectionHeader(),
        const SizedBox(height: 24),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 48,
                color: AppColors.onSurfaceVariant.withAlpha(100),
              ),
              const SizedBox(height: 12),
              Text(
                l.journalNoPhotos,
                style: AppTypography.bodyLg.copyWith(
                  fontWeight: FontWeight.w700,
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAddEntry,
                child: Text(l.journalStartDocumenting),
              ),
            ],
          ),
        ),
      ],
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
