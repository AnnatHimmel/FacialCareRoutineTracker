import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/sub_category.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/services/category_helpers.dart';

// ── Shared fixture ─────────────────────────────────────────────────────────────

const _manifest = MasterListManifest(
  contentVersion: '1.0.0',
  appVersion: '1.0.0',
  changelog: [],
);

/// Full category list covering every keyword the helper must recognise.
const _allCategories = [
  Category(id: 'cat-cleanser', name: 'ניקוי', order: 1),
  Category(id: 'cat-exfoliate', name: 'אקספוליאציה', order: 2),
  Category(id: 'cat-toner', name: 'טונר', order: 4),
  Category(id: 'cat-retinoid', name: 'רטינואיד', order: 5),
  Category(id: 'cat-serum', name: 'סרום', order: 6),
  Category(id: 'cat-moisturizer', name: 'לחות', order: 7),
  Category(id: 'cat-oil', name: 'שמן', order: 8),
  Category(id: 'cat-spf', name: 'הגנה', order: 9),
];

/// Subcategories spread across two categories, deliberately out-of-order
/// so the sort-by-order contract is testable.
const _subcategories = [
  SubCategory(
    id: 'sub-moist-b',
    name: 'לחות ב',
    categoryId: 'cat-moisturizer',
    order: 2,
  ),
  SubCategory(
    id: 'sub-moist-a',
    name: 'לחות א',
    categoryId: 'cat-moisturizer',
    order: 1,
  ),
  SubCategory(
    id: 'sub-spf-a',
    name: 'הגנה א',
    categoryId: 'cat-spf',
    order: 1,
  ),
];

