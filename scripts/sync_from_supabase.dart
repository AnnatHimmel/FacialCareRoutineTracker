#!/usr/bin/env dart
// scripts/sync_from_supabase.dart
//
// Fetches master content from Supabase and merges any new items into the
// local bundled JSON files (assets/data/master_products.json and
// assets/data/incompatibility_rules.json).
//
// Merge rules:
//   - Supabase wins for any item that exists in both (same ID).
//   - Items present only in local JSON are appended (guards against Supabase lag).
//   - contentVersion in master_products.json is updated if Supabase is newer.
//
// Usage (from project root):
//   dart scripts/sync_from_supabase.dart
//
// Required environment variables:
//   SUPABASE_URL      e.g. https://xyzxyz.supabase.co
//   SUPABASE_ANON_KEY

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final anonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty) {
    stderr.writeln('Error: SUPABASE_URL environment variable is not set.');
    exit(1);
  }
  if (anonKey.isEmpty) {
    stderr.writeln('Error: SUPABASE_ANON_KEY environment variable is not set.');
    exit(1);
  }

  // 1. Fetch from Supabase
  stdout.writeln('Fetching master content from Supabase...');
  final Map<String, dynamic> remote;
  try {
    remote = await _fetchFromSupabase(supabaseUrl, anonKey);
  } catch (e) {
    stderr.writeln('Error fetching from Supabase: $e');
    exit(1);
  }

  final remoteProducts = remote['products'] as List<dynamic>? ?? [];
  final remoteCategories = remote['categories'] as List<dynamic>? ?? [];
  final remoteSubcategories = remote['subcategories'] as List<dynamic>? ?? [];
  final remoteRules = remote['rules'] as List<dynamic>? ?? [];
  final remoteVersion = remote['contentVersion'] as String? ?? '0.0.0';

  stdout.writeln(
    '  → Supabase: ${remoteProducts.length} products, '
    '${remoteCategories.length} categories, '
    '${remoteSubcategories.length} subcategories, '
    '${remoteRules.length} rules  (v$remoteVersion)',
  );

  // 2. Read local JSON files
  final productsFile = File('assets/data/master_products.json');
  final rulesFile = File('assets/data/incompatibility_rules.json');

  if (!productsFile.existsSync()) {
    stderr.writeln('Error: ${productsFile.path} not found. Run from project root.');
    exit(1);
  }
  if (!rulesFile.existsSync()) {
    stderr.writeln('Error: ${rulesFile.path} not found. Run from project root.');
    exit(1);
  }

  final localProducts =
      jsonDecode(await productsFile.readAsString()) as Map<String, dynamic>;
  final localRules =
      jsonDecode(await rulesFile.readAsString()) as Map<String, dynamic>;

  final localProductsList = localProducts['products'] as List<dynamic>? ?? [];
  final localCategoriesList = localProducts['categories'] as List<dynamic>? ?? [];
  final localSubcategoriesList =
      localProducts['subcategories'] as List<dynamic>? ?? [];
  final localRulesList = localRules['rules'] as List<dynamic>? ?? [];
  final localVersion = localProducts['contentVersion'] as String? ?? '0.0.0';

  stdout.writeln(
    '  → Local:    ${localProductsList.length} products, '
    '${localCategoriesList.length} categories, '
    '${localSubcategoriesList.length} subcategories, '
    '${localRulesList.length} rules  (v$localVersion)',
  );
  stdout.writeln('');

  // 3. Merge each collection (Supabase first, local-only items appended)
  final mergedCategories = _mergeById(
    remote: remoteCategories,
    local: localCategoriesList,
    label: 'categories',
  );
  final mergedSubcategories = _mergeById(
    remote: remoteSubcategories,
    local: localSubcategoriesList,
    label: 'subcategories',
  );
  final mergedProducts = _mergeById(
    remote: remoteProducts,
    local: localProductsList,
    label: 'products',
  );
  final mergedRules = _mergeById(
    remote: remoteRules,
    local: localRulesList,
    label: 'rules',
  );

  // 4. Write master_products.json if anything changed
  final useRemoteVersion = _compareVersions(remoteVersion, localVersion) > 0;
  final productsFileChanged = useRemoteVersion ||
      mergedCategories.length != localCategoriesList.length ||
      mergedSubcategories.length != localSubcategoriesList.length ||
      mergedProducts.length != localProductsList.length ||
      _anyItemChanged(mergedProducts, localProductsList) ||
      _anyItemChanged(mergedCategories, localCategoriesList) ||
      _anyItemChanged(mergedSubcategories, localSubcategoriesList);

  if (productsFileChanged) {
    final updated = {
      ...localProducts,
      if (useRemoteVersion) 'contentVersion': remoteVersion,
      'categories': mergedCategories,
      'subcategories': mergedSubcategories,
      'products': mergedProducts,
    };
    await productsFile
        .writeAsString(const JsonEncoder.withIndent('  ').convert(updated));
    stdout.writeln('✓ Updated assets/data/master_products.json');
    if (useRemoteVersion) {
      stdout.writeln(
          '  contentVersion: $localVersion → $remoteVersion');
    }
  } else {
    stdout.writeln('· assets/data/master_products.json is already up to date.');
  }

  // 5. Write incompatibility_rules.json if anything changed
  final rulesFileChanged = mergedRules.length != localRulesList.length ||
      _anyItemChanged(mergedRules, localRulesList);

  if (rulesFileChanged) {
    final updated = {
      ...localRules,
      'rules': mergedRules,
    };
    await rulesFile
        .writeAsString(const JsonEncoder.withIndent('  ').convert(updated));
    stdout.writeln('✓ Updated assets/data/incompatibility_rules.json');
  } else {
    stdout
        .writeln('· assets/data/incompatibility_rules.json is already up to date.');
  }

  stdout.writeln('');
  stdout.writeln('Done.');
}

