# System Architecture
Project: Skincare Routine Tracker
Version: 1.0
Date: 2026-05-26

---

## 1. System Overview

A personal skincare routine tracker built as a single Flutter codebase targeting Android (sideloaded APK) and Web (iPhone/Safari + any browser). An admin encodes expertise as a bundled, read-only master product list; users select their owned products and receive a correctly-ordered daily routine. Tracking is optional and lightweight. All user data lives locally on-device; no backend is required for the free product.

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
        │  ┌───────────────────┐                                     │
        │  │ PremiumRepository │  (stub in v1.0; hookpoint for UC-21)│
        │  └───────────────────┘                                     │
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
| **DailyHomeFeature (S4, S5, S10)** | Today's resolved routine, done-toggles, streak widget, conflict markers, deprecation notices | RoutineResolver, StreakCalculator, IncompatibilityChecker, DayBoundaryService, UserDataRepository |
| **HistoryFeature (S6, S7)** | Calendar grid (four completion states), day detail, past record editing | UserDataRepository, DayBoundaryService |
| **SkinLogFeature (S8, S9)** | Skin log entry (text + photos), chronological journal gallery | PhotoRepository, UserDataRepository |
| **DataManagementFeature (S11–S16)** | Settings hub, export/import, about/changelog, backup reminder, update review, premium placeholder | ExportImportService, ReconciliationService, SettingsRepository, MasterContentRepo |
| **RoutineResolver** | Resolves which products are active for a given date + slot; applies 6am boundary, schedule, deprecated state, and effective order | MasterContentRepo, UserDataRepository, DayBoundaryService |
| **StreakCalculator** | Computes current and longest streak per UC-13 grace rules; reads DayRecords | UserDataRepository, DayBoundaryService |
| **IncompatibilityChecker** | Evaluates admin-authored rules against user's current selection/schedule; distinguishes daily↔daily from day-dependent clashes; respects muted conflicts | MasterContentRepo, UserDataRepository |
| **DayBoundaryService** | Pure function: maps a `DateTime` to the effective `LocalDate` (subtracts 1 day if before 06:00) | none |
| **ReconciliationService** | Compares installed master-list content version to last-known version; identifies new, deprecated, and changed products; preserves user data | MasterContentRepo, UserDataRepository, SettingsRepository |
| **ExportImportService** | Serializes full user dataset + photos into a ZIP archive; deserializes and drives Replace/Merge flow | UserDataRepository, PhotoRepository, SettingsRepository |
| **MasterContentRepository** | Loads and parses bundled JSON assets; provides typed master-list and rules | Flutter asset bundle |
| **UserDataRepository** | All CRUD for user data (selections, schedules, order overrides, day records, skin logs, muted conflicts) via Drift DAOs; reactive streams | Drift database |
| **PhotoRepository** | Platform-abstracted photo storage: read, write, delete, list; used by export | Android: FilesDir adapter; Web: IndexedDB adapter |
| **SettingsRepository** | Key-value store for app settings: last export date, last known master version, schema version | SharedPreferences |
| **PremiumRepository** | Stub in v1.0 (always returns `isActivated: false`); interface is the hookpoint for UC-21 | none in v1.0 |

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

### 3.1 Data Models

#### Master Content (bundled assets — read-only at runtime)

```dart
class MasterProduct {
  final String id;            // stable UUID, never changes across versions
  final String name;          // verbatim; may be Latin brand name
  final String? imageAsset;   // path within Flutter assets
  final String? comment;      // admin's note; Hebrew + bidi
  final String categoryId;
  final SlotConfig? morning;  // null if not in this slot
  final SlotConfig? evening;
  final bool isDeprecated;
  final String addedInVersion; // which content version introduced it
}

class SlotConfig {
  final int order;            // admin's canonical 0-based position
  final FrequencyRule frequencyRule;
}

sealed class FrequencyRule {
  const factory FrequencyRule.daily() = DailyRule;
  const factory FrequencyRule.weeklyMax(int maxPerWeek) = WeeklyMaxRule;
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

// AppSettings uses SharedPreferences (key-value):
// Key: 'last_export_date'         → ISO date string or null
// Key: 'last_known_master_version' → content version string
// Key: 'user_schema_version'      → integer
// Key: 'longest_streak'           → integer (cached for performance)
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

- **No authentication required** — offline-first personal app; no accounts; no network.
- **No data leaves the device** except via user-initiated export (UC-16) or the deferred premium backup (UC-21). This is enforced structurally: no network calls in v1.0 code paths.
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
Bottom Navigation (RTL-mirrored):
  [היום / Today S4] [יומן / Calendar S6] [עור / Skin S9] [הגדרות / Settings S11]
```

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

