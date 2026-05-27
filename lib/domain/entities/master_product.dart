import 'package:meta/meta.dart';
import '../enums/slot.dart';

sealed class FrequencyRule {
  const FrequencyRule();
}

final class DailyRule extends FrequencyRule {
  const DailyRule();

  @override
  bool operator ==(Object other) => other is DailyRule;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class WeeklyMaxRule extends FrequencyRule {
  final int maxPerWeek;
  const WeeklyMaxRule(this.maxPerWeek);

  @override
  bool operator ==(Object other) =>
      other is WeeklyMaxRule && other.maxPerWeek == maxPerWeek;

  @override
  int get hashCode => Object.hash(runtimeType, maxPerWeek);
}

@immutable
class SlotConfig {
  final int order;
  final FrequencyRule frequencyRule;

  const SlotConfig({required this.order, required this.frequencyRule});

  @override
  bool operator ==(Object other) =>
      other is SlotConfig &&
      other.order == order &&
      other.frequencyRule == frequencyRule;

  @override
  int get hashCode => Object.hash(order, frequencyRule);

  SlotConfig copyWith({int? order, FrequencyRule? frequencyRule}) => SlotConfig(
        order: order ?? this.order,
        frequencyRule: frequencyRule ?? this.frequencyRule,
      );
}

@immutable
class MasterProduct {
  final String id;
  final String name;
  final String? imageAsset;
  final String? comment;
  final String categoryId;
  final SlotConfig? morningConfig;
  final SlotConfig? eveningConfig;
  final bool isDeprecated;
  final String addedInVersion;

  const MasterProduct({
    required this.id,
    required this.name,
    this.imageAsset,
    this.comment,
    required this.categoryId,
    this.morningConfig,
    this.eveningConfig,
    required this.isDeprecated,
    required this.addedInVersion,
  });

  SlotConfig? configForSlot(Slot slot) =>
      slot == Slot.morning ? morningConfig : eveningConfig;

  @override
  bool operator ==(Object other) =>
      other is MasterProduct &&
      other.id == id &&
      other.name == name &&
      other.imageAsset == imageAsset &&
      other.comment == comment &&
      other.categoryId == categoryId &&
      other.morningConfig == morningConfig &&
      other.eveningConfig == eveningConfig &&
      other.isDeprecated == isDeprecated &&
      other.addedInVersion == addedInVersion;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        imageAsset,
        comment,
        categoryId,
        morningConfig,
        eveningConfig,
        isDeprecated,
        addedInVersion,
      );

  MasterProduct copyWith({
    String? id,
    String? name,
    String? imageAsset,
    String? comment,
    String? categoryId,
    SlotConfig? morningConfig,
    SlotConfig? eveningConfig,
    bool? isDeprecated,
    String? addedInVersion,
  }) =>
      MasterProduct(
        id: id ?? this.id,
        name: name ?? this.name,
        imageAsset: imageAsset ?? this.imageAsset,
        comment: comment ?? this.comment,
        categoryId: categoryId ?? this.categoryId,
        morningConfig: morningConfig ?? this.morningConfig,
        eveningConfig: eveningConfig ?? this.eveningConfig,
        isDeprecated: isDeprecated ?? this.isDeprecated,
        addedInVersion: addedInVersion ?? this.addedInVersion,
      );
}
