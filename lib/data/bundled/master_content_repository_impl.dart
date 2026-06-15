import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/master_list_manifest.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../cache/master_content_serializer.dart';

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
        .map((c) => MasterContentSerializer.parseCategory(c as Map<String, dynamic>))
        .toList();

    final products = (productsData['products'] as List<dynamic>)
        .map((p) => MasterContentSerializer.parseProduct(p as Map<String, dynamic>))
        .toList();

    final rules = (rulesData['rules'] as List<dynamic>)
        .map((r) => MasterContentSerializer.parseRule(r as Map<String, dynamic>))
        .toList();

    final manifest = MasterListManifest(
      contentVersion: changelogData['contentVersion'] as String,
      appVersion: changelogData['appVersion'] as String,
      changelog: (changelogData['changelog'] as List<dynamic>)
          .map((e) => MasterContentSerializer.parseChangelog(e as Map<String, dynamic>))
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
}
