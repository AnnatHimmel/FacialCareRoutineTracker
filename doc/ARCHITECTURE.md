# System Architecture
Project: Skincare Routine Tracker
Version: 1.0
Date: 2026-05-26

---

## 1. System Overview

A personal skincare routine tracker built as a single Flutter codebase targeting Android (sideloaded APK) and Web (iPhone/Safari + any browser). An admin encodes expertise as a bundled, read-only master product list; users select their owned products and receive a correctly-ordered daily routine. Tracking is optional and lightweight. All user data lives locally on-device; no backend is required for the free product.

A separate **Admin Portal** (`admin/`) is a local Node.js web tool used exclusively by the admin at content-authoring time. It is not part of the Flutter app and is never deployed to users.

```
┌─────────────────────────────────────────────────────────┐
│                  Admin Portal (admin/)                   │
│  Node.js Express server + HTML/JS frontend               │
│  • Scrapes YesStyle / OliveYoung / iHerb for product data│
│  • Editable product cards; category management           │
│  • Downloads updated master_products.json                │
│  Runs locally: localhost:3001 — admin only               │
└───────────────────────┬─────────────────────────────────┘
                        │  exports master_products.json
                        ▼
              assets/data/master_products.json  ◄── Flutter app bundles at build time
```

```
                    ┌───────────────────────────────────────────┐
                    │              Supabase (PostgreSQL)         │
                    │  master_products table + storage bucket    │
                    │  get_master_content() RPC                  │
                    └──────────────────┬────────────────────────┘
                                       │  background refresh (non-blocking)
                                       ▼
                    ┌───────────────────────────────────────────┐
                    │    RemoteCachedMasterContentRepositoryImpl │
                    │  1. in-memory (_inMemory)                  │
                    │  2. SharedPrefs cache (contentVersion guard)│
                    │  3. bundled JSON fallback (always works)   │
                    └───────────────────────────────────────────┘
```

### 1.1 Architecture Style

**Layered Clean Architecture** with **Feature-First** organization inside the Presentation layer.

```
┌──────────────────────────────────────────────────┐
│                Presentation Layer                 │  Flutter widgets, screens, Riverpod providers
│   (Feature modules: setup, home, history, …)      │
├──────────────────────────────────────────────────┤
│                 Domain Layer                      │  Pure Dart — entities, services, repo interfaces
│  (RoutineResolver, StreakCalculator, Checker, …)  │
├──────────────────────────────────────────────────┤
│                  Data Layer                       │  Drift (SQLite), asset loader, photo storage
│  (Repositories, DAO, BundledContentLoader, …)    │
├────────────────────────┬─────────────────────────┤
│   Android Platform     │      Web Platform        │  Platform-specific adapters behind interfaces
│  (sqflite, files dir)  │  (sqlite3 WASM, IDB)     │
└────────────────────────┴─────────────────────────┘
```

### 1.2 Key Design Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| **Flutter** as the only runtime | Single codebase for Android APK + Web; no native iOS required; admin distributes directly | React Native (less mature web story); Kotlin Multiplatform (no single UI layer) |
| **Riverpod 2.x** for state management | Reactive, composable, works naturally with Drift Streams; less boilerplate than BLoC for a personal app | BLoC (more boilerplate, overkill here); Provider (superseded) |
| **Drift** (type-safe SQLite ORM) | Works on both Android (sqflite) and Web (sqlite3 WASM); typed schema; built-in migrations; reactive streams via `watchSingleOrNull` | Isar (no mature Web support); raw sqflite (no Web); Hive (no relational queries) |
| **Bundled JSON assets** for master content | Master list is build-time data, not runtime-fetched; avoids any backend dependency in v1.0; versioned per release | Dart code constants (harder for admin to edit); remote CDN (violates offline-first) |
| **Abstract `PhotoRepository`** interface | Android uses app document files; Web uses IndexedDB blobs; export treats photos uniformly as bytes | Forcing one approach across platforms breaks on Web (no persistent FS in iOS Safari) |
| **ZIP export format** | Single portable file; open format (deflate); contains structured JSON + raw photo bytes; future-safe | SQLite dump (not portable); tar (less tool support on mobile) |
| **Snapshot DayRecord on first S4 view** | Historical accuracy — S7 shows "routine as it was that day"; master list may change in future builds | Reconstruct from current state (incorrect after updates); eager snapshot at midnight (complex scheduling) |
| **Day boundary at 06:00** | Per PRD UC-8: late-night activity credits to prior calendar day; implemented in `DayBoundaryService` as a pure function | Midnight (simpler but breaks real usage patterns) |
| **Stable string IDs** for all records | Enables merge-conflict resolution (UC-17) and post-update reconciliation (UC-18); premium-cloud-backup-ready (UC-21 NFR-M7) | Auto-increment integers (lose portability across devices) |
| **Hebrew RTL at `MaterialApp` root** | RTL configured once globally; all screens mirror automatically via Flutter's built-in directionality | Per-screen RTL (error-prone, inconsistent) |
| **Supabase for master content delivery** | `RemoteCachedMasterContentRepositoryImpl` composes bundled JSON + SharedPrefs cache + Supabase RPC. Three-tier load: in-memory → cache → bundled; Supabase refresh runs in background after first load. Cache is version-guarded: if cached `contentVersion` < bundled, cache is discarded. | Direct Supabase reads on every load (slow, network-dependent); CDN-hosted JSON (harder to update per-product images) |

---

## 2. Component Structure

### 2.1 Component Diagram

```
                    ┌──────────────────────────────────────┐
                    │          Flutter App Root             │
                    │  (MaterialApp, Radiant Dew ThemeData, │
                    │   he_IL locale, TextDirection.rtl)    │
                    └──────────────────┬───────────────────┘
                                       │
         ┌─────────────────────────────┼──────────────────────────────┐
         │                             │                              │
         ▼                             ▼                              ▼
┌────────────────┐           ┌──────────────────┐          ┌───────────────────┐
│  Presentation  │           │  Presentation    │          │  Presentation     │
│  Setup Flow    │           │  Daily Use       │          │  History & Data   │
│  (S1, S2, S3) │           │  (S4, S5, S10)   │          │  (S6-S9, S11-S16) │
└───────┬────────┘           └────────┬─────────┘          └────────┬──────────┘
        │                            │                              │
        └────────────────────────────┼──────────────────────────────┘
                                     │  Riverpod Providers
                                     ▼
        ┌────────────────────────────────────────────────────────────┐
        │                      Domain Layer                          │
        │  ┌─────────────────┐  ┌──────────────────┐               │
        │  │ RoutineResolver  │  │ StreakCalculator  │               │
        │  └────────┬─────────┘  └────────┬──────────┘               │
        │           │                     │                          │
        │  ┌────────┴──────────┐  ┌───────┴──────────┐              │
        │  │IncompatibilityChk │  │  DayBoundaryService│             │
        │  └────────┬──────────┘  └───────┬───────────┘             │
        │           │                     │                          │
        │  ┌────────┴──────────┐  ┌───────┴──────────┐              │
        │  │ReconciliationSvc  │  │ ExportImportService│             │
        │  └────────────────────┘  └──────────────────┘              │
        └───────────────────────────────────────┬────────────────────┘
                                                │  Repository Interfaces
                                                ▼
        ┌────────────────────────────────────────────────────────────┐
        │                       Data Layer                           │
        │  ┌───────────────────┐   ┌──────────────────┐             │
        │  │MasterContentRepo  │   │ UserDataRepository│             │
        │  │(assets JSON load) │   │  (Drift / SQLite) │             │
        │  └───────────────────┘   └──────────────────┘             │
        │  ┌───────────────────┐   ┌──────────────────┐             │
        │  │  PhotoRepository  │   │ SettingsRepository│             │
        │  │  (file / IDB)     │   │ (SharedPrefs)     │             │
        │  └───────────────────┘   └──────────────────┘             │
        │  ┌───────────────────────────────┐                        │
        │  │ RemoteCachedMasterContentRepo │ (Supabase + cache +    │
        │  │  + SupabaseDataSource + Cache │  bundled fallback)     │
        │  └───────────────────────────────┘                        │
        │  (No PremiumRepository in v1.0 — S15 screen is a stub.)    │
        └────────────────────────────────────────────────────────────┘
                    │ Android                     │ Web
                    ▼                             ▼
            sqflite + files dir          sqlite3 WASM + IndexedDB
```