MasterContent _buildContent({
  List<Category> categories = _allCategories,
  List<SubCategory> subcategories = _subcategories,
}) =>
    MasterContent(
      products: [],
      categories: categories,
      subcategories: subcategories,
      rules: [],
      manifest: _manifest,
    );

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  // ── subCategoriesForCategory ──────────────────────────────────────────────

  group('subCategoriesForCategory', () {
    test(
        'should_return_only_matching_subcategories_when_categoryId_has_matches',
        () {
      /**
       * Given: MasterContent with subcategories for cat-moisturizer and cat-spf.
       * When: categoryId = 'cat-moisturizer'.
       * Then: Returns only the two cat-moisturizer subcategories, nothing else.
       */
      // Arrange
      final content = _buildContent();

      // Act
      final result = subCategoriesForCategory(content, 'cat-moisturizer');

      // Assert
      expect(result.length, 2);
      expect(result.every((s) => s.categoryId == 'cat-moisturizer'), isTrue);
    });

    test(
        'should_return_subcategories_sorted_by_order_ascending_when_stored_out_of_order',
        () {
      /**
       * Given: The two cat-moisturizer subcategories are stored order=2 first, order=1 second.
       * When: subCategoriesForCategory is called.
       * Then: Result list is [sub-moist-a (order=1), sub-moist-b (order=2)].
       */
      // Arrange
      final content = _buildContent();

      // Act
      final result = subCategoriesForCategory(content, 'cat-moisturizer');

      // Assert
      expect(result[0].id, 'sub-moist-a');
      expect(result[1].id, 'sub-moist-b');
    });

    test(
        'should_return_empty_list_when_categoryId_has_no_matching_subcategories',
        () {
      /**
       * Given: No subcategories exist for cat-retinoid in the fixture.
       * When: categoryId = 'cat-retinoid'.
       * Then: Returns empty list.
       */
      // Arrange
      final content = _buildContent();

      // Act
      final result = subCategoriesForCategory(content, 'cat-retinoid');

      // Assert
      expect(result, isEmpty);
    });

    test('should_return_empty_list_when_categoryId_is_empty_string', () {
      /**
       * Given: Any MasterContent.
       * When: categoryId = ''.
       * Then: Returns empty list (guard against blank input).
       */
      // Arrange
      final content = _buildContent();

      // Act
      final result = subCategoriesForCategory(content, '');

      // Assert
      expect(result, isEmpty);
    });

    test('should_return_empty_list_when_categoryId_is_completely_unknown', () {
      /**
       * Given: Any MasterContent.
       * When: categoryId = 'cat-does-not-exist'.
       * Then: Returns empty list.
       */
      // Arrange
      final content = _buildContent();

      // Act
      final result = subCategoriesForCategory(content, 'cat-does-not-exist');

      // Assert
      expect(result, isEmpty);
    });
  });

  // ── categoryIdFromHint ────────────────────────────────────────────────────

  group('categoryIdFromHint', () {
    late MasterContent fullContent;

    setUp(() {
      fullContent = _buildContent();
    });

    // Null / empty guards
    test('should_return_null_when_hint_is_null', () {
      /**
       * Given: hint is null.
       * When: categoryIdFromHint is called.
       * Then: Returns null.
       */
      expect(categoryIdFromHint(null, fullContent), isNull);
    });

    test('should_return_null_when_hint_is_empty_string', () {
      /**
       * Given: hint is ''.
       * When: categoryIdFromHint is called.
       * Then: Returns null.
       */
      expect(categoryIdFromHint('', fullContent), isNull);
    });

    test('should_return_null_when_hint_is_unrelated_text', () {
      /**
       * Given: hint = 'chocolate bar' — no skincare keyword.
       * When: categoryIdFromHint is called.
       * Then: Returns null (prefer null over a wrong guess).
       */
      expect(categoryIdFromHint('chocolate bar', fullContent), isNull);
    });

    // SPF / sunscreen
    test('should_return_cat_spf_when_hint_contains_sunscreen', () {
      expect(categoryIdFromHint('sunscreen SPF50', fullContent), 'cat-spf');
    });

    test('should_return_cat_spf_when_hint_is_spf', () {
      expect(categoryIdFromHint('spf', fullContent), 'cat-spf');
    });

    test('should_return_cat_spf_when_hint_is_OBF_sunscreens_tag', () {
      // OpenBeautyFacts tag format
      expect(
        categoryIdFromHint('en:sunscreens', fullContent),
        'cat-spf',
      );
    });

    // Moisturizer
    test('should_return_cat_moisturizer_when_hint_contains_moisturizer', () {
      expect(
        categoryIdFromHint('Face moisturizer', fullContent),
        'cat-moisturizer',
      );
    });

    test('should_return_cat_moisturizer_when_hint_contains_cream', () {
      expect(
        categoryIdFromHint('day cream', fullContent),
        'cat-moisturizer',
      );
    });

    // Serum
    test('should_return_cat_serum_when_hint_contains_serum', () {
      expect(categoryIdFromHint('Vitamin C Serum', fullContent), 'cat-serum');
    });

    // Cleanser (merged category)
    test('should_return_cat_cleanser_when_hint_contains_cleanser', () {
      expect(
        categoryIdFromHint('gentle cleanser', fullContent),
        'cat-cleanser',
      );
    });

    test('should_return_cat_cleanser_when_hint_contains_face_wash', () {
      expect(
        categoryIdFromHint('face wash gel', fullContent),
        'cat-cleanser',
      );
    });

    test('should_return_cat_cleanser_when_hint_contains_micellar', () {
      expect(
        categoryIdFromHint('micellar water', fullContent),
        'cat-cleanser',
      );
    });

    test('should_return_cat_cleanser_when_hint_contains_balm', () {
      expect(
        categoryIdFromHint('cleansing balm', fullContent),
        'cat-cleanser',
      );
    });

    test('should_return_cat_cleanser_when_hint_contains_cleansing_balm_oil', () {
      expect(
        categoryIdFromHint('cleansing balm oil', fullContent),
        'cat-cleanser',
      );
    });

    // Toner
    test('should_return_cat_toner_when_hint_contains_toner', () {
      expect(categoryIdFromHint('hydrating toner', fullContent), 'cat-toner');
    });

    // Retinoid
    test('should_return_cat_retinoid_when_hint_contains_retinol', () {
      expect(
        categoryIdFromHint('retinol 0.3%', fullContent),
        'cat-retinoid',
      );
    });

    test('should_return_cat_retinoid_when_hint_contains_retinoid', () {
      expect(
        categoryIdFromHint('retinoid treatment', fullContent),
        'cat-retinoid',
      );
    });

    // Oil
    test('should_return_cat_oil_when_hint_contains_oil', () {
      expect(categoryIdFromHint('facial oil', fullContent), 'cat-oil');
    });

    // Exfoliate
    test('should_return_cat_exfoliate_when_hint_contains_exfoliant', () {
      expect(
        categoryIdFromHint('chemical exfoliant', fullContent),
        'cat-exfoliate',
      );
    });

    test('should_return_cat_exfoliate_when_hint_contains_peeling', () {
      expect(
        categoryIdFromHint('peeling solution AHA', fullContent),
        'cat-exfoliate',
      );
    });

    // Case-insensitivity
    test('should_match_case_insensitively_for_uppercase_SERUM', () {
      expect(categoryIdFromHint('SERUM', fullContent), 'cat-serum');
    });

    // Existence check — matched keyword but category absent from content
    test(
        'should_return_null_when_keyword_matches_but_category_is_absent_from_content',
        () {
      /**
       * Given: A MasterContent whose categories list does NOT include cat-spf.
       * When: hint = 'sunscreen' (would otherwise map to cat-spf).
       * Then: Returns null because cat-spf doesn't exist in this content.
       */
      // Arrange: build content without the cat-spf category
      final contentMissingSpf = _buildContent(
        categories: _allCategories
            .where((c) => c.id != 'cat-spf')
            .toList(),
      );

      // Act
      final result = categoryIdFromHint('sunscreen', contentMissingSpf);

      // Assert
      expect(result, isNull);
    });

    test(
        'should_return_null_when_keyword_matches_but_moisturizer_category_absent_from_content',
        () {
      /**
       * Given: A MasterContent whose categories list does NOT include cat-moisturizer.
       * When: hint = 'moisturizer'.
       * Then: Returns null.
       */
      // Arrange
      final contentMissingMoisturizer = _buildContent(
        categories: _allCategories
            .where((c) => c.id != 'cat-moisturizer')
            .toList(),
      );

      // Act
      final result =
          categoryIdFromHint('moisturizer', contentMissingMoisturizer);

      // Assert
      expect(result, isNull);
    });
  });
}
