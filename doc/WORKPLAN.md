# Work Plan
Project: Skincare Routine Tracker
Created: 2026-05-26
Total Tasks: 35

---

## Overview

Build a cross-platform Flutter app (Android APK + Web) for a curated skincare routine tracker. An admin bundles a master product list; users select owned products and get a personalized Hebrew-RTL daily routine. All user data is local; no backend required for the free product.

Build order follows strict data-layer → service-layer → UI dependency chain. Each task is implementable by a fresh agent given only its prompt + listed context files.

---

## Phase 1: Foundation

### TASK-001: Flutter Project Initialization
**Description**: Initialize the Flutter project in the workspace root and configure `pubspec.yaml` with all required dependencies.
**Depends On**: None
**Files to Create/Modify**:
- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/main.dart` (stub only — `void main() => runApp(const Placeholder());`)

**Acceptance Criteria**:
- [ ] `flutter pub get` succeeds with no errors
- [ ] `flutter analyze` passes with strict lint rules
- [ ] `flutter build apk --debug` and `flutter build web` both succeed (stub app)
- [ ] All required packages declared in `pubspec.yaml`

**Context Files**:
- `doc/ARCHITECTURE.md` (§4 Technology Stack)

**Prompt**:
```
Initialize a Flutter project for a skincare routine tracker app. The project root is the current working directory. Run: flutter create --project-name skincare_tracker --org com.skincareroutine .

Then update pubspec.yaml to include these dependencies:
- flutter_riverpod: ^2.5.1
- riverpod_annotation: ^2.3.5
- drift: ^2.18.0
- drift_flutter: ^0.2.1
- sqlite3_flutter_libs: ^0.5.24
- shared_preferences: ^2.2.3
- archive: ^3.4.10
- share_plus: ^9.0.0
- image_picker: ^1.1.2
- flutter_image_compress: ^2.2.0
- path_provider: ^2.1.3
- google_fonts: ^6.2.1
- flutter_localizations (sdk: flutter)
- intl: ^0.19.0
- go_router: ^14.2.0
- uuid: ^4.4.0

dev_dependencies:
- build_runner: ^2.4.11
- drift_dev: ^2.18.0
- riverpod_generator: ^2.4.3
- flutter_gen_runner (optional)
- mockito: ^5.4.4
- build_runner for testing

analysis_options.yaml: use flutter_lints recommended rules plus explicit-casts and avoid-dynamic.

assets section in pubspec.yaml:
  assets:
    - assets/data/
    - assets/images/products/

Create these empty directories:
- assets/data/
- assets/images/products/
- lib/core/theme/
- lib/core/l10n/
- lib/core/utils/
- lib/core/routing/
- lib/domain/entities/
- lib/domain/enums/
- lib/domain/repositories/
- lib/domain/services/
- lib/data/bundled/
- lib/data/local/database/tables/
- lib/data/local/database/daos/
- lib/data/local/database/migrations/
- lib/data/local/photo_storage/
- lib/data/local/preferences/
- lib/data/repositories_impl/
- lib/features/
- lib/shared/widgets/
- lib/shared/providers/
- test/domain/
- test/data/

Verify: flutter pub get, flutter analyze, flutter build apk --debug all succeed.
```

---

### TASK-002: Radiant Dew Design System
**Description**: Implement the complete Radiant Dew design token system as Flutter `ThemeData` and associated constants.
**Depends On**: TASK-001
**Files to Create/Modify**:
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_typography.dart`
- `lib/core/theme/radiant_dew_theme.dart`

**Acceptance Criteria**:
- [ ] `AppColors` exposes all color constants from DESIGN.md
- [ ] `AppTypography` exposes all 6 text style roles (display, headline-lg, headline-md, body-lg, body-md, label-md, label-sm)
- [ ] `RadiantDewTheme.light()` returns a valid `ThemeData` consuming tokens (no hard-coded values in ThemeData)
- [ ] Quicksand font used for headlines/body; Plus Jakarta Sans for labels
- [ ] Card theme: 32px corner radius; Button theme: full pill; Input theme: 16px radius

**Context Files**:
- `doc/design-reference/screens/uploads/stitch_application_ux_ui_design/radiant_dew/DESIGN.md`
- `doc/UI_DESIGN.md` (§5 Style Guide)

**Prompt**:
```
Implement the Radiant Dew design system for a Flutter skincare app.
Stack: Flutter/Dart, google_fonts package available.

lib/core/theme/app_colors.dart — static const values:
  primary: Color(0xFF9E412C)
  onPrimary: Color(0xFFFFFFFF)
  primaryContainer: Color(0xFFFF8B71)
  onPrimaryContainer: Color(0xFF752311)
  secondary: Color(0xFF67600A)
  onSecondary: Color(0xFFFFFFFF)
  secondaryContainer: Color(0xFFEDE282)
  onSecondaryContainer: Color(0xFF6C6410)
  tertiary: Color(0xFF874E58)
  onTertiary: Color(0xFFFFFFFF)
  tertiaryContainer: Color(0xFFDE99A4)
  onTertiaryContainer: Color(0xFF63303A)
  error: Color(0xFFBA1A1A)
  errorContainer: Color(0xFFFFDAD6)
  surface: Color(0xFFFFF8F6)
  surfaceContainer: Color(0xFFFFE9E4)
  onSurface: Color(0xFF251815)
  onSurfaceVariant: Color(0xFF56423E)
  outline: Color(0xFF89726D)
  outlineVariant: Color(0xFFDCC0BA)
  inverseSurface: Color(0xFF3C2D29)
  inverseOnSurface: Color(0xFFFFEDE9)
  inversePrimary: Color(0xFFFFB4A4)

lib/core/theme/app_typography.dart — TextStyles using GoogleFonts:
  displayLg: Quicksand, 48px, w700
  headlineLg: Quicksand, 32px (28px mobile), w700
  headlineMd: Quicksand, 24px, w600
  bodyLg: Quicksand, 18px, w500
  bodyMd: Quicksand, 16px, w500
  labelMd: Plus Jakarta Sans, 14px, w600
  labelSm: Plus Jakarta Sans, 12px, w700

lib/core/theme/radiant_dew_theme.dart — ThemeData:
  colorScheme: ColorScheme.fromSeed adapted to AppColors values
  cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)))
  elevatedButtonTheme: pill-shaped (StadiumBorder), primary color
  inputDecorationTheme: OutlineInputBorder radius 16px, focusColor primary
  appBarTheme: backgroundColor surface, elevation 0
  navigationBarTheme: backgroundColor = surface with blur (glassmorphism via decoration)
  textTheme: map AppTypography styles to TextTheme roles

Glassmorphism helper constant:
  AppColors.glassFill = Color(0x99FFFFFF) // 60% white
  AppColors.glassBlurSigma = 12.0

No hard-coded color or font values in ThemeData — all reference AppColors/AppTypography.
```

---

### TASK-003: Hebrew RTL Setup + AppLocalizations
**Description**: Configure the app for Hebrew locale and RTL layout globally. Create the Hebrew ARB string resource file.
**Depends On**: TASK-001
**Files to Create/Modify**:
- `lib/core/l10n/app_he.arb`
- `lib/l10n.dart` (generated by flutter gen-l10n — set up the generation, don't hand-write)
- `l10n.yaml` (or `flutter` section in pubspec.yaml for gen-l10n)

**Acceptance Criteria**:
- [ ] `l10n.yaml` configures `flutter gen-l10n` targeting `lib/core/l10n/`
- [ ] `app_he.arb` contains all required UI strings (see prompt)
- [ ] Running `flutter gen-l10n` generates `AppLocalizations` without errors
- [ ] `AppLocalizations.of(context).todayTitle` returns the correct Hebrew string

**Context Files**:
- `doc/UI_DESIGN.md` (§3, screen wireframes for Hebrew label text)

**Prompt**:
```
Set up Hebrew localization for a Flutter skincare tracker app.

1. Create l10n.yaml at project root:
   arb-dir: lib/core/l10n
   template-arb-file: app_he.arb
   output-localization-file: app_localizations.dart
   output-dir: lib/core/l10n/generated

2. Create lib/core/l10n/app_he.arb with these strings (Hebrew):
{
  "@@locale": "he",
  "appName": "מעקב שגרת טיפוח",
  "navToday": "היום",
  "navCalendar": "לוח שנה",
  "navJournal": "יומן עור",
  "navSettings": "הגדרות",
  "slotMorning": "בוקר",
  "slotEvening": "ערב",
  "productSelectionTitle": "בחירת מוצרים",
  "scheduleTitle": "תזמון מוצרים",
  "orderTitle": "סדר מוצרים",
  "streakCurrent": "ימי רצף",
  "streakLongest": "הרצף הארוך",
  "streakMissesThisWeek": "החסרות השבוע",
  "streakMissesOf": "{current} מתוך {max}",
  "@streakMissesOf": { "placeholders": { "current": {}, "max": {} } },
  "warningDeprecated": "לא מומלץ עוד",
  "warningIncompatible": "לא מומלץ לשימוש יחד",
  "warningMute": "השתק",
  "warningOverCap": "נבחרו יותר ימים מההמלצה",
  "exportTitle": "ייצוא / ייבוא",
  "exportAction": "ייצא עכשיו",
  "importAction": "ייבא",
  "importReplace": "החלפה",
  "importMerge": "מיזוג",
  "settingsTitle": "הגדרות",
  "aboutTitle": "אודות / מה חדש",
  "updateReviewTitle": "עדכון הושלם",
  "backupReminderMessage": "גבי את הנתונים שלך",
  "backupAction": "גיבוי",
  "skinLogTitle": "יומן עור",
  "skinLogPlaceholder": "איך העור שלך היום?",
  "emptyRoutine": "אין מוצרים מתוכננים להיום",
  "emptyJournal": "עדיין אין תמונות ביומן",
  "continueAction": "המשך",
  "saveAction": "שמור",
  "resetOrder": "אפס לסדר מומלץ",
  "dataIntactConfirmation": "כל הנתונים שלך שמורים ובשלמותם",
  "before6amNote": "פעילות לפני 6:00 נרשמת ליום אמש",
  "conflictChooserTitle": "התנגשות {current} מתוך {total}",
  "@conflictChooserTitle": { "placeholders": { "current": {}, "total": {} } },
  "chooseArchive": "מהגיבוי",
  "chooseDevice": "מהמכשיר",
  "webStorageWarning": "תמונות מאוחסנות בנפח מוגבל. גיבוי מומלץ."
}

3. Run flutter gen-l10n to verify generation succeeds.
4. Add to pubspec.yaml flutter section: generate: true
```

---

### TASK-004: App Root, main.dart, and Routing
**Description**: Wire up `main.dart` with `ProviderScope`, `MaterialApp.router` with Radiant Dew theme, Hebrew locale, RTL, and `go_router` defining all named routes with bottom-nav shell.
**Depends On**: TASK-002, TASK-003
**Files to Create/Modify**:
- `lib/main.dart`
- `lib/app.dart`
- `lib/core/routing/app_router.dart`

**Acceptance Criteria**:
- [ ] App launches with cream (#FFF8F6) background, Hebrew locale, RTL text direction
- [ ] Bottom nav shows 4 tabs in RTL order: היום | לוח שנה | יומן עור | הגדרות
- [ ] Each tab route renders a placeholder `Scaffold` with correct Hebrew title
- [ ] `flutter run` on both Android and Web renders the shell without errors
- [ ] `Localizations.localeOf(context).languageCode` returns `'he'`

**Context Files**:
- `doc/UI_DESIGN.md` (§4.1 Primary Flow, §2.1 Screen List)
- `doc/ARCHITECTURE.md` (§8 UI-Relevant Contracts — Navigation Structure)

**Prompt**:
```
Set up the Flutter app root for a Hebrew RTL skincare tracker.
Stack: Flutter, go_router ^14, flutter_riverpod ^2.5, Radiant Dew theme (already exists in lib/core/theme/).

lib/main.dart:
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ProviderScope(child: SkincareApp()));
  }

lib/app.dart — SkincareApp StatelessWidget:
  - MaterialApp.router with:
    - routerConfig: appRouter
    - theme: RadiantDewTheme.light()
    - locale: const Locale('he')
    - supportedLocales: [Locale('he')]
    - localizationsDelegates: AppLocalizations.localizationsDelegates
    - debugShowCheckedModeBanner: false

lib/core/routing/app_router.dart — GoRouter:
  Shell route with StatefulShellRoute.indexedStack:
    branches: [
      /today → DailyHomePlaceholder,
      /calendar → CalendarPlaceholder,
      /journal → JournalPlaceholder,
      /settings → SettingsPlaceholder,
    ]
  Each placeholder is a Scaffold with AppBar title (Hebrew) + body Text('Coming soon').

Bottom nav shell widget (part of router or separate):
  NavigationBar with 4 destinations (RTL — rendered RTL automatically):
    destination 0: icon=sun_icon, label='היום'
    destination 1: icon=calendar_icon, label='לוח שנה'
    destination 2: icon=camera_icon, label='יומן עור'
    destination 3: icon=settings_icon, label='הגדרות'
  Use Material Icons temporarily; they'll be replaced in Phase 7.

Named routes to define (can use stub GoRoute for now):
  /today, /calendar, /journal, /settings,
  /setup/selection, /setup/schedule, /setup/order,
  /day/:date, /skin-log/:date, /export-import,
  /about, /update-review, /premium

Verify: flutter run shows bottom nav with Hebrew labels and RTL layout.
```

---

## Phase 2: Domain Models

### TASK-005: Master Content Domain Models
**Description**: Create all pure-Dart domain entities for admin-authored master content. No Flutter or Drift dependencies — pure Dart.
**Depends On**: TASK-001
**Files to Create/Modify**:
- `lib/domain/enums/slot.dart`
- `lib/domain/enums/rule_scope.dart`
- `lib/domain/entities/master_product.dart`
- `lib/domain/entities/category.dart`
- `lib/domain/entities/incompatibility_rule.dart`
- `lib/domain/entities/master_list_manifest.dart`

**Acceptance Criteria**:
- [ ] All classes are immutable (`final` fields, const constructors where applicable)
- [ ] `FrequencyRule` is a sealed class with `DailyRule` and `WeeklyMaxRule(int maxPerWeek)` variants
- [ ] `MasterProduct` has nullable `morningConfig` and `eveningConfig` (a product need not be in both slots)
- [ ] `IncompatibilityRule` has `entityA`, `entityB` of type `RuleTarget` (which carries `type: product|category` and `id`)
- [ ] All entity files contain `==` / `hashCode` / `copyWith`

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.1 Data Models — Master Content section)

**Prompt**:
```
Create pure-Dart domain entities for master content of a skincare tracker app.
No Flutter, no Drift — pure Dart immutable classes.

lib/domain/enums/slot.dart:
  enum Slot { morning, evening }

lib/domain/enums/rule_scope.dart:
  enum RuleScope { withinMorning, withinEvening, sameDayAcrossBoth }

lib/domain/entities/master_product.dart:
  @immutable class MasterProduct {
    final String id;           // stable UUID
    final String name;         // verbatim; may be Latin brand
    final String? imageAsset;  // Flutter asset path (e.g. 'assets/images/products/abc123.jpg')
    final String? comment;     // admin note; Hebrew + bidi
    final String categoryId;
    final SlotConfig? morningConfig;
    final SlotConfig? eveningConfig;
    final bool isDeprecated;
    final String addedInVersion;
  }

  @immutable class SlotConfig {
    final int order;           // 0-based admin canonical position
    final FrequencyRule frequencyRule;
  }

  sealed class FrequencyRule {
    const FrequencyRule();
  }
  class DailyRule extends FrequencyRule { const DailyRule(); }
  class WeeklyMaxRule extends FrequencyRule {
    final int maxPerWeek;
    const WeeklyMaxRule(this.maxPerWeek);
  }

lib/domain/entities/category.dart:
  @immutable class Category { final String id; final String name; }

lib/domain/entities/incompatibility_rule.dart:
  @immutable class IncompatibilityRule {
    final String id;
    final RuleTarget entityA;
    final RuleTarget entityB;
    final RuleScope scope;
  }
  enum RuleTargetType { product, category }
  @immutable class RuleTarget {
    final RuleTargetType type;
    final String id;
  }

lib/domain/entities/master_list_manifest.dart:
  @immutable class MasterListManifest {
    final String contentVersion;
    final String appVersion;
    final List<ChangelogEntry> changelog;
  }
  @immutable class ChangelogEntry {
    final String contentVersion;
    final List<String> changes;
  }

All classes: implement == and hashCode; provide copyWith.
```

---

### TASK-006: User Data Domain Models + Enums
**Description**: Create all pure-Dart domain entities for user-generated data and the supporting enums.
**Depends On**: TASK-001
**Files to Create/Modify**:
- `lib/domain/enums/day_completion_state.dart`
- `lib/domain/entities/product_selection.dart`
- `lib/domain/entities/weekday_schedule.dart`
- `lib/domain/entities/order_override.dart`
- `lib/domain/entities/day_record.dart`
- `lib/domain/entities/skin_log_entry.dart`
- `lib/domain/entities/muted_conflict.dart`
- `lib/domain/entities/user_data_export.dart`

**Acceptance Criteria**:
- [ ] All classes are immutable with `==` / `hashCode` / `copyWith`
- [ ] All records carry `String id` (UUID), `DateTime lastModified`
- [ ] `DayRecord` carries both `resolvedProductIds` (snapshot) and `recordedProductIds` (what was done)
- [ ] `WeekdaySchedule.weekdays` is `Set<int>` where 0=Sunday, 6=Saturday
- [ ] `UserDataExport` aggregates all user data types for serialization

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.1 Data Models — User Data section)

