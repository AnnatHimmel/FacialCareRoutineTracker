import '../entities/master_product.dart';
import '../entities/weekday_schedule.dart';
import '../enums/slot.dart';

/// Leaf helper — no imports from other services, safe to import from anywhere.
///
/// [effectiveDays] is the canonical rule: an explicit schedule row wins (even
/// an empty set = intentionally excluded); else DailyRule → {0..6},
/// WeeklyMaxRule → {}.
Set<int> effectiveDays(
  MasterProduct p,
  Slot slot,
  List<WeekdaySchedule> schedules,
) {
  final row =
      schedules.where((s) => s.productId == p.id && s.slot == slot).firstOrNull;
  if (row != null) return Set<int>.from(row.weekdays);
  final rule = p.configForSlot(slot)?.frequencyRule;
  if (rule is DailyRule) return {0, 1, 2, 3, 4, 5, 6};
  return {};
}

/// Default placement when a product is first added / has no row:
/// DailyRule → {0..6}; WeeklyMaxRule → evenly spread N days.
Set<int> defaultDaysFor(MasterProduct p, Slot slot) {
  final rule = p.configForSlot(slot)?.frequencyRule;
  if (rule is WeeklyMaxRule) return spreadN7(rule.maxPerWeek);
  return {0, 1, 2, 3, 4, 5, 6};
}

/// Evenly spreads [n] days across the week (0–6).
Set<int> spreadN7(int n) {
  final result = <int>{};
  for (var i = 0; i < n; i++) {
    result.add((i * 7 ~/ n));
  }
  return result;
}
