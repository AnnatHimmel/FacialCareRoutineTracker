import 'package:meta/meta.dart';
import 'master_product.dart';

@immutable
class UserCustomProduct {
  final String id;
  final String? brand;
  final String name;
  final String? photoKey;
  final String categoryId;
  final String? subCategoryId;
  final bool inMorning;
  final bool inEvening;
  final bool isDaily;
  final int? maxTimesPerWeek;
  final DateTime lastModified;
  /// User-authored notes per locale code, e.g. {"he": "...", "en": "..."}.
  final Map<String, String>? comment;
  final String? ingredients;
  final bool isDeprecated;

  const UserCustomProduct({
    required this.id,
    this.brand,
    required this.name,
    this.photoKey,
    required this.categoryId,
    this.subCategoryId,
    required this.inMorning,
    required this.inEvening,
    required this.isDaily,
    this.maxTimesPerWeek,
    required this.lastModified,
    this.comment,
    this.ingredients,
    this.isDeprecated = false,
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
        : WeeklyMaxRule(maxTimesPerWeek ?? 3) as FrequencyRule;

    // Split comma-separated INCI string into a trimmed list, dropping empties.
    final ingredientsList = ingredients
            ?.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const [];

    // Comment is stored as a locale-keyed map; MasterProduct has two flat slots
    // (comment = Hebrew-family, commentEn = English). Map the 'en' entry to
    // commentEn and the first non-empty non-'en' entry (covers 'he'/'he_MA')
    // to comment.
    final enComment = comment?['en'];
    String? heComment;
    if (comment != null) {
      for (final e in comment!.entries) {
        if (e.key != 'en' && e.value.isNotEmpty) {
          heComment = e.value;
          break;
        }
      }
    }

    return MasterProduct(
      id: id,
      brand: brand,
      name: name,
      imageAsset: photoKey != null ? 'user_photo:$photoKey' : null,
      comment: heComment,
      commentEn: enComment,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      morningConfig: inMorning ? SlotConfig(order: 999, frequencyRule: rule) : null,
      eveningConfig: inEvening ? SlotConfig(order: 999, frequencyRule: rule) : null,
      isDeprecated: isDeprecated,
      addedInVersion: 'custom',
      ingredients: ingredientsList,
    );
  }

  UserCustomProduct copyWith({
    String? id,
    Object? brand = _sentinel,
    String? name,
    String? photoKey,
    String? categoryId,
    String? subCategoryId,
    bool? inMorning,
    bool? inEvening,
    bool? isDaily,
    int? maxTimesPerWeek,
    DateTime? lastModified,
    Map<String, String>? comment,
    Object? ingredients = _sentinel,
    bool? isDeprecated,
  }) =>
      UserCustomProduct(
        id: id ?? this.id,
        brand: brand == _sentinel ? this.brand : brand as String?,
        name: name ?? this.name,
        photoKey: photoKey ?? this.photoKey,
        categoryId: categoryId ?? this.categoryId,
        subCategoryId: subCategoryId ?? this.subCategoryId,
        inMorning: inMorning ?? this.inMorning,
        inEvening: inEvening ?? this.inEvening,
        isDaily: isDaily ?? this.isDaily,
        maxTimesPerWeek: maxTimesPerWeek ?? this.maxTimesPerWeek,
        lastModified: lastModified ?? this.lastModified,
        comment: comment ?? this.comment,
        ingredients: ingredients == _sentinel ? this.ingredients : ingredients as String?,
        isDeprecated: isDeprecated ?? this.isDeprecated,
      );
}

const _sentinel = Object();
