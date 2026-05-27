import 'package:meta/meta.dart';

@immutable
class MutedConflict {
  final String id;
  final String ruleId;
  final DateTime mutedAt;

  const MutedConflict({
    required this.id,
    required this.ruleId,
    required this.mutedAt,
  });

  @override
  bool operator ==(Object other) =>
      other is MutedConflict &&
      other.id == id &&
      other.ruleId == ruleId &&
      other.mutedAt == mutedAt;

  @override
  int get hashCode => Object.hash(id, ruleId, mutedAt);

  MutedConflict copyWith({String? id, String? ruleId, DateTime? mutedAt}) =>
      MutedConflict(
        id: id ?? this.id,
        ruleId: ruleId ?? this.ruleId,
        mutedAt: mutedAt ?? this.mutedAt,
      );
}
