import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/incompatibility_rule.dart';
import '../../domain/entities/master_list_manifest.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/rule_scope.dart';
import '../../domain/repositories/master_content_repository.dart';

class MasterContentRepositoryImpl implements MasterContentRepository {
  MasterContent? _cached;

  @override
  Future<MasterContent> load() async {
    if (_cached != null) return _cached!;

    final productsJson =
        await rootBundle.loadString('assets/data/master_products.json');
    final rulesJson =
        await rootBundle.loadString('assets/data/incompatibility_rules.json');
    final changelogJson =
        await rootBundle.loadString('assets/data/changelog.json');

    final productsData = jsonDecode(productsJson) as Map<String, dynamic>;
    final rulesData = jsonDecode(rulesJson) as Map<String, dynamic>;
    final changelogData = jsonDecode(changelogJson) as Map<String, dynamic>;

    final categories = (productsData['categories'] as List<dynamic>)
        .map((c) => _parseCategory(c as Map<String, dynamic>))
        .toList();

    final products = (productsData['products'] as List<dynamic>)
        .map((p) => _parseProduct(p as Map<String, dynamic>))
        .toList();

    final rules = (rulesData['rules'] as List<dynamic>)
        .map((r) => _parseRule(r as Map<String, dynamic>))
        .toList();

    final manifest = MasterListManifest(
      contentVersion: changelogData['contentVersion'] as String,
      appVersion: changelogData['appVersion'] as String,
      changelog: (changelogData['changelog'] as List<dynamic>)
          .map((e) => _parseChangelog(e as Map<String, dynamic>))
          .toList(),
    );

    _cached = MasterContent(
      products: products,
      categories: categories,
      rules: rules,
      manifest: manifest,
    );
    return _cached!;
  }

  Category _parseCategory(Map<String, dynamic> m) {
    final nameRaw = m['name'];
    final String nameHe;
    final String? nameEn;
    if (nameRaw is Map) {
      nameHe = nameRaw['he'] as String? ?? '';
      nameEn = nameRaw['en'] as String?;
    } else {
      nameHe = nameRaw as String? ?? '';
      nameEn = m['nameEn'] as String?;
    }
    return Category(
      id: m['id'] as String,
      name: nameHe,
      nameEn: nameEn,
      order: m['order'] as int,
      icon: m['icon'] as String?,
    );
  }

  MasterProduct _parseProduct(Map<String, dynamic> m) {
    final commentRaw = m['comment'];
    final String? commentHe;
    final String? commentEn;
    if (commentRaw is Map) {
      commentHe = commentRaw['he'] as String?;
      commentEn = commentRaw['en'] as String?;
    } else {
      commentHe = commentRaw as String?;
      commentEn = m['commentEn'] as String?;
    }
    return MasterProduct(
      id: m['id'] as String,
      name: m['name'] as String,
      imageAsset: m['imageAsset'] as String?,
      comment: commentHe,
      commentEn: commentEn,
      categoryId: m['categoryId'] as String,
      morningConfig: m['morningConfig'] == null
          ? null
          : _parseSlotConfig(m['morningConfig'] as Map<String, dynamic>),
      eveningConfig: m['eveningConfig'] == null
          ? null
          : _parseSlotConfig(m['eveningConfig'] as Map<String, dynamic>),
      isDeprecated: m['isDeprecated'] as bool,
      addedInVersion: m['addedInVersion'] as String,
    );
  }

  SlotConfig _parseSlotConfig(Map<String, dynamic> m) => SlotConfig(
        order: m['order'] as int,
        frequencyRule: _parseFrequency(m['frequency'] as Map<String, dynamic>),
      );

  FrequencyRule _parseFrequency(Map<String, dynamic> m) {
    final type = m['type'] as String;
    return switch (type) {
      'daily' => const DailyRule(),
      'weeklyMax' => WeeklyMaxRule(m['maxPerWeek'] as int),
      _ => const DailyRule(),
    };
  }

  IncompatibilityRule _parseRule(Map<String, dynamic> m) {
    final reasonRaw = m['reason'];
    final String? reasonHe;
    final String? reasonEn;
    if (reasonRaw is Map) {
      reasonHe = reasonRaw['he'] as String?;
      reasonEn = reasonRaw['en'] as String?;
    } else {
      reasonHe = reasonRaw as String?;
      reasonEn = m['reasonEn'] as String?;
    }
    return IncompatibilityRule(
      id: m['id'] as String,
      entityA: _parseTarget(m['entityA'] as Map<String, dynamic>),
      entityB: _parseTarget(m['entityB'] as Map<String, dynamic>),
      scope: _parseScope(m['scope'] as String),
      reason: reasonHe,
      reasonEn: reasonEn,
    );
  }

  RuleTarget _parseTarget(Map<String, dynamic> m) => RuleTarget(
        type: m['type'] == 'product'
            ? RuleTargetType.product
            : RuleTargetType.category,
        id: m['id'] as String,
      );

  RuleScope _parseScope(String s) => switch (s) {
        'withinSlot' => RuleScope.withinSlot,
        _ => RuleScope.sameDayAcrossBoth,
      };

  ChangelogEntry _parseChangelog(Map<String, dynamic> m) => ChangelogEntry(
        contentVersion: m['contentVersion'] as String,
        changes: (m['changes'] as List<dynamic>).cast<String>(),
      );
}
