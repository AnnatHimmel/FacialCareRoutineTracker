import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/features/onboarding/onboarding_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);

  @override
  Future<MasterContent> load() async => content;
}

// ── Test data ─────────────────────────────────────────────────────────────────

MasterProduct _product(String id, String name, String categoryId) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: categoryId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterContent _masterWith(List<MasterProduct> products, List<Category> cats) =>
    MasterContent(
      products: products,
      categories: cats,
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

Widget _wrap({
  required MasterContent master,
  required VoidCallback onFinish,
}) {
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: OnboardingScreen(onFinish: onFinish),
      ),
    ),
  );
}

void main() {
  const cat1 = Category(id: 'cat1', name: 'לחות');
  const cat2 = Category(id: 'cat2', name: 'ניקוי');

  group('OnboardingScreen', () {
    testWidgets('Step 1 displays welcome headline "ברוכה הבאה"',
        (tester) async {
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
        ],
        [cat1, cat2],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      expect(find.text('ברוכה הבאה'), findsOneWidget);
    });

    testWidgets('Step 1 displays "בואי נתחיל" button',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      expect(find.text('בואי נתחיל'), findsOneWidget);
    });

    testWidgets('Step 1 displays "דלגי" skip link',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      expect(find.text('דלגי'), findsOneWidget);
    });

    testWidgets('Tapping "בואי נתחיל" advances to Step 2',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.text('ספרי לנו עלייך'), findsOneWidget);
    });

    testWidgets('Step 2 displays "ספרי לנו עלייך" headline',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.text('ספרי לנו עלייך'), findsOneWidget);
    });

    testWidgets('Step 2 displays name text field',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Step 2 displays gender toggle buttons "נקבה" and "זכר"',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.text('נקבה'), findsOneWidget);
      expect(find.text('זכר'), findsOneWidget);
    });

    testWidgets('Step 2: "המשך" button is disabled when name is empty',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשך',
      );

      expect(continueButton, findsOneWidget);

      // Button should be disabled (no name entered, no gender selected)
      final ElevatedButton button =
          tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'Step 2: "המשך" button is disabled when name is non-empty but gender not selected',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשך',
      );

      // Button should still be disabled (gender not selected)
      final ElevatedButton button =
          tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'Step 2: "המשך" button is disabled when gender selected but name is empty',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Select gender
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשך',
      );

      // Button should still be disabled (name is empty)
      final ElevatedButton button =
          tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'Step 2: "המשך" button is enabled when name is non-empty AND gender is selected',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();

      // Select gender
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשך',
      );

      // Button should now be enabled
      final ElevatedButton button =
          tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Step 2: "חזרה" button returns to Step 1',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.text('חזרה'));
      await tester.pumpAndSettle();

      expect(find.text('ברוכה הבאה'), findsOneWidget);
    });

    testWidgets('Tapping "דלגי" in Step 1 calls onFinish',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );

      bool onFinishCalled = false;
      final onFinishCallback = () {
        onFinishCalled = true;
      };

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      await tester.tap(find.text('דלגי'));
      await tester.pumpAndSettle();

      expect(onFinishCalled, isTrue);
    });

    testWidgets('Step 3 displays "המוצרים שלך" headline after advancing from Step 2',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Enter name and select gender
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      // Advance to step 3
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      expect(find.text('המוצרים שלך'), findsOneWidget);
    });

    testWidgets('Step 3 displays product grid',
        (tester) async {
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
          _product('p3', 'סרום', 'cat1'),
        ],
        [cat1, cat2],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Enter name and select gender
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      // Advance to step 3
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsOneWidget);
      expect(find.text('סרום'), findsOneWidget);
    });

    testWidgets('Step 3 displays "סיום והתחלה" finish button',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      final onFinishCallback = () {};

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Enter name and select gender
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      // Advance to step 3
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      expect(find.text('סיום והתחלה'), findsOneWidget);
    });

    testWidgets('Tapping "סיום והתחלה" in Step 3 calls onFinish',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );

      bool onFinishCalled = false;
      final onFinishCallback = () {
        onFinishCalled = true;
      };

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Advance to step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      // Enter name and select gender
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      // Advance to step 3
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      // Finish
      await tester.tap(find.text('סיום והתחלה'));
      await tester.pumpAndSettle();

      expect(onFinishCalled, isTrue);
    });

    testWidgets('Complete onboarding flow: Step 1 → Step 2 → Step 3 → onFinish',
        (tester) async {
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
        ],
        [cat1, cat2],
      );

      bool onFinishCalled = false;
      final onFinishCallback = () {
        onFinishCalled = true;
      };

      await tester.pumpWidget(_wrap(master: master, onFinish: onFinishCallback));
      await tester.pumpAndSettle();

      // Step 1: verify welcome
      expect(find.text('ברוכה הבאה'), findsOneWidget);

      // Step 1 → Step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();
      expect(find.text('ספרי לנו עלייך'), findsOneWidget);

      // Step 2: enter name and select gender
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      // Step 2 → Step 3
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();
      expect(find.text('המוצרים שלך'), findsOneWidget);

      // Step 3: finish
      await tester.tap(find.text('סיום והתחלה'));
      await tester.pumpAndSettle();

      expect(onFinishCalled, isTrue);
    });
  });
}