// ---------------------------------------------------------------------------
// Supabase fetch
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _fetchFromSupabase(
    String baseUrl, String anonKey) async {
  final uri = Uri.parse('$baseUrl/rest/v1/rpc/get_master_content');
  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    request.headers
      ..set('apikey', anonKey)
      ..set('Authorization', 'Bearer $anonKey')
      ..set('Content-Type', 'application/json');
    request.write('{}');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: $body');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// Merge helpers
// ---------------------------------------------------------------------------

/// Merges [remote] and [local] lists of JSON objects keyed by "id".
/// Remote items take precedence. Local-only items are appended at the end.
List<dynamic> _mergeById({
  required List<dynamic> remote,
  required List<dynamic> local,
  required String label,
}) {
  final localIds = <String>{};
  for (final item in local) {
    localIds.add((item as Map<String, dynamic>)['id'] as String);
  }

  final remoteIds = <String>{};
  for (final item in remote) {
    remoteIds.add((item as Map<String, dynamic>)['id'] as String);
  }

  final addedFromRemote = remoteIds.difference(localIds);
  final localOnlyIds = localIds.difference(remoteIds);

  if (addedFromRemote.isNotEmpty) {
    stdout.writeln(
        '  + $label: ${addedFromRemote.length} new item(s) from Supabase: $addedFromRemote');
  }
  if (localOnlyIds.isNotEmpty) {
    stdout.writeln(
        '  ! $label: ${localOnlyIds.length} item(s) only in local JSON — preserved: $localOnlyIds');
  }

  // Remote items first (Supabase wins), then local-only items
  final merged = [...remote];
  for (final item in local) {
    final m = item as Map<String, dynamic>;
    if (!remoteIds.contains(m['id'] as String)) {
      merged.add(m);
    }
  }
  return merged;
}

/// Returns true if any item in [updated] differs from the corresponding item
/// (by id) in [original] — catches field updates to existing items.
bool _anyItemChanged(List<dynamic> updated, List<dynamic> original) {
  final originalById = <String, String>{};
  for (final item in original) {
    final m = item as Map<String, dynamic>;
    originalById[m['id'] as String] = jsonEncode(m);
  }
  for (final item in updated) {
    final m = item as Map<String, dynamic>;
    final id = m['id'] as String;
    final orig = originalById[id];
    if (orig != null && orig != jsonEncode(m)) return true;
  }
  return false;
}

/// Compares two "major.minor.patch" version strings.
/// Returns positive if [a] > [b], negative if [a] < [b], 0 if equal.
int _compareVersions(String a, String b) {
  final ap = a.split('.');
  final bp = b.split('.');
  for (var i = 0; i < 3; i++) {
    final av = int.tryParse(ap.elementAtOrNull(i) ?? '') ?? 0;
    final bv = int.tryParse(bp.elementAtOrNull(i) ?? '') ?? 0;
    if (av != bv) return av - bv;
  }
  return 0;
}