**Prompt**:
```
Create pure-Dart domain entities for user data of a skincare tracker. No Flutter, no Drift.
All records need: String id (UUID), DateTime lastModified.

lib/domain/enums/day_completion_state.dart:
  enum DayCompletionState { complete, partial, missed, future, noData }

lib/domain/entities/product_selection.dart:
  class ProductSelection { id, productId, Slot slot, bool isSelected, lastModified }

lib/domain/entities/weekday_schedule.dart:
  class WeekdaySchedule { id, productId, Slot slot, Set<int> weekdays, lastModified }
  // weekdays: 0=Sunday, 1=Monday, ..., 6=Saturday

lib/domain/entities/order_override.dart:
  class OrderOverride { id, Slot slot, List<String> orderedProductIds, lastModified }

lib/domain/entities/day_record.dart:
  class DayRecord {
    id, String date, // 'YYYY-MM-DD' effective date
    Slot slot,
    List<String> resolvedProductIds,   // snapshot of routine for that day
    List<String> recordedProductIds,   // what user marked done
    String resolvedAtMasterVersion,
    lastModified
  }

lib/domain/entities/skin_log_entry.dart:
  class SkinLogEntry { id, String date, String? notes, List<String> photoPaths, lastModified }
  // photoPaths: platform-specific storage keys/paths

lib/domain/entities/muted_conflict.dart:
  class MutedConflict { id, String ruleId, DateTime mutedAt }

lib/domain/entities/user_data_export.dart:
  class UserDataExport {
    final String schemaVersion;          // e.g. "1"
    final String exportDate;             // ISO datetime
    final String appVersion;
    final String masterContentVersion;
    final List<ProductSelection> selections;
    final List<WeekdaySchedule> schedules;
    final List<OrderOverride> overrides;
    final List<DayRecord> dayRecords;
    final List<SkinLogEntry> skinLogs;
    final List<MutedConflict> mutedConflicts;
    // settings snapshot
    final String? lastExportDate;
    final String? lastKnownMasterVersion;
  }

All: == / hashCode / copyWith. Use package:meta @immutable annotation.
```

---

## Phase 3: Data Layer

### TASK-007: Drift Database Schema
**Description**: Define the Drift `AppDatabase` with all 6 tables, database factory for Android and Web, and initial migration.
**Depends On**: TASK-006
**Files to Create/Modify**:
- `lib/data/local/database/tables/` (one file per table — 6 files)
- `lib/data/local/database/app_database.dart`

**Acceptance Criteria**:
- [ ] `dart run build_runner build` generates `.g.dart` files without errors
- [ ] `AppDatabase` opens successfully on Android (sqflite) and Web (sqlite3 WASM via `drift_flutter`)
- [ ] All 6 tables defined: product_selections, weekday_schedules, order_overrides, day_records, skin_log_entries, muted_conflicts
- [ ] Schema version = 1; `MigrationStrategy` defined with `onCreate`
- [ ] All ID columns use `TEXT PRIMARY KEY` (UUID strings)

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.1 Data Models — User Data / Drift tables pseudocode)

**Prompt**:
```
Define the Drift database schema for a Flutter skincare tracker.
Stack: Drift ^2.18, drift_flutter ^0.2.1, sqlite3_flutter_libs.

lib/data/local/database/tables/ — create one file per table:

product_selections.dart: Table with columns:
  id TEXT PK, productId TEXT, slot TEXT, isSelected BOOL, lastModifiedMs INT

weekday_schedules.dart:
  id TEXT PK, productId TEXT, slot TEXT, weekdaysJson TEXT (JSON array e.g. [0,2,4]), lastModifiedMs INT

order_overrides.dart:
  id TEXT PK, slot TEXT, orderedProductIdsJson TEXT (JSON array), lastModifiedMs INT

day_records.dart:
  id TEXT PK, date TEXT, slot TEXT,
  resolvedProductIdsJson TEXT, recordedProductIdsJson TEXT,
  resolvedAtMasterVersion TEXT, lastModifiedMs INT

skin_log_entries.dart:
  id TEXT PK, date TEXT, notes TEXT nullable, photoPathsJson TEXT (JSON array), lastModifiedMs INT

muted_conflicts.dart:
  id TEXT PK, ruleId TEXT, mutedAtMs INT

lib/data/local/database/app_database.dart:
  @DriftDatabase(tables: [ProductSelections, WeekdaySchedules, OrderOverrides, DayRecords, SkinLogEntries, MutedConflicts])
  class AppDatabase extends _$AppDatabase {
    AppDatabase(QueryExecutor e) : super(e);
    @override int get schemaVersion => 1;
    @override MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) async { await m.createAll(); }
    );
  }

  // Factory:
  AppDatabase openDatabase() {
    return AppDatabase(driftDatabase(name: 'skincare_tracker'));
    // driftDatabase() from drift_flutter handles Android vs Web automatically
  }

Run: dart run build_runner build --delete-conflicting-outputs
Verify: generated .g.dart files present, no errors.
```

---

### TASK-008: Drift DAOs
**Description**: Implement all 6 DAOs providing CRUD operations and reactive `Stream` queries for each table.
**Depends On**: TASK-007
**Files to Create/Modify**:
- `lib/data/local/database/daos/selections_dao.dart`
- `lib/data/local/database/daos/schedules_dao.dart`
- `lib/data/local/database/daos/order_overrides_dao.dart`
- `lib/data/local/database/daos/day_records_dao.dart`
- `lib/data/local/database/daos/skin_log_dao.dart`
- `lib/data/local/database/daos/muted_conflicts_dao.dart`

**Acceptance Criteria**:
- [ ] Each DAO is a `@DriftAccessor` class added to `AppDatabase.daos`
- [ ] Each DAO has `watchAll()` returning `Stream<List<T>>` and `upsert(T)` / `deleteById(String)`
- [ ] `SelectionsDao.watchBySlot(Slot)` filters by slot column
- [ ] `DayRecordsDao.watchByDateAndSlot(String date, String slot)` filters by both columns
- [ ] `SkinLogDao.watchAll()` returns entries ordered by date DESC

**Context Files**:
- `lib/data/local/database/app_database.dart`
- `doc/ARCHITECTURE.md` (§2.3 Interface Contracts — UserDataRepository)

**Prompt**:
```
Implement Drift DAOs for a Flutter skincare tracker database.
Stack: Drift ^2.18; the AppDatabase with 6 tables already exists.

Create @DriftAccessor classes for each table. Each DAO file follows this pattern:

@DriftAccessor(tables: [ProductSelections])
class SelectionsDao extends DatabaseAccessor<AppDatabase> with _$SelectionsDaoMixin {
  SelectionsDao(super.db);

  Stream<List<ProductSelection>> watchBySlot(String slot) =>
    (select(productSelections)..where((t) => t.slot.equals(slot))).watch();

  Stream<List<ProductSelection>> watchAll() => select(productSelections).watch();

  Future<void> upsert(ProductSelectionsCompanion entry) =>
    into(productSelections).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
    (delete(productSelections)..where((t) => t.id.equals(id))).go();
}

Implement all 6 DAOs with these key methods:
- SelectionsDao: watchBySlot(slot), upsert, deleteById
- SchedulesDao: watchByProductAndSlot(productId, slot), upsert, deleteById
- OrderOverridesDao: watchBySlot(slot), upsert, deleteById
- DayRecordsDao: watchByDateAndSlot(date, slot), watchForMonth(yearMonth: String e.g. '2026-05'), upsert, deleteById
- SkinLogDao: watchAll() DESC by date, watchByDate(date), upsert, deleteById
- MutedConflictsDao: watchAll(), upsert, deleteByRuleId(ruleId)

Add all DAOs to AppDatabase:
  @DriftDatabase(tables: [...], daos: [SelectionsDao, SchedulesDao, OrderOverridesDao, DayRecordsDao, SkinLogDao, MutedConflictsDao])

Run build_runner to regenerate. Verify no compilation errors.
```

---