### 2.2 Component Descriptions

| Component | Responsibility | Dependencies |
|-----------|---------------|--------------|
| **AppRoot** | `MaterialApp` with Radiant Dew `ThemeData`, `he_IL` locale, `TextDirection.rtl`, `ProviderScope` | Riverpod, flutter_localizations |
| **SetupFlow (S1–S3)** | Product selection, schedule setup, order customization; drives incompatibility warnings | RoutineResolver, IncompatibilityChecker, UserDataRepository, MasterContentRepo |
| **DailyHomeFeature (S4, S5, S10)** | Today's resolved routine, done-toggles, streak widget, conflict markers, deprecation notices, weekly skin-reminder card | RoutineResolver, StreakCalculator, IncompatibilityChecker, DayBoundaryService, UserDataRepository, SettingsRepository |
| **HistoryFeature (S6, S7)** | Calendar grid (four completion states), day detail, past record editing | UserDataRepository, DayBoundaryService |
| **SkinLogFeature (S8, S9)** | Skin log entry (text + photos), chronological journal gallery | PhotoRepository, UserDataRepository |
| **DataManagementFeature (S11–S16)** | Settings hub, export/import, about/changelog, backup reminder, update review, premium placeholder | ExportImportService, ReconciliationService, SettingsRepository, MasterContentRepo |
| **RoutineResolver** | Resolves which products are active for a given date + slot; applies 6am boundary, schedule, deprecated state, and effective order | MasterContentRepo, UserDataRepository, DayBoundaryService |
| **StreakCalculator** | Computes current and longest streak per UC-13 grace rules; reads DayRecords | UserDataRepository, DayBoundaryService |
| **IncompatibilityChecker** | Evaluates admin-authored rules against user's current selection/schedule; distinguishes daily↔daily from day-dependent clashes; respects muted conflicts | MasterContentRepo, UserDataRepository |
| **DayBoundaryService** | Pure function: maps a `DateTime` to the effective `LocalDate` (subtracts 1 day if before 06:00) | none |
| **ReconciliationService** | Compares installed master-list content version to last-known version; identifies new, deprecated, and changed products; preserves user data | MasterContentRepo, UserDataRepository, SettingsRepository |
| **ExportImportService** | Serializes full user dataset + photos into a ZIP archive; deserializes and drives Replace/Merge flow | UserDataRepository, PhotoRepository, SettingsRepository |
| **MasterContentRepositoryImpl** | Loads and parses bundled JSON assets; in-memory cached after first load | Flutter asset bundle |
| **RemoteCachedMasterContentRepositoryImpl** | Three-tier load: in-memory → SharedPrefs version-guarded cache → bundled fallback; background Supabase refresh | MasterContentRepositoryImpl, SupabaseMasterContentDataSource, SharedPrefsMasterContentCache |
| **SupabaseMasterContentDataSource** | Fetches master content from Supabase via `get_master_content()` RPC; maps PostgreSQL rows to MasterContent | supabase_flutter |
| **SharedPrefsMasterContentCache** | Persists MasterContent as JSON in SharedPreferences; version guard enforced by caller | shared_preferences |
| **BarcodeProductLookupService** | Queries 5 external APIs in parallel (OpenBeautyFacts, OpenFoodFacts, UPCItemDB, InciBeauty, BarcodeSpider); merges results by priority | http package |
| **UserDataRepository** | All CRUD for user data (selections, schedules, order overrides, day records, skin logs, muted conflicts) via Drift DAOs; reactive streams | Drift database |
| **PhotoRepository** | Platform-abstracted photo storage: read, write, delete, list; used by export | Android: FilesDir adapter; Web: IndexedDB adapter |
| **SettingsRepository** | Key-value store for app settings: last export date, last known master version, schema version, onboarding/locale/gender, demo flags, weekly skin-reminder dismiss date | SharedPreferences |
| **RefreshableRepository** | Marker interface (`refresh()`) implemented by `RemoteCachedMasterContentRepositoryImpl`; lets the app trigger a background Supabase refresh without coupling to the concrete impl | none |
| **PremiumScreen (S15)** | UI stub in v1.0 — no `PremiumRepository` interface exists yet; the license-activation screen is a placeholder hookpoint for UC-21 | none in v1.0 |
| **RoutineScheduler** | Single gateway for all routine data (selections, weekday schedules, order overrides) and product ordering; owns every routine device read/write; orchestrates RoutineResolver, WeekGlanceBuilder, IncompatibilityChecker, ConflictResolver, ProductSorter | UserDataRepository, RoutineResolver, WeekGlanceBuilder, IncompatibilityChecker, ConflictResolver |

### 2.3 Interface Contracts

**RoutineResolver**
```
resolve(date: DateTime, slot: Slot) → List<ResolvedProduct>
  // ResolvedProduct: {product, isDeprecated, hasActiveConflict}
```

**StreakCalculator**
```
computeStreak(asOf: DateTime) → StreakResult
  // StreakResult: {currentStreak, longestStreak, missesThisWeek, graceBudgetRemaining}
```

**IncompatibilityChecker**
```
getConflictsForSelection(slot: Slot) → List<ConflictInfo>
  // daily↔daily conflicts (for S1)
getConflictsForDay(date: DateTime) → List<ConflictInfo>
  // day-specific conflicts across both slots (for S4)
getConflictsForSchedule(productId, slot, proposedWeekdays) → List<ConflictInfo>
  // for S2 scheduling warnings
// ConflictInfo: {ruleId, productA, productB, scope, isMuted}
```

