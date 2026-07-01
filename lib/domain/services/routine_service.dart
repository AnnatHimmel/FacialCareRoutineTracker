import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../entities/master_product.dart';
import '../entities/order_override.dart';
import '../entities/product_selection.dart';
import '../entities/user_custom_product.dart';
import '../entities/weekday_schedule.dart';
import '../enums/rule_scope.dart';
import '../enums/slot.dart';
import '../repositories/master_content_repository.dart';
import '../repositories/user_data_repository.dart';
import 'conflict_resolver.dart';
import 'day_boundary_service.dart';
import 'incompatibility_checker.dart';
import 'product_sorter.dart';
import 'routine_build_summary.dart';
import 'routine_resolver.dart';
import 'schedule_days.dart' as sd;
import 'week_glance_builder.dart';

const _uuid = Uuid();

// ── Value types ────────────────────────────────────────────────────────────────

class OveruseEntry {
  final MasterProduct product;
  final int count; // total weekly applications across BOTH slots
  final int cap; // WeeklyMaxRule.maxPerWeek

  const OveruseEntry({
    required this.product,
    required this.count,
    required this.cap,
  });
}

class DayWarnings {
  final List<ConflictInfo> conflicts;
  final List<OveruseEntry> overused;
  final int zeroDayCount; // capped products unscheduled in ALL their slots

  const DayWarnings({
    this.conflicts = const [],
    this.overused = const [],
    this.zeroDayCount = 0,
  });

  bool get hasIssues => conflicts.isNotEmpty || overused.isNotEmpty;
  int get noteCount => conflicts.length + overused.length;
}

class RoutineFixResult {
  final List<ScheduleMutation> applied;
  final List<ScheduleMutation> inverse; // re-apply to Undo
  final List<({String he, String en})> changeDescriptions;
  final bool anyPartial;

  /// Per-conflict adjustments enriched with slot + kind, for the
  /// "routine ready" summary screen. Additive — [changeDescriptions] is kept
  /// for the existing Schedule-Setup auto-fix dialog consumer.
  final List<RoutineChange> changes;

  const RoutineFixResult({
    required this.applied,
    required this.inverse,
    required this.changeDescriptions,
    required this.anyPartial,
    this.changes = const [],
  });

  bool get isEmpty => applied.isEmpty;
}

/// A product whose position in the effective order differs from the order it
/// would return to if the active manual override were reverted.
class MovedProduct {
  final MasterProduct product;

  /// 1-based position the product takes in the post-revert (recommended) order.
  final int targetPosition;

  const MovedProduct({required this.product, required this.targetPosition});
}

/// Describes how a slot's manual (global) order deviates from the recommended
/// order. Used by the Order Customization screen's "manual changes" chip +
/// revert sheet.
class ManualOrderChanges {
  /// Whether a manual override (per-day or global) is in effect for the day.
  final bool hasOverride;

  /// True when the effective override is the global (all-days) one; false when
  /// a per-day override is in effect.
  final bool isGlobalScope;

  /// The weekday of the effective override (null when global).
  final int? weekday;

  /// Products that actually changed position vs. the post-revert order, sorted
  /// by [MovedProduct.targetPosition]. Empty when the override matches the
  /// recommended order.
  final List<MovedProduct> moved;

  const ManualOrderChanges({
    required this.hasOverride,
    required this.isGlobalScope,
    required this.weekday,
    required this.moved,
  });

  static const none = ManualOrderChanges(
    hasOverride: false,
    isGlobalScope: false,
    weekday: null,
    moved: [],
  );

  int get count => moved.length;
}

// ── RoutineService ────────────────────────────────────────────────────────────

class RoutineService {
  final UserDataRepository _repo;

  RoutineService(this._repo);

  // ── Static helpers ──────────────────────────────────────────────────────────

  /// Explicit schedule row wins (even an empty set = intentionally excluded);
  /// else DailyRule → {0..6}, WeeklyMaxRule → {}.
  /// Delegates to the canonical leaf helper in schedule_days.dart.
  static Set<int> effectiveDays(
    MasterProduct p,
    Slot slot,
    List<WeekdaySchedule> schedules,
  ) =>
      sd.effectiveDays(p, slot, schedules);

  /// Default placement when a product is first added / has no row:
  /// DailyRule → {0..6}; WeeklyMaxRule → evenly spread N days.
  static Set<int> defaultDaysFor(MasterProduct p, Slot slot) =>
      sd.defaultDaysFor(p, slot);

  /// Evenly spreads [n] days across the week (0–6).
  static Set<int> _spreadN7(int n) => sd.spreadN7(n);

  // ── Reactive reads (delegate to repo) ──────────────────────────────────────

  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      _repo.watchSelections(slot);

  Future<void> upsertSelection(ProductSelection s) =>
      _repo.upsertSelection(s);

  Stream<WeekdaySchedule?> watchSchedule(String productId, Slot slot) =>
      _repo.watchSchedule(productId, slot);

  Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      _repo.watchAllSchedules();

  Future<void> upsertSchedule(WeekdaySchedule s) =>
      _repo.upsertSchedule(s);

  Stream<OrderOverride?> watchOrderOverride(Slot slot) =>
      _repo.watchOrderOverride(slot);

  Future<void> upsertOrderOverride(OrderOverride o) =>
      _repo.upsertOrderOverride(o);

