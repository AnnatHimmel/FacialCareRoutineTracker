import '../entities/category.dart';
import '../entities/master_product.dart';
import '../entities/sub_category.dart';
import '../enums/slot.dart';

class ProductSorter {
  /// Returns a comparator that sorts [MasterProduct]s by admin-defined order
  /// (PRD §15, two-tier): category.order (phase) first, then sub-category
  /// order within the phase, then the slot-specific product order, with the
  /// product id as a final stable tiebreak.
  ///
  /// [categoryOverrides] optionally remaps a productId → categoryId for
  /// sorting purposes only (does not change the product's stored categoryId).
  /// [subCategoryOverrides] mirrors that for sub-categories. A null/unknown
  /// sub-category sorts last within its category (sentinel 9999).
  static Comparator<MasterProduct> adminComparator({
    required List<Category> categories,
    required List<SubCategory> subcategories,
    required Slot slot,
    Map<String, String>? categoryOverrides,
    Map<String, String>? subCategoryOverrides,
  }) {
    final catOrderById = {for (final c in categories) c.id: c.order};
    final subOrderById = {for (final s in subcategories) s.id: s.order};

    String effectiveCatId(MasterProduct p) =>
        categoryOverrides?[p.id] ?? p.categoryId;

    String? effectiveSubId(MasterProduct p) =>
        subCategoryOverrides?[p.id] ?? p.subCategoryId;

    int subOrder(MasterProduct p) {
      final subId = subCategoryOverrides?[p.id] ?? p.subCategoryId;
      if (subId == null) return 9999;
      return subOrderById[subId] ?? 9999;
    }

    int slotOrder(MasterProduct p) =>
        (slot == Slot.morning ? p.morningConfig?.order : p.eveningConfig?.order) ??
        999;

    return (a, b) {
      final catA = catOrderById[effectiveCatId(a)] ?? 9999;
      final catB = catOrderById[effectiveCatId(b)] ?? 9999;
      if (catA != catB) return catA.compareTo(catB);

      // Apply the sub-category tier ONLY when BOTH products have a known
      // (non-sentinel) sub-category. If either is null/unknown (sentinel 9999),
      // skip this tier and fall through to the slot config.order tier so that
      // mixed/asymmetric Supabase data never inverts the admin-intended order.
      final subA = subOrder(a);
      final subB = subOrder(b);
      final bothKnown = subA != 9999 && subB != 9999;
      if (bothKnown && subA != subB) return subA.compareTo(subB);

      // Moisture weight rule: within cat-moisturizer and the same subcategory
      // grouping, a "lotion" sorts before a "cream" — lotions are lighter and
      // applied first. This takes precedence over the numeric slot order.
      // (Products in different known subcategories already returned above.)
      const moistureCategoryId = 'cat-moisturizer';
      if (effectiveCatId(a) == moistureCategoryId &&
          effectiveCatId(b) == moistureCategoryId &&
          effectiveSubId(a) == effectiveSubId(b)) {
        final wa = _moistureWeightRank(a.name);
        final wb = _moistureWeightRank(b.name);
        if (wa != null && wb != null && wa != wb) return wa.compareTo(wb);
      }

      final slotCmp = slotOrder(a).compareTo(slotOrder(b));
      if (slotCmp != 0) return slotCmp;

      return a.id.compareTo(b.id);
    };
  }

  /// Weight rank for the moisture lotion-before-cream rule.
  /// 0 = lotion (lighter, applied first), 1 = cream (heavier). Returns null
  /// when the name carries neither keyword (or ambiguously both), so the
  /// product keeps its existing slot order.
  static int? _moistureWeightRank(String name) {
    final lower = name.toLowerCase();
    final hasLotion = lower.contains('lotion');
    final hasCream = lower.contains('cream');
    if (hasLotion && !hasCream) return 0;
    if (hasCream && !hasLotion) return 1;
    return null;
  }
}