**RoutineScheduler**
```
// Reactive reads (delegate to UserDataRepository)
watchSelections(slot: Slot) → Stream<List<ProductSelection>>
watchAllSchedules() → Stream<List<WeekdaySchedule>>
watchOrderOverride(slot: Slot) → Stream<OrderOverride?>

// Derived reads (all named params)
orderForDay({master, slot, weekday: int}) → Future<List<MasterProduct>>
warningsForDay({master, slot, weekday: int}) → Future<DayWarnings>
  // DayWarnings: {conflicts: List<ConflictInfo>, overused: List<OveruseEntry>, zeroDayCount: int}
weekGlance({master}) → Future<WeekGlance>

// Product mutations (named params)
addProduct({master, productId: String, slot: Slot}) → Future<int>
  // returns the product's 0-based index in the admin-sorted slot routine
removeProduct({productId: String, slot: Slot}) → Future<void>
fixProblems({master, slot: Slot}) → Future<RoutineFixResult>
  // RoutineFixResult: {applied, inverse, changeDescriptions, anyPartial}

// Schedule mutations (named params)
setDays({productId: String, slot: Slot, days: Set<int>}) → Future<void>
toggleDay({productId: String, slot: Slot, weekday: int}) → Future<void>
removeDay({productId: String, slot: Slot, weekday: int}) → Future<void>
setOrder({slot: Slot, int? weekday, required List<String> orderedIds}) → Future<void>
resetOrder({slot: Slot, int? weekday}) → Future<void>
applyMutationsPersisting(mutations: List<ScheduleMutation>) → Future<void>
ensureDefaultSchedules({master}) → Future<void>

// Canonical static helpers
static effectiveDays(product: MasterProduct, slot: Slot, schedules: List<WeekdaySchedule>) → Set<int>
  // explicit schedule row wins; DailyRule → {0..6}; WeeklyMaxRule → {} if no row
static defaultDaysFor(product: MasterProduct, slot: Slot) → Set<int>
  // DailyRule → {0..6}; WeeklyMaxRule → evenly spread N days
```

**ExportImportService**
```
exportToArchive() → Future<Uint8List>          // ZIP bytes
importArchive(bytes: Uint8List) → ArchiveValidationResult
replaceAll(archive: ValidArchive) → Future<void>
startMerge(archive: ValidArchive) → MergeSession
  // MergeSession: {totalConflicts, nextConflict(), resolveConflict(choice), complete()}
```

**UserDataRepository** (key methods)
```
watchSelections(slot: Slot) → Stream<List<ProductSelection>>
upsertSelection(productId, slot, isSelected) → Future<void>
watchDayRecord(date: LocalDate, slot: Slot) → Stream<DayRecord?>
snapshotAndGetDayRecord(date: LocalDate, slot: Slot, resolvedProducts) → Future<DayRecord>
toggleProductDone(date: LocalDate, slot: Slot, productId, isDone) → Future<void>
watchOrderOverride(slot: Slot) → Stream<OrderOverride?>
upsertOrderOverride(slot: Slot, orderedIds: List<String>) → Future<void>
exportAllData() → Future<UserDataExport>
replaceAllData(export: UserDataExport) → Future<void>
```

---

## 3. Data Architecture

### 3.0 Routine data — single source of truth

Only `RoutineScheduler` (`lib/domain/services/routine_scheduler.dart`) may read or write routine device data — that is, `ProductSelection`, `WeekdaySchedule`, and `OrderOverride` records. No feature screen or provider accesses `UserDataRepository` directly for these three tables; every routine read/write is funnelled through the scheduler's `watch*` streams and mutation methods.

**Scope is routine-only.** Day records, skin log entries, muted conflicts, collection items, and category overrides remain on `UserDataRepository` and are not part of the scheduler's contract.

**`effectiveDays` is the canonical rule.** The rule "which weekdays is a product active on for a given slot" was previously implemented independently in `RoutineResolver.resolve`, `WeekGlanceBuilder._buildActiveDays`, and the schedule setup screen's `_effectiveDays` helper. It is now defined once as `RoutineScheduler.effectiveDays(product, slot, schedules)` and called from all three sites. The semantics are: an explicit `WeekdaySchedule` row wins regardless of value (even an empty set means intentionally excluded); a `DailyRule` product with no row defaults to `{0..6}`; a `WeeklyMaxRule` product with no row defaults to `{}`.

**`buildRoutineSummary` is the "routine ready" derived read.** `RoutineScheduler.buildRoutineSummary({master})` returns a `RoutineBuildSummary` (`lib/domain/services/routine_build_summary.dart`) describing the auto-sorter's decisions for the post-build summary screen (S17). It composes existing pieces: it runs `fixProblems` (whose `RoutineFixResult` now carries an additive `changes: List<RoutineChange>` — each a slot + `RoutineChangeKind` {movedDays, reducedFrequency, movedSlot} + the resolver's localized text), counts distinct/per-slot selections, and derives `advisories` from `IncompatibilityChecker` — pairs that *still* co-occur on a weekday after the fix (i.e. user-muted pairs the resolver leaves alone). Keeping this on the scheduler preserves the single-source-of-truth rule; the screen (`RoutineReadySummaryScreen`) is a pure presentation widget fed the value object. Invoked at three sites: onboarding finish (`onboarding_screen.dart`), add-product save (`add_product_flow_screen.dart`), and custom-product delete (`add_custom_product_sheet.dart`).

### 3.1 Data Models

#### Master Content (bundled assets — read-only at runtime)

```dart
class MasterProduct {
  final String id;               // stable UUID, never changes across versions
  final String? brand;           // NEW: extracted from admin content; may be null
  final String name;             // verbatim; may be Latin brand name
  final String? imageAsset;      // local path OR https:// URL (Supabase Storage)
  final String? comment;         // Hebrew admin note
  final String? commentEn;       // English admin note (optional)
  final String categoryId;
  final String? subCategoryId;   // optional finer grouping within a category
  final SlotConfig? morningConfig;
  final SlotConfig? eveningConfig;
  final bool isDeprecated;
  final String addedInVersion;   // which content version introduced it
  final List<String> ingredients; // NEW: ingredient list from admin/external source
  final List<String> barcodes;   // NEW: EAN/UPC barcodes for scanner matching
}

class SlotConfig {
  final int order;            // admin's canonical 0-based position
  final FrequencyRule frequencyRule;
}

sealed class FrequencyRule { const FrequencyRule(); }
final class DailyRule extends FrequencyRule { const DailyRule(); }
final class WeeklyMaxRule extends FrequencyRule {
  final int maxPerWeek;
  const WeeklyMaxRule(this.maxPerWeek);
}

class Category {
  final String id;
  final String name;          // verbatim; bidi-safe
}

class IncompatibilityRule {
  final String id;
  final RuleTarget entityA;
  final RuleTarget entityB;
  final RuleScope scope;
}

class RuleTarget {
  final RuleTargetType type;  // product | category
  final String id;
}

enum RuleScope { withinMorning, withinEvening, sameDayAcrossBoth }

class MasterListManifest {
  final String contentVersion;
  final String appVersion;
  final List<ChangelogEntry> changelog;
}

class ChangelogEntry {
  final String contentVersion;
  final List<String> changes; // Hebrew description strings
}
```

