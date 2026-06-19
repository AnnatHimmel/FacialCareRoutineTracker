/// Maps a free-form product (name + INCI ingredients + brand + form) onto a
/// sub-category id (PRD §15.4), entirely on-device with no network.
///
/// The classifier is **data-driven**: it consumes the keyword / brand-line map
/// authored alongside the sub-categories in master content. Each sub-category
/// entry may carry a `keywords` array (Hebrew, English and INCI tokens) and an
/// optional `brandLines` array (specific product-line names). Matching keys on
/// the HERO active of a product, so e.g. numbuzin "No.9" resolves to NAD+ even
/// though it also contains niacinamide.
///
/// Priority, highest first:
///   1. brand-line tokens found in the name (most specific — e.g. "No.9")
///   2. keyword tokens found in the name (the hero active)
///   3. keyword tokens found in the INCI ingredient list
///   4. brand-line tokens found in the brand field
/// No confident match falls back to [unclassifiedId]. Never throws.
class ProductClassifier {
  static const String unclassifiedId = 'sub-unclassified';

  /// One matchable sub-category, with its normalized token sets.
  final List<_SubCategoryRule> _rules;

  const ProductClassifier._(this._rules);

  /// Builds a classifier from parsed subcategory JSON entries (the
  /// `subcategories` array of master content). Reads only `id`, `keywords` and
  /// `brandLines`; unknown fields are ignored.
  factory ProductClassifier.fromSubcategories(
    List<Map<String, dynamic>> subcategories,
  ) {
    final rules = <_SubCategoryRule>[];
    for (final s in subcategories) {
      final id = s['id'] as String?;
      if (id == null || id == unclassifiedId) continue;
      final keywords = _normalizeTokens(s['keywords']);
      final brandLines = _normalizeTokens(s['brandLines']);
      final formKeywords = _normalizeTokens(s['formKeywords']);
      if (keywords.isEmpty && brandLines.isEmpty) continue;
      rules.add(_SubCategoryRule(
        id: id,
        keywords: keywords,
        brandLines: brandLines,
        formKeywords: formKeywords,
      ));
    }
    return ProductClassifier._(rules);
  }

  /// Returns the best-matching sub-category id, or [unclassifiedId] if nothing
  /// matches confidently. Never throws.
  String classify({
    required String name,
    List<String> ingredients = const [],
    String? brand,
    String? form,
  }) {
    // Build the searchable name haystack from name + form, so galactomyces
    // toner vs serum disambiguates on the form/name text.
    final nameHaystack = _normalize('$name ${form ?? ''}');
    final ingredientHaystack = _normalize(ingredients.join(' '));
    final brandHaystack = _normalize(brand ?? '');

    // 1. brand-line tokens in the name (most specific signal).
    for (final rule in _rules) {
      if (_containsAny(nameHaystack, rule.brandLines)) return rule.id;
    }

    // 2. keyword tokens in the name (the hero active). When a rule carries
    // formKeywords it shares its keyword with a sibling (e.g. galactomyces
    // toner vs serum) and only matches when the form token is also present.
    for (final rule in _rules) {
      if (_matchesName(nameHaystack, rule)) return rule.id;
    }

    // 3. keyword tokens in the INCI ingredient list.
    for (final rule in _rules) {
      if (_containsAny(ingredientHaystack, rule.keywords)) return rule.id;
    }

    // 4. brand-line tokens in the brand field.
    for (final rule in _rules) {
      if (_containsAny(brandHaystack, rule.brandLines)) return rule.id;
    }

    return unclassifiedId;
  }

  static bool _matchesName(String haystack, _SubCategoryRule rule) {
    if (!_containsAny(haystack, rule.keywords)) return false;
    if (rule.formKeywords.isEmpty) return true;
    return _containsAny(haystack, rule.formKeywords);
  }

  static bool _containsAny(String haystack, List<String> tokens) {
    if (haystack.isEmpty) return false;
    for (final t in tokens) {
      if (t.isNotEmpty && haystack.contains(t)) return true;
    }
    return false;
  }

  static List<String> _normalizeTokens(Object? raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final t in raw) {
      if (t is String) {
        final n = _normalize(t);
        if (n.isNotEmpty) out.add(n);
      }
    }
    return out;
  }

  /// Lower-cases and collapses whitespace so matching is case- and
  /// spacing-insensitive across Hebrew, Latin and INCI text.
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _SubCategoryRule {
  final String id;
  final List<String> keywords;
  final List<String> brandLines;

  /// When non-empty, the name must also contain one of these tokens for a name
  /// match — disambiguates sibling sub-categories that share a keyword (e.g.
  /// galactomyces toner vs serum).
  final List<String> formKeywords;

  const _SubCategoryRule({
    required this.id,
    required this.keywords,
    required this.brandLines,
    required this.formKeywords,
  });
}
