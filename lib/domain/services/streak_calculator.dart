import '../entities/day_record.dart';
import '../enums/slot.dart';
import 'day_boundary_service.dart';

class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final int missesThisWeek;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.missesThisWeek,
  });
}

class StreakCalculator {
  StreakResult compute({
    required List<DayRecord> allRecords,
    required DateTime asOf,
    required DayBoundaryService boundary,
  }) {
    if (allRecords.isEmpty) {
      return const StreakResult(
        currentStreak: 0,
        longestStreak: 0,
        missesThisWeek: 0,
      );
    }

    // Build lookup: 'YYYY-MM-DD_slot' → DayRecord
    final Map<String, DayRecord> lookup = {
      for (final r in allRecords) '${r.date}_${r.slot.name}': r,
    };

    final effectiveToday = boundary.effectiveDate(asOf);
    final yesterday = effectiveToday.subtract(const Duration(days: 1));

    // Compute missesThisWeek through yesterday only — today's incomplete slots
    // are not yet "missed" since the day hasn't ended.
    final todayWeekSunday = _weekSunday(effectiveToday);
    final missesThisWeek = _weekMisses(lookup, todayWeekSunday, yesterday, boundary);

    // Walk backward week by week, starting from the week containing yesterday
    int currentStreak = 0;
    int longestStreak = 0;

    DateTime weekStart = _weekSunday(yesterday);
    bool first = true;

    for (int weekIdx = 0; weekIdx < 200; weekIdx++) {
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Determine the range we actually care about for this week
      final rangeEnd = first ? yesterday : weekEnd;
      first = false;

      // Collect days in this week range (weekStart..rangeEnd)
      final int misses = _weekMissesInRange(lookup, weekStart, rangeEnd, boundary);

      if (misses >= 4) {
        // Grace exhausted — streak stops here
        break;
      }

      // Grace covers the misses; count all days with at least one scheduled slot
      final int contributingDays =
          _scheduledDaysInRange(lookup, weekStart, rangeEnd, boundary);
      currentStreak += contributingDays;

      if (currentStreak > longestStreak) longestStreak = currentStreak;

      // If we've gone back before any records exist, stop
      final oldestDate = _oldestRecordDate(allRecords, boundary);
      if (!weekStart.isAfter(oldestDate)) break;

      weekStart = weekStart.subtract(const Duration(days: 7));
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      missesThisWeek: missesThisWeek,
    );
  }

  /// Sunday of the Sun-Sat week containing [date].
  DateTime _weekSunday(DateTime date) {
    // Dart weekday: Mon=1..Sun=7 → days since last Sunday = weekday % 7
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  bool _isDone(DayRecord? r) =>
      r != null && r.resolvedProductIds.isNotEmpty && r.recordedProductIds.isNotEmpty;

  bool _isScheduled(DayRecord? r) =>
      r != null && r.resolvedProductIds.isNotEmpty;

  int _missCount(DayRecord? r) =>
      (_isScheduled(r) && !_isDone(r)) ? 1 : 0;

  int _weekMisses(
    Map<String, DayRecord> lookup,
    DateTime weekSunday,
    DateTime through,
    DayBoundaryService boundary,
  ) {
    return _weekMissesInRange(lookup, weekSunday, through, boundary);
  }

  int _weekMissesInRange(
    Map<String, DayRecord> lookup,
    DateTime from,
    DateTime through,
    DayBoundaryService boundary,
  ) {
    int misses = 0;
    DateTime cursor = from;
    while (!cursor.isAfter(through)) {
      final d = boundary.formatDate(cursor);
      misses += _missCount(lookup['${d}_${Slot.morning.name}']);
      misses += _missCount(lookup['${d}_${Slot.evening.name}']);
      cursor = cursor.add(const Duration(days: 1));
    }
    return misses;
  }

  int _scheduledDaysInRange(
    Map<String, DayRecord> lookup,
    DateTime from,
    DateTime through,
    DayBoundaryService boundary,
  ) {
    int count = 0;
    DateTime cursor = from;
    while (!cursor.isAfter(through)) {
      final d = boundary.formatDate(cursor);
      final morning = lookup['${d}_${Slot.morning.name}'];
      final evening = lookup['${d}_${Slot.evening.name}'];
      if (_isScheduled(morning) || _isScheduled(evening)) count++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  DateTime _oldestRecordDate(List<DayRecord> records, DayBoundaryService b) {
    return records
        .map((r) => b.parseDate(r.date))
        .reduce((a, c) => a.isBefore(c) ? a : c);
  }
}