#### User Data (Drift SQLite tables)

```dart
// Drift table definitions (pseudocode — actual Drift DSL in code)

@DataClassName('ProductSelection')
class ProductSelections extends Table {
  TextColumn get id => text()();              // UUID
  TextColumn get productId => text()();
  TextColumn get slot => text()();           // 'morning' | 'evening'
  BoolColumn get isSelected => boolean()();
  IntColumn get lastModified => integer()(); // Unix ms
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('WeekdaySchedule')
class WeekdaySchedules extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get slot => text()();
  TextColumn get weekdays => text()();       // JSON: [0,2,4] (Sun=0)
  IntColumn get lastModified => integer()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('OrderOverride')
class OrderOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get slot => text()();
  TextColumn get orderedProductIds => text()(); // JSON array
  IntColumn get lastModified => integer()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('DayRecord')
class DayRecords extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();           // ISO: YYYY-MM-DD (effective date after 6am boundary)
  TextColumn get slot => text()();
  TextColumn get resolvedProductIds => text()(); // JSON — snapshot of routine for that day
  TextColumn get recordedProductIds => text()(); // JSON — what was marked done
  TextColumn get resolvedAtMasterVersion => text()();
  IntColumn get lastModified => integer()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('SkinLogEntry')
class SkinLogEntries extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();           // ISO: YYYY-MM-DD
  TextColumn get notes => text().nullable()();
  TextColumn get skinState => text().nullable()(); // optional skin-state tag
  TextColumn get photoPaths => text()();     // JSON array of storage keys
  IntColumn get lastModified => integer()();
  @override Set<Column> get primaryKey => {id};
}

@DataClassName('MutedConflict')
class MutedConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId => text()();
  IntColumn get mutedAt => integer()();
  @override Set<Column> get primaryKey => {id};
}

// Additional Drift tables (same id + lastModified convention; see
// lib/data/local/database/tables/ for full DSL):
//   CategoryOverrides      — per-product user category reassignment
//   CollectionItems        — product lifecycle / "my collection" status (CollectionStatus)
//   ProductUseTimestamps   — opened/expiry timestamps feeding the PAO (period-after-opening) meter
//   UserCustomProducts     — user-authored products (soft-deletable; map to MasterProduct via toMasterProduct())

// AppSettings uses SharedPreferences (key-value):
// Key: 'last_export_date'         → ISO date string or null
// Key: 'last_known_master_version' → content version string
// Key: 'user_schema_version'      → integer
// Key: 'longest_streak'           → integer (cached for performance)
// Key: 'weekly_photo_reminder_dismissed_date' → ISO date string; S4 weekly skin-reminder snoozed for that day
// Key: 'weekly_photo_reminder_enabled' → bool (default true); master on/off for the S4 weekly skin-reminder
```

#### Export Archive Format (ZIP)

```
skincare_backup_YYYY-MM-DD.zip
├── manifest.json        # { exportVersion: "1", exportDate, appVersion, contentVersion }
├── user_data.json       # { schemaVersion, selections[], schedules[], overrides[], dayRecords[], skinLogs[], mutedConflicts[], settings{} }
└── photos/
    └── {storageKey}.jpg # one file per photo; key matches paths in user_data.json skinLogs[].photoPaths
```

### 3.2 Data Flow

```
Admin authors JSON → bundled into app assets at build time
                                    │
                         App start  │
                                    ▼
                    MasterContentRepository.load()
                    └── Parses products, categories, rules, manifest
                    └── Checks contentVersion vs SettingsRepository.lastKnownVersion
                    └── If changed → triggers ReconciliationService (UC-18)

User taps S4 (Daily Home)
    │
    ├── DayBoundaryService.effectiveDate(DateTime.now())
    │       → LocalDate to use for all lookups
    │
    ├── RoutineResolver.resolve(date, slot)
    │       → reads UserDataRepository.watchSelections(slot)
    │       → reads UserDataRepository.watchSchedule(productId, slot)
    │       → reads UserDataRepository.watchOrderOverride(slot)
    │       → returns ordered List<ResolvedProduct>
    │
    ├── UserDataRepository.snapshotAndGetDayRecord(date, slot, resolvedProducts)
    │       → if DayRecord exists: return it  (snapshot already taken today)
    │       → if not: create DayRecord with resolvedProductIds = resolved products
    │               (historical snapshot for S7 accuracy)
    │
    ├── IncompatibilityChecker.getConflictsForDay(date)
    │       → checks active conflicts against muted list
    │
    └── StreakCalculator.computeStreak(asOf: now)
            → walks DayRecords backwards
            → accumulates slot-misses per Sun-Sat week
            → finds last reset point → current streak

User taps "done" on a product
    │
    └── UserDataRepository.toggleProductDone(date, slot, productId, true/false)
            → updates DayRecord.recordedProductIds
            → lastModified updated (for future merge-conflict detection)

User requests Export
    │
    └── ExportImportService.exportToArchive()
            → UserDataRepository.exportAllData()
            → PhotoRepository.readAllPhotos()
            → serializes to ZIP bytes
            → triggers file save / share sheet
            → SettingsRepository.setLastExportDate(today)
```

### 3.3 Storage Strategy

| Data Type | Storage Mechanism | Persistence Guarantee |
|-----------|------------------|----------------------|
| Master content (products, rules, manifest) | Flutter asset bundle (JSON files) | Bundled with app; survives updates |
| Product selections, schedules, order overrides | Drift / SQLite | Survives updates (same APK signing key on Android; OPFS on Web — evictable on iOS) |
| Day records (routine snapshots + done state) | Drift / SQLite | Same as above |
| Skin log text | Drift / SQLite | Same as above |
| Skin log photos | Android: app documents directory; Web: IndexedDB blob store | Android: durable; Web: evictable on iOS |
| App settings (last export date, schema version) | SharedPreferences | Survives updates; may be cleared with app data |
| Export archive | User-chosen location (Downloads / Files app / share sheet) | User-controlled; durable |

**Web storage risk:** iOS Safari may evict IndexedDB and OPFS data after extended periods of non-use. The app surfaces this risk to web users (S16 backup reminder, explicit warning on first web launch).

---

## 4. Technology Stack

