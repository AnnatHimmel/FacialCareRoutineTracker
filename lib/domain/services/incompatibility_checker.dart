import '../entities/category.dart';
import '../entities/incompatibility_rule.dart';
import '../entities/master_product.dart';
import '../enums/rule_scope.dart';
import '../enums/slot.dart';

class ConflictInfo {
  final String ruleId;
  final MasterProduct productA;
  final MasterProduct productB;
  final RuleScope scope;
  final bool isMuted;
  final String? reason;
  final String? reasonEn;

  const ConflictInfo({
    required this.ruleId,
    required this.productA,
    required this.productB,
    required this.scope,
    required this.isMuted,
    this.reason,
    this.reasonEn,
  });

  String? localizedReason(String locale) =>
      locale == 'en' ? (reasonEn ?? reason) : reason;
}

class IncompatibilityChecker {
  List<ConflictInfo> getConflictsForDay({
    required List<MasterProduct> morningProducts,
    required List<MasterProduct> eveningProducts,
    required List<IncompatibilityRule> rules,
    required List<Category> categories,
    required Set<String> mutedRuleIds,
  }) {
    final conflicts = <ConflictInfo>[];
    for (final rule in rules) {
      switch (rule.scope) {
        case RuleScope.withinSlot:
          _checkWithinSlot(morningProducts, rule, categories, mutedRuleIds, conflicts);
          _checkWithinSlot(eveningProducts, rule, categories, mutedRuleIds, conflicts);
        case RuleScope.sameDayAcrossBoth:
          _checkAcrossSlots(
            morningProducts,
            eveningProducts,
            rule,
            categories,
            mutedRuleIds,
            conflicts,
          );
      }
    }
    return conflicts;
  }

  /// Conflicts for selection screen (S1): scope-aware check.
  /// [activeSlot] is the tab the user is currently on.
  /// [otherSlotProducts] are already-selected products in the other slot.
  List<ConflictInfo> getConflictsForSelection({
    required Slot activeSlot,
    required List<MasterProduct> slotProducts,
    required List<MasterProduct> otherSlotProducts,
    required List<IncompatibilityRule> rules,
    required List<Category> categories,
    required Set<String> mutedRuleIds,
  }) {
    final conflicts = <ConflictInfo>[];
    for (final rule in rules) {
      switch (rule.scope) {
        case RuleScope.withinSlot:
          _checkWithinSlot(slotProducts, rule, categories, mutedRuleIds, conflicts);
        case RuleScope.sameDayAcrossBoth:
          _checkAcrossSlots(
            slotProducts,
            otherSlotProducts,
            rule,
            categories,
            mutedRuleIds,
            conflicts,
          );
      }
    }
    return conflicts;
  }

  bool _matches(
    MasterProduct p,
    RuleTarget target,
    List<Category> categories,
  ) =>
      switch (target.type) {
        RuleTargetType.product => p.id == target.id,
        RuleTargetType.category => p.categoryId == target.id,
      };

  void _checkWithinSlot(
    List<MasterProduct> products,
    IncompatibilityRule rule,
    List<Category> categories,
    Set<String> muted,
    List<ConflictInfo> out,
  ) {
    for (final a in products) {
      for (final b in products) {
        if (a.id == b.id) continue;
        if (_matches(a, rule.entityA, categories) &&
            _matches(b, rule.entityB, categories)) {
          out.add(ConflictInfo(
            ruleId: rule.id,
            productA: a,
            productB: b,
            scope: rule.scope,
            isMuted: muted.contains(rule.id),
            reason: rule.reason,
            reasonEn: rule.reasonEn,
          ));
          return;
        }
      }
    }
  }

  void _checkAcrossSlots(
    List<MasterProduct> morningProducts,
    List<MasterProduct> eveningProducts,
    IncompatibilityRule rule,
    List<Category> categories,
    Set<String> muted,
    List<ConflictInfo> out,
  ) {
    final all = [...morningProducts, ...eveningProducts];
    for (final a in all) {
      for (final b in all) {
        if (a.id == b.id) continue;
        if (_matches(a, rule.entityA, categories) &&
            _matches(b, rule.entityB, categories)) {
          out.add(ConflictInfo(
            ruleId: rule.id,
            productA: a,
            productB: b,
            scope: rule.scope,
            isMuted: muted.contains(rule.id),
            reason: rule.reason,
            reasonEn: rule.reasonEn,
          ));
          return;
        }
      }
    }
  }
}
