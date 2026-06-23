import '../entities/category.dart';
import '../entities/incompatibility_rule.dart';
import '../entities/master_product.dart';
import '../entities/order_override.dart';
import '../entities/product_selection.dart';
import '../entities/sub_category.dart';
import '../entities/weekday_schedule.dart';
import '../enums/slot.dart';
import 'incompatibility_checker.dart';
import 'product_sorter.dart';
import 'schedule_days.dart';

class ProductWeekSpread {
  final MasterProduct product;
  final List<bool> activeDays; // length 7, 0=Sunday .. 6=Saturday
  final Set<int> conflictDays; // active day-indices where product is in an active conflict

  const ProductWeekSpread({
    required this.product,
    required this.activeDays,
    this.conflictDays = const {},
  });
}

class WeekConflictPair {
  final MasterProduct productA;
  final MasterProduct productB;
  final Set<int> days;
  final String? reason;
  final String? reasonEn;

  const WeekConflictPair({
    required this.productA,
    required this.productB,
    required this.days,
    this.reason,
    this.reasonEn,
  });
}

class SlotWeekGlance {
  final Slot slot;
  final List<ProductWeekSpread> products;
  final List<WeekConflictPair> conflicts;

  const SlotWeekGlance({
    required this.slot,
    required this.products,
    required this.conflicts,
  });

  bool get hasIssues => conflicts.isNotEmpty;
  int get issueCount => conflicts.length;
}

class WeekGlance {
  final SlotWeekGlance morning;
  final SlotWeekGlance evening;

  const WeekGlance({required this.morning, required this.evening});
}

class WeekGlanceBuilder {
  const WeekGlanceBuilder();

  WeekGlance build({
    required List<MasterProduct> allProducts,
    required List<Category> categories,
    required List<SubCategory> subcategories,
    required List<IncompatibilityRule> rules,
    required List<ProductSelection> morningSelections,
    required List<ProductSelection> eveningSelections,
    required List<WeekdaySchedule> schedules,
    required Set<String> mutedRuleIds,
    OrderOverride? morningOrderOverride,
    OrderOverride? eveningOrderOverride,
    Map<String, String>? categoryOverrides,
  }) {
    // Selected, non-deprecated, admin-ordered products, then dropping any with
    // zero scheduled days in the slot — a product that runs on no day is not
    // part of that routine and must not appear in the overview.
    List<MasterProduct> withActiveDays(List<MasterProduct> products, Slot slot) =>
        products
            .where((p) => _buildActiveDays(p, slot, schedules).contains(true))
            .toList();

    final morningProducts = withActiveDays(
      _selectedProducts(
        allProducts: allProducts,
        selections: morningSelections,
        slot: Slot.morning,
        categories: categories,
        subcategories: subcategories,
        orderOverride: morningOrderOverride,
        categoryOverrides: categoryOverrides,
      ),
      Slot.morning,
    );

    final eveningProducts = withActiveDays(
      _selectedProducts(
        allProducts: allProducts,
        selections: eveningSelections,
        slot: Slot.evening,
        categories: categories,
        subcategories: subcategories,
        orderOverride: eveningOrderOverride,
        categoryOverrides: categoryOverrides,
      ),
      Slot.evening,
    );

    // Build activeDays for each surviving product
    final morningActiveDays = {
      for (final p in morningProducts)
        p.id: _buildActiveDays(p, Slot.morning, schedules),
    };
    final eveningActiveDays = {
      for (final p in eveningProducts)
        p.id: _buildActiveDays(p, Slot.evening, schedules),
    };

    // Per-day conflict pass
    // Key: (slot, sorted pair of ids) → accumulated data
    final checker = IncompatibilityChecker();

    // accumulator: key = '$slot:$idA:$idB' (sorted ids), value = _PairAccum
    final morningAccum = <String, _PairAccum>{};
    final eveningAccum = <String, _PairAccum>{};

    for (var d = 0; d < 7; d++) {
      final morningActiveD = morningProducts
          .where((p) => morningActiveDays[p.id]![d])
          .toList();
      final eveningActiveD = eveningProducts
          .where((p) => eveningActiveDays[p.id]![d])
          .toList();

      final conflicts = checker.getConflictsForDay(
        morningProducts: morningActiveD,
        eveningProducts: eveningActiveD,
        rules: rules,
        categories: categories,
        mutedRuleIds: mutedRuleIds,
      );

      for (final conflict in conflicts) {
        if (conflict.isMuted) continue;

        final inMorning = morningActiveD.any((p) => p.id == conflict.productA.id) &&
            morningActiveD.any((p) => p.id == conflict.productB.id);
        final inEvening = eveningActiveD.any((p) => p.id == conflict.productA.id) &&
            eveningActiveD.any((p) => p.id == conflict.productB.id);

        final ids = [conflict.productA.id, conflict.productB.id]..sort();
        final key = '${ids[0]}:${ids[1]}';

        if (inMorning) {
          morningAccum.putIfAbsent(
            key,
            () => _PairAccum(
              productA: conflict.productA,
              productB: conflict.productB,
              reason: conflict.reason,
              reasonEn: conflict.reasonEn,
            ),
          ).days.add(d);
        }
        if (inEvening) {
          eveningAccum.putIfAbsent(
            key,
            () => _PairAccum(
              productA: conflict.productA,
              productB: conflict.productB,
              reason: conflict.reason,
              reasonEn: conflict.reasonEn,
            ),
          ).days.add(d);
        }
        if (!inMorning && !inEvening) {
          // cross-slot: sameDayAcrossBoth — add to both
          morningAccum.putIfAbsent(
            key,
            () => _PairAccum(
              productA: conflict.productA,
              productB: conflict.productB,
              reason: conflict.reason,
              reasonEn: conflict.reasonEn,
            ),
          ).days.add(d);
          eveningAccum.putIfAbsent(
            key,
            () => _PairAccum(
              productA: conflict.productA,
              productB: conflict.productB,
              reason: conflict.reason,
              reasonEn: conflict.reasonEn,
            ),
          ).days.add(d);
        }
      }
    }

    final morningConflicts = morningAccum.values
        .map((a) => WeekConflictPair(
              productA: a.productA,
              productB: a.productB,
              days: a.days,
              reason: a.reason,
              reasonEn: a.reasonEn,
            ))
        .toList();

    final eveningConflicts = eveningAccum.values
        .map((a) => WeekConflictPair(
              productA: a.productA,
              productB: a.productB,
              days: a.days,
              reason: a.reason,
              reasonEn: a.reasonEn,
            ))
        .toList();

    // Build conflictDays per product
    List<ProductWeekSpread> buildSpreads(
      List<MasterProduct> products,
      Map<String, List<bool>> activeDaysMap,
      List<WeekConflictPair> conflicts,
    ) {
      return products.map((p) {
        final conflictDays = <int>{};
        for (final pair in conflicts) {
          if (pair.productA.id == p.id || pair.productB.id == p.id) {
            conflictDays.addAll(pair.days);
          }
        }
        return ProductWeekSpread(
          product: p,
          activeDays: activeDaysMap[p.id]!,
          conflictDays: conflictDays,
        );
      }).toList();
    }

    final morningSpreads = buildSpreads(morningProducts, morningActiveDays, morningConflicts);
    final eveningSpreads = buildSpreads(eveningProducts, eveningActiveDays, eveningConflicts);

    return WeekGlance(
      morning: SlotWeekGlance(
        slot: Slot.morning,
        products: morningSpreads,
        conflicts: morningConflicts,
      ),
      evening: SlotWeekGlance(
        slot: Slot.evening,
        products: eveningSpreads,
        conflicts: eveningConflicts,
      ),
    );
  }