| Layer | Technology | Justification |
|-------|------------|---------------|
| Language | Dart 3.x | Required by Flutter |
| UI Framework | Flutter 3.x | Single codebase → Android + Web; RTL built-in; strong widget ecosystem |
| State Management | Riverpod 2.x (`flutter_riverpod`) | Reactive; composable; integrates cleanly with Drift Streams; scoped providers per feature; no boilerplate EventSink/State classes |
| Local Database | Drift 2.x | Type-safe SQLite ORM; runs on Android (sqflite) and Web (sqlite3 WASM via `drift_flutter`); built-in schema migrations; reactive `Stream`-based watchers |
| Photo Storage (Android) | `path_provider` + `dart:io` | App document directory; durable on Android |
| Photo Storage (Web) | `idb_shim` / custom JS interop | IndexedDB blob storage; only persistent option on Web without native file system access |
| Photo Compression | `flutter_image_compress` | Resize to max 1080px long edge before storage; keeps storage bounded |
| Photo Picker | `image_picker` | Cross-platform (camera + gallery on Android; browser picker on Web) |
| Archive / Export | `archive` package (ZIP) | Pure Dart; no native dependencies; works on both platforms |
| File Save / Share | `share_plus` | Platform-appropriate: downloads file on Web; share sheet on Android |
| RTL / i18n | `flutter_localizations` + `intl` + ARB files | Hebrew locale (`he`); `Directionality.rtl` at root |
| Typography | `google_fonts` | Quicksand + Plus Jakarta Sans; both available on Google Fonts; offline-cached in build |
| Preferences | `shared_preferences` | Key-value settings (last export date, schema version, master version) |
| Barcode Scanning | `mobile_scanner ^7.2.0` | Camera-based barcode/QR scan for product lookup; Android only (guarded by `kIsWeb`); requires `CAMERA` permission in `AndroidManifest.xml` |
| Remote content | supabase_flutter | Single-client Supabase SDK; `get_master_content()` RPC avoids 4 round-trips |
| Network image cache | cached_network_image | Caches Supabase Storage URLs for product thumbnails |
| HTTP client | http | Used by BarcodeProductLookupService for external API queries |
| Testing | `flutter_test` + `mockito` + `drift` test utilities | Unit tests for domain services; widget tests for key screens |

---

## 5. Error Handling Strategy

| Error Category | Handling Approach | User Feedback |
|----------------|-------------------|---------------|
| Invalid import archive | Validate ZIP structure and `manifest.json` schema before any data write; abort if invalid | Hebrew error message on S12: "הקובץ אינו תקין" (file is not valid) |
| Photo read/write failure | Catch `IOException` / IDB errors; skip the photo; log locally | Show photo placeholder; do not crash |
| Database migration failure | Drift migration runs in a transaction; on failure, rolls back; app logs the schema version mismatch | Display error screen prompting user to export if possible, then reinstall |
| Master content parse error | Fatal at startup — bundled JSON is admin-controlled and must be correct | Crash with developer-readable error (this only affects admin during authoring) |
| Merge conflict resolution | Sequential per-conflict UI with clear imported-vs-local comparison; user must choose one | S12 conflict chooser UI; no automatic resolution |
| Photo storage eviction (Web) | Detected on app load by checking if expected photo keys are missing from IDB | Warn user that photos may have been lost; encourage export from Settings |
| Export failure (out of disk) | Catch filesystem/IDB errors during archive write | Hebrew: "לא ניתן לייצא — אין מספיק מקום" |
| Replace-on-import (irreversible) | Require explicit confirmation dialog before `replaceAll` | Confirmation alert naming the consequence |

---

## 6. Security Considerations

- **No authentication required** — network-optional personal app; no accounts; no sync of user data.
- **No data leaves the device** except via user-initiated export (UC-16) or the deferred premium backup (UC-21). Network calls are opt-in: Supabase refresh runs in background and fails silently; barcode lookup is user-initiated. All user data remains on-device; no user data is sent to any external service. Supabase access is read-only for master content (no user data stored there in v1.0).
- **Import validation:** archive bytes are parsed and validated against a known schema before any data is written; malformed input is rejected.
- **No analytics or telemetry** — confirmed non-goal (PRD §10 Privacy).
- **Premium license key (deferred):** v1.0 stub always returns `false`; the v1.0 codebase has no key validation logic to harden.
- **Android APK signing:** the signing key must be kept securely by the admin; a key loss would force reinstall, destroying all user data. This is operational, not code-level.
- **Photo storage:** photos are stored only in the app's private sandbox (Android) or in IndexedDB (Web) — not accessible by other apps.

---

## 7. Performance Considerations

| Concern | Approach |
|---------|----------|
| Master list size (~100 products) | Loaded once at startup into memory; no re-reads during navigation |
| Daily routine resolution | Pure in-memory computation after initial DB load; resolves in <1ms for ~100 products |
| Calendar month view | `watchDayRecordsForMonth()` Drift stream returns pre-computed completion states; no per-day lazy loading |
| Streak computation | Walks DayRecords backward; cached `longestStreak` in SharedPreferences; `currentStreak` computed on S4 open |
| Photo compression | `flutter_image_compress` compresses before write (not on display) to cap disk usage |
| Skin journal gallery | Paginated / lazy-loaded list; photos decoded on scroll, not pre-loaded |
| Incompatibility check at selection | O(products² × rules) = O(100² × ~20 rules) ≈ trivial; no optimization needed |
| Database reactive updates | Drift streams push updates to Riverpod providers; UI rebuilds only affected subtrees via `ConsumerWidget` |

---

## 8. UI-Relevant Contracts

### Navigation Structure

```
Bottom Navigation (RTL-mirrored, 4 tabs):
  [היום / Today S4] [המוצרים שלי / My Products S1-browse] [יומן / Calendar S6] [הגדרות / Settings S11]
```

Note: The Skin Journal (S9) is not a bottom-nav tab. It is accessible from Calendar (S6) and from the skin-log icon on S4. The second tab is My Products — the browse view of `ProductSelectionScreen(isTabDestination: true)`.

### Shared Widget Contracts

**RoutineItemRow (S5 component)**
```
RoutineItemRow({
  required ResolvedProduct product,
  required bool isDone,                // from DayRecord
  required bool isDeprecated,
  required bool hasConflict,
  required VoidCallback onToggleDone,
  bool isOwnershipToggle = false,      // S1 uses "own" semantics, S4 uses "done"
  bool isDraggable = false,            // S3 drag context
})
```

**SoftWarningBanner**
```
SoftWarningBanner({
  required String message,             // Hebrew string
  ConflictInfo? conflict,              // if present, shows mute affordance
  VoidCallback? onMute,
  VoidCallback? onDismiss,
})
```

### State Providers (Riverpod)

All defined in `lib/shared/providers/root_providers.dart` unless noted.

