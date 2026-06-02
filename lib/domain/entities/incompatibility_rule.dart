import 'package:meta/meta.dart';
import '../enums/rule_scope.dart';

enum RuleTargetType { product, category }

@immutable
class RuleTarget {
  final RuleTargetType type;
  final String id;

  const RuleTarget({required this.type, required this.id});

  @override
  bool operator ==(Object other) =>
      other is RuleTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);

  RuleTarget copyWith({RuleTargetType? type, String? id}) =>
      RuleTarget(type: type ?? this.type, id: id ?? this.id);
}

@immutable
class IncompatibilityRule {
  final String id;
  final RuleTarget entityA;
  final RuleTarget entityB;
  final RuleScope scope;
  final String? reason;

  const IncompatibilityRule({
    required this.id,
    required this.entityA,
    required this.entityB,
    required this.scope,
    this.reason,
  });

  @override
  bool operator ==(Object other) =>
      other is IncompatibilityRule &&
      other.id == id &&
      other.entityA == entityA &&
      other.entityB == entityB &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(id, entityA, entityB, scope);

  IncompatibilityRule copyWith({
    String? id,
    RuleTarget? entityA,
    RuleTarget? entityB,
    RuleScope? scope,
    String? reason,
  }) =>
      IncompatibilityRule(
        id: id ?? this.id,
        entityA: entityA ?? this.entityA,
        entityB: entityB ?? this.entityB,
        scope: scope ?? this.scope,
        reason: reason ?? this.reason,
      );
}