### TASK-009: Bundled JSON Assets + MasterContentRepository
**Description**: Create the admin-authored JSON data files (with realistic sample data) and implement `MasterContentRepository` that loads and parses them.
**Depends On**: TASK-005
**Files to Create/Modify**:
- `assets/data/master_products.json`
- `assets/data/incompatibility_rules.json`
- `assets/data/changelog.json`
- `lib/domain/repositories/master_content_repository.dart` (abstract interface)
- `lib/data/bundled/master_content_repository_impl.dart`

**Acceptance Criteria**:
- [ ] JSON files parse without error using `jsonDecode`
- [ ] `MasterContentRepository.load()` returns a `MasterContent` with products, categories, rules, manifest
- [ ] At least 5 products in 3 categories across both Morning and Evening slots (sample data)
- [ ] At least 1 product with `isDeprecated: true`
- [ ] At least 1 `WeeklyMaxRule` frequency rule and 1 `DailyRule`
- [ ] At least 1 incompatibility rule (product↔product) and 1 (category↔category)

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.1 Data Models — Master Content, §3.2 Data Flow)
- `lib/domain/entities/master_product.dart`

**Prompt**:
```
Create bundled JSON assets and the MasterContentRepository for a Flutter skincare tracker.

1. assets/data/master_products.json format:
{
  "contentVersion": "1.0.0",
  "categories": [
    {"id": "cat-cleanser", "name": "ניקוי"},
    {"id": "cat-serum", "name": "סרום / אקטיב"},
    {"id": "cat-moisturizer", "name": "לחות"},
    {"id": "cat-spf", "name": "הגנה"}
  ],
  "products": [
    {
      "id": "prod-001", "name": "CeraVe Foaming Cleanser",
      "categoryId": "cat-cleanser", "isDeprecated": false, "addedInVersion": "1.0.0",
      "imageAsset": "assets/images/products/prod-001.jpg",
      "comment": "מנקה עדין ולא מייבש, מתאים לשימוש יומיומי",
      "morningConfig": {"order": 0, "frequency": {"type": "daily"}},
      "eveningConfig": {"order": 0, "frequency": {"type": "daily"}}
    },
    {
      "id": "prod-002", "name": "The Ordinary Niacinamide 10%",
      "categoryId": "cat-serum", "isDeprecated": false, "addedInVersion": "1.0.0",
      "morningConfig": {"order": 1, "frequency": {"type": "daily"}},
      "eveningConfig": null
    },
    {
      "id": "prod-003", "name": "Paula's Choice BHA Exfoliant",
      "categoryId": "cat-serum", "isDeprecated": false, "addedInVersion": "1.0.0",
      "morningConfig": null,
      "eveningConfig": {"order": 1, "frequency": {"type": "weeklyMax", "maxPerWeek": 3}}
    },
    {
      "id": "prod-004", "name": "CeraVe PM Moisturizer",
      "categoryId": "cat-moisturizer", "isDeprecated": false, "addedInVersion": "1.0.0",
      "eveningConfig": {"order": 2, "frequency": {"type": "daily"}}
    },
    {
      "id": "prod-005", "name": "Neutrogena Hydra Boost",
      "categoryId": "cat-moisturizer", "isDeprecated": true, "addedInVersion": "1.0.0",
      "morningConfig": {"order": 2, "frequency": {"type": "daily"}}
    },
    {
      "id": "prod-006", "name": "La Roche-Posay SPF 50+",
      "categoryId": "cat-spf", "isDeprecated": false, "addedInVersion": "1.0.0",
      "morningConfig": {"order": 3, "frequency": {"type": "daily"}}
    }
  ]
}

2. assets/data/incompatibility_rules.json:
{
  "rules": [
    {"id": "rule-001", "entityA": {"type": "product", "id": "prod-002"}, "entityB": {"type": "product", "id": "prod-003"}, "scope": "sameDayAcrossBoth"},
    {"id": "rule-002", "entityA": {"type": "category", "id": "cat-serum"}, "entityB": {"type": "category", "id": "cat-spf"}, "scope": "withinMorning"}
  ]
}

3. assets/data/changelog.json:
{
  "appVersion": "1.0.0",
  "contentVersion": "1.0.0",
  "changelog": [{"contentVersion": "1.0.0", "changes": ["גרסה ראשונית"]}]
}

4. Abstract interface lib/domain/repositories/master_content_repository.dart:
  abstract class MasterContentRepository {
    Future<MasterContent> load();
  }
  class MasterContent { final List<MasterProduct> products; final List<Category> categories; final List<IncompatibilityRule> rules; final MasterListManifest manifest; }

5. Implementation lib/data/bundled/master_content_repository_impl.dart:
  Loads JSON via rootBundle.loadString(), parses into domain entities.
  Cache result after first load (load() returns cached Future).
```

---

### TASK-010: UserDataRepository Implementation
**Description**: Implement `UserDataRepository` that wraps Drift DAOs, maps rows ↔ domain entities, and exposes reactive Streams and async mutations.
**Depends On**: TASK-008, TASK-006
**Files to Create/Modify**:
- `lib/domain/repositories/user_data_repository.dart` (abstract)
- `lib/data/repositories_impl/user_data_repository_impl.dart`
- `lib/core/utils/json_list.dart` (JSON encode/decode helpers)

**Acceptance Criteria**:
- [ ] `watchSelections(Slot)` returns `Stream<List<ProductSelection>>`
- [ ] `snapshotAndGetDayRecord(date, slot, resolvedProductIds)` creates a new `DayRecord` if none exists, else returns existing
- [ ] `exportAllData()` returns a `UserDataExport` with all user records
- [ ] `replaceAllData(UserDataExport)` runs in a transaction, deletes all rows, inserts from export
- [ ] `json_list.dart` has `encodeIds(List<String>)` and `decodeIds(String)` helpers

**Context Files**:
- `doc/ARCHITECTURE.md` (§2.3 Interface Contracts — UserDataRepository)
- `lib/data/local/database/daos/` (existing DAOs)

**Prompt**:
```
Implement UserDataRepository for a Flutter skincare tracker.
Stack: Drift DAOs already exist for 6 tables.

lib/core/utils/json_list.dart:
  String encodeIds(List<String> ids) => jsonEncode(ids);
  List<String> decodeIds(String json) => (jsonDecode(json) as List).cast<String>();
  String encodeWeekdays(Set<int> days) => jsonEncode(days.toList()..sort());
  Set<int> decodeWeekdays(String json) => (jsonDecode(json) as List).cast<int>().toSet();

lib/domain/repositories/user_data_repository.dart — abstract interface with:
  Stream<List<ProductSelection>> watchSelections(Slot slot)
  Future<void> upsertSelection(ProductSelection s)
  Stream<WeekdaySchedule?> watchSchedule(String productId, Slot slot)
  Future<void> upsertSchedule(WeekdaySchedule s)
  Stream<OrderOverride?> watchOrderOverride(Slot slot)
  Future<void> upsertOrderOverride(OrderOverride o)
  Stream<DayRecord?> watchDayRecord(String date, Slot slot)
  Future<DayRecord> snapshotAndGetDayRecord(String date, Slot slot, List<String> resolvedProductIds, String masterVersion)
  Future<void> updateDayRecord(DayRecord r)
  Stream<List<DayRecord>> watchDayRecordsForMonth(String yearMonth) // 'YYYY-MM'
  Stream<SkinLogEntry?> watchSkinLog(String date)
  Future<void> upsertSkinLog(SkinLogEntry e)
  Stream<List<SkinLogEntry>> watchAllSkinLogs()
  Stream<List<MutedConflict>> watchMutedConflicts()
  Future<void> muteConflict(MutedConflict m)
  Future<void> unmuteConflict(String ruleId)
  Future<UserDataExport> exportAllData()
  Future<void> replaceAllData(UserDataExport export)

Implementation maps Drift row types ↔ domain entities using encodeIds/decodeIds.
snapshotAndGetDayRecord: check if DayRecord exists for (date, slot); if not, create one with resolvedProductIds snapshot; return it.
replaceAllData: wrap in db.transaction(() async { delete all tables; insert all from export; });
```

---

### TASK-011: SettingsRepository + PhotoRepository
**Description**: Implement `SettingsRepository` (SharedPreferences-backed) and the `PhotoRepository` interface plus Android file-system implementation.
**Depends On**: TASK-001
**Files to Create/Modify**:
- `lib/domain/repositories/settings_repository.dart` (abstract)
- `lib/data/local/preferences/settings_repository_impl.dart`
- `lib/domain/repositories/photo_repository.dart` (abstract)
- `lib/data/local/photo_storage/photo_repository_android.dart`
- `lib/data/local/photo_storage/photo_repository_web_stub.dart`

**Acceptance Criteria**:
- [ ] `SettingsRepository` persists: `lastExportDate`, `lastKnownMasterVersion`, `userSchemaVersion`, `longestStreak`
- [ ] `PhotoRepository.savePhoto(key, bytes)` saves compressed JPEG; `readPhoto(key)` returns bytes
- [ ] Android implementation stores photos in `{appDocDir}/skin_photos/{key}.jpg`
- [ ] Web stub implementation stores photos in memory (map) for now; returns `UnsupportedError` on `listAllKeys` — actual IndexedDB in TASK-034
- [ ] `PhotoRepository.deletePhoto(key)` and `listAllKeys()` work correctly on Android

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.3 Storage Strategy)

**Prompt**:
```
Implement SettingsRepository and PhotoRepository for a Flutter skincare tracker.

lib/domain/repositories/settings_repository.dart — abstract:
  Future<String?> getLastExportDate()
  Future<void> setLastExportDate(String isoDate)
  Future<String?> getLastKnownMasterVersion()
  Future<void> setLastKnownMasterVersion(String version)
  Future<int> getUserSchemaVersion()
  Future<void> setUserSchemaVersion(int v)
  Future<int> getLongestStreak()
  Future<void> setLongestStreak(int streak)

Implementation (shared_preferences): use keys 'last_export_date', 'last_known_master_version', 'user_schema_version' (default 1), 'longest_streak' (default 0).

lib/domain/repositories/photo_repository.dart — abstract:
  Future<void> savePhoto(String key, Uint8List bytes)
  Future<Uint8List?> readPhoto(String key)
  Future<void> deletePhoto(String key)
  Future<List<String>> listAllKeys()

Android implementation (path_provider + dart:io):
  Base dir: {appDocumentsDirectory}/skin_photos/
  key is the filename without extension (UUID).
  savePhoto: compress bytes to max 1080px (flutter_image_compress), write to {base}/{key}.jpg
  readPhoto: read bytes from file; return null if not found
  deletePhoto: delete file if exists
  listAllKeys: list files in base dir, strip .jpg extension

Web stub:
  In-memory Map<String, Uint8List> _cache = {};
  savePhoto/readPhoto/deletePhoto operate on _cache.
  listAllKeys: returns _cache.keys.toList().
  (Real IndexedDB implementation in TASK-034.)
```

---

## Phase 4: Domain Services

### TASK-012: DayBoundaryService
**Description**: Implement the 6am day boundary rule as a pure Dart service with comprehensive unit tests.
**Depends On**: TASK-001
**Files to Create/Modify**:
- `lib/domain/services/day_boundary_service.dart`
- `test/domain/day_boundary_service_test.dart`

**Acceptance Criteria**:
- [ ] `effectiveDate(DateTime dt)` returns the calendar date for dt, minus 1 day if dt.hour < 6
- [ ] `todayEffectiveDate()` calls `effectiveDate(DateTime.now())`
- [ ] `formatDate(DateTime dt)` returns `'YYYY-MM-DD'` string for a given effective date
- [ ] Unit tests cover: 05:59 → yesterday, 06:00 → today, 23:00 → today, midnight edge

**Context Files**: None (pure business logic)

**Prompt**:
```
Implement DayBoundaryService for a skincare tracker. Pure Dart, no dependencies.

Rule: A "day" ends at 06:00 the NEXT morning. Any DateTime before 06:00 belongs to the PRIOR calendar date.

lib/domain/services/day_boundary_service.dart:
class DayBoundaryService {
  /// Returns the effective calendar date for [dateTime].
  /// If hour < 6, returns the previous calendar date.
  DateTime effectiveDate(DateTime dateTime) {
    final normalized = dateTime.toLocal();
    if (normalized.hour < 6) {
      return DateTime(normalized.year, normalized.month, normalized.day - 1);
    }
    return DateTime(normalized.year, normalized.month, normalized.day);
  }

  /// Effective date for right now.
  DateTime get todayEffectiveDate => effectiveDate(DateTime.now());

  /// Formats a DateTime as 'YYYY-MM-DD'.
  String formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';

  /// Parses 'YYYY-MM-DD' back to DateTime.
  DateTime parseDate(String date) {
    final parts = date.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

test/domain/day_boundary_service_test.dart — test cases:
  - 05:59 local → previous day
  - 06:00 local → current day
  - 06:01 local → current day
  - 00:00 midnight → previous day
  - 23:59 → current day
  - formatDate round-trips correctly with parseDate

Run: flutter test test/domain/day_boundary_service_test.dart — all pass.
```