| Provider | Type | Scope |
|----------|------|-------|
| `masterContentProvider` | `FutureProvider<MasterContent>` | Global — loaded once at startup via `masterContentRepositoryProvider.load()` |
| `masterContentRefreshProvider` | `Provider<Future<void> Function()>` | Global — triggers background Supabase refresh + invalidates `masterContentProvider` |
| `effectiveDateProvider` | `Provider<DateTime>` | Global — `todayEffectiveDate` from `DayBoundaryService` (06:00 boundary) |
| `routineSchedulerProvider` | `Provider<RoutineScheduler>` | Global — single instance; owns all routine device access |
| `dailyRoutineProvider(({String date, Slot slot}))` | `StreamProvider.family<List<MasterProduct>>` | Per-day per-slot; **scheduler-backed** — composes selections, schedules, effective order override, category overrides, and custom products via `RoutineResolver` |
| `selectionsProvider(slot)` | `StreamProvider.family<List<ProductSelection>, Slot>` | Per-slot; **scheduler-backed** — delegates to `watchSelections` |
| `allSchedulesProvider` | `StreamProvider<List<WeekdaySchedule>>` | Global; **scheduler-backed** — delegates to `watchAllSchedules` |
| `orderOverrideProvider(slot)` | `StreamProvider.family<OrderOverride?, Slot>` | Per-slot; **scheduler-backed** — delegates to `watchOrderOverride` |
| `weekGlanceProvider` | `FutureProvider<WeekGlance>` | Global; **scheduler-backed** — watches selections/schedules/custom/muted then calls `weekGlance` |
| `dayWarningsProvider(({Slot slot, int weekday}))` | `FutureProvider.family<DayWarnings>` | Per-slot per-weekday; **scheduler-backed** — delegates to `warningsForDay` |
| `mutedConflictsProvider` | `StreamProvider<List<MutedConflict>>` | Global — `UserDataRepository.watchMutedConflicts` |
| `allDayRecordsProvider` | `StreamProvider<List<DayRecord>>` | Global — `UserDataRepository.watchAllDayRecords` |
| `customProductsProvider` | `StreamProvider<List<UserCustomProduct>>` | Global — user-added custom products |
| `collectionItemsProvider` | `StreamProvider<List<CollectionItem>>` | Global — product lifecycle / collection items |
| `categoryOverridesProvider` | `StreamProvider<List<CategoryOverride>>` | Global — per-product category overrides |
| `barcodeProductLookupServiceProvider` | `Provider<BarcodeProductLookupService>` | Global — barcode lookup (APIs + scrapers) |
| `productClassifierProvider` | `FutureProvider<ProductClassifier>` | Global — built from raw bundled subcategory keywords |
| `paoCalculatorProvider` | `Provider<PaoCalculator>` | Global |
| `silentStartupProvider` / `conflictAutoFixProvider` | `FutureProvider<void>` / `FutureProvider<int>` | Global — cold-start reconcile + default-schedule seeding/healing |
| `appLocaleProvider` / `localeSyncProvider` | `StateProvider<Locale>` / `FutureProvider<void>` | Global — Hebrew (f/m) / English locale selection |
| `appVersionProvider` / `onboardingCompletedProvider` / `userNameProvider` | `FutureProvider<…>` | Global — settings-backed |
| `isProDemoProvider` / `milestoneDemoProvider` | `StateProvider<bool>` | Global — in-memory demo toggles |

---

## 9. File Structure

