import '../entities/master_product.dart';
import '../entities/category.dart';
import '../entities/incompatibility_rule.dart';
import '../entities/master_list_manifest.dart';

class MasterContent {
  final List<MasterProduct> products;
  final List<Category> categories;
  final List<IncompatibilityRule> rules;
  final MasterListManifest manifest;

  const MasterContent({
    required this.products,
    required this.categories,
    required this.rules,
    required this.manifest,
  });

  @override
  bool operator ==(Object other) =>
      other is MasterContent &&
      manifest == other.manifest &&
      _listEqual(products, other.products) &&
      _listEqual(categories, other.categories) &&
      _listEqual(rules, other.rules);

  @override
  int get hashCode => Object.hash(
        manifest,
        Object.hashAll(products),
        Object.hashAll(categories),
        Object.hashAll(rules),
      );

  static bool _listEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

abstract class MasterContentRepository {
  Future<MasterContent> load();
}
