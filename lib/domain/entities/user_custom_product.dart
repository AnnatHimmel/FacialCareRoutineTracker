import 'package:meta/meta.dart';
import 'master_product.dart';

@immutable
class UserCustomProduct {
  final String id;
  final String name;
  final String? photoKey;
  final String categoryId;
  final bool inMorning;
  final bool inEvening;
  final bool isDaily;
  final int? timesPerWeek;
  final DateTime lastModified;

  const UserCustomProduct({
    required this.id,
    required this.name,
    this.photoKey,
    required this.categoryId,
    required this.inMorning,
    required this.inEvening,
    required this.isDaily,
    this.timesPerWeek,
    required this.lastModified,
  });

  MasterProduct toMasterProduct() {
    final rule = isDaily
        ? const DailyRule()
        : WeeklyMaxRule(timesPerWeek ?? 3) as FrequencyRule;

    return MasterProduct(
      id: id,
      name: name,
      imageAsset: photoKey != null ? 'user_photo:$photoKey' : null,
      categoryId: categoryId,
      morningConfig: inMorning ? SlotConfig(order: 999, frequencyRule: rule) : null,
      eveningConfig: inEvening ? SlotConfig(order: 999, frequencyRule: rule) : null,
      isDeprecated: false,
      addedInVersion: 'custom',
    );
  }

  UserCustomProduct copyWith({
    String? id,
    String? name,
    String? photoKey,
    String? categoryId,
    bool? inMorning,
    bool? inEvening,
    bool? isDaily,
    int? timesPerWeek,
    DateTime? lastModified,
  }) =>
      UserCustomProduct(
        id: id ?? this.id,
        name: name ?? this.name,
        photoKey: photoKey ?? this.photoKey,
        categoryId: categoryId ?? this.categoryId,
        inMorning: inMorning ?? this.inMorning,
        inEvening: inEvening ?? this.inEvening,
        isDaily: isDaily ?? this.isDaily,
        timesPerWeek: timesPerWeek ?? this.timesPerWeek,
        lastModified: lastModified ?? this.lastModified,
      );
}
