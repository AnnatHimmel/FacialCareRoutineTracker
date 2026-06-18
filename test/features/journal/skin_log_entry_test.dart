import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/photo_repository.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/journal/skin_log_entry_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fake photo repository ─────────────────────────────────────────────────────

class _FakePhotoRepo implements PhotoRepository {
  @override
  Future<void> savePhoto(String key, Uint8List bytes) async {}
  @override
  Future<Uint8List?> readPhoto(String key) async => null;
  @override
  Future<void> deletePhoto(String key) async {}
  @override
  Future<List<String>> listAllKeys() async => [];
}

// ── Fake user data repository ─────────────────────────────────────────────────

class _FakeUserDataRepo implements UserDataRepository {
  SkinLogEntry? _entry;
  SkinLogEntry? lastUpserted;

  _FakeUserDataRepo(this._entry);

  @override
  Stream<SkinLogEntry?> watchSkinLog(String date) => Stream.value(_entry);

  @override
  Future<void> upsertSkinLog(SkinLogEntry e) async {
    lastUpserted = e;
    _entry = e;
  }

  // ── Unused stubs ──────────────────────────────────────────────────────────

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value([]);

  @override
  Future<void> upsertSelection(ProductSelection s) async {}

  @override
  Stream<WeekdaySchedule?> watchSchedule(String productId, Slot slot) =>
      Stream.value(null);

  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value([]);

  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async {}

  @override
  Stream<OrderOverride?> watchOrderOverride(Slot slot) => Stream.value(null);

  @override
  Future<void> upsertOrderOverride(OrderOverride o) async {}

  @override
  Future<void> deleteOrderOverride(Slot slot) async {}

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}

  @override
  Stream<DayRecord?> watchDayRecord(String date, Slot slot) =>
      Stream.value(null);

  @override
  Future<DayRecord> snapshotAndGetDayRecord(
    String date,
    Slot slot,
    List<String> resolvedProductIds,
    String masterVersion,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> updateDayRecord(DayRecord r) async {}

  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String yearMonth) =>
      Stream.value([]);

  @override
  Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([]);

  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() => Stream.value([]);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<void> muteConflict(MutedConflict m) async {}

  @override
  Future<void> unmuteConflict(String ruleId) async {}

  @override
  Future<UserDataExport> exportAllData() => throw UnimplementedError();

  @override
  Future<void> replaceAllData(UserDataExport export) async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Widget _buildScreen(_FakeUserDataRepo repo) => ProviderScope(
      overrides: [
        userDataRepositoryProvider.overrideWithValue(repo),
        photoRepositoryProvider.overrideWithValue(_FakePhotoRepo()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('he', 'MA'),
        home: const SkinLogEntryScreen(date: '2024-01-15'),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SkinLogEntryScreen — skin state persistence', () {
    testWidgets(
        'entry with skinState oily: skinState preserved when saving notes',
        (tester) async {
      final entry = SkinLogEntry(
        id: 'id1',
        date: '2024-01-15',
        skinState: 'oily',
        photoPaths: [],
        lastModified: DateTime.utc(2024, 1, 15),
      );
      final repo = _FakeUserDataRepo(entry);

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      // Type notes to make the form dirty
      await tester.enterText(find.byType(TextField).first, 'some notes');
      await tester.pump();

      // Press save
      await tester.tap(find.text('שמור'));
      await tester.pumpAndSettle();

      // skinState should be preserved in the upserted entry
      expect(repo.lastUpserted, isNotNull);
      expect(repo.lastUpserted!.skinState, 'oily');
    });

    testWidgets('tap oily chip sets skinState on save', (tester) async {
      final repo = _FakeUserDataRepo(null);

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      // Tap the "שמני" (oily) chip
      await tester.tap(find.text('שומני'));
      await tester.pump();

      // Chip tap should mark the form dirty — save button should activate
      expect(find.text('שמור'), findsOneWidget);

      // Press save
      await tester.tap(find.text('שמור'));
      await tester.pumpAndSettle();

      expect(repo.lastUpserted, isNotNull);
      expect(repo.lastUpserted!.skinState, 'oily');
    });

    testWidgets('deselect chip and save → skinState null', (tester) async {
      final entry = SkinLogEntry(
        id: 'id1',
        date: '2024-01-15',
        skinState: 'oily',
        photoPaths: [],
        lastModified: DateTime.utc(2024, 1, 15),
      );
      final repo = _FakeUserDataRepo(entry);

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      // Tap "שמני" again to deselect it
      await tester.tap(find.text('שומני'));
      await tester.pump();

      // Press save
      await tester.tap(find.text('שמור'));
      await tester.pumpAndSettle();

      expect(repo.lastUpserted, isNotNull);
      expect(repo.lastUpserted!.skinState, isNull);
    });
  });
}
