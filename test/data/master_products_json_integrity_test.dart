import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> data;

  setUpAll(() {
    final file = File('assets/data/master_products.json');
    data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  group('master_products.json integrity', () {
    group('categories', () {
      test('every category name is a {"he","en"} map with non-empty strings',
          () {
        final categories = data['categories'] as List<dynamic>;
        expect(categories, isNotEmpty);
        for (final raw in categories) {
          final c = raw as Map<String, dynamic>;
          final id = c['id'];
          final name = c['name'];
          expect(name, isA<Map<String, dynamic>>(),
              reason: 'category $id: name must be a map');
          final he = (name as Map)['he'];
          final en = name['en'];
          expect(he, isA<String>(),
              reason: 'category $id: name.he must be a string');
          expect((he as String).trim(), isNotEmpty,
              reason: 'category $id: name.he must not be empty');
          expect(en, isA<String>(),
              reason: 'category $id: name.en must be a string');
          expect((en as String).trim(), isNotEmpty,
              reason: 'category $id: name.en must not be empty');
        }
      });
    });

    group('products', () {
      test('every product comment is a {"he","en"} map', () {
        final products = data['products'] as List<dynamic>;
        expect(products, isNotEmpty);
        for (final raw in products) {
          final p = raw as Map<String, dynamic>;
          final id = p['id'];
          final comment = p['comment'];
          expect(comment, isA<Map<String, dynamic>>(),
              reason: 'product $id: comment must be a {"he","en"} map');
        }
      });

      test('every product comment.he is a non-empty string', () {
        final products = data['products'] as List<dynamic>;
        for (final raw in products) {
          final p = raw as Map<String, dynamic>;
          final id = p['id'];
          final comment = p['comment'] as Map;
          final he = comment['he'];
          expect(he, isA<String>(),
              reason: 'product $id: comment.he must be a string');
          expect((he as String).trim(), isNotEmpty,
              reason: 'product $id: comment.he must not be empty');
        }
      });

      test('every product comment.en is a non-empty string', () {
        final products = data['products'] as List<dynamic>;
        for (final raw in products) {
          final p = raw as Map<String, dynamic>;
          final id = p['id'];
          final comment = p['comment'] as Map;
          final en = comment['en'];
          expect(en, isA<String>(),
              reason: 'product $id: comment.en must be a string');
          expect((en as String).trim(), isNotEmpty,
              reason: 'product $id: comment.en must not be empty');
        }
      });

      test('no field anywhere contains the literal "[object Object]"', () {
        final raw = File('assets/data/master_products.json').readAsStringSync();
        expect(raw, isNot(contains('[object Object]')),
            reason:
                'JSON contains "[object Object]" — a JS serialization error');
      });

      test('every product has required fields with correct types', () {
        final products = data['products'] as List<dynamic>;
        for (final raw in products) {
          final p = raw as Map<String, dynamic>;
          final id = p['id'];
          expect(p['id'], isA<String>(),
              reason: 'product $id: id must be a string');
          expect(p['name'], isA<String>(),
              reason: 'product $id: name must be a string');
          expect(p['categoryId'], isA<String>(),
              reason: 'product $id: categoryId must be a string');
          expect(p['isDeprecated'], isA<bool>(),
              reason: 'product $id: isDeprecated must be a bool');
          expect(p['addedInVersion'], isA<String>(),
              reason: 'product $id: addedInVersion must be a string');
          expect(p.containsKey('morningConfig'), isTrue,
              reason: 'product $id: morningConfig key must exist');
          expect(p.containsKey('eveningConfig'), isTrue,
              reason: 'product $id: eveningConfig key must exist');
          final morning = p['morningConfig'];
          final evening = p['eveningConfig'];
          expect(morning == null || morning is Map, isTrue,
              reason: 'product $id: morningConfig must be null or a map');
          expect(evening == null || evening is Map, isTrue,
              reason: 'product $id: eveningConfig must be null or a map');
          expect(morning != null || evening != null, isTrue,
              reason:
                  'product $id: must have at least one of morningConfig or eveningConfig');
        }
      });
    });
  });
}