---

### TASK-013: RoutineResolver
**Description**: Implement the algorithm that resolves which products are active for a given date and slot, applying schedule, 6am boundary, and effective order.
**Depends On**: TASK-010, TASK-012, TASK-005
**Files to Create/Modify**:
- `lib/domain/services/routine_resolver.dart`
- `test/domain/routine_resolver_test.dart`

**Acceptance Criteria**:
- [ ] Daily products always included if selected
- [ ] Occasional (WeeklyMax) products included only if their schedule includes the effective day-of-week
- [ ] Admin order used by default; personal override applied if present
- [ ] Deprecated products included if selected (not filtered out)
- [ ] Unit tests cover: all-daily routine, occasional on scheduled day, occasional on unscheduled day, order override active, deprecated product included

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.2 Data Flow — RoutineResolver algorithm)
- `lib/domain/services/day_boundary_service.dart`

**Prompt**:
```
Implement RoutineResolver for a Flutter skincare tracker.
Stack: Pure Dart; depends on domain entities and DayBoundaryService.

lib/domain/services/routine_resolver.dart:
class RoutineResolver {
  // Returns products active for given date+slot in effective order.
  List<MasterProduct> resolve({
    required DateTime date,
    required Slot slot,
    required List<MasterProduct> allProducts,       // full master list
    required List<ProductSelection> selections,      // user's selected products
    required List<WeekdaySchedule> schedules,        // user's weekly schedules
    required OrderOverride? orderOverride,           // user's personal order (nullable)
    required DayBoundaryService boundary,
  }) {
    final effectiveDate = boundary.effectiveDate(date);
    final dayOfWeek = effectiveDate.weekday % 7; // Convert: Mon=1..Sun=7 → Sun=0..Sat=6
    // Note: Dart's weekday: Mon=1, Tue=2, ..., Sun=7. Convert to Sun=0: (weekday % 7)

    // 1. Filter to products selected in this slot
    final selectedIds = selections
      .where((s) => s.slot == slot && s.isSelected)
      .map((s) => s.productId).toSet();
    final selected = allProducts.where((p) {
      if (slot == Slot.morning && p.morningConfig == null) return false;
      if (slot == Slot.evening && p.eveningConfig == null) return false;
      return selectedIds.contains(p.id);
    }).toList();

    // 2. Filter by frequency/schedule
    final active = selected.where((p) {
      final config = slot == Slot.morning ? p.morningConfig! : p.eveningConfig!;
      return switch (config.frequencyRule) {
        DailyRule() => true,
        WeeklyMaxRule() => schedules.any((s) =>
          s.productId == p.id && s.slot == slot && s.weekdays.contains(dayOfWeek)
        ),
      };
    }).toList();

    // 3. Sort by effective order
    if (orderOverride != null && orderOverride.slot == slot) {
      final orderMap = { for (var i = 0; i < orderOverride.orderedProductIds.length; i++)
        orderOverride.orderedProductIds[i]: i };
      active.sort((a, b) {
        final ai = orderMap[a.id] ?? 9999;
        final bi = orderMap[b.id] ?? 9999;
        if (ai != bi) return ai.compareTo(bi);
        // fallback: admin order
        final ao = (slot == Slot.morning ? a.morningConfig?.order : a.eveningConfig?.order) ?? 999;
        final bo = (slot == Slot.morning ? b.morningConfig?.order : b.eveningConfig?.order) ?? 999;
        return ao.compareTo(bo);
      });
    } else {
      active.sort((a, b) {
        final ao = (slot == Slot.morning ? a.morningConfig?.order : a.eveningConfig?.order) ?? 999;
        final bo = (slot == Slot.morning ? b.morningConfig?.order : b.eveningConfig?.order) ?? 999;
        return ao.compareTo(bo);
      });
    }
    return active;
  }
}

Write unit tests for all the cases listed in Acceptance Criteria. Verify: flutter test passes.
```

---

### TASK-014: IncompatibilityChecker
**Description**: Implement the rule-evaluation service that detects admin-authored incompatibility conflicts for a user's selection/schedule.
**Depends On**: TASK-005, TASK-013
**Files to Create/Modify**:
- `lib/domain/services/incompatibility_checker.dart`
- `test/domain/incompatibility_checker_test.dart`

**Acceptance Criteria**:
- [ ] Detects product↔product and category↔category conflicts
- [ ] Respects scope: `withinMorning`, `withinEvening`, `sameDayAcrossBoth`
- [ ] Returns only conflicts where both products are actually in the relevant slot(s) on the given day
- [ ] Filters out conflicts muted by user (`mutedConflicts` list)
- [ ] `ConflictInfo` includes ruleId, productA, productB, scope, isMuted
- [ ] Unit tests cover: product conflict detected, category conflict detected, scoped correctly, muted conflict excluded

**Context Files**:
- `doc/ARCHITECTURE.md` (§2.3 Interface Contracts — IncompatibilityChecker)
- `lib/domain/entities/incompatibility_rule.dart`

**Prompt**:
```
Implement IncompatibilityChecker for a Flutter skincare tracker.
Pure Dart; no Flutter dependencies.

class ConflictInfo {
  final String ruleId;
  final MasterProduct productA;
  final MasterProduct productB;
  final RuleScope scope;
  final bool isMuted;
}

class IncompatibilityChecker {
  // Check conflicts for today's resolved routine.
  List<ConflictInfo> getConflictsForDay({
    required List<MasterProduct> morningProducts,
    required List<MasterProduct> eveningProducts,
    required List<IncompatibilityRule> rules,
    required List<Category> categories,
    required Set<String> mutedRuleIds,
  }) {
    final conflicts = <ConflictInfo>[];
    for (final rule in rules) {
      switch (rule.scope) {
        case RuleScope.withinMorning:
          _checkWithinSlot(morningProducts, rule, categories, mutedRuleIds, conflicts);
        case RuleScope.withinEvening:
          _checkWithinSlot(eveningProducts, rule, categories, mutedRuleIds, conflicts);
        case RuleScope.sameDayAcrossBoth:
          _checkAcrossSlots(morningProducts, eveningProducts, rule, categories, mutedRuleIds, conflicts);
      }
    }
    return conflicts;
  }

  // Also provide: getConflictsForSelection (all daily products in a slot — for S1)
  // and getConflictsForSchedule (for day-dependent conflicts — for S2)

  bool _matches(MasterProduct p, RuleTarget target, List<Category> categories) {
    return switch (target.type) {
      RuleTargetType.product => p.id == target.id,
      RuleTargetType.category => p.categoryId == target.id,
    };
  }

  void _checkWithinSlot(List<MasterProduct> products, IncompatibilityRule rule,
    List<Category> categories, Set<String> muted, List<ConflictInfo> out) {
    for (final a in products) {
      for (final b in products) {
        if (a.id == b.id) continue;
        if (_matches(a, rule.entityA, categories) && _matches(b, rule.entityB, categories)) {
          out.add(ConflictInfo(ruleId: rule.id, productA: a, productB: b,
            scope: rule.scope, isMuted: muted.contains(rule.id)));
          return; // one conflict per rule per check
        }
      }
    }
  }

  void _checkAcrossSlots(...) { /* similar, combining both slot lists */ }
}

Write unit tests. Run flutter test.
```

---

### TASK-015: StreakCalculator
**Description**: Implement the streak computation algorithm with grace logic. This is the most complex domain service.
**Depends On**: TASK-006, TASK-012
**Files to Create/Modify**:
- `lib/domain/services/streak_calculator.dart`
- `test/domain/streak_calculator_test.dart`

**Acceptance Criteria**:
- [ ] `slot done` = DayRecord exists for slot AND `recordedProductIds.isNotEmpty`
- [ ] `miss` = DayRecord exists for slot AND `resolvedProductIds.isNotEmpty` AND `recordedProductIds.isEmpty`
- [ ] `unscheduled slot` (no DayRecord or `resolvedProductIds.isEmpty`) = never a miss
- [ ] Grace: ≤3 slot-misses per Sun–Sat calendar week; 4th miss resets streak
- [ ] Unused grace resets each new week (Sunday)
- [ ] `longestStreak` is returned and should be max of all computed streak lengths
- [ ] Comprehensive unit tests: perfect days, partial days, missed days, grace exhaustion, multi-week scenarios

**Context Files**:
- `doc/FUNCTIONALITY.md` (§6 Core Features — Streak Tracking UC-13)

**Prompt**:
```
Implement StreakCalculator for a Flutter skincare tracker.
The 6am day boundary means DayRecord.date is already the effective date (pre-adjusted).

Rules:
- slot done: DayRecord for (date, slot) has recordedProductIds.isNotEmpty AND resolvedProductIds.isNotEmpty
- miss: DayRecord for (date, slot) exists AND resolvedProductIds.isNotEmpty AND recordedProductIds.isEmpty
- unscheduled: no DayRecord OR resolvedProductIds.isEmpty → never a miss, never done
- complete day: both morning and evening slots are done
- Grace: track slot-misses per Sun-Sat week (week key = ISO week or Sun-based week number)
  - Sun–Sat week: weekday of Sunday is 7 in Dart → use (date.weekday % 7 == 0) for Sunday
  - Week identifier: find the most recent Sunday on or before the date
  - ≤3 misses in a week: streak continues (regardless of done/miss ratio)
  - 4th miss in same week: streak resets to 0 for all prior days in that week's computation

class StreakResult {
  final int currentStreak;   // days since last reset (including today if complete)
  final int longestStreak;
  final int missesThisWeek;  // for the current Sun-Sat week
}

class StreakCalculator {
  StreakResult compute({
    required List<DayRecord> allRecords,   // sorted any order
    required DateTime asOf,                // compute "as of" this datetime (pre-boundary)
    required DayBoundaryService boundary,
  }) { ... }
}

Algorithm:
1. Build a map: date+slot → DayRecord
2. Walk backward from (effective yesterday, since today may be incomplete):
3. For each day, compute morningMisses + eveningMisses
4. Accumulate misses per week; if weekMisses < 4 → continue streak; if == 4 → reset
5. currentStreak = count of days walked without reset
6. Track longestStreak globally

test/domain/streak_calculator_test.dart — test scenarios:
  - 5 perfect days → streak=5
  - 3 miss budget in week 1 (3 misses) → streak continues
  - 4th miss in week → streak resets
  - Blank day (2 misses if 2 slots scheduled) → counts correctly
  - Unscheduled slot → not a miss
  - Multi-week scenario with grace reset on Sunday
Run flutter test — all pass.
```

---

### TASK-016: ReconciliationService
**Description**: Implement the post-update master-list reconciliation that compares the installed content version to the prior known version and computes what changed.
**Depends On**: TASK-009, TASK-010, TASK-011
**Files to Create/Modify**:
- `lib/domain/services/reconciliation_service.dart`
- `test/domain/reconciliation_service_test.dart`

**Acceptance Criteria**:
- [ ] `reconcile()` compares `lastKnownVersion` (from SettingsRepository) to `currentContentVersion` (from MasterContent)
- [ ] Returns `ReconciliationResult` with: `isUpdateDetected`, `newProducts` (unselected), `newlyDeprecatedSelected` (deprecated products the user has selected)
- [ ] Never auto-selects new products or auto-removes deprecated ones
- [ ] Updates `lastKnownMasterVersion` in settings after reconciliation is acknowledged
- [ ] Unit tests cover: no update, new products detected, deprecated product detection

**Context Files**:
- `doc/ARCHITECTURE.md` (§2.3 Interface Contracts — ReconciliationService)

**Prompt**:
```
Implement ReconciliationService for a Flutter skincare tracker.
This runs on first app launch after a master-list update.

class ReconciliationResult {
  final bool isUpdateDetected;
  final List<MasterProduct> newProducts;           // added since lastKnownVersion, not selected by user
  final List<MasterProduct> newlyDeprecatedSelected; // deprecated products user currently has selected
  final String currentContentVersion;
}

class ReconciliationService {
  final MasterContentRepository _masterRepo;
  final UserDataRepository _userRepo;
  final SettingsRepository _settings;

  Future<ReconciliationResult> reconcile() async {
    final masterContent = await _masterRepo.load();
    final lastKnown = await _settings.getLastKnownMasterVersion();
    final currentVersion = masterContent.manifest.contentVersion;

    if (lastKnown == currentVersion) {
      return ReconciliationResult(isUpdateDetected: false, ...empty lists, currentContentVersion: currentVersion);
    }

    // Get user's selected product IDs (both slots)
    final morningSelections = await _userRepo.exportAllData().then((e) => e.selections);
    final selectedIds = morningSelections.where((s) => s.isSelected).map((s) => s.productId).toSet();

    // New products: present in master, added after lastKnown version, not selected
    // Since we don't have per-product version tracking in detail, treat all products
    // with addedInVersion > lastKnown as new.
    // Simple approach: new products are those NOT in a prior snapshot.
    // Use addedInVersion field on MasterProduct.
    final newProducts = masterContent.products
      .where((p) => !p.isDeprecated && !selectedIds.contains(p.id)
                    && p.addedInVersion != lastKnown) // simplified
      .toList();

    final newlyDeprecatedSelected = masterContent.products
      .where((p) => p.isDeprecated && selectedIds.contains(p.id))
      .toList();

    return ReconciliationResult(
      isUpdateDetected: true,
      newProducts: newProducts,
      newlyDeprecatedSelected: newlyDeprecatedSelected,
      currentContentVersion: currentVersion,
    );
  }

  // Call after user has reviewed the update screen
  Future<void> acknowledgeUpdate(String version) async {
    await _settings.setLastKnownMasterVersion(version);
  }
}

Write unit tests with mock repositories. flutter test passes.
```

