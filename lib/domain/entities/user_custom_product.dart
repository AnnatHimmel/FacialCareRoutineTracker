import 'package:meta/meta.dart';
import 'master_product.dart';

@immutable
class UserCustomProduct {
  final String id;
  final String name;
  final String? photoKey;
  final String categoryId;
  final String? subCategoryId;
  final bool inMorning;
  final bool inEvening;
  final bool isDaily;
  final int? timesPerWeek;
  final DateTime lastModified;
  /// User-authored notes per locale code, e.g. {"he": "...", "en": "..."}.
  final Map<String, String>? comment;

  const UserCustomProduct({
    required this.id,
    required this.name,
    this.photoKey,
    required this.categoryId,
    this.subCategoryId,
    required this.inMorning,
    required this.inEvening,
    required this.isDaily,
    this.timesPerWeek,
    required this.lastModified,
    this.comment,
  });

  /// Returns (text, sourceLocale) for the requested locale.
  /// sourceLocale is null when the text is in the requested locale,
  /// or the actual locale code when returning a fallback.
  (String, String?)? commentForLocale(String locale) {
    if (comment == null || comment!.isEmpty) return null;
    final direct = comment![locale];
    if (direct != null && direct.isNotEmpty) return (direct, null);
    for (final e in comment!.entries) {
      if (e.value.isNotEmpty) return (e.value, e.key);
    }
    return null;
  }

  MasterProduct toMasterProduct() {
    final rule = isDaily
        ? const DailyRule()
        : WeeklyMaxRule(timesPerWeek ?? 3) as FrequencyRule;

    return MasterProduct(
      id: id,
      name: name,
      imageAsset: photoKey != null ? 'user_photo:$photoKey' : null,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
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
    String? subCategoryId,
    bool? inMorning,
    bool? inEvening,
    bool? isDaily,
    int? timesPerWeek,
    DateTime? lastModified,
    Map<String, String>? comment,
  }) =>
      UserCustomProduct(
        id: id ?? this.id,
        name: name ?? this.name,
        photoKey: photoKey ?? this.photoKey,
        categoryId: categoryId ?? this.categoryId,
        subCategoryId: subCategoryId ?? this.subCategoryId,
        inMorning: inMorning ?? this.inMorning,
        inEvening: inEvening ?? this.inEvening,
        isDaily: isDaily ?? this.isDaily,
        timesPerWeek: timesPerWeek ?? this.timesPerWeek,
        lastModified: lastModified ?? this.lastModified,
        comment: comment ?? this.comment,
      );
}
