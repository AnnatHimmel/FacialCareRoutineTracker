import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/enums/day_completion_state.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/completion_indicator.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() {
        _displayMonth = DateTime(
          _displayMonth.year,
          _displayMonth.month - 1,
        );
      });

  void _nextMonth() => setState(() {
        _displayMonth = DateTime(
          _displayMonth.year,
          _displayMonth.month + 1,
        );
      });

  @override
  Widget build(BuildContext context) {
    final yearMonth =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}';
    final recordsAsync = ref.watch(_monthRecordsProvider(yearMonth));
    final boundary = ref.read(dayBoundaryServiceProvider);
    final today = boundary.effectiveDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: Column(
        children: [
          // Month navigation
          GlowCard(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            radius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _displayMonth.isBefore(DateTime(today.year, today.month))
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

          // Calendar grid wrapped in GlowCard (includes day-of-week headers)
          GlowCard(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Day-of-week headers (RTL: Sunday on right, Saturday on left)
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

                // Calendar grid
                recordsAsync.when(
                  loading: () =>
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error: (e, _) =>
                      SizedBox(
                        height: 200,
                        child: Center(child: Text('שגיאה: $e')),
                      ),
                  data: (records) {
                    return _buildGrid(records, today, context);
                  },
                ),
              ],
            ),
          ),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<DayRecord> records,
    DateTime today,
    BuildContext context,
  ) {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;

    // Compute states for each day
    final Map<String, DayCompletionState> states = {};
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_displayMonth.year, _displayMonth.month, d);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayRecords =
          records.where((r) => r.date == dateStr).toList();
      states[dateStr] = _computeState(dayRecords, date, today);
    }

    // Offset: how many columns the first day shifts (0=Sunday, 6=Saturday)
    // In RTL grid col 0 is Saturday, col 6 is Sunday
    // firstDay.weekday: Mon=1..Sun=7, so Sunday offset from right = 7-firstDay.weekday%7
    // Actually: Dart Sunday weekday=7, so (7 % 7 = 0 = Sunday in 0-indexed 0=Sun..6=Sat)
    // In RTL grid where Sunday is col 6 (rightmost), offset = firstDay.weekday % 7
    final offset = firstDay.weekday % 7; // Sun=0, Mon=1, ..., Sat=6

    final cells = <Widget>[];
    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_displayMonth.year, _displayMonth.month, d);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final state = states[dateStr] ?? DayCompletionState.noData;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      cells.add(_DayCell(
        day: d,
        state: state,
        isToday: isToday,
        onTap: () => context.push('/day/$dateStr'),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.all(8),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 0.9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // RTL: GridView already respects Directionality
      children: cells,
    );
  }

  DayCompletionState _computeState(
    List<DayRecord> records,
    DateTime date,
    DateTime today,
  ) {
    if (date.isAfter(today)) return DayCompletionState.future;

    final morning = records
        .where((r) => r.slot == Slot.morning)
        .firstOrNull;
    final evening = records
        .where((r) => r.slot == Slot.evening)
        .firstOrNull;

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
    return GlowCard(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      radius: 20,
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          for (final (state, label) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CompletionIndicator(state: state, size: 20),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

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

class _DayCell extends StatelessWidget {
  final int day;
  final DayCompletionState state;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.state,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primaryFixed
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.glowSm,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: AppTypography.labelSm.copyWith(
                color: isToday
                    ? AppColors.primary
                    : AppColors.onSurface,
                fontWeight:
                    isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            CompletionIndicator(state: state, size: 18),
          ],
        ),
      ),
    );
  }
}

final _monthRecordsProvider =
    StreamProvider.family<List<DayRecord>, String>(
  (ref, yearMonth) => ref
      .watch(userDataRepositoryProvider)
      .watchDayRecordsForMonth(yearMonth),
);
