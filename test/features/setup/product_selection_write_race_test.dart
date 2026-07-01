// RED test: verifies that the "Next" CTA waits for in-flight selection writes
// before invoking onDone. Without the fix, onDone fires while the write is
// still gated by the Completer → the write/read race bug.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/features/setup/product_selection_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fake MCR ──────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

// ── Gated UDR — upsertSelection blocks until the Completer is completed ───────
//
// This models write latency. The stream immediately reflects the new selection
// (matching how an in-memory DB works) but the upsertSelection Future itself
// is gated — it will not complete until completeAll() is called.
// This lets us verify that the CTA waits for the Future before calling onDone.

class _GatedUDR implements UserDataRepository {
  // Selected products — updated immediately when upsertSelection is called,
  // before the gated future resolves, so the UI re-enables correctly.
  final Map<String, ProductSelection> _selections = {};
  final _selMorningCtrl = StreamController<List<ProductSelection>>.broadcast();
  final _selEveningCtrl = StreamController<List<ProductSelection>>.broadcast();

  // Each call to upsertSelection creates a new Completer and enqueues it.
  final List<Completer<void>> _pending = [];

  int get pendingCount => _pending.length;

  // Ungate all pending writes at once.
  void completeAll() {
    for (final c in List.of(_pending)) {
      c.complete();
    }
    _pending.clear();
  }

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) {
    final ctrl = slot == Slot.morning ? _selMorningCtrl : _selEveningCtrl;
    // Return a broadcast stream that re-maps to the current in-memory selection
    // on every event. The stream starts empty; calling _selMorningCtrl.add([])
    // or _selEveningCtrl.add([]) in upsertSelection triggers re-evaluation.
    return ctrl.stream.map((_) => _selections.values
        .where((s) => s.slot == slot && s.isSelected)
        .toList());
  }

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<void> upsertSelection(ProductSelection s) {
    // Update the in-memory map immediately so the stream reflects the new state.
    _selections[s.id] = s;
    // Notify stream listeners.
    _selMorningCtrl.add([]);
    _selEveningCtrl.add([]);

    // But the Future itself is gated — won't complete until completeAll().
    final c = Completer<void>();
    _pending.add(c);
    return c.future;
  }

  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() =>
      Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() =>
      Stream.value([]);
  @override Future<void> upsertCollectionItem(CollectionItem item) async {}
  @override Future<void> deleteCollectionItem(String id) async {}
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      Stream.value(null);
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      Stream.value([]);
  @override Future<void> upsertSchedule(WeekdaySchedule s) async {}
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) =>
      Stream.value(null);
  @override Future<void> upsertOrderOverride(OrderOverride o) async {}
  @override Future<void> deleteOrderOverride(Slot s) async {}
  @override Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      Stream.value([]);
  @override Future<OrderOverride?> getEffectiveOrderOverride(
          Slot slot, int weekday) async =>
      null;
  @override Future<void> deletePerDayOrderOverride(
          Slot slot, int weekday) async {}
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) =>
      Stream.value(null);
  @override Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) async {}
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      Stream.value([]);
  @override Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([]);
  @override Stream<SkinLogEntry?> watchSkinLog(String d) =>
      Stream.value(null);
  @override Future<void> upsertSkinLog(SkinLogEntry e) async {}
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => Stream.value([]);
  @override Future<UserDataExport> exportAllData() =>
      throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) async {}
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() =>
      Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Helpers ────────────────────────────────────────────────────────────────────

MasterProduct _amProduct(String id, String name, String catId) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterContent _masterWith(List<MasterProduct> products, List<Category> cats) =>
    MasterContent(
      products: products,
      categories: cats,
      rules: <IncompatibilityRule>[],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

/// Wraps [ProductSelectionScreen] in a minimal router + provider scope.
/// [onDone] is the spy we assert against.
Widget _wrap({
  required MasterContent master,
  required _GatedUDR udr,
  required VoidCallback onDone,
}) {
  final router = GoRouter(
    initialLocation: '/setup/selection',
    routes: [
      GoRoute(
        path: '/setup/selection',
        builder: (context, _) => ProductSelectionScreen(
          onDone: onDone,
        ),
      ),
      GoRoute(
        path: '/setup/schedule',
        builder: (_, state) => const Scaffold(body: Text('schedule')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
    ),
  );
}

void main() {
  group('ProductSelectionScreen — write-race guard (flush before onDone)', () {
    testWidgets(
        'onDone must NOT fire while upsertSelection write is still in-flight',
        (tester) async {
      const cat = Category(id: 'cat-serum', name: 'סרום', order: 5);
      final master = _masterWith(
        [_amProduct('p1', 'קרם לחות', 'cat-serum')],
        [cat],
      );

      final udr = _GatedUDR();
      var doneFired = false;
      void onDone() => doneFired = true;

      await tester.pumpWidget(_wrap(master: master, udr: udr, onDone: onDone));
      await tester.pumpAndSettle();

      // Select the product — this enqueues a gated write in the UDR.
      // The stream update fires immediately so the UI shows 1 selected product
      // and enables the CTA.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('v3_row_p1')),
          matching: find.byType(GestureDetector),
        ).last,
      );
      // Pump to process the stream update so the CTA gets enabled.
      await tester.pumpAndSettle();

      // At least one write should be pending in the UDR.
      expect(udr.pendingCount, greaterThan(0),
          reason: 'The product toggle should have enqueued a write in the UDR');

      // Tap the CTA ("סידור המדף שלי") to try to navigate.
      await tester.tap(find.text('סידור המדף שלי'));
      // Allow microtasks/event loop but not the gated future to complete.
      await tester.pump();
      await tester.pump(Duration.zero);

      // KEY ASSERTION: onDone must NOT have fired because the write is still pending.
      expect(
        doneFired,
        isFalse,
        reason:
            'onDone must not fire while upsertSelection writes are in-flight; '
            'the CTA must await _flushWrites() first',
      );

      // Now release the gated write(s).
      udr.completeAll();
      await tester.pumpAndSettle();

      // Now onDone must have fired.
      expect(
        doneFired,
        isTrue,
        reason:
            'once all in-flight writes are done, onDone must be invoked',
      );
    });

    testWidgets(
        'onDone fires immediately when no writes are in-flight',
        (tester) async {
      // Sanity check: after all writes have been completed and there are no
      // pending writes, the CTA fires onDone immediately without any delay.
      const cat = Category(id: 'cat-serum', name: 'סרום', order: 5);
      final master = _masterWith(
        [_amProduct('p1', 'קרם לחות', 'cat-serum')],
        [cat],
      );

      final udr = _GatedUDR();
      var doneFired = false;
      void onDone() => doneFired = true;

      await tester.pumpWidget(_wrap(master: master, udr: udr, onDone: onDone));
      await tester.pumpAndSettle();

      // Toggle product ON.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('v3_row_p1')),
          matching: find.byType(GestureDetector),
        ).last,
      );
      await tester.pumpAndSettle();

      // Complete the write immediately so it's no longer pending.
      udr.completeAll();
      await tester.pumpAndSettle();

      // CTA is enabled (1 product selected). No pending writes.
      expect(udr.pendingCount, 0);

      // Tap the CTA — no pending writes.
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();

      expect(
        doneFired,
        isTrue,
        reason: 'onDone should fire promptly when no writes are in-flight',
      );
    });
  });
}
