import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/hebrew_date_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/entities/skin_log_entry.dart';
import '../../domain/services/calendar_stats.dart';
import '../../domain/enums/day_completion_state.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/completion_indicator.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/skin_state_chip.dart';

// ═══════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _displayMonth;
  String? _selectedDay; // "YYYY-MM-DD" or null

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _selectedDay =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _prevMonth() => setState(() {
        final newMonth =
            DateTime(_displayMonth.year, _displayMonth.month - 1);
        _displayMonth = newMonth;
        final now = DateTime.now();
        _selectedDay =
            (newMonth.year == now.year && newMonth.month == now.month)
                ? _todayStr()
                : null;
      });

  void _nextMonth() => setState(() {
        final newMonth =
            DateTime(_displayMonth.year, _displayMonth.month + 1);
        _displayMonth = newMonth;
        final now = DateTime.now();
        _selectedDay =
            (newMonth.year == now.year && newMonth.month == now.month)
                ? _todayStr()
                : null;
      });

  @override
  Widget build(BuildContext context) {
    final yearMonth =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}';
    final prevMonthDt =
        DateTime(_displayMonth.year, _displayMonth.month - 1);
    final prevYearMonth =
        '${prevMonthDt.year}-${prevMonthDt.month.toString().padLeft(2, '0')}';

    final recordsAsync = ref.watch(_monthRecordsProvider(yearMonth));
    final prevRecordsAsync = ref.watch(_monthRecordsProvider(prevYearMonth));
    final boundary = ref.read(dayBoundaryServiceProvider);
    final today = boundary.effectiveDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (records) {
          final prevRecords = prevRecordsAsync.valueOrNull ?? [];
          final todayStr = _dateStr(today);
          final avgPct = computeMonthAvg(records, today: todayStr);
          final prevAvgPct = computeMonthAvg(prevRecords, today: todayStr);
          final progressPct =
              prevRecords.isEmpty ? null : avgPct - prevAvgPct;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Stats row ────────────────────────────────────────────
                _StatsRow(avgPct: avgPct, progressPct: progressPct),
                const SizedBox(height: 8),

                // ── Month nav ────────────────────────────────────────────
                GlowCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  radius: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: !_displayMonth.isBefore(
                                DateTime(today.year, today.month))
                            ? null
                            : _nextMonth,
                        color: AppColors.onSurface,
                      ),
                      Text(
                        _monthLabel(_displayMonth),
                        style: AppTypography.headlineMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _prevMonth,
                        color: AppColors.onSurface,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ── Calendar grid + legend ──────────────────────────────
                GlowCard(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          _DayHeader('א׳'),
                          _DayHeader('ב׳'),
                          _DayHeader('ג׳'),
                          _DayHeader('ד׳'),
                          _DayHeader('ה׳'),
                          _DayHeader('ו׳'),
                          _DayHeader('ש׳'),
                        ],
                      ),
                      _buildGrid(records, today),
                      _buildLegend(),
                    ],
                  ),
                ),

                // ── Day detail ───────────────────────────────────────────
                if (_selectedDay != null) ...[
                  const SizedBox(height: 4),
                  _DayDetailSection(
                    date: _selectedDay!,
                    dayRecords: records
                        .where((r) => r.date == _selectedDay)
                        .toList(),
                    onEditTap: () =>
                        context.push('/skin-log/$_selectedDay'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<DayRecord> records, DateTime today) {
    final firstDay =
        DateTime(_displayMonth.year, _displayMonth.month);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;

    final Map<String, DayCompletionState> states = {};
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_displayMonth.year, _displayMonth.month, d);
      final dateStr = _dateStr(date);
      final dayRecords = records.where((r) => r.date == dateStr).toList();
      states[dateStr] = _computeState(dayRecords, date, today);
    }

    final offset = firstDay.weekday % 7;
    final cells = <Widget>[];
    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_displayMonth.year, _displayMonth.month, d);
      final dateStr = _dateStr(date);
      final state = states[dateStr] ?? DayCompletionState.noData;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      cells.add(_DayCell(
        day: d,
        state: state,
        isToday: isToday,
        isSelected: _selectedDay == dateStr,
        onTap: () => setState(() {
          _selectedDay = _selectedDay == dateStr ? null : dateStr;
        }),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      mainAxisSpacing: 3,
      crossAxisSpacing: 4,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  DayCompletionState _computeState(
    List<DayRecord> records,
    DateTime date,
    DateTime today,
  ) {
    if (date.isAfter(today)) return DayCompletionState.future;

    final morning =
        records.where((r) => r.slot == Slot.morning).firstOrNull;
    final evening =
        records.where((r) => r.slot == Slot.evening).firstOrNull;

    int scheduled = 0;
    int done = 0;
    for (final r in [morning, evening]) {
      if (r == null) continue;
      if (r.resolvedProductIds.isNotEmpty) {
        scheduled++;
        if (r.recordedProductIds.isNotEmpty) done++;
      }
    }

    if (scheduled == 0) return DayCompletionState.noData;
    if (done == scheduled) return DayCompletionState.complete;
    if (done > 0) return DayCompletionState.partial;
    return DayCompletionState.missed;
  }

  Widget _buildLegend() {
    const items = [
      (DayCompletionState.complete, 'הושלם'),
      (DayCompletionState.partial, 'חלקי'),
      (DayCompletionState.missed, 'הוחמץ'),
      (DayCompletionState.noData, 'ללא נתונים'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          for (final (state, label) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CompletionIndicator(state: state, size: 10),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    return '${HebrewDateStrings.months[date.month - 1]} ${date.year}';
  }

  static String _dateStr(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════════════════════════════
// STATS ROW
// ═══════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final double avgPct;
  final double? progressPct;

  const _StatsRow({required this.avgPct, this.progressPct});

  @override
  Widget build(BuildContext context) {
    final avgInt = (avgPct * 100).round();
    final progInt = progressPct == null
        ? null
        : (progressPct! * 100).round();

    return Row(
      children: [
        // Monthly average card
        Expanded(
          child: GlowCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'ממוצע חודשי',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  '$avgInt%',
                  style: AppTypography.headlineLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: avgPct,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.primaryFixed.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryFixedDim),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Progress / trend card
        Expanded(
          child: GlowCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'התקדמות',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                if (progInt != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        progInt >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: progInt >= 0
                            ? AppColors.primary
                            : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${progInt >= 0 ? '+' : ''}$progInt%',
                        style: AppTypography.headlineMd.copyWith(
                          color: progInt >= 0
                              ? AppColors.primary
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'לעומת חודש קודם',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    '—',
                    style: AppTypography.headlineMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'אין נתוני השוואה',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DAY DETAIL SECTION
// ═══════════════════════════════════════════════════════════════════

class _DayDetailSection extends ConsumerWidget {
  final String date;
  final List<DayRecord> dayRecords;
  final VoidCallback onEditTap;

  const _DayDetailSection({
    required this.date,
    required this.dayRecords,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinLogAsync = ref.watch(_skinLogProvider(date));
    final masterAsync = ref.watch(masterContentProvider);
    final customProducts = ref.watch(customProductsProvider).valueOrNull ?? [];

    final parts = date.split('-');
    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    const monthNames = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
    ];
    final monthName = monthNames[month - 1];

    final skinLog = skinLogAsync.valueOrNull;
    final photoPaths = skinLog?.photoPaths ?? const [];
    final notes = skinLog?.notes;
    final skinState = skinLog?.skinState;

    // All unique resolved product IDs (preserving slot order: morning then evening)
    final resolvedIds = dayRecords
        .expand((r) => r.resolvedProductIds)
        .toSet()
        .toList();

    // Which of those were actually recorded (done)
    final recordedSet = dayRecords
        .expand((r) => r.recordedProductIds)
        .toSet();

    final productNames = <String, String>{};
    final master = masterAsync.valueOrNull;
    if (master != null) {
      for (final p in master.products) {
        productNames[p.id] = p.name;
      }
    }
    for (final p in customProducts) {
      productNames[p.id] = p.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'תיעוד יומי: $day ב$monthName',
              style: AppTypography.bodyLg.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: onEditTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'ערוך',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Photos grid (always shows add-photo cell)
        _buildPhotosGrid(photoPaths),
        const SizedBox(height: 12),

        // Mood / notes card
        _buildNotesCard(skinState, notes),
        const SizedBox(height: 12),

        // All resolved products with done/undone state
        if (resolvedIds.isNotEmpty)
          _buildProductsCard(resolvedIds, recordedSet, productNames),
      ],
    );
  }

  Widget _buildPhotosGrid(List<String> photoPaths) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _AddPhotoCell(onTap: onEditTap),
        for (final path in photoPaths) _PhotoCell(photoPath: path),
      ],
    );
  }

  Widget _buildNotesCard(String? skinState, String? notes) {
    final hasContent =
        (notes != null && notes.isNotEmpty) || skinState != null;

    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mood_outlined,
                    size: 20, color: AppColors.onSecondaryContainer),
              ),
              Text(
                'מצב העור היום',
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          if (hasContent) ...[
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notes,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            ],
            if (skinState != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SkinStateChip(state: skinState),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'לא נרשמו הערות',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }

Widget _buildProductsCard(
    List<String> resolvedIds,
    Set<String> recordedSet,
    Map<String, String> productNames,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: AppColors.primaryFixed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'משימות שביצעו היום:',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          for (final id in resolvedIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.glowSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Done: filled secondary circle; undone: bordered empty circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28,
                      height: 28,
                      decoration: recordedSet.contains(id)
                          ? const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            )
                          : BoxDecoration(
                              color: AppColors.surfaceLow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.outlineVariant,
                                  width: 2),
                            ),
                      child: recordedSet.contains(id)
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                    Flexible(
                      child: Text(
                        productNames[id] ?? id,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ADD PHOTO CELL
// ═══════════════════════════════════════════════════════════════════

class _AddPhotoCell extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoCell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryFixed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryFixedDim.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'הוסף תמונה',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PHOTO CELL
// ═══════════════════════════════════════════════════════════════════

class _PhotoCell extends ConsumerWidget {
  final String photoPath;

  const _PhotoCell({required this.photoPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(_photoProvider(photoPath));
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: photoAsync.when(
        loading: () => Container(
          color: AppColors.surfaceContainer,
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => Container(
          color: AppColors.surfaceContainer,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.onSurfaceVariant),
        ),
        data: (bytes) => bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Container(
                color: AppColors.surfaceContainer,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: AppColors.onSurfaceVariant),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DAY HEADER
// ═══════════════════════════════════════════════════════════════════

class _DayHeader extends StatelessWidget {
  final String label;

  const _DayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DAY CELL
// ═══════════════════════════════════════════════════════════════════

class _DayCell extends StatelessWidget {
  final int day;
  final DayCompletionState state;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.state,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (isSelected) {
      bg = AppColors.primaryFixed;
    } else if (isToday) {
      bg = AppColors.primaryFixed.withValues(alpha: 0.5);
    } else {
      bg = AppColors.surfaceContainerLowest;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.glowSm,
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: AppTypography.labelSm.copyWith(
                  color: (isToday || isSelected)
                      ? AppColors.primary
                      : AppColors.onSurface,
                  fontWeight: (isToday || isSelected)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              CompletionIndicator(state: state, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════

final _monthRecordsProvider =
    StreamProvider.family<List<DayRecord>, String>(
  (ref, yearMonth) => ref
      .watch(userDataRepositoryProvider)
      .watchDayRecordsForMonth(yearMonth),
);

final _skinLogProvider =
    StreamProvider.family<SkinLogEntry?, String>(
  (ref, date) =>
      ref.watch(userDataRepositoryProvider).watchSkinLog(date),
);

final _photoProvider =
    FutureProvider.family<Uint8List?, String>(
  (ref, path) =>
      ref.watch(photoRepositoryProvider).readPhoto(path),
);
