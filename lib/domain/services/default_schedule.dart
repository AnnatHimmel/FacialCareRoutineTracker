/// Default weekday placement for a capped (weekly-max) product (PRD §15.5).
///
/// When a product is used a fixed number of times per week, we seed a sensible
/// default schedule that spreads those uses evenly across the week instead of
/// bunching them on consecutive days (e.g. an exfoliant used 3×/week should
/// land on roughly every-other-day, not three days in a row).
///
/// Spacing rule: place the i-th use (0-based) on weekday `floor(i * 7 / n)`.
/// This distributes `n` uses across the 7-day cycle as evenly as integer
/// rounding allows, anchored at Sunday (index 0). It is deterministic and
/// produces an ascending, duplicate-free list.
///
/// Weekday indices are 0 = Sunday … 6 = Saturday, matching [WeekdaySchedule].
///
/// Edge cases:
///   * `n <= 0` → empty list (nothing scheduled).
///   * `n >= 7` → every day `[0, 1, 2, 3, 4, 5, 6]`.
///
/// Examples:
///   * `spreadWeekdays(1)` → `[0]`
///   * `spreadWeekdays(2)` → `[0, 3]`
///   * `spreadWeekdays(3)` → `[0, 2, 4]`
///   * `spreadWeekdays(4)` → `[0, 1, 3, 5]`
List<int> spreadWeekdays(int n) {
  if (n <= 0) return const [];
  if (n >= 7) return const [0, 1, 2, 3, 4, 5, 6];

  final days = <int>[];
  for (var i = 0; i < n; i++) {
    days.add((i * 7) ~/ n);
  }
  return days;
}
