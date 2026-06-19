import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/incompatibility_checker.dart';

void main() {
  final checker = IncompatibilityChecker();
  final categories = <Category>[];

  MasterProduct makeProduct(String id, String categoryId) => MasterProduct(
        id: id,
        name: id,
        categoryId: categoryId,
        isDeprecated: false,
        addedInVersion: '1.0.0',
      );

  MasterProduct makeSubProduct(
    String id,
    String categoryId,
    String subCategoryId,
  ) =>
      MasterProduct(
        id: id,
        name: id,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        isDeprecated: false,
        addedInVersion: '1.0.0',
      );

  IncompatibilityRule subCategoryRule(
    String id,
    String scA,
    String scB,
    RuleScope scope,
  ) =>
      IncompatibilityRule(
        id: id,
        entityA: RuleTarget(type: RuleTargetType.subCategory, id: scA),
        entityB: RuleTarget(type: RuleTargetType.subCategory, id: scB),
        scope: scope,
      );

  IncompatibilityRule productRule(String id, String pA, String pB, RuleScope scope) =>
      IncompatibilityRule(
        id: id,
        entityA: RuleTarget(type: RuleTargetType.product, id: pA),
        entityB: RuleTarget(type: RuleTargetType.product, id: pB),
        scope: scope,
      );

  IncompatibilityRule categoryRule(String id, String cA, String cB, RuleScope scope) =>
      IncompatibilityRule(
        id: id,
        entityA: RuleTarget(type: RuleTargetType.category, id: cA),
        entityB: RuleTarget(type: RuleTargetType.category, id: cB),
        scope: scope,
      );

  group('product conflicts', () {
    test('detects product↔product conflict within morning', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinSlot);

      final conflicts = checker.getConflictsForDay(
        morningProducts: [p1, p2],
        eveningProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.ruleId, 'r1');
      expect(conflicts.first.isMuted, isFalse);
    });

    test('no conflict when products are in different slots', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinSlot);

      final conflicts = checker.getConflictsForDay(
        morningProducts: [p1],
        eveningProducts: [p2],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.isEmpty, isTrue);
    });
  });

  group('category conflicts', () {
    test('detects category↔category conflict', () {
      final p1 = makeProduct('p1', 'cat-a');
      final p2 = makeProduct('p2', 'cat-b');
      final rule = categoryRule('r1', 'cat-a', 'cat-b', RuleScope.withinSlot);

      final conflicts = checker.getConflictsForDay(
        morningProducts: [p1, p2],
        eveningProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.length, 1);
    });
  });

  group('sub-category conflicts', () {
    test('detects subCategory↔subCategory conflict within slot', () {
      final p1 = makeSubProduct('p1', 'cat-serum', 'sub-argireline');
      final p2 = makeSubProduct('p2', 'cat-serum', 'sub-vitamin-c');
      final rule = subCategoryRule(
        'r1',
        'sub-argireline',
        'sub-vitamin-c',
        RuleScope.withinSlot,
      );

      final conflicts = checker.getConflictsForDay(
        morningProducts: [p1, p2],
        eveningProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.ruleId, 'r1');
    });

    test('no conflict when only one sub-category present', () {
      final p1 = makeSubProduct('p1', 'cat-serum', 'sub-argireline');
      final rule = subCategoryRule(
        'r1',
        'sub-argireline',
        'sub-vitamin-c',
        RuleScope.withinSlot,
      );

      final conflicts = checker.getConflictsForDay(
        morningProducts: [p1],
        eveningProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.isEmpty, isTrue);
    });
  });

  group('muted conflicts', () {
    test('muted conflict still appears but isMuted=true', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinSlot);

      final conflicts = checker.getConflictsForDay(
        morningProducts: [p1, p2],
        eveningProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {'r1'},
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.isMuted, isTrue);
    });
  });

  group('sameDayAcrossBoth scope', () {
    test('detects conflict across morning and evening', () {
      final pMorning = makeProduct('p1', 'cat');
      final pEvening = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.sameDayAcrossBoth);

      final conflicts = checker.getConflictsForDay(
        morningProducts: [pMorning],
        eveningProducts: [pEvening],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.length, 1);
    });
  });

  group('getConflictsForSelection — scope filtering', () {
    test('withinSlot rule + both products in active slot → conflict found', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinSlot);

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.morning,
        slotProducts: [p1, p2],
        otherSlotProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.length, 1);
    });

    test('withinSlot rule + only one product in active slot → no conflict', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinSlot);

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.morning,
        slotProducts: [p1],
        otherSlotProducts: [p2],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('withinSlot rule + both products in evening slot → conflict found', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinSlot);

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.evening,
        slotProducts: [p1, p2],
        otherSlotProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.length, 1);
    });

    test('sameDayAcrossBoth rule: active morning product + other evening product → conflict', () {
      final pMorning = makeProduct('p1', 'cat');
      final pEvening = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.sameDayAcrossBoth);

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.morning,
        slotProducts: [pMorning],
        otherSlotProducts: [pEvening],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.length, 1);
    });

    test('sameDayAcrossBoth rule: other product not selected → no conflict', () {
      final pMorning = makeProduct('p1', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.sameDayAcrossBoth);

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.morning,
        slotProducts: [pMorning],
        otherSlotProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('muted sameDayAcrossBoth conflict → isMuted: true', () {
      final pMorning = makeProduct('p1', 'cat');
      final pEvening = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.sameDayAcrossBoth);

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.morning,
        slotProducts: [pMorning],
        otherSlotProducts: [pEvening],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {'r1'},
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.isMuted, isTrue);
    });
  });
}