---

### TASK-017: ExportImportService
**Description**: Implement ZIP-based export of all user data (including photos) and both import flows: Replace and Merge with `MergeSession`.
**Depends On**: TASK-010, TASK-011
**Files to Create/Modify**:
- `lib/domain/services/export_import_service.dart`
- `test/data/export_import_service_test.dart`

**Acceptance Criteria**:
- [ ] `exportToArchive()` returns a ZIP as `Uint8List` containing `manifest.json`, `user_data.json`, and `photos/`
- [ ] `validateArchive(bytes)` returns an `ArchiveValidationResult` (valid/invalid + parsed data if valid)
- [ ] `replaceAll(validated)` deletes all local data and inserts from export in a single transaction
- [ ] `startMerge(validated)` returns a `MergeSession` exposing `conflicts`, `resolveConflict(choice)`, `complete()`
- [ ] Conflict = a record present in both archive and local with different `lastModified`

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.1 Export Archive Format, §2.3 Interface Contracts — ExportImportService)

**Prompt**:
```
Implement ExportImportService for a Flutter skincare tracker using the 'archive' package for ZIP.

Export format (ZIP):
- manifest.json: { "exportVersion": "1", "exportDate": ISO string, "appVersion": "1.0.0", "contentVersion": "..." }
- user_data.json: UserDataExport as JSON (dart:convert jsonEncode)
- photos/{key}.jpg: raw bytes for each photo key in skinLogs[].photoPaths

class ExportImportService {
  final UserDataRepository _userRepo;
  final PhotoRepository _photoRepo;
  final SettingsRepository _settings;

  Future<Uint8List> exportToArchive() async {
    final export = await _userRepo.exportAllData();
    final archive = Archive();
    // Add manifest.json
    // Add user_data.json (jsonEncode(export.toJson()))
    // For each unique photo key in export.skinLogs.photoPaths:
    //   bytes = await _photoRepo.readPhoto(key)
    //   if bytes != null: archive.addFile(ArchiveFile('photos/$key.jpg', bytes.length, bytes))
    final zipBytes = ZipEncoder().encode(archive)!;
    await _settings.setLastExportDate(DateTime.now().toIso8601String());
    return Uint8List.fromList(zipBytes);
  }
}

class ArchiveValidationResult {
  final bool isValid;
  final String? errorMessage;
  final UserDataExport? data;
  final Map<String, Uint8List> photos; // key → bytes
}

ArchiveValidationResult validateArchive(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile('manifest.json'); // must exist
    final dataFile = archive.findFile('user_data.json');    // must exist
    if (manifestFile == null || dataFile == null) return ArchiveValidationResult(isValid: false, ...);
    final export = UserDataExport.fromJson(jsonDecode(utf8.decode(dataFile.content)));
    final photos = <String, Uint8List>{};
    for (final f in archive.files.where((f) => f.name.startsWith('photos/'))) {
      final key = f.name.replaceFirst('photos/', '').replaceAll('.jpg', '');
      photos[key] = Uint8List.fromList(f.content);
    }
    return ArchiveValidationResult(isValid: true, data: export, photos: photos);
  } catch (e) { return ArchiveValidationResult(isValid: false, errorMessage: e.toString()); }
}

Future<void> replaceAll(ArchiveValidationResult validated) async {
  await _userRepo.replaceAllData(validated.data!);
  for (final e in validated.photos.entries) { await _photoRepo.savePhoto(e.key, e.value); }
}

// MergeSession: builds conflict list (records with different lastModified), exposes nextConflict(), resolveConflict(useArchive: bool)
class MergeSession { ... }
Future<MergeSession> startMerge(ArchiveValidationResult validated) async { ... }

Add UserDataExport.toJson() and UserDataExport.fromJson() methods.
Write basic unit tests for export round-trip. flutter test passes.
```

---

## Phase 5: Providers + Shared Widgets

### TASK-018: Riverpod Providers
**Description**: Wire all repositories and services into Riverpod providers accessible throughout the app.
**Depends On**: TASK-009, TASK-010, TASK-011, TASK-012, TASK-013, TASK-014, TASK-015, TASK-016, TASK-017
**Files to Create/Modify**:
- `lib/shared/providers/root_providers.dart`
- Update `lib/main.dart` to initialize database and override providers

**Acceptance Criteria**:
- [ ] `masterContentProvider` is a `FutureProvider<MasterContent>` that loads on app start
- [ ] `appDatabaseProvider` is a `Provider<AppDatabase>` (singleton, initialized in `main`)
- [ ] `routineResolverProvider` is a `Provider<RoutineResolver>`
- [ ] `streakCalculatorProvider` is a `Provider<StreakCalculator>`
- [ ] `incompatibilityCheckerProvider` is a `Provider<IncompatibilityChecker>`
- [ ] `dailyRoutineProvider(date, slot)` is a `StreamProvider` computing resolved products
- [ ] `effectiveDateProvider` is a `Provider<DateTime>` (DayBoundaryService.todayEffectiveDate)

**Context Files**:
- `doc/ARCHITECTURE.md` (§8 UI-Relevant Contracts — State Providers table)

**Prompt**:
```
Wire Riverpod providers for a Flutter skincare tracker.
Stack: flutter_riverpod ^2.5, all repositories and services implemented.

lib/shared/providers/root_providers.dart:

// Database (singleton — initialized in main.dart override)
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

// Repositories
final masterContentRepositoryProvider = Provider<MasterContentRepository>((ref) =>
  MasterContentRepositoryImpl());

final userDataRepositoryProvider = Provider<UserDataRepository>((ref) =>
  UserDataRepositoryImpl(ref.watch(appDatabaseProvider)));

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) =>
  SettingsRepositoryImpl());

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  if (kIsWeb) return PhotoRepositoryWebStub();
  return PhotoRepositoryAndroid();
});

// Services
final dayBoundaryServiceProvider = Provider((ref) => DayBoundaryService());
final routineResolverProvider = Provider((ref) => RoutineResolver());
final streakCalculatorProvider = Provider((ref) => StreakCalculator());
final incompatibilityCheckerProvider = Provider((ref) => IncompatibilityChecker());
final reconciliationServiceProvider = Provider((ref) => ReconciliationService(
  ref.watch(masterContentRepositoryProvider),
  ref.watch(userDataRepositoryProvider),
  ref.watch(settingsRepositoryProvider),
));
final exportImportServiceProvider = Provider((ref) => ExportImportService(
  ref.watch(userDataRepositoryProvider),
  ref.watch(photoRepositoryProvider),
  ref.watch(settingsRepositoryProvider),
));

// Derived async providers
final masterContentProvider = FutureProvider<MasterContent>((ref) =>
  ref.watch(masterContentRepositoryProvider).load());

final effectiveDateProvider = Provider<DateTime>((ref) =>
  ref.watch(dayBoundaryServiceProvider).todayEffectiveDate);

// Per-day routine (family provider)
final dailyRoutineProvider = StreamProvider.family<List<MasterProduct>, ({String date, Slot slot})>(
  (ref, params) async* {
    // combine: masterContent + selections + schedules + orderOverride → resolve
    // yield resolved products
  }
);

Update lib/main.dart to initialize AppDatabase and use ProviderScope overrides:
  final db = openDatabase();
  runApp(ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(db)], child: SkincareApp()));
```

---

### TASK-019: RoutineItemRow Widget (S5)
**Description**: Implement the core reusable routine row widget with all 4 variants: collapsed, expanded, deprecated, and draggable.
**Depends On**: TASK-002, TASK-003, TASK-004
**Files to Create/Modify**:
- `lib/shared/widgets/routine_item_row.dart`

**Acceptance Criteria**:
- [ ] Collapsed state: shows product name (bidi-safe) + toggle checkbox + expand chevron
- [ ] Expanded state: shows image (or placeholder), admin comment, deprecation notice if deprecated
- [ ] Deprecated variant: shows "לא מומלץ" badge; expanded shows explanation notice
- [ ] Drag variant: shows drag handle `⣿` instead of checkbox (used in S3)
- [ ] Product name uses `Directionality(textDirection: TextDirection.ltr, child: Text(name))` if the name is a Latin-only brand, otherwise auto-bidi
- [ ] Toggle checkbox uses distinct visual for "own" (S1) vs "done" (S4/S7) via `isOwnershipContext` bool

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S5 Routine Item Component)
- `lib/core/theme/app_colors.dart`

**Prompt**:
```
Implement the RoutineItemRow widget for a Flutter skincare tracker.
Stack: Flutter, Radiant Dew theme (AppColors available), RTL layout.

lib/shared/widgets/routine_item_row.dart:

class RoutineItemRow extends StatefulWidget {
  final MasterProduct product;
  final bool isToggled;       // "owned" in S1; "done" in S4/S7
  final VoidCallback onToggle;
  final bool isOwnershipContext; // true=S1 own/not-own; false=S4/S7 done/undone
  final bool isDraggable;        // true=S3 drag mode
  final bool hasConflict;
  final VoidCallback? onConflictTap; // opens bottom sheet
  const RoutineItemRow({...});
}

Collapsed state layout (RTL-aware, use Row with appropriate alignment):
  [toggle/drag-handle] [product-name(bidi)] [conflict-icon?] [deprecated-badge?] [expand-chevron]

Expanded state (AnimatedSize or AnimatedCrossFade):
  Above + below expansion:
    Row: [image 80x80 rounded 16px] [comment text in body-md style]
  If deprecated: yellow-ish notice container "מוצר זה אינו מומלץ עוד"

Product name BiDi handling:
  - Detect if name is likely Latin-only (all ASCII): wrap in Directionality(ltr)
  - Otherwise: let Flutter Unicode BiDi handle naturally (don't force direction)
  - Helper: bool _isLikelyLatin(String s) => s.codeUnits.every((c) => c < 128)

Toggle visual:
  - isOwnershipContext && isToggled: filled peach checkbox icon
  - !isOwnershipContext && isToggled: checkmark in primary color
  - Not toggled: outline checkbox
  Use Checkbox widget or custom InkWell + Icon.

Drag mode: replace toggle with ReorderableDragStartListener child (Icon(Icons.drag_indicator)).

Conflict icon: if hasConflict && !isDraggable: show Icons.warning_amber in tertiary color; onTap = onConflictTap.

Deprecated badge: "לא מומלץ" small chip in error-container color (AppColors.errorContainer).

Use Semantics for accessibility: label includes product name + done/not-done state.
```

---

### TASK-020: Shared Utility Widgets
**Description**: Implement all remaining shared widgets used across multiple screens.
**Depends On**: TASK-002, TASK-003, TASK-019
**Files to Create/Modify**:
- `lib/shared/widgets/soft_warning_banner.dart`
- `lib/shared/widgets/slot_section_header.dart`
- `lib/shared/widgets/category_header.dart`
- `lib/shared/widgets/weekday_picker.dart`
- `lib/shared/widgets/completion_indicator.dart`
- `lib/shared/widgets/streak_widget.dart`

