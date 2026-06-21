import '../entities/sub_category.dart';
import '../repositories/master_content_repository.dart';

/// Returns all subcategories belonging to [categoryId], sorted by [SubCategory.order]
/// ascending. Returns an empty list when [categoryId] is empty or has no matches.
List<SubCategory> subCategoriesForCategory(
    MasterContent content, String categoryId) {
  if (categoryId.isEmpty) return const [];
  final matches = content.subcategories
      .where((s) => s.categoryId == categoryId)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  return matches;
}

// cat-cleanser comes before cat-oil so that "cleansing oil" / "balm oil" phrases
// match the cleanser category rather than the oil category.
const List<(String categoryId, List<String> keywords)> _keywordMap = [
  ('cat-spf', ['spf', 'sunscreen', 'sun screen', 'sunblock']),
  ('cat-exfoliate', ['exfoliant', 'exfoliat', 'peeling', 'peel', 'aha', 'bha']),
  ('cat-retinoid', ['retinol', 'retinoid', 'retinal', 'tretinoin']),
  ('cat-serum', ['serum']),
  ('cat-toner', ['toner', 'tonic']),
  ('cat-cleanser', ['cleanser', 'face wash', 'facewash', 'cleansing', 'wash', 'micellar', 'foam', 'balm']),
  ('cat-oil', ['oil']),
  ('cat-moisturizer', ['moisturizer', 'moisturiser', 'cream', 'lotion', 'hydrating gel']),
];

/// Maps a free-text [hint] to a category ID using a keyword lookup.
///
/// Returns null if:
/// - [hint] is null or blank after trim.
/// - No keyword matches.
/// - The matched category ID is not present in [content].
String? categoryIdFromHint(String? hint, MasterContent content) {
  if (hint == null || hint.trim().isEmpty) return null;
  final lower = hint.toLowerCase();

  for (final (categoryId, keywords) in _keywordMap) {
    for (final kw in keywords) {
      if (lower.contains(kw)) {
        if (content.categories.any((c) => c.id == categoryId)) {
          return categoryId;
        }
        return null;
      }
    }
  }
  return null;
}
