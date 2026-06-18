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

      final subA = subOrder(a);
      final subB = subOrder(b);
      if (subA != subB) return subA.compareTo(subB);

      final slotCmp = slotOrder(a).compareTo(slotOrder(b));
      if (slotCmp != 0) return slotCmp;

      return a.id.compareTo(b.id);
    };
  }
}
