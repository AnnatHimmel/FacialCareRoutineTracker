import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/services/incompatibility_checker.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

MasterProduct _prod(String id, {String? subCategoryId}) => MasterProduct(
      id: id,
      name: id,
      categoryId: 'cat-1',
      subCategoryId: subCategoryId,
      isDeprecated: false,
      morningConfig: null,
      eveningConfig: null,
    );

IncompatibilityRule _rule(
  String entityASubCat,
  String entityBSubCat, {
  RuleScope scope = RuleScope.sameDayAcrossBoth,
}) =>
    IncompatibilityRule(
      id: 'rule-$entityASubCat-$entityBSubCat',
      entityA: RuleTarget(type: RuleTargetType.subCategory, id: entityASubCat),
      entityB: RuleTarget(type: RuleTargetType.subCategory, id: entityBSubCat),
      scope: scope,
    );

const _noCategories = <Category>[];
const _noMuted = <String>{};

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  final checker = IncompatibilityChecker();

  group('getConflictsForDay — sameDayAcrossBoth', () {
    test(
        'returns a conflict for EACH retinoid product when 2 retinoids × 1 acid',
        () {
      // Regression: previously the checker returned `return` after the first
      // matching pair, so retinoid-B never got a conflict entry.
      final acid = _prod('acid-1', subCategoryId: 'subcat-acid');
      final retinoidA = _prod('retinoid-A', subCategoryId: 'subcat-retinoid');
      final retinoidB = _prod('retinoid-B', subCategoryId: 'subcat-retinoid');

      final rule = _rule('subcat-acid', 'subcat-retinoid');

      final conflicts = checker.getConflictsForDay(
        morningProducts: [acid],
        eveningProducts: [retinoidA, retinoidB],
        rules: [rule],
        categories: _noCategories,
        mutedRuleIds: _noMuted,
      );

      // Expect both retinoid products to have a conflict entry.
      final involvedIds = conflicts.map((c) => c.productB.id).toSet();
      expect(conflicts, hasLength(2));
      expect(involvedIds, containsAll(['retinoid-A', 'retinoid-B']));
    });

    test('conflict pair ordering: productA=acid, productB=retinoid for each', () {
      final acid = _prod('acid-1', subCategoryId: 'subcat-acid');
      final retinoidA = _prod('retinoid-A', subCategoryId: 'subcat-retinoid');
      final retinoidB = _prod('retinoid-B', subCategoryId: 'subcat-retinoid');

      final rule = _rule('subcat-acid', 'subcat-retinoid');

      final conflicts = checker.getConflictsForDay(
        morningProducts: [acid],
        eveningProducts: [retinoidA, retinoidB],
        rules: [rule],
        categories: _noCategories,
        mutedRuleIds: _noMuted,
      );

      for (final c in conflicts) {
        expect(c.productA.id, equals('acid-1'));
        expect(c.productB.subCategoryId, equals('subcat-retinoid'));
      }
    });
  });

  group('getConflictsForDay — withinSlot', () {
    test(
        'returns a conflict for EACH second product when 1 product × 2 products in same slot',
        () {
      // Same regression but within a single slot: if we have 3 products
      // A, B, C where rule is A-subcat × B-subcat, and B and C share subcat,
      // both (A×B) and (A×C) should be reported.
      final base = _prod('base-1', subCategoryId: 'subcat-base');
      final targetA = _prod('target-A', subCategoryId: 'subcat-target');
      final targetB = _prod('target-B', subCategoryId: 'subcat-target');

      final rule = _rule('subcat-base', 'subcat-target',
          scope: RuleScope.withinSlot);

      final conflicts = checker.getConflictsForDay(
        morningProducts: [base, targetA, targetB],
        eveningProducts: [],
        rules: [rule],
        categories: _noCategories,
        mutedRuleIds: _noMuted,
      );

      expect(conflicts, hasLength(2));
      final involvedIds = conflicts.map((c) => c.productB.id).toSet();
      expect(involvedIds, containsAll(['target-A', 'target-B']));
    });
  });

  group('getConflictsForDay — muting', () {
    test('muted conflicts are still returned but isMuted=true', () {
      final acid = _prod('acid-1', subCategoryId: 'subcat-acid');
      final retinoid = _prod('retinoid-A', subCategoryId: 'subcat-retinoid');
      final rule = _rule('subcat-acid', 'subcat-retinoid');

      final conflicts = checker.getConflictsForDay(
        morningProducts: [acid],
        eveningProducts: [retinoid],
        rules: [rule],
        categories: _noCategories,
        mutedRuleIds: {rule.id},
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.first.isMuted, isTrue);
    });
  });
}