| Provider | Type | Scope |
|----------|------|-------|
| `masterContentProvider` | `FutureProvider<MasterContent>` | Global — loaded once at startup |
| `effectiveDateProvider` | `Provider<LocalDate>` | Global — recomputed; invalidated at 06:00 |
| `dailyRoutineProvider(date, slot)` | `StreamProvider<List<ResolvedProduct>>` | Per-day; depends on master content + user data streams |
| `dayRecordProvider(date, slot)` | `StreamProvider<DayRecord?>` | Per-day per-slot |
| `streakProvider` | `StreamProvider<StreakResult>` | Global — recomputes when DayRecords change |
| `selectionsProvider(slot)` | `StreamProvider<List<ProductSelection>>` | Per-slot |
| `conflictsForDayProvider(date)` | `Provider<List<ConflictInfo>>` | Per-day; derived from routine + rules |
| `orderOverrideProvider(slot)` | `StreamProvider<OrderOverride?>` | Per-slot |
| `exportImportStateProvider` | `StateNotifierProvider<ExportImportNotifier>` | Feature-scoped |
| `settingsProvider` | `StateNotifierProvider<SettingsNotifier>` | Global |

---

## 9. File Structure

```
skincare_tracker/
├── lib/
│   ├── main.dart                         # Entry point; ProviderScope wrapper
│   ├── app.dart                          # MaterialApp; ThemeData; locale; RTL; routing
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── radiant_dew_theme.dart    # Full ThemeData from DESIGN.md tokens
│   │   │   ├── app_colors.dart           # Color constants
│   │   │   └── app_typography.dart       # TextStyles (Quicksand + Plus Jakarta Sans)
│   │   ├── l10n/
│   │   │   └── app_he.arb               # Hebrew string resources
│   │   ├── utils/
│   │   │   ├── day_boundary.dart         # effectiveDate(DateTime) → LocalDate
│   │   │   ├── bidi_text.dart            # BiDi text widget helpers for bidi product names
│   │   │   └── json_list.dart            # JSON encode/decode helpers for Drift TEXT columns
│   │   └── routing/
│   │       └── app_router.dart           # go_router or Navigator route definitions
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── master_product.dart
│   │   │   ├── category.dart
│   │   │   ├── incompatibility_rule.dart
│   │   │   ├── master_list_manifest.dart
│   │   │   ├── product_selection.dart
│   │   │   ├── weekday_schedule.dart
│   │   │   ├── order_override.dart
│   │   │   ├── day_record.dart
│   │   │   ├── skin_log_entry.dart
│   │   │   └── muted_conflict.dart
│   │   ├── enums/
│   │   │   ├── slot.dart                 # morning | evening
│   │   │   ├── rule_scope.dart
│   │   │   └── day_completion_state.dart # complete | partial | missed | future
│   │   ├── repositories/                 # Abstract interfaces
│   │   │   ├── master_content_repository.dart
│   │   │   ├── user_data_repository.dart
│   │   │   ├── photo_repository.dart
│   │   │   ├── settings_repository.dart
│   │   │   └── premium_repository.dart
│   │   └── services/
│   │       ├── routine_resolver.dart
│   │       ├── streak_calculator.dart
│   │       ├── incompatibility_checker.dart
│   │       ├── reconciliation_service.dart
│   │       └── export_import_service.dart
│   │
│   ├── data/
│   │   ├── bundled/
│   │   │   └── master_content_repository_impl.dart  # Loads assets/data/*.json
│   │   ├── local/
│   │   │   ├── database/
│   │   │   │   ├── app_database.dart     # Drift @DriftDatabase definition
│   │   │   │   ├── tables/               # One file per Drift table
│   │   │   │   ├── daos/                 # SelectionsDao, DayRecordsDao, etc.
│   │   │   │   └── migrations/           # Versioned migration steps
│   │   │   ├── photo_storage/
│   │   │   │   ├── photo_repository_android.dart
│   │   │   │   └── photo_repository_web.dart
│   │   │   └── preferences/
│   │   │       └── settings_repository_impl.dart
│   │   └── repositories_impl/
│   │       └── user_data_repository_impl.dart
│   │
│   ├── features/
│   │   ├── setup/
│   │   │   ├── selection/               # S1 — Product Selection
│   │   │   ├── schedule/                # S2 — Schedule Setup
│   │   │   └── ordering/               # S3 — Order Customization
│   │   ├── daily_home/                  # S4 — Daily Home + S10 Streak widget
│   │   ├── history/
│   │   │   ├── calendar/               # S6 — Calendar
│   │   │   └── day_detail/             # S7 — Day Detail
│   │   ├── skin_log/
│   │   │   ├── entry/                  # S8 — Skin Log Entry
│   │   │   └── journal/                # S9 — Skin Journal
│   │   ├── settings/                   # S11 — Settings hub
│   │   ├── data_management/
│   │   │   └── export_import/          # S12 — Export / Import
│   │   ├── about/                      # S13 — About / What's New
│   │   ├── update_review/              # S14 — Post-update reconciliation screen
│   │   ├── backup_reminder/            # S16 — Backup reminder surface
│   │   └── premium/                    # S15 — License Activation (stub in v1.0)
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── routine_item_row.dart    # S5 component — core shared widget
│       │   ├── soft_warning_banner.dart
│       │   ├── slot_section_header.dart
│       │   ├── category_header.dart
│       │   ├── completion_indicator.dart
│       │   ├── weekday_picker.dart
│       │   └── streak_widget.dart
│       └── providers/
│           └── root_providers.dart      # Global Riverpod providers
│
├── assets/
│   ├── data/
│   │   ├── master_products.json         # Admin-authored product list
│   │   ├── incompatibility_rules.json
│   │   └── changelog.json               # Manifest + version history
│   └── images/
│       └── products/                    # Admin-uploaded product images
│           └── {product_id}.jpg
│
├── test/
│   ├── domain/
│   │   ├── routine_resolver_test.dart
│   │   ├── streak_calculator_test.dart
│   │   ├── incompatibility_checker_test.dart
│   │   └── day_boundary_test.dart
│   ├── data/
│   │   └── export_import_test.dart
│   └── features/
│       └── daily_home/
│           └── daily_home_widget_test.dart
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
| UC-4 Product selection (S1) | `SelectionFeature`; `UserDataRepository.upsertSelection()`; `MasterContentRepository` |
| UC-4b Incompatibility feedback | `IncompatibilityChecker`; `SoftWarningBanner` widget; `MutedConflicts` table |
| UC-5 Schedule setup (S2) | `ScheduleFeature`; `UserDataRepository.upsertSchedule()`; `WeekdayPicker` widget |
| UC-6 Order customization (S3) | `OrderingFeature`; `UserDataRepository.upsertOrderOverride()` |
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
| NFR-L1–L4 Hebrew RTL, bidi | `AppRoot` (locale + `TextDirection.rtl`); `BidiTextHelper`; `RoutineItemRow` bidi-safe names |
| NFR-M1–M7 Data durability | Stable UUID IDs on all records; `lastModified` on all rows; Drift schema migrations; `ReconciliationService`; export archive versioning |
| Design system (Radiant Dew) | `RadiantDewTheme`; `AppColors`; `AppTypography`; all screens consume tokens |
