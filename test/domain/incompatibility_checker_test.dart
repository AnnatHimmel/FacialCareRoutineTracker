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
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinMorning);

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

    test('no conflict if products in different scope', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinEvening);

      final conflicts = checker.getConflictsForDay(
        morningProducts: [p1, p2],
        eveningProducts: [],
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
      final rule = categoryRule('r1', 'cat-a', 'cat-b', RuleScope.withinMorning);

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

  group('muted conflicts', () {
    test('muted conflict still appears but isMuted=true', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinMorning);

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

  // ── BUG 4 — getConflictsForSelection ignores rule scope ───────────────────
  //
  // getConflictsForSelection must accept an activeSlot and otherSlotProducts.
  // withinMorning/withinEvening rules apply only to the matching active slot.
  // sameDayAcrossBoth rules check active-slot products against the other slot.

  group('getConflictsForSelection — scope filtering', () {
    test('withinMorning rule + morning active slot → conflict found', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinMorning);

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

    test('withinMorning rule + evening active slot → no conflict', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinMorning);

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.evening,
        slotProducts: [p1, p2],
        otherSlotProducts: [],
        rules: [rule],
        categories: categories,
        mutedRuleIds: {},
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('withinEvening rule + evening active slot → conflict found', () {
      final p1 = makeProduct('p1', 'cat');
      final p2 = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.withinEvening);

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
      final pEvening = makeProduct('p2', 'cat');
      final rule = productRule('r1', 'p1', 'p2', RuleScope.sameDayAcrossBoth);

      // pEvening is NOT in otherSlotProducts → no conflict
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