**Acceptance Criteria**:
- [ ] `SoftWarningBanner`: displays Hebrew message; optional "השתק" mute action; ✕ dismiss; uses glassmorphism surface
- [ ] `SlotSectionHeader`: shows slot icon + Hebrew label + expand/collapse chevron; morning=secondary color, evening=tertiary color
- [ ] `CategoryHeader`: verbatim admin label (bidi-safe); subtle divider line
- [ ] `WeekdayPicker`: 7 toggles, Sunday first (labels: א' ב' ג' ד' ה' ו' ש'), shows over-cap warning when exceeded
- [ ] `CompletionIndicator`: renders 5 states (complete, partial, missed, future, noData) with BOTH color and shape cue
- [ ] `StreakWidget`: shows current + longest streak with flame/star icons; optional weekly miss budget bar

**Context Files**:
- `doc/UI_DESIGN.md` (§3 Component Library, §3 S10 Streak Display)
- `lib/core/theme/app_colors.dart`

**Prompt**:
```
Implement 6 shared utility widgets for a Flutter skincare tracker.
Use Radiant Dew AppColors, AppTypography, RTL-aware layouts.

1. SoftWarningBanner:
   Container with glassmorphism (AppColors.glassFill bg, blur if possible),
   Row: [Icons.warning_amber] [message Text flexible] [mute Button? if onMute!=null] [dismiss IconButton]
   Props: String message, VoidCallback? onMute, VoidCallback? onDismiss

2. SlotSectionHeader:
   Props: Slot slot, bool isExpanded, VoidCallback onToggle, int productCount
   Morning: secondary color icon (sun) + 'בוקר'; Evening: tertiary icon (moon) + 'ערב'
   Trailing: expand/collapse chevron + productCount badge

3. CategoryHeader:
   Props: String categoryName (verbatim, may be Latin)
   Divider + Text in label-md style, bidi-safe (same BiDi logic as RoutineItemRow)

4. WeekdayPicker:
   Props: Set<int> selectedDays (0=Sun), ValueChanged<Set<int>> onChanged, int maxDays, bool showOverCapWarning
   7 chip buttons labeled ['א׳','ב׳','ג׳','ד׳','ה׳','ו׳','ש׳'] (Sun first, indices 0-6)
   Selected chip: primary-container; not selected: surface-container
   If selectedDays.length > maxDays: show SoftWarningBanner for over-cap

5. CompletionIndicator:
   Props: DayCompletionState state, double size=24
   complete → ● filled circle in secondaryContainer (#EDE282)
   partial → ◑ half-circle in tertiaryContainer (#DE99A4)
   missed → ✗ in errorContainer (#FFDAD6)
   future → □ in surfaceContainer (#FFE9E4)
   noData → transparent/empty
   Use CustomPainter or Icon + Color for each state.

6. StreakWidget:
   Props: int currentStreak, int longestStreak, int missesThisWeek, int graceBudget=3
   Glassmorphism card; Row with two stat columns: 🔥 currentStreak + label, ⭐ longestStreak + label
   Optional: progress bar for missesThisWeek / graceBudget in lemon color
```

---

## Phase 6: Setup Flow Screens

### TASK-021: S1 Product Selection Screen
**Description**: Implement the product selection screen (setup step 1) with slot tabs, category groups, ownership toggles, and daily incompatibility warnings.
**Depends On**: TASK-018, TASK-019, TASK-020
**Files to Create/Modify**:
- `lib/features/setup/selection/product_selection_screen.dart`
- `lib/features/setup/selection/product_selection_providers.dart`

**Acceptance Criteria**:
- [ ] Two slot tabs (Morning/Evening) switch the displayed product list
- [ ] Products grouped under category headers, in admin order, deprecated products excluded
- [ ] Tapping a product row toggles ownership (calls `UserDataRepository.upsertSelection`)
- [ ] Daily↔daily incompatibility warnings shown as `SoftWarningBanner` with "השתק" mute action
- [ ] "המשך" button navigates to S2 (if any occasional products) or S4

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S1 Product Selection wireframe)
- `lib/shared/widgets/routine_item_row.dart`

**Prompt**:
```
Implement the Product Selection screen (S1) for a Flutter skincare tracker.
Stack: Flutter, Riverpod, existing providers and widgets.

Screen: ProductSelectionScreen (StatefulWidget or ConsumerWidget)
Route: /setup/selection

UI layout (RTL):
  AppBar: title "בחירת מוצרים" + optional step indicator
  Tab bar: Morning tab | Evening tab (use DefaultTabController or TabController)
  Body per tab:
    ListView of category sections:
      For each category in master content:
        CategoryHeader(categoryName)
        For each non-deprecated product in that category + slot:
          RoutineItemRow(product, isToggled=isSelected, isOwnershipContext=true, onToggle=toggleSelection)
  Bottom fixed: [conflict banners if any] + "המשך" button

Providers to create (product_selection_providers.dart):
  - `selectionsProvider(Slot)`: watch UserDataRepository.watchSelections(slot) → Set<String> selectedIds
  - `dailyConflictsProvider(Slot)`: use IncompatibilityChecker.getConflictsForSelection on daily products
  - `mutedConflictsProvider`: watch UserDataRepository.watchMutedConflicts()

Actions:
  toggleSelection(productId, slot): upsertSelection with toggled isSelected
  muteConflict(ruleId): UserDataRepository.muteConflict(MutedConflict(ruleId))
  onContinue: if any selected product has WeeklyMaxRule → navigate to /setup/schedule
               else → navigate to /today

Display SoftWarningBanner for each unmuted daily↔daily conflict detected.
"השתק" on banner calls muteConflict for that ruleId.

After continue → also navigate if called from Settings (S11) back to /settings.
Track whether entry was from setup wizard or settings via route extra parameter.
```

---

### TASK-022: S2 Schedule Setup Screen
**Description**: Implement the schedule setup screen (step 2) with per-product weekday pickers, over-cap warnings, and day-dependent incompatibility warnings.
**Depends On**: TASK-021
**Files to Create/Modify**:
- `lib/features/setup/schedule/schedule_setup_screen.dart`
- `lib/features/setup/schedule/schedule_providers.dart`

**Acceptance Criteria**:
- [ ] Only shows occasional (WeeklyMax) products from the user's selection
- [ ] Each product has a `WeekdayPicker` with over-cap detection
- [ ] Day-dependent conflict warnings appear when schedules cause clashes
- [ ] Schedule saved immediately on toggle change (reactive)
- [ ] "המשך" navigates to S3 (order) or S4

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S2 Schedule Setup wireframe)
- `lib/shared/widgets/weekday_picker.dart`

**Prompt**:
```
Implement the Schedule Setup screen (S2) for a Flutter skincare tracker.
Stack: Flutter, Riverpod.

Screen: ScheduleSetupScreen
Route: /setup/schedule

Logic:
  Fetch selected products (both slots) from UserDataRepository.
  Filter to those with WeeklyMaxRule frequency.
  For each such product, show:
    - Product name (bidi-safe)
    - Admin cap label: "מומלץ: עד {maxPerWeek} פעמים בשבוע"
    - WeekdayPicker(selectedDays=currentSchedule, maxDays=rule.maxPerWeek, onChanged=saveSchedule, showOverCapWarning=auto)

Day-dependent conflicts:
  After each schedule change, call IncompatibilityChecker.getConflictsForSchedule
  (you'll need to add this method: check if any occasional+occasional or occasional+daily products
  will share the same day given current schedules).
  Show SoftWarningBanner per conflict.

saveSchedule(productId, slot, weekdays):
  UserDataRepository.upsertSchedule(WeekdaySchedule(id: uuid, productId, slot, weekdays, lastModified: now))

Slot: products from both Morning and Evening slots shown, grouped by slot using SlotSectionHeader.

Continue button: navigate to /setup/order

If reached from Settings (S11), back button returns to /settings.
```

---

### TASK-023: S3 Order Customization Screen
**Description**: Implement the drag-to-reorder screen with reset-to-admin-order action.
**Depends On**: TASK-022, TASK-019
**Files to Create/Modify**:
- `lib/features/setup/ordering/order_customization_screen.dart`
- `lib/features/setup/ordering/order_providers.dart`

**Acceptance Criteria**:
- [ ] Flutter `ReorderableListView` for drag-to-reorder per slot
- [ ] Override indicator shown when custom order is active
- [ ] "אפס לסדר מומלץ" clears the override
- [ ] Order saved to `UserDataRepository.upsertOrderOverride` on reorder
- [ ] "סיים" navigates to S4 (or back to settings)

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S3 Order Customization wireframe)

**Prompt**:
```
Implement the Order Customization screen (S3) for a Flutter skincare tracker.

Screen: OrderCustomizationScreen
Route: /setup/order

UI:
  Tab bar: Morning | Evening
  Per tab:
    If orderOverride active: SoftWarningBanner("סדר מותאם אישית פעיל", with action "אפס לסדר מומלץ")
    ReorderableListView.builder:
      Items: RoutineItemRow(product, isDraggable: true)
      onReorder: save new order to UserDataRepository.upsertOrderOverride

Providers:
  Watch watchOrderOverride(slot) for each slot.
  Watch resolved product list for each slot (in effective order).

onReorder callback:
  1. Take current product ID list
  2. Move item from old index to new index
  3. Call upsertOrderOverride(OrderOverride(id: uuid, slot, orderedProductIds: newOrder, lastModified: now))

Reset action:
  Call deleteById on the OrderOverride for that slot (or upsert with empty orderedProductIds).

"סיים" button: navigate to /today

Keyboard accessibility: ReorderableListView supports keyboard reorder by default (Flutter built-in).
```

---

## Phase 7: Daily Use Screens

### TASK-024: S4 Daily Home Screen
**Description**: Implement the primary daily screen showing today's resolved routine with done-toggles, streak widget, and conflict/deprecation markers.
**Depends On**: TASK-018, TASK-019, TASK-020
**Files to Create/Modify**:
- `lib/features/daily_home/daily_home_screen.dart`
- `lib/features/daily_home/daily_home_providers.dart`

**Acceptance Criteria**:
- [ ] Shows today's effective date (respecting 6am boundary) using `DayBoundaryService`
- [ ] Morning and Evening sections; each collapsible
- [ ] `RoutineItemRow` shown for each product; done-toggle calls `updateDayRecord`
- [ ] `StreakWidget` shown at top
- [ ] Snapshot DayRecord created on first view via `snapshotAndGetDayRecord`
- [ ] Conflict markers (⚠️) shown per conflicting product
- [ ] Deprecation marker on deprecated products
- [ ] Empty slot state: "אין מוצרים מתוכננים להיום"
- [ ] S16 backup reminder banner shown when applicable

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S4 Daily Home wireframe, §3 S10 Streak widget)
- `lib/shared/widgets/streak_widget.dart`

**Prompt**:
```
Implement the Daily Home screen (S4 + S10) for a Flutter skincare tracker.
This is the primary screen — route /today.

Screen: DailyHomeScreen (ConsumerStatefulWidget)

On build:
  1. effectiveDate = ref.watch(effectiveDateProvider)
  2. For each slot, watch dailyRoutineProvider((date: formatDate(effectiveDate), slot: slot))
  3. For each slot, watch dayRecordProvider(date, slot)
  4. Snapshot: on first load, if no DayRecord for today+slot, call snapshotAndGetDayRecord

UI structure:
  AppBar: date text (Quicksand headline-md) + skin-log icon button (right, → /skin-log/:date)
  StreakWidget (watch streakProvider)
  For each slot (Morning, Evening):
    SlotSectionHeader(slot, isExpanded, onToggle: expand/collapse)
    AnimatedList/ListView of RoutineItemRow for resolved products
      isToggled = productId in dayRecord.recordedProductIds
      onToggle = toggleDone(date, slot, productId)
      hasConflict = productId appears in conflictsForDay
      onConflictTap = show bottom sheet with conflict detail
      isDeprecated = product.isDeprecated
  If slot empty: padding + Text(AppLocalizations.of(context).emptyRoutine)
  Pre-6am notice: if DateTime.now().hour < 6, show Text(AppLocalizations.of(context).before6amNote)
  S16 Backup reminder banner: watch settingsProvider.lastExportDate
    if null or > 30 days ago: show SoftWarningBanner

Actions:
  toggleDone(date, slot, productId):
    currentRecord = current DayRecord
    updated = currentRecord.copyWith(recordedProductIds: toggle productId in/out of list)
    userDataRepository.updateDayRecord(updated)

Streak provider: watch all DayRecords, compute StreakCalculator.compute(asOf: now).
```

---

### TASK-025: S8 Skin Log Entry Screen
**Description**: Implement the skin log entry screen with free-text notes and multi-photo capture/selection.
**Depends On**: TASK-018, TASK-011
**Files to Create/Modify**:
- `lib/features/skin_log/entry/skin_log_entry_screen.dart`

**Acceptance Criteria**:
- [ ] Text field pre-filled with existing notes (if editing)
- [ ] Photo grid shows existing photos; add button opens ImagePicker
- [ ] Photos compressed via `flutter_image_compress` before saving via `PhotoRepository`
- [ ] On save: `UserDataRepository.upsertSkinLog(entry)`
- [ ] Web-only: shows storage warning banner

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S8 Skin Log Entry wireframe)

**Prompt**:
```
Implement the Skin Log Entry screen (S8) for a Flutter skincare tracker.
Route: /skin-log/:date — date param is the effective date 'YYYY-MM-DD'.
Stack: Flutter, image_picker, flutter_image_compress, PhotoRepository.

Screen: SkinLogEntryScreen(date: String)
  Load existing SkinLogEntry for date via watchSkinLog(date).
  If exists: pre-fill notes and show existing photos.

UI:
  AppBar: "יומן עור — {formatted date}" + "שמור" action button (leading in RTL = right side)
  TextFormField (multiline, hint "איך העור שלך היום?", RTL)
  "── תמונות ──" section header
  GridView of photo thumbnails (3 columns) + add button (+ icon)
  Row: [camera button "📷 צלמי"] [gallery button "🖼️ בחרי מגלריה"]
  Web only: SoftWarningBanner with AppLocalizations.webStorageWarning

Photo actions:
  pickImage(ImageSource source) async:
    XFile? file = await ImagePicker().pickImage(source: source)
    if file == null return
    Uint8List bytes = await file.readAsBytes()
    compressed = await FlutterImageCompress.compressWithList(bytes, minWidth:1080, minHeight:1080, quality:85)
    key = uuid.v4()
    await photoRepository.savePhoto(key, compressed)
    addPhotoKeyToCurrentEntry(key)

Long-press photo thumbnail → show delete option → deletePhoto(key) + remove from entry.

Save action:
  entry = SkinLogEntry(id: existing.id ?? uuid.v4(), date, notes: textController.text, photoPaths: currentKeys, lastModified: now)
  await userDataRepository.upsertSkinLog(entry)
  Navigator.pop(context)
```

