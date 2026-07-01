// Tests for ProductDetailScreen: verifies the screen uses allProductsProvider
// (the merged master+custom list) rather than the old dual-watch pattern.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
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
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/collection/product_detail_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeSettings implements SettingsRepository {
  @override Future<String?> getLastExportDate() async => null;
  @override Future<void> setLastExportDate(String d) async {}
  @override Future<String?> getLastKnownMasterVersion() async => null;
  @override Future<void> setLastKnownMasterVersion(String v) async {}
  @override Future<int> getUserSchemaVersion() async => 1;
  @override Future<void> setUserSchemaVersion(int v) async {}
  @override Future<int> getLongestStreak() async => 0;
  @override Future<void> setLongestStreak(int s) async {}
  @override Future<bool> getOnboardingCompleted() async => true;
  @override Future<void> setOnboardingCompleted(bool v) async {}
  @override Future<String?> getUserName() async => null;
  @override Future<void> setUserName(String n) async {}
  @override Future<String?> getUserGender() async => null;
  @override Future<void> setUserGender(String g) async {}
  @override Future<void> clearUserProfile() async {}
  @override Future<String> getRoutineViewMode() async => 'list';
  @override Future<void> setRoutineViewMode(String m) async {}
  @override Future<bool> getRoutineShowNames() async => false;
  @override Future<void> setRoutineShowNames(bool v) async {}
  @override Future<String> getAppLanguage() async => 'he';
  @override Future<void> setAppLanguage(String code) async {}
  @override Future<bool> getTapHintSeen() async => true;
  @override Future<void> setTapHintSeen(bool value) async {}
  @override Future<String?> getWeeklyPhotoReminderDismissedDate() async => null;
  @override Future<void> setWeeklyPhotoReminderDismissedDate(String d) async {}
  @override Future<bool> getWeeklyReminderEnabled() async => true;
  @override Future<void> setWeeklyReminderEnabled(bool value) async {}
  @override Future<Set<String>?> getKnownProductIds() async => null;
  @override Future<void> setKnownProductIds(Set<String> ids) async {}
}

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<UserCustomProduct> customProducts;
  _FakeUDR({this.customProducts = const []});

  @override Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value([]);
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value([]);
  @override Stream<OrderOverride?> watchOrderOverride(Slot slot) => Stream.value(null);
  @override Stream<DayRecord?> watchDayRecord(String date, Slot slot) => Stream.value(null);
  @override Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([]);
  @override Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override Stream<List<UserCustomProduct>> watchCustomProducts() =>
      Stream.value(customProducts);
  @override Stream<List<CollectionItem>> watchCollectionItems() => Stream.value([]);
  @override Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) async =>
      throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) async {}
  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      throw UnimplementedError();
  @override Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();
  @override Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();
  @override Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override Future<void> clearRoutineData() async {}
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      Stream.value([]);
  @override Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async =>
      null;
  @override Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _kCat = Category(id: 'cat1', name: 'לחות', order: 1);

const _kMaster = MasterContent(
  products: [
    MasterProduct(
      id: 'master-p1',
      name: 'קרם לחות',
      categoryId: 'cat1',
      isDeprecated: false,
      morningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
    ),
  ],
  categories: [_kCat],
  rules: [],
  manifest: MasterListManifest(
    contentVersion: '1.0.0',
    appVersion: '1.0.0',
    changelog: [],
  ),
);

final _kCustomProduct = UserCustomProduct(
  id: 'custom-p1',
  name: 'מוצר מותאם אישית',
  categoryId: 'cat1',
  inMorning: true,
  inEvening: false,
  isDaily: true,
  lastModified: DateTime(2025),
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrapDetail({
  required String productId,
  List<UserCustomProduct> customProducts = const [],
}) {
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(
        _FakeMCR(_kMaster),
      ),
      userDataRepositoryProvider.overrideWithValue(
        _FakeUDR(customProducts: customProducts),
      ),
      settingsRepositoryProvider.overrideWithValue(_FakeSettings()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
      home: ProductDetailScreen(productId: productId),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ProductDetailScreen', () {
    testWidgets(
        'shows custom product name sourced from allProductsProvider '
        'and renders the edit button', (tester) async {
      await tester.pumpWidget(_wrapDetail(
        productId: 'custom-p1',
        customProducts: [_kCustomProduct],
      ));
      // Allow async providers to resolve.
      await tester.pumpAndSettle();

      // Product name is visible.
      expect(find.text('מוצר מותאם אישית'), findsWidgets);

      // Edit button is shown for editable (custom) products.
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets(
        'shows master product name and does NOT render the edit button',
        (tester) async {
      await tester.pumpWidget(_wrapDetail(
        productId: 'master-p1',
      ));
      await tester.pumpAndSettle();

      // Product name is visible.
      expect(find.text('קרם לחות'), findsWidgets);

      // No edit button for non-editable master products.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });
}
