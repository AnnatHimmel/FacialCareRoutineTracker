import '../entities/category.dart';
import '../entities/master_product.dart';
import '../entities/product_selection.dart';
import '../entities/weekday_schedule.dart';
import '../entities/order_override.dart';
import '../enums/slot.dart';
import 'day_boundary_service.dart';

class RoutineResolver {
  /// Returns products active for [date]+[slot] in effective order.
  List<MasterProduct> resolve({
    required DateTime date,
    required Slot slot,
    required List<MasterProduct> allProducts,
    required List<Category> categories,
    required List<ProductSelection> selections,
    required List<WeekdaySchedule> schedules,
    required OrderOverride? orderOverride,
    required DayBoundaryService boundary,
  }) {
    final effectiveDate = boundary.effectiveDate(date);
    // Dart: Mon=1..Sun=7 → convert to Sun=0..Sat=6
    final dayOfWeek = effectiveDate.weekday % 7;

    final selectedIds = selections
        .where((s) => s.slot == slot && s.isSelected)
        .map((s) => s.productId)
        .toSet();

    final selected = allProducts.where((p) {
      if (slot == Slot.morning && p.morningConfig == null) return false;
      if (slot == Slot.evening && p.eveningConfig == null) return false;
      return selectedIds.contains(p.id);
    }).toList();

    final active = selected.where((p) {
      final config =
          slot == Slot.morning ? p.morningConfig! : p.eveningConfig!;
      return switch (config.frequencyRule) {
        DailyRule() => true,
        WeeklyMaxRule() => schedules.any(
            (s) =>
                s.productId == p.id &&
                s.slot == slot &&
                s.weekdays.contains(dayOfWeek),
          ),
      };
    }).toList();

    final categoryOrderById = {
      for (final cat in categories) cat.id: cat.order,
    };

    int categoryThenSlotOrder(MasterProduct a, MasterProduct b) {
      final catA = categoryOrderById[a.categoryId] ?? 9999;
      final catB = categoryOrderById[b.categoryId] ?? 9999;
      if (catA != catB) return catA.compareTo(catB);
      final orderA = _slotOrder(a, slot);
      final orderB = _slotOrder(b, slot);
      return orderA.compareTo(orderB);
    }

    if (orderOverride != null && orderOverride.slot == slot) {
      final overrideMap = {
        for (var i = 0; i < orderOverride.orderedProductIds.length; i++)
          orderOverride.orderedProductIds[i]: i,
      };
      active.sort((a, b) {
        final ai = overrideMap[a.id];
        final bi = overrideMap[b.id];
        if (ai != null && bi != null) return ai.compareTo(bi);
        if (ai != null) return -1;
        if (bi != null) return 1;
        return categoryThenSlotOrder(a, b);
      });
    } else {
      active.sort(categoryThenSlotOrder);
    }

    return active;
  }

  int _slotOrder(MasterProduct p, Slot slot) =>
      (slot == Slot.morning ? p.morningConfig?.order : p.eveningConfig?.order) ??
      999;
}
