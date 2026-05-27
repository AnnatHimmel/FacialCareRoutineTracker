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
}

abstract class MasterContentRepository {
  Future<MasterContent> load();
}