  List<MasterProduct> _selectedProducts({
    required List<MasterProduct> allProducts,
    required List<ProductSelection> selections,
    required Slot slot,
    required List<Category> categories,
    required List<SubCategory> subcategories,
    OrderOverride? orderOverride,
    Map<String, String>? categoryOverrides,
  }) {
    final selectedIds = selections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();

    final filtered = allProducts.where((p) {
      if (p.isDeprecated) return false;
      if (p.configForSlot(slot) == null) return false;
      return selectedIds.contains(p.id);
    }).toList();

    final cmp = ProductSorter.adminComparator(
      categories: categories,
      subcategories: subcategories,
      slot: slot,
      categoryOverrides: categoryOverrides,
    );

    // A persisted custom order (Order Customization screen / S3) wins — use the
    // order the routine already set, falling back to admin order only for
    // products the override doesn't list. Mirrors RoutineResolver's ordering.
    if (orderOverride != null && orderOverride.slot == slot) {
      final overrideIndex = {
        for (var i = 0; i < orderOverride.orderedProductIds.length; i++)
          orderOverride.orderedProductIds[i]: i,
      };
      filtered.sort((a, b) {
        final ai = overrideIndex[a.id];
        final bi = overrideIndex[b.id];
        if (ai != null && bi != null) return ai.compareTo(bi);
        if (ai != null) return -1;
        if (bi != null) return 1;
        return cmp(a, b);
      });
    } else {
      filtered.sort(cmp);
    }

    return filtered;
  }

  /// The actual per-day allocation for [product] in [slot].
  /// Delegates to the canonical [effectiveDays] leaf helper.
  List<bool> _buildActiveDays(
    MasterProduct product,
    Slot slot,
    List<WeekdaySchedule> schedules,
  ) {
    final days = effectiveDays(product, slot, schedules);
    return List.generate(7, (d) => days.contains(d));
  }
}

class _PairAccum {
  final MasterProduct productA;
  final MasterProduct productB;
  final Set<int> days = {};
  final String? reason;
  final String? reasonEn;

  _PairAccum({
    required this.productA,
    required this.productB,
    this.reason,
    this.reasonEn,
  });
}
