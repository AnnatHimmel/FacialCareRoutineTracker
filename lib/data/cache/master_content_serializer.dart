import '../../domain/entities/category.dart';
import '../../domain/entities/incompatibility_rule.dart';
import '../../domain/entities/master_list_manifest.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/sub_category.dart';
import '../../domain/enums/rule_scope.dart';
import '../../domain/repositories/master_content_repository.dart';

abstract final class MasterContentSerializer {
  static MasterContent fromCombinedJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List<dynamic>)
        .map((c) => _parseCategory(c as Map<String, dynamic>))
        .toList();

    final subcategories =
        ((json['subcategories'] as List<dynamic>?) ?? const [])
            .map((s) => _parseSubCategory(s as Map<String, dynamic>))
            .toList();

    final products = (json['products'] as List<dynamic>)
        .map((p) => _parseProduct(p as Map<String, dynamic>))
        .toList();

    final rules = (json['rules'] as List<dynamic>)
        .map((r) => _parseRule(r as Map<String, dynamic>))
        .toList();

    final manifest = MasterListManifest(
      contentVersion: json['contentVersion'] as String,
      appVersion: json['appVersion'] as String,
      changelog: (json['changelog'] as List<dynamic>)
          .map((e) => _parseChangelog(e as Map<String, dynamic>))
          .toList(),
    );

    return MasterContent(
      products: products,
      categories: categories,
      subcategories: subcategories,
      rules: rules,
      manifest: manifest,
    );
  }

  static Map<String, dynamic> toJson(MasterContent content) => {
        'contentVersion': content.manifest.contentVersion,
        'appVersion': content.manifest.appVersion,
        'changelog': content.manifest.changelog
            .map((e) => {
                  'contentVersion': e.contentVersion,
                  'changes': e.changes,
                })
            .toList(),
        'categories': content.categories
            .map((c) => {
                  'id': c.id,
                  'name': {'he': c.name, 'en': c.nameEn},
                  'order': c.order,
                  'icon': c.icon,
                })
            .toList(),
        'subcategories':
            content.subcategories.map(_subCategoryToJson).toList(),
        'products': content.products.map(_productToJson).toList(),
        'rules': content.rules.map(_ruleToJson).toList(),
      };

  static Map<String, dynamic> _productToJson(MasterProduct p) => {
        'id': p.id,
        'brand': p.brand,
        'name': p.name,
        'imageAsset': p.imageAsset,
        'comment': {'he': p.comment, 'en': p.commentEn},
        'categoryId': p.categoryId,
        'subCategoryId': p.subCategoryId,
        'isDeprecated': p.isDeprecated,
        'addedInVersion': p.addedInVersion,
        'morningConfig':
            p.morningConfig != null ? _slotConfigToJson(p.morningConfig!) : null,
        'eveningConfig':
            p.eveningConfig != null ? _slotConfigToJson(p.eveningConfig!) : null,
        'ingredients': p.ingredients,
        'barcodes': p.barcodes,
      };

  static Map<String, dynamic> _subCategoryToJson(SubCategory s) => {
        'id': s.id,
        'name': {'he': s.name, 'en': s.nameEn},
        'categoryId': s.categoryId,
        'order': s.order,
      };

  static Map<String, dynamic> _slotConfigToJson(SlotConfig c) => {
        'order': c.order,
        'frequency': _frequencyToJson(c.frequencyRule),
      };

  static Map<String, dynamic> _frequencyToJson(FrequencyRule r) =>
      switch (r) {
        DailyRule() => {'type': 'daily'},
        WeeklyMaxRule(:final maxPerWeek) => {
            'type': 'weeklyMax',
            'maxPerWeek': maxPerWeek,
          },
      };

  static Map<String, dynamic> _ruleToJson(IncompatibilityRule r) => {
        'id': r.id,
        'entityA': {'type': _targetTypeStr(r.entityA.type), 'id': r.entityA.id},
        'entityB': {'type': _targetTypeStr(r.entityB.type), 'id': r.entityB.id},
        'scope': _scopeStr(r.scope),
        'reason': {'he': r.reason, 'en': r.reasonEn},
      };

  static String _targetTypeStr(RuleTargetType t) => switch (t) {
        RuleTargetType.product => 'product',
        RuleTargetType.category => 'category',
        RuleTargetType.subCategory => 'subCategory',
      };

  static String _scopeStr(RuleScope s) =>
      s == RuleScope.withinSlot ? 'withinSlot' : 'sameDayAcrossBoth';

  // ── Parsing helpers (shared with MasterContentRepositoryImpl) ──────────────

  static Category parseCategory(Map<String, dynamic> m) =>
      _parseCategory(m);

  static SubCategory parseSubCategory(Map<String, dynamic> m) =>
      _parseSubCategory(m);

  static MasterProduct parseProduct(Map<String, dynamic> m) =>
      _parseProduct(m);

  static IncompatibilityRule parseRule(Map<String, dynamic> m) =>
      _parseRule(m);

  static SlotConfig parseSlotConfig(Map<String, dynamic> m) =>
      _parseSlotConfig(m);

  static FrequencyRule parseFrequency(Map<String, dynamic> m) =>
      _parseFrequency(m);

  static ChangelogEntry parseChangelog(Map<String, dynamic> m) =>
      _parseChangelog(m);

  // ── Private parsers ────────────────────────────────────────────────────────

  static Category _parseCategory(Map<String, dynamic> m) {
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

  static SubCategory _parseSubCategory(Map<String, dynamic> m) {
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
    return SubCategory(
      id: m['id'] as String,
      name: nameHe,
      nameEn: nameEn,
      categoryId: m['categoryId'] as String,
      order: m['order'] as int,
    );
  }

  static MasterProduct _parseProduct(Map<String, dynamic> m) {
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
      brand: m['brand'] as String?,
      name: m['name'] as String,
      imageAsset: m['imageAsset'] as String?,
      comment: commentHe,
      commentEn: commentEn,
      categoryId: m['categoryId'] as String,
      subCategoryId: m['subCategoryId'] as String?,
      morningConfig: m['morningConfig'] == null
          ? null
          : _parseSlotConfig(m['morningConfig'] as Map<String, dynamic>),
      eveningConfig: m['eveningConfig'] == null
          ? null
          : _parseSlotConfig(m['eveningConfig'] as Map<String, dynamic>),
      isDeprecated: m['isDeprecated'] as bool,
      addedInVersion: m['addedInVersion'] as String,
      ingredients:
          (m['ingredients'] as List<dynamic>?)?.cast<String>() ?? const [],
      barcodes:
          (m['barcodes'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  static SlotConfig _parseSlotConfig(Map<String, dynamic> m) => SlotConfig(
        order: m['order'] as int,
        frequencyRule: _parseFrequency(m['frequency'] as Map<String, dynamic>),
      );

  static FrequencyRule _parseFrequency(Map<String, dynamic> m) {
    final type = m['type'] as String;
    return switch (type) {
      'daily' => const DailyRule(),
      'weeklyMax' => WeeklyMaxRule(m['maxPerWeek'] as int),
      _ => const DailyRule(),
    };
  }

  static IncompatibilityRule _parseRule(Map<String, dynamic> m) {
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

  static RuleTarget _parseTarget(Map<String, dynamic> m) => RuleTarget(
        type: switch (m['type']) {
          'product' => RuleTargetType.product,
          'subCategory' => RuleTargetType.subCategory,
          _ => RuleTargetType.category,
        },
        id: m['id'] as String,
      );

  static RuleScope _parseScope(String s) => switch (s) {
        'withinSlot' => RuleScope.withinSlot,
        _ => RuleScope.sameDayAcrossBoth,
      };

  static ChangelogEntry _parseChangelog(Map<String, dynamic> m) =>
      ChangelogEntry(
        contentVersion: m['contentVersion'] as String,
        changes: (m['changes'] as List<dynamic>).cast<String>(),
      );
}