  Future<void> deleteOrderOverride(Slot slot) =>
      _repo.deleteOrderOverride(slot);

  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) =>
      _repo.deletePerDayOrderOverride(slot, weekday);

  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      _repo.watchPerDayOrderOverrides(slot);

  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) =>
      _repo.getEffectiveOrderOverride(slot, weekday);

  // ── master+custom merge ──────────────────────────────────────────────────────

  /// Returns master products followed by all custom products (as MasterProduct).
  /// Custom entries have [MasterProduct.editable] == true.
  Future<List<MasterProduct>> allProducts(MasterContent master) async {
    final customs = await _repo.watchCustomProducts().first;
    return [...master.products, ...customs.map((c) => c.toMasterProduct())];
  }

  /// Stream of the merged master+custom product list. Re-emits whenever the
  /// custom product list changes.
  Stream<List<MasterProduct>> watchAllProducts(MasterContent master) =>
      _repo.watchCustomProducts().map(
            (customs) => [...master.products, ...customs.map((c) => c.toMasterProduct())]);

  // ── custom product CRUD pass-throughs ────────────────────────────────────────

  Stream<List<UserCustomProduct>> watchCustomProducts() =>
      _repo.watchCustomProducts();

  Future<UserCustomProduct?> getCustomProduct(String id) async =>
      (await _repo.watchCustomProducts().first).firstWhereOrNull((p) => p.id == id);

  Future<void> upsertCustomProduct(UserCustomProduct p) =>
      _repo.upsertCustomProduct(p);

  Future<void> deleteCustomProduct(String id) =>
      _repo.deleteCustomProduct(id);

  // ── orderForDay ─────────────────────────────────────────────────────────────

  /// Returns products active for [weekday]+[slot] in effective order.
  /// Delegates to [RoutineResolver]. weekday: 0=Sunday … 6=Saturday.
  Future<List<MasterProduct>> orderForDay({
    required MasterContent master,
    required Slot slot,
    required int weekday,
  }) async {
    final orderOverride = await _repo.watchOrderOverride(slot).first;
    return _resolveForWeekday(
      master: master,
      slot: slot,
      weekday: weekday,
      orderOverride: orderOverride,
    );
  }

  /// Builds a deterministic calendar date for our [weekday] (0=Sun … 6=Sat).
  /// 2026-01-05 is a Monday; map our weekday onto that week.
  static DateTime _dateForWeekday(int weekday) {
    final mondayBase = DateTime(2026, 1, 5); // Monday
    // our weekday: 0=Sun=6 days after Mon; 1=Mon=0 days; ... 6=Sat=5 days
    final daysFromMonday = weekday == 0 ? 6 : weekday - 1;
    return mondayBase.add(Duration(days: daysFromMonday));
  }

  /// Resolves the active products for [weekday]+[slot] applying the given
  /// [orderOverride] (pass null for the recommended/admin order).
  Future<List<MasterProduct>> _resolveForWeekday({
    required MasterContent master,
    required Slot slot,
    required int weekday,
    required OrderOverride? orderOverride,
  }) async {
    final selections = await _repo.watchSelections(slot).first;
    final schedules = await _repo.watchAllSchedules().first;
    // Fetch category overrides so all surfaces (Daily Home, Order screen, Week
    // Glance) sort identically to dailyRoutineProvider.
    final catOverrideList = await _repo.watchCategoryOverrides().first;
    final catOverrides = catOverrideList.isEmpty
        ? null
        : {for (final o in catOverrideList) o.productId: o.categoryId};

    final mergedProducts = await allProducts(master);
    return RoutineResolver().resolve(
      date: _dateForWeekday(weekday),
      slot: slot,
      allProducts: mergedProducts,
      categories: master.categories,
      subcategories: master.subcategories,
      selections: selections,
      schedules: schedules,
      orderOverride: orderOverride,
      boundary: DayBoundaryService(),
      categoryOverrides: catOverrides,
    );
  }

  // ── manualOrderChangesForSlot ───────────────────────────────────────────────

  /// Describes how the slot's **global** custom order (as edited on the Order
  /// Customization screen) deviates from the recommended/admin order, over the
  /// full set of selected products for [slot] (not day-filtered — matching the
  /// reorderable list that screen shows). `moved` lists the products whose
  /// position differs, each tagged with its 1-based position in the recommended
  /// order (where it returns to on revert). Single source of truth for the
  /// order-screen "manual changes" chip + revert sheet. Revert is a plain
  /// [deleteOrderOverride] (the global row).
  Future<ManualOrderChanges> manualOrderChangesForSlot({
    required MasterContent master,
    required Slot slot,
  }) async {
    final override = await _repo.watchOrderOverride(slot).first; // global
    if (override == null) return ManualOrderChanges.none;

    final selections = await _repo.watchSelections(slot).first;
    final schedules = await _repo.watchAllSchedules().first;
    final catOverrideList = await _repo.watchCategoryOverrides().first;
    final catOverrides = catOverrideList.isEmpty
        ? null
        : {for (final o in catOverrideList) o.productId: o.categoryId};

    final selectedIds = selections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();
    // Exclude products whose schedule for this slot was explicitly cleared to
    // empty (mirrors the Order screen's _sortedProducts filter).
    bool isExcluded(String id) => schedules.any(
          (s) => s.productId == id && s.slot == slot && s.weekdays.isEmpty,
        );

    final mergedProducts = await allProducts(master);
    final products = mergedProducts
        .where((p) =>
            !p.isDeprecated &&
            selectedIds.contains(p.id) &&
            p.configForSlot(slot) != null &&
            !isExcluded(p.id))
        .toList();

    final adminCmp = ProductSorter.adminComparator(
      categories: master.categories,
      subcategories: master.subcategories,
      slot: slot,
      categoryOverrides: catOverrides,
    );

    // Recommended (target) order vs. the order with the override applied.
    final adminOrder = List<MasterProduct>.from(products)..sort(adminCmp);
    final overrideIds = override.orderedProductIds;
    final currentOrder = List<MasterProduct>.from(products)
      ..sort((a, b) {
        final ai = overrideIds.indexOf(a.id);
        final bi = overrideIds.indexOf(b.id);
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return adminCmp(a, b);
      });

    final currentIds = currentOrder.map((p) => p.id).toList();
    final moved = <MovedProduct>[];
    for (var i = 0; i < adminOrder.length; i++) {
      final product = adminOrder[i];
      if (currentIds.indexOf(product.id) != i) {
        moved.add(MovedProduct(product: product, targetPosition: i + 1));
      }
    }

    return ManualOrderChanges(
      hasOverride: true,
      isGlobalScope: true,
      weekday: null,
      moved: moved,
    );
  }

  // ── warningsForDayFrom (pure / synchronous) ─────────────────────────────────

  /// Pure, synchronous warnings computation.
  ///
  /// Callers that already hold their data (e.g. provider-backed widgets) pass
  /// the snapshots directly; no repo access occurs.
  ///
  /// [slotProducts]      — selected, non-deprecated products that have a config
  ///                       in [slot] (the "active" slot).
  /// [otherSlotProducts] — same for the other slot.
  /// [schedules]         — full list of WeekdaySchedule rows.
  /// [mutedRuleIds]      — muted conflict rule IDs.
  DayWarnings warningsForDayFrom({
    required MasterContent master,
    required Slot slot,
    required int weekday,
    required List<MasterProduct> slotProducts,
    required List<MasterProduct> otherSlotProducts,
    required List<WeekdaySchedule> schedules,
    required Set<String> mutedRuleIds,
  }) {
    final otherSlot = slot == Slot.morning ? Slot.evening : Slot.morning;

    // Active products on this specific weekday
    final activeOnDay = slotProducts
        .where((p) => effectiveDays(p, slot, schedules).contains(weekday))
        .toList();
    final otherOnDay = otherSlotProducts
        .where((p) => effectiveDays(p, otherSlot, schedules).contains(weekday))
        .toList();

    // Conflicts
    final checker = IncompatibilityChecker();
    final rawConflicts = checker.getConflictsForSelection(
      activeSlot: slot,
      slotProducts: activeOnDay,
      otherSlotProducts: otherOnDay,
      rules: master.rules,
      categories: master.categories,
      mutedRuleIds: mutedRuleIds,
    );
    final conflicts = rawConflicts.where((c) => !c.isMuted).toList();

    // Overuse — counts total applications across BOTH slots
    final overused = <OveruseEntry>[];
    for (final p in slotProducts) {
      final rule = p.configForSlot(slot)?.frequencyRule;
      if (rule is! WeeklyMaxRule) continue;
      final activeDaysSet = effectiveDays(p, slot, schedules);
      if (!activeDaysSet.contains(weekday)) continue;
      final otherDaysSet = p.configForSlot(otherSlot) != null
          ? effectiveDays(p, otherSlot, schedules)
          : const <int>{};
      final totalUses = activeDaysSet.length + otherDaysSet.length;
      if (totalUses > rule.maxPerWeek) {
        overused.add(OveruseEntry(
          product: p,
          count: totalUses,
          cap: rule.maxPerWeek,
        ));
      }
    }

    // Zero-day count — capped products in active slot with 0 effective days in ALL slots
    var zeroDayCount = 0;
    for (final p in slotProducts) {
      if (p.configForSlot(slot)?.frequencyRule is! WeeklyMaxRule) continue;
      final activeDaysSet = effectiveDays(p, slot, schedules);
      if (activeDaysSet.isNotEmpty) continue;
      final hasOtherSlot = p.configForSlot(otherSlot) != null;
      final otherDaysCount =
          hasOtherSlot ? effectiveDays(p, otherSlot, schedules).length : 0;
      if (otherDaysCount == 0) zeroDayCount++;
    }

    return DayWarnings(
      conflicts: conflicts,
      overused: overused,
      zeroDayCount: zeroDayCount,
    );
  }

  // ── warningsForDay ──────────────────────────────────────────────────────────

  /// Returns conflict/overuse/zero-day warnings for [weekday] in [slot].
  /// Fetches repo snapshots then delegates to [warningsForDayFrom].
  Future<DayWarnings> warningsForDay({
    required MasterContent master,
    required Slot slot,
    required int weekday,
  }) async {
    final morningSelections = await _repo.watchSelections(Slot.morning).first;
    final eveningSelections = await _repo.watchSelections(Slot.evening).first;
    final schedules = await _repo.watchAllSchedules().first;
    final mutedConflicts = await _repo.watchMutedConflicts().first;
    final mutedRuleIds = mutedConflicts.map((m) => m.ruleId).toSet();

    // Build selected non-deprecated products for each slot
    Set<String> selectedIds(List<ProductSelection> sels) =>
        sels.where((s) => s.isSelected).map((s) => s.productId).toSet();

    final mergedProducts = await allProducts(master);
    List<MasterProduct> slotProductsFor(Slot s, Set<String> ids) =>
        mergedProducts
            .where((p) =>
                !p.isDeprecated &&
                ids.contains(p.id) &&
                p.configForSlot(s) != null)
            .toList();

    final morningIds = selectedIds(morningSelections);
    final eveningIds = selectedIds(eveningSelections);
    final morningProducts = slotProductsFor(Slot.morning, morningIds);
    final eveningProducts = slotProductsFor(Slot.evening, eveningIds);

    final slotProds =
        slot == Slot.morning ? morningProducts : eveningProducts;
    final otherSlotProds =
        slot == Slot.morning ? eveningProducts : morningProducts;

    return warningsForDayFrom(
      master: master,
      slot: slot,
      weekday: weekday,
      slotProducts: slotProds,
      otherSlotProducts: otherSlotProds,
      schedules: schedules,
      mutedRuleIds: mutedRuleIds,
    );
  }

  // ── weekGlance ──────────────────────────────────────────────────────────────

  Future<WeekGlance> weekGlance({
    required MasterContent master,
  }) async {
    final morningSelections = await _repo.watchSelections(Slot.morning).first;
    final eveningSelections = await _repo.watchSelections(Slot.evening).first;
    final schedules = await _repo.watchAllSchedules().first;
    final mutedConflicts = await _repo.watchMutedConflicts().first;
    final mutedRuleIds = mutedConflicts.map((m) => m.ruleId).toSet();
    // Fetch category overrides so Week Glance sorts identically to Daily Home.
    final catOverrideList = await _repo.watchCategoryOverrides().first;
    final catOverrides = catOverrideList.isEmpty
        ? null
        : {for (final o in catOverrideList) o.productId: o.categoryId};

    final morningOrderOverride = await _repo.watchOrderOverride(Slot.morning).first;
    final eveningOrderOverride = await _repo.watchOrderOverride(Slot.evening).first;

    final mergedProducts = await allProducts(master);
    return const WeekGlanceBuilder().build(
      allProducts: mergedProducts,
      categories: master.categories,
      subcategories: master.subcategories,
      rules: master.rules,
      morningSelections: morningSelections,
      eveningSelections: eveningSelections,
      schedules: schedules,
      mutedRuleIds: mutedRuleIds,
      categoryOverrides: catOverrides,
      morningOrderOverride: morningOrderOverride,
      eveningOrderOverride: eveningOrderOverride,
    );
  }

  // ── addProduct ──────────────────────────────────────────────────────────────

  /// Upserts selection (isSelected=true), writes default schedule if no row
  /// exists, then returns the product's admin-sorted index in the slot.
  Future<int> addProduct({
    required MasterContent master,
    required String productId,
    required Slot slot,
  }) async {
    // Custom products are not in master.products — look in the combined list.
    final mergedProducts = await allProducts(master);
    final product = mergedProducts.firstWhereOrNull((p) => p.id == productId);

    // Upsert selection
    final existingSelections = await _repo.watchSelections(slot).first;
    final existingSel =
        existingSelections.where((s) => s.productId == productId).firstOrNull;

    if (existingSel != null) {
      await _repo.upsertSelection(existingSel.copyWith(
        isSelected: true,
        lastModified: DateTime.now(),
      ));
    } else {
      await _repo.upsertSelection(ProductSelection(
        id: _uuid.v4(),
        productId: productId,
        slot: slot,
        isSelected: true,
        lastModified: DateTime.now(),
      ));
    }

    // Write default schedule only for WeeklyMaxRule products (DailyRule has
    // implicit all-7-days default when no row exists, so the write is optional
    // but for WeeklyMaxRule we MUST write the spread).
    final rule = product?.configForSlot(slot)?.frequencyRule;
    final existingSchedules = await _repo.watchAllSchedules().first;
    final existingRow = existingSchedules
        .where((s) => s.productId == productId && s.slot == slot)
        .firstOrNull;

    if (existingRow == null && rule is WeeklyMaxRule) {
      final defaultDays = _spreadN7(rule.maxPerWeek);
      await _repo.upsertSchedule(WeekdaySchedule(
        id: _uuid.v4(),
        productId: productId,
        slot: slot,
        weekdays: defaultDays,
        lastModified: DateTime.now(),
      ));
    }

    // Return admin-sorted index (custom products not in master list → 0)
    if (product == null) return 0;
    final allSelections = await _repo.watchSelections(slot).first;
    final selectedIds = allSelections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();
    final selectedProducts = mergedProducts
        .where((p) =>
            selectedIds.contains(p.id) && p.configForSlot(slot) != null)
        .toList();

    final cmp = ProductSorter.adminComparator(
      categories: master.categories,
      subcategories: master.subcategories,
      slot: slot,
    );
    selectedProducts.sort(cmp);

    final index = selectedProducts.indexWhere((p) => p.id == productId);

    // Insert the new product into any existing order overrides at its
    // admin-sorted position, so the daily home screen respects the placement
    // the user was shown on the "where it goes" step.
    List<String> insertAtAdminPosition(List<String> existingIds) {
      if (existingIds.contains(productId)) return existingIds;
      int insertAt = 0;
      for (int i = 0; i < existingIds.length; i++) {
        final existing = mergedProducts.firstWhereOrNull((p) => p.id == existingIds[i]);
        if (existing != null && cmp(existing, product) <= 0) insertAt = i + 1;
      }
      return [...existingIds.sublist(0, insertAt), productId, ...existingIds.sublist(insertAt)];
    }

    final globalOverride = await _repo.watchOrderOverride(slot).first;
    if (globalOverride != null) {
      await setOrder(
        slot: slot,
        weekday: null,
        orderedIds: insertAtAdminPosition(globalOverride.orderedProductIds),
      );
    }
    final perDayOverrides = await _repo.watchPerDayOrderOverrides(slot).first;
    for (final perDay in perDayOverrides) {
      await setOrder(
        slot: slot,
        weekday: perDay.weekday,
        orderedIds: insertAtAdminPosition(perDay.orderedProductIds),
      );
    }

    return index < 0 ? 0 : index;
  }

  // ── removeProduct ────────────────────────────────────────────────────────────

  /// Deselects the product and clears its schedule for the slot.
  Future<void> removeProduct({
    required String productId,
    required Slot slot,
  }) async {
    // Deselect all matching rows (defensive against duplicate DB records)
    final existingSelections = await _repo.watchSelections(slot).first;
    final matches =
        existingSelections.where((s) => s.productId == productId).toList();
    for (final match in matches) {
      await _repo.upsertSelection(match.copyWith(
        isSelected: false,
        lastModified: DateTime.now(),
      ));
    }

    // Clear schedule (write empty weekdays)
    final existingSchedules = await _repo.watchAllSchedules().first;
    final existingRow = existingSchedules
        .where((s) => s.productId == productId && s.slot == slot)
        .firstOrNull;
    if (existingRow != null) {
      await _repo.upsertSchedule(existingRow.copyWith(
        weekdays: const {},
        lastModified: DateTime.now(),
      ));
    }

    // Strip product from order overrides for this slot
    final globalOverride = await _repo.watchOrderOverride(slot).first;
    if (globalOverride != null &&
        globalOverride.orderedProductIds.contains(productId)) {
      final updated = globalOverride.orderedProductIds
          .where((id) => id != productId)
          .toList();
      if (updated.isEmpty) {
        await _repo.deleteOrderOverride(slot);
      } else {
        await setOrder(slot: slot, weekday: null, orderedIds: updated);
      }
    }
    final perDayOverrides = await _repo.watchPerDayOrderOverrides(slot).first;
    for (final perDay in perDayOverrides) {
      if (perDay.orderedProductIds.contains(productId)) {
        final updated = perDay.orderedProductIds
            .where((id) => id != productId)
            .toList();
        if (updated.isEmpty) {
          await _repo.deletePerDayOrderOverride(slot, perDay.weekday!);
        } else {
          await setOrder(
              slot: slot, weekday: perDay.weekday, orderedIds: updated);
        }
      }
    }
  }

  // ── schedule edits ──────────────────────────────────────────────────────────

  Future<void> setDays({
    required String productId,
    required Slot slot,
    required Set<int> days,
  }) async {
    final schedules = await _repo.watchAllSchedules().first;
    final existing = schedules
        .where((s) => s.productId == productId && s.slot == slot)
        .firstOrNull;
    if (existing != null) {
      await _repo.upsertSchedule(
          existing.copyWith(weekdays: days, lastModified: DateTime.now()));
    } else {
      await _repo.upsertSchedule(WeekdaySchedule(
        id: _uuid.v4(),
        productId: productId,
        slot: slot,
        weekdays: days,
        lastModified: DateTime.now(),
      ));
    }
  }

  Future<void> toggleDay({
    required String productId,
    required Slot slot,
    required int weekday,
  }) async {
    final schedules = await _repo.watchAllSchedules().first;
    final existing = schedules
        .where((s) => s.productId == productId && s.slot == slot)
        .firstOrNull;
    final currentDays = existing?.weekdays ?? const <int>{};
    final newDays = Set<int>.from(currentDays);
    if (newDays.contains(weekday)) {
      newDays.remove(weekday);
    } else {
      newDays.add(weekday);
    }
    await setDays(productId: productId, slot: slot, days: newDays);
  }

  Future<void> removeDay({
    required String productId,
    required Slot slot,
    required int weekday,
  }) async {
    final schedules = await _repo.watchAllSchedules().first;
    final existing = schedules
        .where((s) => s.productId == productId && s.slot == slot)
        .firstOrNull;
    final currentDays = Set<int>.from(existing?.weekdays ?? const <int>{});
    currentDays.remove(weekday);
    await setDays(productId: productId, slot: slot, days: currentDays);
  }

  // ── applyMutationsPersisting ─────────────────────────────────────────────────

  /// Applies [mutations] to the repo (used for Undo, replaying inverse).
  Future<void> applyMutationsPersisting(List<ScheduleMutation> mutations) async {
    final schedules = await _repo.watchAllSchedules().first;
    for (final m in mutations) {
      final existing =
          schedules.where((s) => s.productId == m.productId && s.slot == m.slot).firstOrNull;
      if (existing != null) {
        await _repo.upsertSchedule(existing.copyWith(
          weekdays: Set<int>.from(m.days),
          lastModified: DateTime.now(),
        ));
      } else {
        await _repo.upsertSchedule(WeekdaySchedule(
          id: _uuid.v4(),
          productId: m.productId,
          slot: m.slot,
          weekdays: Set<int>.from(m.days),
          lastModified: DateTime.now(),
        ));
      }
    }
  }

  // ── fixProblems ──────────────────────────────────────────────────────────────

  /// Mirrors `conflictAutoFixProvider`: ensure defaults for unscheduled capped
  /// products, dedup conflicting pairs, run ConflictResolver per pair, prune
  /// overuse, persist, and return RoutineFixResult (with inverse for Undo).
  Future<RoutineFixResult> fixProblems({
    required MasterContent master,
    required Slot slot,
  }) async {
    final morningSelections = await _repo.watchSelections(Slot.morning).first;
    final eveningSelections = await _repo.watchSelections(Slot.evening).first;
    var schedules = await _repo.watchAllSchedules().first;
    final mutedConflicts = await _repo.watchMutedConflicts().first;
    final mutedRuleIds = mutedConflicts.map((m) => m.ruleId).toSet();

    final mergedProducts = await allProducts(master);

    Set<String> selectedIds(List<ProductSelection> sels) =>
        sels.where((s) => s.isSelected).map((s) => s.productId).toSet();

    List<MasterProduct> slotProducts(Slot s, Set<String> ids) => mergedProducts
        .where((p) =>
            !p.isDeprecated &&
            ids.contains(p.id) &&
            p.configForSlot(s) != null)
        .toList();

    final morningIds = selectedIds(morningSelections);
    final eveningIds = selectedIds(eveningSelections);
    final morningProducts = slotProducts(Slot.morning, morningIds);
    final eveningProducts = slotProducts(Slot.evening, eveningIds);

    // Phase 0: ensure capped products have a default spread schedule
    final allSlotPairs = [
      ...[for (final p in morningProducts) (prod: p, slot: Slot.morning)],
      ...[for (final p in eveningProducts) (prod: p, slot: Slot.evening)],
    ];
    for (final pair in allSlotPairs) {
      final p = pair.prod;
      final pSlot = pair.slot;
      final rule = p.configForSlot(pSlot)?.frequencyRule;
      if (rule is! WeeklyMaxRule) continue;
      final existing = schedules
          .where((s) => s.productId == p.id && s.slot == pSlot)
          .firstOrNull;
      if (existing != null) continue;
      final defaultDays = _spreadN7(rule.maxPerWeek);
      final newSchedule = WeekdaySchedule(
        id: 'autofix-default-${p.id}-${pSlot.name}',
        productId: p.id,
        slot: pSlot,
        weekdays: defaultDays,
        lastModified: DateTime.now(),
      );
      await _repo.upsertSchedule(newSchedule);
      schedules = [...schedules, newSchedule];
    }

    // Phase 1: detect conflicts
    final checker = IncompatibilityChecker();
    final conflicts = checker.getConflictsForDay(
      morningProducts: morningProducts,
      eveningProducts: eveningProducts,
      rules: master.rules,
      categories: master.categories,
      mutedRuleIds: mutedRuleIds,
    );

    // Deduplicate — process each unique unordered pair only once
    final seen = <String>{};
    final active = conflicts.where((c) {
      if (c.isMuted) return false;
      final key = ([c.productA.id, c.productB.id]..sort()).join('|');
      return seen.add(key);
    }).toList();

    if (active.isEmpty) {
      return const RoutineFixResult(
        applied: [],
        inverse: [],
        changeDescriptions: [],
        anyPartial: false,
      );
    }

    const resolver = ConflictResolver();
    final allApplied = <ScheduleMutation>[];
    final allInverse = <ScheduleMutation>[];
    final allDescriptions = <({String he, String en})>[];
    final allChanges = <RoutineChange>[];
    bool anyPartial = false;

    for (final conflict in active) {
      final inMorning = morningProducts.any((p) => p.id == conflict.productA.id) &&
          morningProducts.any((p) => p.id == conflict.productB.id);
      final conflictSlot = inMorning ? Slot.morning : Slot.evening;

      final resolution = resolver.resolve(
        productA: conflict.productA,
        productB: conflict.productB,
        slot: conflictSlot,
        schedules: schedules,
      );

      if (resolution.isPartial) anyPartial = true;

      // Supplement mutations: if a DailyRule product ends up with targetDays={}
      // but has no prior schedule row (so the resolver saw {} == {} and skipped
      // a mutation), we must write an explicit suppression row. Otherwise the
      // product remains active on all days via its default-to-all-7 behaviour.
      final supplemented = List<ScheduleMutation>.from(resolution.mutations);
      final mutatedIds =
          supplemented.map((m) => '${m.productId}|${m.slot.name}').toSet();

      // The resolver assigns no days to the yielder when anchor took them all.
      // Detect: a product is involved (productA or productB) in this conflict
      // slot, has no mutation yet, has no prior schedule row, and is DailyRule —
      // it needs an explicit empty row to be suppressed.
      for (final p in [conflict.productA, conflict.productB]) {
        final key = '${p.id}|${conflictSlot.name}';
        if (mutatedIds.contains(key)) continue;
        final hasRow = schedules.any(
            (s) => s.productId == p.id && s.slot == conflictSlot);
        if (hasRow) continue;
        // Check if this product would still be active on all 7 days (DailyRule, no row)
        final rule = p.configForSlot(conflictSlot)?.frequencyRule;
        if (rule is! DailyRule) continue;
        // If the conflict partner was already cleared from this slot, the resolver
        // chose slot separation (moving the partner to its other slot). This
        // product is the stayer and must remain in this slot — skip supplementation.
        final partner = p.id == conflict.productA.id
            ? conflict.productB
            : conflict.productA;
        final partnerKey = '${partner.id}|${conflictSlot.name}';
        final partnerCleared = supplemented
            .any((m) => '${m.productId}|${m.slot.name}' == partnerKey && m.days.isEmpty);
        if (partnerCleared) continue;
        // Day-separation: the yielder has no remaining days after the anchor
        // claimed them all. Write an explicit suppression row so the DailyRule
        // default (all-7) doesn't keep it active.
        supplemented.add(ScheduleMutation(
          productId: p.id,
          slot: conflictSlot,
          days: const <int>{},
        ));
      }

      // Build inverse from actual repo state BEFORE applying mutations.
      // This captures what the schedules truly are now (including rows written
      // by Phase 0), so that applyMutationsPersisting(inverse) restores them
      // to exactly the state they were in before fixProblems ran.
      final trueInverse = <ScheduleMutation>[];
      for (final m in supplemented) {
        final priorRow = schedules
            .where((s) => s.productId == m.productId && s.slot == m.slot)
            .firstOrNull;
        trueInverse.add(ScheduleMutation(
          productId: m.productId,
          slot: m.slot,
          days: priorRow != null ? Set<int>.from(priorRow.weekdays) : const <int>{},
        ));
      }

      // Capture EFFECTIVE before-days (daily-with-no-row counts as 7, not 0)
      // from the pre-persist snapshot, for the summary's change classification.
      final beforeDaysByKey = <String, Set<int>>{};
      for (final m in supplemented) {
        final p = mergedProducts.where((p) => p.id == m.productId).firstOrNull;
        if (p == null) continue;
        beforeDaysByKey['${m.productId}|${m.slot.name}'] =
            sd.effectiveDays(p, m.slot, schedules);
      }

      // Persist mutations, updating local snapshot
      for (final m in supplemented) {
        final existing = schedules
            .where((s) => s.productId == m.productId && s.slot == m.slot)
            .firstOrNull;

        final updated = WeekdaySchedule(
          id: existing?.id ?? 'autofix-${m.productId}-${m.slot.name}',
          productId: m.productId,
          slot: m.slot,
          weekdays: m.days,
          lastModified: DateTime.now(),
        );
        await _repo.upsertSchedule(updated);
        final idx = schedules
            .indexWhere((s) => s.productId == m.productId && s.slot == m.slot);
        if (idx >= 0) {
          schedules = [...schedules]..[idx] = updated;
        } else {
          schedules = [...schedules, updated];
        }
      }

      allApplied.addAll(supplemented);
      allInverse.addAll(trueInverse);
      allDescriptions.add((
        he: resolution.description,
        en: resolution.descriptionEn ?? resolution.description,
      ));

      // Classify this conflict's adjustment for the "routine ready" summary,
      // using EFFECTIVE before-days. `movedSlot` = a product cleared from this
      // slot that still runs in its other slot (a true slot move); otherwise a
      // drop in total active days is `reducedFrequency`, else `movedDays`.
      var movedSlot = false;
      var beforeTotal = 0;
      var afterTotal = 0;
      for (final m in supplemented) {
        final before =
            beforeDaysByKey['${m.productId}|${m.slot.name}'] ?? const <int>{};
        final after = m.days;
        if (before.isNotEmpty && after.isEmpty) {
          final otherSlot =
              m.slot == Slot.morning ? Slot.evening : Slot.morning;
          final p = mergedProducts.where((p) => p.id == m.productId).firstOrNull;
          if (p?.configForSlot(otherSlot) != null) movedSlot = true;
        }
        beforeTotal += before.length;
        afterTotal += after.length;
      }
      final kind = movedSlot
          ? RoutineChangeKind.movedSlot
          : afterTotal < beforeTotal
              ? RoutineChangeKind.reducedFrequency
              : RoutineChangeKind.movedDays;
      allChanges.add(RoutineChange(
        slot: conflictSlot,
        kind: kind,
        he: resolution.description,
        en: resolution.descriptionEn ?? resolution.description,
      ));
    }

    return RoutineFixResult(
      applied: allApplied,
      inverse: allInverse,
      changeDescriptions: allDescriptions,
      anyPartial: anyPartial,
      changes: allChanges,
    );
  }

  // ── buildRoutineSummary ──────────────────────────────────────────────────────

  /// One-shot summary of the auto-sorter's decisions for the "routine ready"
  /// screen. Resolves all conflicts (via [fixProblems], reusing its enriched
  /// [RoutineFixResult.changes]), counts the selected products per slot, and
  /// collects the advisory conflicts the resolver intentionally leaves alone —
  /// pairs that still co-occur on a weekday after the fix (e.g. two daily
  /// products that oxidize together and cannot be separated).
  Future<RoutineBuildSummary> buildRoutineSummary({
    required MasterContent master,
  }) async {
    final fix = await fixProblems(
      master: master,
      slot: Slot.morning,
    );

    final morningSelections = await _repo.watchSelections(Slot.morning).first;
    final eveningSelections = await _repo.watchSelections(Slot.evening).first;

    final mergedProducts = await allProducts(master);

    bool isLive(String id, Slot s) {
      final p = mergedProducts.firstWhereOrNull((p) => p.id == id);
      return p != null && !p.isDeprecated && p.configForSlot(s) != null;
    }

    Set<String> liveIds(List<ProductSelection> sels, Slot s) => sels
        .where((sel) => sel.isSelected && isLive(sel.productId, s))
        .map((sel) => sel.productId)
        .toSet();

    final morningIds = liveIds(morningSelections, Slot.morning);
    final eveningIds = liveIds(eveningSelections, Slot.evening);
    final totalIds = {...morningIds, ...eveningIds};

    final schedules = await _repo.watchAllSchedules().first;
    final mutedConflicts = await _repo.watchMutedConflicts().first;
    final mutedRuleIds = mutedConflicts.map((m) => m.ruleId).toSet();

    List<MasterProduct> slotProducts(Slot s, Set<String> ids) =>
        mergedProducts
            .where((p) =>
                !p.isDeprecated &&
                ids.contains(p.id) &&
                p.configForSlot(s) != null)
            .toList();

    final conflicts = IncompatibilityChecker().getConflictsForDay(
      morningProducts: slotProducts(Slot.morning, morningIds),
      eveningProducts: slotProducts(Slot.evening, eveningIds),
      rules: master.rules,
      categories: master.categories,
      mutedRuleIds: mutedRuleIds,
    );

    // Advisories = pairs that STILL co-occur on a weekday after the fix. The
    // resolver separates every conflict it acts on, so what remains are the
    // pairs the user chose to keep together (muted) — "we didn't block, just a
    // gentle recommendation". Resolved/separated pairs no longer overlap and
    // are excluded here (they appear under "what we arranged" instead).
    final advisories = <RoutineAdvisory>[];
    final seen = <String>{};
    for (final c in conflicts) {
      final key = ([c.productA.id, c.productB.id]..sort()).join('|');
      if (!seen.add(key)) continue;
      final slot = _advisorySlot(c, schedules);
      if (slot == null) continue;
      advisories.add(RoutineAdvisory(
        slot: slot,
        he: c.reason ?? '',
        en: c.reasonEn ?? c.reason ?? '',
      ));
    }

    return RoutineBuildSummary(
      totalProducts: totalIds.length,
      morningCount: morningIds.length,
      eveningCount: eveningIds.length,
      changes: fix.changes,
      advisories: advisories,
    );
  }

  /// The slot to badge for an advisory, or null when the pair no longer
  /// co-occurs on any weekday (so it isn't worth noting).
  Slot? _advisorySlot(ConflictInfo c, List<WeekdaySchedule> schedules) {
    final a = c.productA;
    final b = c.productB;
    Set<int> days(MasterProduct p, Slot s) =>
        p.configForSlot(s) != null ? sd.effectiveDays(p, s, schedules) : <int>{};

    if (c.scope == RuleScope.withinSlot) {
      for (final s in const [Slot.morning, Slot.evening]) {
        if (days(a, s).intersection(days(b, s)).isNotEmpty) return s;
      }
      return null;
    }
    // sameDayAcrossBoth: one product in the morning, the other in the evening,
    // both active on the same calendar weekday.
    if (days(a, Slot.morning).intersection(days(b, Slot.evening)).isNotEmpty) {
      return Slot.morning;
    }
    if (days(b, Slot.morning).intersection(days(a, Slot.evening)).isNotEmpty) {
      return Slot.morning;
    }
    return null;
  }

  // ── order edits ──────────────────────────────────────────────────────────────

  Future<void> setOrder({
    required Slot slot,
    int? weekday,
    required List<String> orderedIds,
  }) async {
    // Use a deterministic id so insertOnConflictUpdate always updates the one
    // canonical row, preventing duplicate global/per-day rows when the user
    // drags quickly before the watch-stream re-emits.
    final id = weekday == null
        ? 'order-global-${slot.name}'
        : 'order-day-${slot.name}-$weekday';
    await _repo.upsertOrderOverride(OrderOverride(
      id: id,
      slot: slot,
      weekday: weekday,
      orderedProductIds: orderedIds,
      lastModified: DateTime.now(),
    ));
  }

  Future<void> resetOrder({required Slot slot, int? weekday}) async {
    if (weekday != null) {
      await _repo.deletePerDayOrderOverride(slot, weekday);
    } else {
      await _repo.deleteOrderOverride(slot);
    }
  }

  // ── healStaleAutoSpreadSchedules ─────────────────────────────────────────────

  /// One-time migration: when a product's master frequency has been corrected
  /// from a weekly cap to [DailyRule] (e.g. prod-007 sunscreen, `weeklyMax 3` →
  /// `daily`), an explicit [WeekdaySchedule] row written by the old default
  /// spread still wins over the new rule (`effectiveDays`), pinning the product
  /// to the stale cap. This heals any **selected** product whose **current**
  /// master rule is [DailyRule] and whose stored row is exactly the auto-spread
  /// `spreadN7(n)` for its own size — i.e. machine-generated, never hand-picked —
  /// by promoting it to all-7 days. Empty (intentionally suppressed), already
  /// all-7, and hand-picked rows are left untouched. Custom products are out of
  /// scope (their frequency is user-authored, not subject to master drift).
  ///
  /// Returns the number of rows healed. Callers must guard this so it runs once
  /// (see the user schema-version migration in root_providers).
  Future<int> healStaleAutoSpreadSchedules({
    required MasterContent master,
  }) async {
    final schedules = await _repo.watchAllSchedules().first;
    const all7 = {0, 1, 2, 3, 4, 5, 6};
    var healed = 0;

    for (final slot in const [Slot.morning, Slot.evening]) {
      final selections = await _repo.watchSelections(slot).first;
      final selectedIds = selections
          .where((s) => s.isSelected)
          .map((s) => s.productId)
          .toSet();

      for (final p in master.products) {
        if (!selectedIds.contains(p.id)) continue;
        if (p.configForSlot(slot)?.frequencyRule is! DailyRule) continue;

        final row = schedules
            .where((s) => s.productId == p.id && s.slot == slot)
            .firstOrNull;
        if (row == null) continue;

        final days = row.weekdays;
        if (days.isEmpty) continue; // intentional suppression — never touch
        if (days.length == 7) continue; // already daily-equivalent
        // Heal only rows that match a machine-generated even spread; a
        // hand-picked schedule (which never starts at day 0 unless deliberate)
        // is preserved.
        if (!const SetEquality<int>().equals(days, sd.spreadN7(days.length))) {
          continue;
        }

        await _repo.upsertSchedule(
          row.copyWith(weekdays: all7, lastModified: DateTime.now()),
        );
        healed++;
      }
    }

    return healed;
  }

  // ── ensureDefaultSchedules ───────────────────────────────────────────────────

  /// Ensures all capped products without a schedule row get the default spread.
  Future<void> ensureDefaultSchedules({required MasterContent master}) async {
    final morningSelections = await _repo.watchSelections(Slot.morning).first;
    final eveningSelections = await _repo.watchSelections(Slot.evening).first;
    var schedules = await _repo.watchAllSchedules().first;

    Set<String> selectedIds(List<ProductSelection> sels) =>
        sels.where((s) => s.isSelected).map((s) => s.productId).toSet();

    final mergedProducts = await allProducts(master);
    List<MasterProduct> slotProducts(Slot s, Set<String> ids) => mergedProducts
        .where((p) =>
            !p.isDeprecated &&
            ids.contains(p.id) &&
            p.configForSlot(s) != null)
        .toList();

    final morningIds = selectedIds(morningSelections);
    final eveningIds = selectedIds(eveningSelections);

    for (final pSlot in [Slot.morning, Slot.evening]) {
      final ids = pSlot == Slot.morning ? morningIds : eveningIds;
      for (final p in slotProducts(pSlot, ids)) {
        final rule = p.configForSlot(pSlot)?.frequencyRule;
        if (rule is! WeeklyMaxRule) continue;
        final existing = schedules
            .where((s) => s.productId == p.id && s.slot == pSlot)
            .firstOrNull;
        if (existing != null) continue;
        final defaultDays = _spreadN7(rule.maxPerWeek);
        final newSchedule = WeekdaySchedule(
          id: 'default-${p.id}-${pSlot.name}',
          productId: p.id,
          slot: pSlot,
          weekdays: defaultDays,
          lastModified: DateTime.now(),
        );
        await _repo.upsertSchedule(newSchedule);
        schedules = [...schedules, newSchedule];
      }
    }
  }
}
