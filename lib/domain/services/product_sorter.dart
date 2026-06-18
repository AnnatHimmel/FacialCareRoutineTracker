import '../entities/category.dart';
import '../entities/master_product.dart';
import '../enums/slot.dart';

class ProductSorter {
  /// Returns a comparator that sorts [MasterProduct]s by admin-defined order:
  /// category.order first, then the slot-specific product order.
  ///
  /// [categoryOverrides] optionally remaps a productId → categoryId for
  /// sorting purposes only (does not change the product's stored categoryId).
  static Comparator<MasterProduct> adminComparator({
    required List<Category> categories,
    required Slot slot,
    Map<String, String>? categoryOverrides,
  }) {
    final orderById = {for (final c in categories) c.id: c.order};

    String effectiveCatId(MasterProduct p) =>
        categoryOverrides?[p.id] ?? p.categoryId;

    int slotOrder(MasterProduct p) =>
        (slot == Slot.morning ? p.morningConfig?.order : p.eveningConfig?.order) ??
        999;

    return (a, b) {
      final catA = orderById[effectiveCatId(a)] ?? 9999;
      final catB = orderById[effectiveCatId(b)] ?? 9999;
      if (catA != catB) return catA.compareTo(catB);
      return slotOrder(a).compareTo(slotOrder(b));
    };
  }
}