```
skincare_tracker/
├── lib/
│   ├── main.dart                         # Entry point; ProviderScope wrapper; Supabase + DB init
│   ├── app.dart                          # MaterialApp; ThemeData; locale; RTL; routing
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── radiant_dew_theme.dart    # Full ThemeData from DESIGN.md tokens
│   │   │   ├── app_colors.dart           # Color constants
│   │   │   ├── app_typography.dart       # TextStyles (Quicksand + Plus Jakarta Sans)
│   │   │   └── app_layout.dart           # Spacing / radius layout constants
│   │   ├── config/
│   │   │   ├── supabase_config.dart      # Supabase URL + anon key
│   │   │   └── feature_flags.dart        # Build-time feature toggles
│   │   ├── l10n/
│   │   │   ├── hebrew_date_strings.dart  # Hebrew month/weekday strings
│   │   │   └── generated/               # gen_l10n output (app_localizations*.dart)
│   │   ├── utils/
│   │   │   └── json_list.dart            # JSON encode/decode helpers for Drift TEXT columns
│   │   └── routing/
│   │       └── app_router.dart           # go_router route definitions
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── master_product.dart        # incl. SlotConfig + FrequencyRule
│   │   │   ├── category.dart
│   │   │   ├── sub_category.dart
│   │   │   ├── incompatibility_rule.dart
│   │   │   ├── master_list_manifest.dart
│   │   │   ├── product_selection.dart
│   │   │   ├── weekday_schedule.dart
│   │   │   ├── order_override.dart
│   │   │   ├── day_record.dart
│   │   │   ├── skin_log_entry.dart
│   │   │   ├── muted_conflict.dart
│   │   │   ├── category_override.dart
│   │   │   ├── collection_item.dart
│   │   │   ├── product_use_timestamp.dart
│   │   │   ├── user_custom_product.dart
│   │   │   ├── scanned_product_info.dart
│   │   │   └── user_data_export.dart
│   │   ├── enums/
│   │   │   ├── slot.dart                 # morning | evening
│   │   │   ├── rule_scope.dart
│   │   │   ├── day_completion_state.dart # complete | partial | missed | future
│   │   │   ├── collection_status.dart
│   │   │   └── pao_tone.dart
│   │   ├── repositories/                 # Abstract interfaces
│   │   │   ├── master_content_repository.dart
│   │   │   ├── user_data_repository.dart
│   │   │   ├── photo_repository.dart
│   │   │   ├── settings_repository.dart
│   │   │   └── refreshable_repository.dart
│   │   └── services/
│   │       ├── routine_scheduler.dart        # Single gateway for all routine device data
│   │       ├── routine_resolver.dart
│   │       ├── week_glance_builder.dart
│   │       ├── product_sorter.dart
│   │       ├── schedule_days.dart            # canonical effectiveDays / defaultDaysFor
│   │       ├── default_schedule.dart
│   │       ├── incompatibility_checker.dart
│   │       ├── conflict_resolver.dart
│   │       ├── streak_calculator.dart
│   │       ├── calendar_stats.dart
│   │       ├── day_boundary_service.dart
│   │       ├── reconciliation_service.dart
│   │       ├── export_import_service.dart
│   │       ├── pao_calculator.dart
│   │       ├── product_classifier.dart
│   │       └── category_helpers.dart
│   │
│   ├── data/
│   │   ├── bundled/
│   │   │   └── master_content_repository_impl.dart  # Loads assets/data/*.json (offline fallback)
│   │   ├── cache/
│   │   │   ├── master_content_cache.dart            # Cache interface
│   │   │   ├── shared_prefs_master_content_cache.dart
│   │   │   └── master_content_serializer.dart
│   │   ├── remote/
│   │   │   ├── supabase_master_content_data_source.dart
│   │   │   ├── remote_content_data_source.dart
│   │   │   ├── barcode_lookup_service.dart           # 5 barcode APIs, merged by priority
│   │   │   ├── retailer_search_scraper.dart          # scraper interface
│   │   │   └── scrapers/                             # iherb, incidecoder, olive_young_global,
│   │   │                                             #   open_beauty_facts_name_search, yes_style
│   │   ├── remote_cached/
│   │   │   └── remote_cached_master_content_repository_impl.dart  # 3-tier: memory→cache→bundled
│   │   ├── local/
│   │   │   ├── database/
│   │   │   │   ├── app_database.dart     # Drift @DriftDatabase definition + migrations
│   │   │   │   ├── tables/               # One file per Drift table
│   │   │   │   └── daos/                 # SelectionsDao, DayRecordsDao, etc. (+ .g.dart)
│   │   │   ├── photo_storage/
│   │   │   │   ├── photo_repository_android.dart
│   │   │   │   └── photo_repository_web.dart
│   │   │   └── preferences/
│   │   │       └── settings_repository_impl.dart
│   │   └── repositories_impl/
│   │       └── user_data_repository_impl.dart
│   │
│   ├── features/
│   │   ├── welcome/                    # First-launch welcome
│   │   ├── onboarding/                 # Onboarding flow
│   │   ├── app_entry.dart              # Post-startup routing gate (reconcile + locale sync)
│   │   ├── setup/
│   │   │   ├── product_selection_screen.dart  # S1 guided + S1b browse tab (isTabDestination)
│   │   │   ├── add_product_flow_screen.dart    # Guided add-product flow
│   │   │   ├── barcode_scan_sheet.dart         # Camera barcode scanner modal (Android only)
│   │   │   ├── add_custom_product_sheet.dart   # Add/edit custom product
│   │   │   ├── category_review_screen.dart     # Category override review
│   │   │   ├── schedule_setup_screen.dart      # S2 — Schedule Setup
│   │   │   └── order_customization_screen.dart # S3 — Order Customization
│   │   ├── home/
│   │   │   ├── daily_home_screen.dart  # S4 — Daily Home + S10 Streak widget
│   │   │   └── week_glance_screen.dart # Week overview
│   │   ├── calendar/
│   │   │   ├── calendar_screen.dart    # S6 — Calendar
│   │   │   └── day_detail_screen.dart  # S7 — Day Detail
│   │   ├── journal/
│   │   │   ├── skin_log_entry_screen.dart  # S8 — Skin Log Entry
│   │   │   └── skin_journal_screen.dart    # S9 — Skin Journal
│   │   ├── collection/
│   │   │   ├── collection_screen.dart      # Product collection / lifecycle
│   │   │   └── product_detail_screen.dart
│   │   └── settings/
│   │       ├── settings_screen.dart        # S11 — Settings hub
│   │       ├── export_import_screen.dart   # S12 — Export / Import
│   │       ├── merge_conflict_screen.dart  # S12 merge conflict chooser
│   │       ├── about_screen.dart           # S13 — About / What's New
│   │       ├── update_review_screen.dart   # S14 — Post-update reconciliation
│   │       └── premium_screen.dart         # S15 — License Activation (stub in v1.0)
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── routine_item_row.dart    # S5 component — core shared widget
│       │   ├── soft_warning_banner.dart
│       │   ├── backup_reminder_banner.dart  # S16 — Backup reminder surface
│       │   ├── slot_section_header.dart
│       │   ├── category_header.dart
│       │   ├── completion_indicator.dart
│       │   ├── weekday_picker.dart
│       │   ├── streak_widget.dart
│       │   ├── glow_card.dart
│       │   ├── glow_app_bar.dart
│       │   ├── glass_bottom_nav.dart
│       │   ├── product_thumb.dart
│       │   ├── pao_meter.dart
│       │   ├── radiant_chips.dart
│       │   ├── fixed_slot_chip.dart
│       │   ├── skin_state_chip.dart
│       │   ├── pro_tag.dart
│       │   ├── upgrade_sheet.dart
│       │   ├── primary_button.dart
│       │   └── soft_icon_button.dart
│       └── providers/
│           └── root_providers.dart      # Global Riverpod providers
│
├── assets/
│   ├── data/
│   │   ├── master_products.json         # Admin-authored products + categories + subcategories
│   │   ├── incompatibility_rules.json
│   │   └── changelog.json               # Manifest + version history
│   └── images/
│       ├── app_icon.png
│       └── products/                    # Admin-uploaded product images
│           └── {product_id}.jpg
│
├── test/                                # Unit + widget + Playwright (test/playwright/) tests
├── supabase/                            # Supabase schema + seed for remote master content
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_add_ingredients.sql
│   └── 04_add_barcodes.sql
│
├── doc/
│   ├── skincare-tracker-prd.md
│   ├── skincare-tracker-ux-brief.md
│   ├── FUNCTIONALITY.md
│   ├── ARCHITECTURE.md                  # ← this file
│   └── design-reference/               # HTML/CSS references (not shipped)
│
├── pubspec.yaml
├── analysis_options.yaml
└── CLAUDE.md
```

---

## 10. Build Order

Dependencies flow from foundation to feature. Each step assumes prior steps are complete.

| Step | Component | Dependencies | Notes |
|------|-----------|-------------|-------|
| 1 | Radiant Dew `ThemeData` | none | Colors, typography, shapes; consumed by every screen |
| 2 | Hebrew ARB strings + `AppLocalizations` | none | All UI strings; required before any screen |
| 3 | `AppRoot` (`MaterialApp`, RTL, locale, routing) | Steps 1–2 | Shell before any feature |
| 4 | Domain entities (Dart data classes) | none | Pure Dart; no Flutter dependencies |
| 5 | `DayBoundaryService` | none | Pure function; needed by Resolver and Streak |
| 6 | Drift database schema + DAOs | Step 4 | Foundation of all user data |
| 7 | `MasterContentRepository` (JSON loader) | Step 4 | Loads bundled JSON; required by all features |
| 8 | `UserDataRepository` (Drift-backed) | Steps 6–7 | CRUD + Streams for user data |
| 9 | `SettingsRepository` (SharedPreferences) | none | Last export date, schema version |
| 10 | `RoutineResolver` | Steps 5, 7, 8 | Core algorithm; needed by S4, S1, S2, S3 |
| 11 | `IncompatibilityChecker` | Steps 7, 8 | Needed by S1, S2, S4 |
| 12 | `StreakCalculator` | Steps 5, 8 | Needed by S4/S10 |
| 13 | `PhotoRepository` (platform-abstracted) | Step 9 | Needed by S8, S9, export |
| 14 | **Shared widget: `RoutineItemRow` (S5)** | Steps 1–3 | Core reusable row; used in S1, S4, S7 |
| 15 | **S1 — Product Selection** | Steps 10, 11, 14 | First user-facing feature |
| 16 | **S2 — Schedule Setup** | Steps 10, 11 | After S1 in setup flow |
| 17 | **S3 — Order Customization** | Steps 10, 14 | After S1 in setup flow |
| 18 | **S4 — Daily Home** | Steps 10, 11, 12, 14 | Primary screen; snapshot DayRecords |
| 19 | **S6 — Calendar** + **S7 — Day Detail** | Steps 8, 14 | History feature |
| 20 | **S8 — Skin Log Entry** | Steps 8, 13 | Photo capture |
| 21 | **S9 — Skin Journal** | Steps 8, 13 | Photo gallery |
| 22 | `ReconciliationService` | Steps 7, 8, 9 | Needed by S14 |
| 23 | `ExportImportService` | Steps 8, 9, 13 | Needed by S12 |
| 24 | **S12 — Export / Import** | Step 23 | Data portability |
| 25 | **S13 — About / What's New** | Step 7 | Changelog display |
| 26 | **S14 — Update Review** | Step 22 | Post-update reconciliation |
| 27 | **S16 — Backup Reminder** | Steps 9, 24 | Nudge surface |
| 28 | **S11 — Settings hub** | Steps 15–17, 24–27 | Entry point to all management flows |
| 29 | **S15 — Premium stub** | Step 28 | Placeholder; never activated in v1.0 |

