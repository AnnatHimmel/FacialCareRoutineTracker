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
  final String? brand;
  final String name;
  final String? imageAsset;
  final String? comment;
  final String? commentEn;
  final String categoryId;
  final String? subCategoryId;
  final SlotConfig? morningConfig;
  final SlotConfig? eveningConfig;
  final bool isDeprecated;
  final String addedInVersion;
  final List<String> ingredients;
  final List<String> barcodes;

  const MasterProduct({
    required this.id,
    this.brand,
    required this.name,
    this.imageAsset,
    this.comment,
    this.commentEn,
    required this.categoryId,
    this.subCategoryId,
    this.morningConfig,
    this.eveningConfig,
    required this.isDeprecated,
    required this.addedInVersion,
    this.ingredients = const [],
    this.barcodes = const [],
  });

  SlotConfig? configForSlot(Slot slot) =>
      slot == Slot.morning ? morningConfig : eveningConfig;

  @override
  bool operator ==(Object other) {
    if (other is! MasterProduct) {
      return false;
    }
    if (other.id != id ||
        other.brand != brand ||
        other.name != name ||
        other.imageAsset != imageAsset ||
        other.comment != comment ||
        other.commentEn != commentEn ||
        other.categoryId != categoryId ||
        other.subCategoryId != subCategoryId ||
        other.morningConfig != morningConfig ||
        other.eveningConfig != eveningConfig ||
        other.isDeprecated != isDeprecated ||
        other.addedInVersion != addedInVersion) {
      return false;
    }
    if (other.ingredients.length != ingredients.length) {
      return false;
    }
    for (var i = 0; i < ingredients.length; i++) {
      if (other.ingredients[i] != ingredients[i]) {
        return false;
      }
    }
    if (other.barcodes.length != barcodes.length) {
      return false;
    }
    for (var i = 0; i < barcodes.length; i++) {
      if (other.barcodes[i] != barcodes[i]) {
        return false;
      }
    }
    return true;
  }

  String localizedComment(String locale) =>
      locale == 'en' ? (commentEn ?? comment ?? '') : (comment ?? '');

  @override
  int get hashCode => Object.hash(
        id,
        brand,
        name,
        imageAsset,
        comment,
        commentEn,
        categoryId,
        subCategoryId,
        morningConfig,
        eveningConfig,
        isDeprecated,
        addedInVersion,
        Object.hashAll(ingredients),
        Object.hashAll(barcodes),
      );

  MasterProduct copyWith({
    String? id,
    Object? brand = _sentinel,
    String? name,
    String? imageAsset,
    String? comment,
    String? commentEn,
    String? categoryId,
    String? subCategoryId,
    SlotConfig? morningConfig,
    SlotConfig? eveningConfig,
    bool? isDeprecated,
    String? addedInVersion,
    List<String>? ingredients,
    List<String>? barcodes,
  }) =>
      MasterProduct(
        id: id ?? this.id,
        brand: brand == _sentinel ? this.brand : brand as String?,
        name: name ?? this.name,
        imageAsset: imageAsset ?? this.imageAsset,
        comment: comment ?? this.comment,
        commentEn: commentEn ?? this.commentEn,
        categoryId: categoryId ?? this.categoryId,
        subCategoryId: subCategoryId ?? this.subCategoryId,
        morningConfig: morningConfig ?? this.morningConfig,
        eveningConfig: eveningConfig ?? this.eveningConfig,
        isDeprecated: isDeprecated ?? this.isDeprecated,
        addedInVersion: addedInVersion ?? this.addedInVersion,
        ingredients: ingredients ?? this.ingredients,
        barcodes: barcodes ?? this.barcodes,
      );
}

const _sentinel = Object();