---

### TASK-026: S9 Skin Journal Screen
**Description**: Implement the chronological skin photo gallery.
**Depends On**: TASK-018, TASK-011, TASK-025
**Files to Create/Modify**:
- `lib/features/skin_log/journal/skin_journal_screen.dart`

**Acceptance Criteria**:
- [ ] Shows all skin log entries with photos, grouped by month
- [ ] Photos displayed in a 3-column grid with date label
- [ ] Empty state: warm message with CTA to S8
- [ ] Tap photo → full-screen viewer with date; "ערוך רשומה" → S8

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S9 Skin Journal wireframe)

**Prompt**:
```
Implement the Skin Journal screen (S9) for a Flutter skincare tracker.
Route: /journal (bottom nav tab)

Screen: SkinJournalScreen (ConsumerWidget)
Watch: userDataRepository.watchAllSkinLogs() → sorted by date DESC

Group entries by month ('YYYY-MM'). For each month group:
  Section header: month name in Hebrew (use intl DateFormat with 'he' locale: DateFormat.yMMMM('he').format(date))
  GridView.builder (crossAxisCount: 3, childAspectRatio: 1):
    For each photo key in entry.photoPaths:
      FutureBuilder reading photoRepository.readPhoto(key) → Image widget
      Date label below: DateFormat('d.M', 'he').format(date)

Tap photo → showDialog or Navigator.push fullscreen image viewer:
  Full-screen image + date text at top + "ערוך רשומה" button → /skin-log/:date

Empty state (no entries with photos):
  Center column: icon (camera) + Text(AppLocalizations.emptyJournal) + TextButton("📷 " → /skin-log/:today)

Use lazy loading: load photos in FutureBuilder per thumbnail — don't preload all.
```

---

## Phase 8: History Screens

### TASK-027: S6 Calendar Screen
**Description**: Implement the monthly RTL calendar grid with 4 completion states and month navigation.
**Depends On**: TASK-018, TASK-020
**Files to Create/Modify**:
- `lib/features/history/calendar/calendar_screen.dart`
- `lib/features/history/calendar/calendar_providers.dart`

**Acceptance Criteria**:
- [ ] Monthly grid in RTL (Saturday→Sunday columns, right-to-left)
- [ ] Each cell shows `CompletionIndicator` for the appropriate state
- [ ] Month navigation (prev/next) loads the correct month's DayRecords
- [ ] Future dates show `DayCompletionState.future` (non-tappable)
- [ ] Legend shown below grid
- [ ] Tap past/today → navigate to S7

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S6 Calendar wireframe)
- `lib/shared/widgets/completion_indicator.dart`

**Prompt**:
```
Implement the Calendar/History screen (S6) for a Flutter skincare tracker.
Route: /calendar (bottom nav tab). Hebrew RTL layout.

Screen: CalendarScreen (ConsumerStatefulWidget)
State: DateTime _displayedMonth (initially current month)

Providers:
  monthRecordsProvider(yearMonth: String): watch DayRecordsDao.watchForMonth('YYYY-MM')
    → compute DayCompletionState for each date in month

Compute state for a date:
  morningRecord = DayRecord for (date, morning)
  eveningRecord = DayRecord for (date, evening)
  if date is in future → future
  morningDone = morningRecord?.recordedProductIds.isNotEmpty ?? false (if record has resolved products)
  eveningDone = eveningRecord?.recordedProductIds.isNotEmpty ?? false
  morningScheduled = morningRecord?.resolvedProductIds.isNotEmpty ?? false
  eveningScheduled = eveningRecord?.resolvedProductIds.isNotEmpty ?? false
  if morningDone && (!eveningScheduled || eveningDone) → complete
  if morningDone || eveningDone → partial
  if morningScheduled || eveningScheduled → missed
  else → noData

Grid layout:
  Row of day headers: ['ש','ו','ה','ד','ג','ב','א'] (Sat first in RTL reading order = leftmost column)
  Wait — RTL order: the FIRST column on the right = Sunday (א'), then Mon (ב') ... Sat (ש') on far left
  Correct RTL day header order (left-to-right visually): ש' | ו' | ה' | ד' | ג' | ב' | א'
  GridView 7 columns; compute first day of month offset from Sunday.

Month navigation:
  AppBar with prev/next IconButtons + month+year label in Hebrew

Legend row: ● שלם | ◑ חלקי | ✗ הוחמץ | □ עתידי

Tap on past or today → Navigator.push to /day/:date
```

---

### TASK-028: S7 Day Detail Screen
**Description**: Implement the day detail screen showing the historical routine, done-toggles, and skin log for a specific past day.
**Depends On**: TASK-027, TASK-025
**Files to Create/Modify**:
- `lib/features/history/day_detail/day_detail_screen.dart`

**Acceptance Criteria**:
- [ ] Shows the routine as it was that day (from DayRecord.resolvedProductIds — the historical snapshot)
- [ ] Done toggles are editable (same toggle logic as S4)
- [ ] Skin log shown if present; "ערוך יומן עור" → S8
- [ ] Slot completion badge (✓ שלם / ◑ חלקי) per slot
- [ ] Historical note shown if DayRecord exists from snapshot
- [ ] Deprecated products from history still render

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S7 Day Detail wireframe)
- `lib/shared/widgets/routine_item_row.dart`

**Prompt**:
```
Implement the Day Detail screen (S7) for a Flutter skincare tracker.
Route: /day/:date (date = 'YYYY-MM-DD')

Screen: DayDetailScreen(date: String)
Load: watchDayRecord(date, morning) + watchDayRecord(date, evening) + watchSkinLog(date)
Also load masterContent to resolve product details from resolvedProductIds.

Display logic:
  For each slot: 
    resolved products = look up each id in dayRecord.resolvedProductIds against master content
    show SlotSectionHeader + list of RoutineItemRow for resolved products
    isToggled = productId in dayRecord.recordedProductIds
    onToggle = updateDayRecord toggle (same as S4)
    slot completion badge next to SlotSectionHeader: if all resolved are recorded → "שלם", some → "חלקי"
    
  If dayRecord is null for a slot: show "אין רשומה — מוצגים המוצרים הנוכחיים" notice
    and resolve current products instead (with note that this is not historical)

Skin log section:
  If SkinLogEntry exists: show notes text + photo thumbnails
    "ערוך יומן עור" button → /skin-log/:date
  If not: "אין רשומה ביומן עור" + "הוסיפי רשומה" CTA → /skin-log/:date

Historical note below:
  Text("הנתונים מ-{date} מבוססים על הבחירות שהיו תקפות באותה עת", style: caption)

AppBar: formatted date in Hebrew (use intl DateFormat)
Back button: Navigator.pop
```

---

## Phase 9: Data Management & Settings

### TASK-029: S12 Export/Import Screen (Export + Replace)
**Description**: Implement the export screen and import-Replace flow.
**Depends On**: TASK-017, TASK-018
**Files to Create/Modify**:
- `lib/features/data_management/export_import/export_import_screen.dart`
- `lib/features/data_management/export_import/export_import_notifier.dart`

**Acceptance Criteria**:
- [ ] "ייצא עכשיו" button calls `ExportImportService.exportToArchive()` + `share_plus` share
- [ ] Last backup date displayed from `SettingsRepository.getLastExportDate()`
- [ ] File picker for import; Replace chosen → confirmation dialog → `replaceAll()`
- [ ] Import validation error displayed in Hebrew if archive is invalid
- [ ] Merge option navigates to S12 merge resolver (TASK-030)

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S12 Export/Import wireframe)

**Prompt**:
```
Implement the Export/Import screen (S12) for a Flutter skincare tracker.
Route: /export-import

Screen: ExportImportScreen (ConsumerStatefulWidget)
Notifier: ExportImportNotifier (StateNotifier with states: idle, exporting, importing, error, success)

EXPORT SECTION:
  Watch: settingsRepository.getLastExportDate() → show "גיבוי אחרון: {date}" or "לא בוצע גיבוי"
  "ייצא עכשיו" button (primary peach pill):
    state = exporting → show CircularProgressIndicator
    bytes = await exportImportService.exportToArchive()
    filename = "skincare_backup_${date}.zip"
    await Share.shareXFiles([XFile.fromData(bytes, name: filename, mimeType: 'application/zip')])
    state = idle; refresh lastExportDate

IMPORT SECTION:
  Radio buttons: ○ החלפה | ○ מיזוג (default: merge)
  "בחרי קובץ" button → FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip'])
  On file selected: validate archive
  If invalid: show error banner in Hebrew
  If valid:
    Show file name selected
    "ייבא" button enabled

  On "ייבא" with Replace selected:
    showDialog(confirm replace — "פעולה זו תמחק את כל הנתונים. להמשיך?")
    Confirmed: replaceAll(validated)
    Show success snackbar, navigate back to /settings

  On "ייבא" with Merge:
    Navigate to merge resolver screen (push /export-import/merge with validated data)
```

---

### TASK-030: S12 Merge Conflict Resolver
**Description**: Implement the sequential per-conflict chooser UI for the import Merge flow.
**Depends On**: TASK-029
**Files to Create/Modify**:
- `lib/features/data_management/export_import/merge_resolver_screen.dart`

**Acceptance Criteria**:
- [ ] Shows "התנגשות N מתוך Total" progress
- [ ] Two-column comparison: archive version vs local version
- [ ] "בחרי גיבוי" and "בחרי מכשיר" buttons
- [ ] Navigates to next conflict or completes
- [ ] Cancel ("בטל") dismisses with confirmation

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S12 Merge conflict resolver wireframe)

**Prompt**:
```
Implement the Merge Conflict Resolver screen for a Flutter skincare tracker.
Route: /export-import/merge (receives MergeSession as extra)

Screen: MergeResolverScreen(MergeSession session)

State: track currentConflictIndex, total = session.conflicts.length

For each conflict:
  AppBar: "בטל" (left/trailing in RTL) + progress "התנגשות {index+1} מתוך {total}"
  
  Conflict display (two Column widgets side by side):
    Left column header: "מהמכשיר"   Right column header: "מהגיבוי"  (RTL: right=start)
    Show a human-readable description of the conflicting record:
      For DayRecord: "יום {date} — {slot}"
      List recorded products (by name lookup in master content)
      Show lastModified timestamp for each version

  Two buttons row:
    "בחרי גיבוי ←" (primary) | "בחרי מכשיר ←" (secondary)

  onChooseArchive: session.resolveConflict(useArchive: true); next()
  onChooseDevice: session.resolveConflict(useArchive: false); next()

  next():
    if more conflicts: currentConflictIndex++; rebuild
    else: await session.complete(); show success snackbar; pop back to /settings

Cancel button: showDialog("ביטול המיזוג — כל הנתונים יישמרו ללא שינוי"); on confirm: session.cancel(); pop
```

---

### TASK-031: S13 About/What's New Screen
**Description**: Implement the about screen showing version info and changelog.
**Depends On**: TASK-018, TASK-009
**Files to Create/Modify**:
- `lib/features/about/about_screen.dart`

**Acceptance Criteria**:
- [ ] Shows app name, version, and master-list content version
- [ ] Changelog entries rendered per version in reverse-chronological order
- [ ] Product names in changelog rendered bidi-safe
- [ ] No "update now" button (deliberate)

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S13 About/What's New wireframe)

**Prompt**:
```
Implement the About/What's New screen (S13) for a Flutter skincare tracker.
Route: /about

Screen: AboutScreen (ConsumerWidget)
Watch: masterContentProvider

UI:
  AppBar: "אודות / מה חדש"
  
  Section 1 — App identity:
    Row: app icon (placeholder circle in primary color) + Column[
      Text("Skincare Routine Tracker", style: headlineMd)
      Text("גרסה {packageInfo.version} | רשימת מוצרים v{manifest.contentVersion}", style: labelMd)
    ]

  Section 2 — Changelog:
    ListView of masterContent.manifest.changelog (reversed — newest first):
      For each ChangelogEntry:
        Text("📦 גרסה {entry.contentVersion}", style: bodyLg, bold)
        For each change string:
          Row: [•] [Text(change, bidi-safe — changes may mention product names)]

  Note: do NOT add an "update now" button or any app-store link. Deliberate omission.

  Use PackageInfo.fromPlatform() (add package_info_plus to pubspec) to get app version.
  Or hardcode version string from manifest.appVersion if package_info_plus isn't added yet.
```