---

## 11. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Bidirectional text rendering** — Hebrew + Latin brand names break in some widgets | Medium | High (core UX) | Test BiDi early (Step 14 routine row); use `Directionality` overrides and `BidiUtils` where Flutter's auto-detection misreads mixed text |
| **Web / iOS Safari storage eviction** — IndexedDB or OPFS cleared by browser | High (iOS Safari) | High (data loss) | Proactive backup reminder (S16); export flow prominent in Settings (S11); surface explicit warning to web users on first launch |
| **sqlite3 WASM on Web** — Drift's web support requires WASM; may have initialization latency | Low-Medium | Medium (startup) | Test Web build on iPhone Safari early; use `drift_flutter`'s `driftDatabase()` factory which handles WASM loading; show loading indicator |
| **Streak algorithm correctness** — grace logic (Sun–Sat week, 3-miss grace, 4th resets) is complex | Medium | Medium (trust) | Unit-test StreakCalculator exhaustively with known scenarios before building S4/S10 (Step 12 before Step 18) |
| **DayRecord snapshot accuracy** — if user never opens S4 on a given day, no snapshot exists | Medium | Low-Medium | For past days with no snapshot, S7 reconstructs from current selection (noting the caveat); this is an acceptable UX tradeoff |
| **Android signing key loss** — admin loses signing key; all user data destroyed on reinstall | Low | Critical | Admin must back up keystore off-device (ops concern, not code); document prominently in admin guide |
| **Export archive compatibility** — future app versions must read archives from older versions | Low | High (data portability) | Version the archive manifest; write a compatibility test per export schema version |
| **Photo storage size on Web** — IndexedDB has browser-imposed storage limits | Medium | Medium | Compress photos before storage; inform users; guide them to export regularly |
| **Flutter Web performance on older iPhones** — WASM + SQLite may be slow on iPhone ≤ 12 | Medium | Medium (UX) | Keep master list <100 products; avoid unnecessary reactive rebuilds; test on iPhone 12 Safari |

---

## 12. Traceability

| Functionality Requirement | Architecture Component(s) |
|--------------------------|--------------------------|
| UC-1 Master list authoring | `assets/data/master_products.json`; `MasterContentRepository` |
| UC-1b Incompatibility rules | `assets/data/incompatibility_rules.json`; `IncompatibilityChecker` |
| UC-2 Product deprecation | `MasterProduct.isDeprecated`; `RoutineResolver` (include deprecated if selected); `RoutineItemRow` deprecated variant |
| UC-3 Release versioning | `MasterListManifest.contentVersion`; `assets/data/changelog.json` |
| UC-4 Product selection (S1) | `SelectionFeature`; **`RoutineScheduler.addProduct/removeProduct`**; `MasterContentRepository` |
| UC-4b Incompatibility feedback | `IncompatibilityChecker`; `SoftWarningBanner` widget; `MutedConflicts` table |
| UC-5 Schedule setup (S2) | `ScheduleFeature`; **`RoutineScheduler.setDays/toggleDay/removeDay/fixProblems`**; `WeekdayPicker` widget |
| UC-6 Order customization (S3) | `OrderingFeature`; **`RoutineScheduler.setOrder/resetOrder`** |
| UC-7 Revise setup | Navigation back to S1/S2/S3 from S11; `IncompatibilityChecker` re-evaluates on change |
| UC-8 View today's routine (S4) | `DailyHomeFeature`; `RoutineResolver`; `DayBoundaryService` |
| UC-9 Record product use | `UserDataRepository.toggleProductDone()`; `RoutineItemRow.onToggleDone` |
| UC-10 Product detail expand | `RoutineItemRow` expanded state; `MasterProduct.imageAsset` + `.comment` |
| UC-11 Calendar history (S6, S7) | `CalendarFeature`; `DayDetailFeature`; `DayRecord` table; `DayCompletionState` enum |
| UC-12 Deprecated product warning | `MasterProduct.isDeprecated`; `RoutineItemRow` deprecated variant; `RoutineResolver` |
| UC-13 Streak tracking (S10) | `StreakCalculator`; `StreakWidget`; `DayRecord` table; `AppSettings.longestStreak` |
| UC-14 Skin log entry (S8) | `SkinLogEntryFeature`; `PhotoRepository`; `SkinLogEntry` table |
| UC-15 Skin journal (S9) | `SkinJournalFeature`; `PhotoRepository.listAll()`; paginated gallery |
| UC-16 Export | `ExportImportService.exportToArchive()`; `PhotoRepository`; `share_plus` |
| UC-17 Import / Merge | `ExportImportService.startMerge()`; `MergeSession`; S12 conflict chooser UI |
| UC-18 Post-update reconciliation (S14) | `ReconciliationService`; `UpdateReviewFeature`; `SettingsRepository.lastKnownMasterVersion` |
| UC-19 Version + changelog (S13) | `AboutFeature`; `MasterListManifest`; `assets/data/changelog.json` |
| UC-20 Backup reminder (S16) | `BackupReminderFeature`; `SettingsRepository.lastExportDate`; `SoftWarningBanner` |
| UC-21 Premium backup (deferred) | `PremiumRepository` stub interface; `S15` placeholder screen; archive format (UC-16) is the natural seed |
| UC-22 Barcode scanning | BarcodeScanSheet; BarcodeProductLookupService; MasterProduct.barcodes; barcode_scan_sheet.dart |
| Supabase remote content | RemoteCachedMasterContentRepositoryImpl; SupabaseMasterContentDataSource; `get_master_content()` RPC; supabase/*.sql |
| NFR-L1–L4 Hebrew RTL, bidi | `AppRoot` (locale + `TextDirection.rtl`); `BidiTextHelper`; `RoutineItemRow` bidi-safe names |
| NFR-M1–M7 Data durability | Stable UUID IDs on all records; `lastModified` on all rows; Drift schema migrations; `ReconciliationService`; export archive versioning |
| Design system (Radiant Dew) | `RadiantDewTheme`; `AppColors`; `AppTypography`; all screens consume tokens |
