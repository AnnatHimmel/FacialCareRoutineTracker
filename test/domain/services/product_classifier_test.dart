import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/services/product_classifier.dart';

void main() {
  // Drive the classifier from the bundled master data, so the test exercises
  // the same keyword/brand-line map that ships with the app (data-driven).
  late ProductClassifier classifier;

  setUpAll(() {
    final file = File('assets/data/master_products.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final subs = (data['subcategories'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    classifier = ProductClassifier.fromSubcategories(subs);
  });

  group('ProductClassifier', () {
    group('name (hero active) match', () {
      test('should_classify_The_Ordinary_Niacinamide_10pct_as_sub_niacinamide',
          () {
        final result =
            classifier.classify(name: 'The Ordinary Niacinamide 10% + Zinc 1%');
        expect(result, 'sub-niacinamide');
      });

      test('should_classify_vitamin_c_serum_by_name_as_sub_vitamin_c', () {
        final result = classifier.classify(name: 'Vitamin C Suspension 23%');
        expect(result, 'sub-vitamin-c');
      });

      test('should_classify_salicylic_acid_by_name_as_sub_bha_salicylic', () {
        final result = classifier.classify(name: 'Salicylic Acid 2% Solution');
        expect(result, 'sub-bha-salicylic');
      });
    });

    group('INCI ingredient match', () {
      test('should_classify_by_niacinamide_ingredient_when_name_is_generic',
          () {
        final result = classifier.classify(
          name: 'Brightening Serum',
          ingredients: const ['Aqua', 'Niacinamide', 'Glycerin'],
        );
        expect(result, 'sub-niacinamide');
      });

      test('should_classify_by_retinol_ingredient_as_sub_retinoid', () {
        final result = classifier.classify(
          name: 'Night Renewal Treatment',
          ingredients: const ['Aqua', 'Retinol', 'Squalane'],
        );
        expect(result, 'sub-retinoid');
      });

      test('should_prefer_name_token_over_ingredient', () {
        // Name says vitamin C; ingredient list also mentions niacinamide.
        // Name (hero active) wins.
        final result = classifier.classify(
          name: 'Vitamin C Brightening Serum',
          ingredients: const ['Aqua', 'Niacinamide', 'Ascorbic Acid'],
        );
        expect(result, 'sub-vitamin-c');
      });
    });

    group('brand-line match', () {
      test(
          'should_classify_numbuzin_No_9_as_sub_nad_not_sub_niacinamide',
          () {
        // numbuzin No.9 is a NAD+ booster; it contains niacinamide as an
        // ingredient but the hero/brand-line is NAD+, so it must NOT fall to
        // sub-niacinamide.
        final result = classifier.classify(
          name: 'numbuzin No.9 Hyaluronic Acid Serum',
          ingredients: const ['Aqua', 'Niacinamide', 'Hyaluronic Acid'],
          brand: 'numbuzin',
        );
        expect(result, 'sub-nad');
      });
    });

    group('galactomyces toner vs serum (form/name)', () {
      test('should_classify_galactomyces_toner_as_sub_galactomyces_toner', () {
        final result = classifier.classify(
          name: 'Galactomyces 95% Tone Balancing Essence Toner',
          form: 'toner',
        );
        expect(result, 'sub-galactomyces-toner');
      });

      test('should_classify_galactomyces_serum_as_sub_galactomyces_serum', () {
        final result = classifier.classify(
          name: 'Galactomyces Ferment Filtrate Serum',
          form: 'serum',
        );
        expect(result, 'sub-galactomyces-serum');
      });
    });

    group('no confident match', () {
      test('should_return_sub_unclassified_for_unknown_product', () {
        final result =
            classifier.classify(name: 'Mystery Goo 3000', ingredients: const [
          'Aqua',
          'Glycerin',
          'Phenoxyethanol',
        ]);
        expect(result, 'sub-unclassified');
      });

      test('should_return_sub_unclassified_for_empty_input', () {
        final result = classifier.classify(name: '');
        expect(result, 'sub-unclassified');
      });
    });

    test('should_never_throw_on_odd_input', () {
      expect(
        () => classifier.classify(
          name: '!!! @#\$ 12345',
          ingredients: const ['', '   ', '???'],
          brand: '',
          form: '',
        ),
        returnsNormally,
      );
    });
  });
}