---

### TASK-032: S14 Update Review Screen
**Description**: Implement the post-update review screen shown on first launch after a master-list version change.
**Depends On**: TASK-016, TASK-018
**Files to Create/Modify**:
- `lib/features/update_review/update_review_screen.dart`
- Update `lib/app.dart` to check ReconciliationService on startup and redirect to /update-review if needed

**Acceptance Criteria**:
- [ ] Shown automatically on first run after content version change
- [ ] Data-intact confirmation displayed prominently
- [ ] New (unselected) products shown with ownership toggle
- [ ] Newly deprecated selected products shown with remove/keep option
- [ ] "ייצא עכשיו" shortcut to export
- [ ] "המשך" acknowledges update and navigates to /today

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S14 Update Review wireframe)

**Prompt**:
```
Implement the Update Review screen (S14) for a Flutter skincare tracker.
Route: /update-review (pushed before /today if update detected)

Startup check (in app.dart or a startup provider):
  On app start (after masterContentProvider loads):
  reconciliationResult = await reconciliationService.reconcile()
  if reconciliationResult.isUpdateDetected:
    navigate to /update-review with result as extra
  else:
    continue to /today normally

Screen: UpdateReviewScreen(ReconciliationResult result)

UI:
  No back button (must complete review)
  AppBar: "עדכון הושלם! 🎉"
  
  Section: "✅ כל הנתונים שלך שמורים ובשלמותם" (prominent, green/success color)
  
  if result.newProducts.isNotEmpty:
    Section header: "── מוצרים חדשים ──"
    Info text: "לא נוספו לשגרה — בחרי אם תרצי"
    For each new product: RoutineItemRow(isOwnershipContext: true, onToggle: add/remove selection)
  
  if result.newlyDeprecatedSelected.isNotEmpty:
    Section header: "── מוצרים שהוצאו משימוש ──"
    For each deprecated product: card with product name + "לא מומלץ עוד"
      Row: [הסירי button → remove from selection] [השארי button → do nothing]
  
  Backup offer:
    Card: "💾 גבי את הנתונים לפני השינויים"
    "ייצא עכשיו →" button → trigger export then return

  "המשך" button:
    await reconciliationService.acknowledgeUpdate(result.currentContentVersion)
    navigate to /today (clear back stack)
```

---

### TASK-033: S16 Backup Reminder + S11 Settings Hub
**Description**: Implement the backup reminder banner (S16) integrated into S4, and the Settings hub screen (S11).
**Depends On**: TASK-029, TASK-031, TASK-032, TASK-021, TASK-022, TASK-023
**Files to Create/Modify**:
- `lib/features/backup_reminder/backup_reminder_widget.dart`
- `lib/features/settings/settings_screen.dart`

**Acceptance Criteria**:
- [ ] `BackupReminderWidget` shown at bottom of S4 when no backup in 30+ days (7 days on Web)
- [ ] Dismissible per-session (session flag); re-shown next launch if condition persists
- [ ] Tapping "גיבוי" navigates to S12
- [ ] S11 Settings shows 5 entry points (S1, S2, S3, S12, S13) + Web-only S15 link
- [ ] All S11 links navigate to correct routes

**Context Files**:
- `doc/UI_DESIGN.md` (§3 S11 Settings, §3 S16 Backup Reminder)

**Prompt**:
```
Implement BackupReminderWidget (S16) and SettingsScreen (S11).

1. BackupReminderWidget (lib/features/backup_reminder/backup_reminder_widget.dart):
   StatefulWidget with bool _dismissed = false in state.
   Watch: settingsRepository.getLastExportDate()
   Show if: lastExportDate == null OR daysSince > (kIsWeb ? 7 : 30)
   AND !_dismissed

   UI: SoftWarningBanner with:
     message: AppLocalizations.backupReminderMessage (+ web storage warning if kIsWeb)
     onDismiss: setState(() => _dismissed = true)
     Custom action: TextButton("גיבוי" → /export-import)

   Usage: add to S4 DailyHomeScreen widget tree above bottom nav.

2. SettingsScreen (lib/features/settings/settings_screen.dart):
   Route: /settings (bottom nav tab)
   
   UI (RTL list with sections):
   
   Section "השגרה שלי":
     ListTile "ערוך בחירת מוצרים" → /setup/selection (with fromSettings=true extra)
     ListTile "ערוך תזמון" → /setup/schedule
     ListTile "ערוך סדר" → /setup/order

   Section "נתונים":
     ListTile "ייצוא / ייבוא" → /export-import

   Section "פרמיום" (Web only, kIsWeb):
     ListTile "הפעלת רישיון פרמיום" → /premium

   Section "אודות":
     ListTile "גרסה ועדכונים" → /about

   Each ListTile: trailing chevron icon (← direction in RTL = Icons.chevron_left)
   ListTile style: card with 16px radius, 8px vertical padding
```

---

## Phase 10: Platform & Final

### TASK-034: S15 Premium Stub + Web PhotoRepository
**Description**: Implement the deferred premium stub screen and the Web IndexedDB photo storage implementation.
**Depends On**: TASK-011, TASK-033
**Files to Create/Modify**:
- `lib/features/premium/premium_stub_screen.dart`
- `lib/data/local/photo_storage/photo_repository_web.dart`

**Acceptance Criteria**:
- [ ] S15 shows "תכונה זו תהיה זמינה בקרוב" — no functional key entry in v1.0
- [ ] Web PhotoRepository stores photos in IndexedDB using `dart:html` JS interop
- [ ] `savePhoto`, `readPhoto`, `deletePhoto`, `listAllKeys` all work on Web builds
- [ ] `flutter build web` succeeds with Web photo repo implementation

**Context Files**:
- `doc/ARCHITECTURE.md` (§3.3 Storage Strategy — Web row)
- `doc/UI_DESIGN.md` (§3 S15 License Activation stub)

**Prompt**:
```
Implement the Premium stub screen and Web PhotoRepository for a Flutter skincare tracker.

1. PremiumStubScreen (lib/features/premium/premium_stub_screen.dart):
   Route: /premium (visible in S11 on Web only)
   Simple screen: AppBar "הפעלת גיבוי ענן" + Center Text "תכונה זו תהיה זמינה בקרוב" in bodyLg

2. Web PhotoRepository (lib/data/local/photo_storage/photo_repository_web.dart):
   Uses dart:html + IndexedDB API via JS interop.
   Database: 'skincare_photos_db', objectStore: 'photos', key = photo key string

   Implementation:
     Future<Database> _openDb() — open IDB, create objectStore on upgradeneeded
     
     savePhoto(key, bytes): put entry {key: key, data: bytes} in objectStore
     readPhoto(key): get by key → return bytes or null
     deletePhoto(key): delete by key
     listAllKeys(): getAllKeys from objectStore → List<String>

   Use package:idb_shim or raw dart:html IDBDatabase API.
   If idb_shim is available (add to pubspec): use IdbFactory.open().
   Otherwise use dart:html directly with Completer-based JS interop.

   Add conditional import in providers (root_providers.dart):
     import 'photo_repository_android.dart' if (dart.library.html) 'photo_repository_web.dart';
     final photoRepositoryProvider = Provider<PhotoRepository>((ref) => PhotoRepository.create());
     — add static factory method to each implementation.

Verify: flutter build web succeeds.
```

---

### TASK-035: Android + Web Build Configuration
**Description**: Configure Android signing, versionCode, and Web build settings (sqlite3 WASM + PWA manifest). Verify full production builds succeed.
**Depends On**: All prior tasks
**Files to Create/Modify**:
- `android/app/build.gradle`
- `android/key.properties` (documentation only — actual keystore is external)
- `web/manifest.json`
- `web/index.html` (sqlite3 WASM headers)

**Acceptance Criteria**:
- [ ] `flutter build apk --release` succeeds (with debug signing for now; note where to plug in release keystore)
- [ ] `flutter build web --release` succeeds with WASM sqlite3 support
- [ ] `web/manifest.json` has correct Hebrew app name and icons
- [ ] Android `versionCode` starts at 1 and is manually incremented; documented in CLAUDE.md update
- [ ] COOP/COEP headers configured in `web/index.html` (required for SharedArrayBuffer / sqlite3 WASM)

**Context Files**:
- `doc/ARCHITECTURE.md` (§6 Security — Android signing, §11 Risk Assessment)
- `CLAUDE.md` (Android signing requirements)

**Prompt**:
```
Configure Android and Web builds for a Flutter skincare tracker.

ANDROID (android/app/build.gradle):
  android {
    compileSdkVersion 34
    defaultConfig {
      applicationId "com.skincareroutine.tracker"
      minSdkVersion 29   // Android 10 = API 29
      targetSdkVersion 34
      versionCode 1
      versionName "1.0.0"
    }
    signingConfigs {
      release {
        // Configured via key.properties (not committed to git)
        // See android/key.properties.template
      }
    }
    buildTypes {
      release { signingConfig signingConfigs.debug } // placeholder; replace with release config
    }
  }

Create android/key.properties.template with:
  storePassword=<KEYSTORE_PASSWORD>
  keyPassword=<KEY_PASSWORD>
  keyAlias=<KEY_ALIAS>
  storeFile=<PATH_TO_KEYSTORE>
Add android/key.properties to .gitignore.

WEB (web/index.html — for sqlite3 WASM SharedArrayBuffer support):
  Add to <head>:
  <meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">
  <meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">

web/manifest.json:
  {
    "name": "מעקב שגרת טיפוח",
    "short_name": "שגרת טיפוח",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#FFF8F6",
    "theme_color": "#9E412C",
    "description": "מעקב שגרת טיפוח יומית",
    "icons": [{ "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" }]
  }

flutter_service_worker: configure for offline-first (add to web/index.html serviceWorker registration).

Update CLAUDE.md to document: "Every Android release must use the same signing key and strictly increasing versionCode. Current versionCode: 1."

Verify:
  flutter build apk --debug
  flutter build web --release
Both succeed without errors.
```

---

## Dependency Graph

```
TASK-001 (Flutter Init)
├── TASK-002 (Theme) ──────────────────────────────┐
├── TASK-003 (Hebrew RTL) ─────────────────────────┤
├── TASK-004 (App Root + Routing) ← TASK-002,003   │
│   └── (screen tasks start from TASK-021+)        │
│                                                   │
├── TASK-005 (Master Entities) ─────────────────── │──┐
│   ├── TASK-007 (Drift Schema) ← TASK-006         │  │
│   │   └── TASK-008 (DAOs)                        │  │
│   │       └── TASK-010 (UserDataRepo)            │  │
│   │           └── TASK-016 (Reconciliation)      │  │
│   │               └── TASK-017 (Export/Import)   │  │
│   └── TASK-009 (JSON Assets + MasterRepo)        │  │
│       └── TASK-010 ──────────────────────────────┘  │
│                                                      │
├── TASK-006 (User Entities) ──→ TASK-007             │
│                                                      │
├── TASK-011 (Settings + Photo)                        │
│   └── TASK-013 (RoutineResolver) ← TASK-012,010     │
│       └── TASK-014 (IncompatibilityChecker)          │
│           └── TASK-018 (Providers) ←─────────────────┘
│               └── TASK-019 (RoutineItemRow)
│                   └── TASK-020 (Shared Widgets)
│                       ├── TASK-021 (S1) → TASK-022 (S2) → TASK-023 (S3)
│                       ├── TASK-024 (S4) 
│                       ├── TASK-025 (S8) → TASK-026 (S9)
│                       ├── TASK-027 (S6) → TASK-028 (S7)
│                       ├── TASK-029 (S12 Export) → TASK-030 (S12 Merge)
│                       ├── TASK-031 (S13)
│                       ├── TASK-032 (S14) ← TASK-016
│                       └── TASK-033 (S16 + S11) → TASK-034 → TASK-035

TASK-012 (DayBoundary) → TASK-013 → TASK-015 (StreakCalc) → TASK-018
```

## Critical Path
TASK-001 → TASK-005 → TASK-007 → TASK-008 → TASK-010 → TASK-012 → TASK-013 → TASK-018 → TASK-019 → TASK-020 → TASK-021 → TASK-024

**12 tasks** on the critical path.

## Parallelizable Tasks (once their common dependency completes)

After TASK-001:
- TASK-002 (Theme) ‖ TASK-003 (Hebrew RTL) ‖ TASK-005 (Master Entities) ‖ TASK-006 (User Entities)

After TASK-007:
- TASK-008 can start while TASK-009 proceeds independently

After TASK-018 (Providers):
- TASK-019, TASK-020 can start in parallel
- After TASK-020: TASK-021, TASK-024, TASK-025, TASK-027 can all start in parallel

Domain services (TASK-012–016) can all be developed in parallel once repositories are ready.
