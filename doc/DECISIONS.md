# Technical Decisions Log
Project: Skincare Routine Tracker

## Purpose
Persists architectural and implementation decisions across task contexts. Each agent reads relevant decisions before starting a task to avoid contradicting earlier choices.

---

## Decisions

### Flutter / Dart

#### DEC-001: State Management — Riverpod 2.x
**Date**: 2026-05-26
**Context**: Needed reactive state management for a Flutter app with Drift streams and multiple interdependent data sources.
**Decision**: Use `flutter_riverpod ^2.5` with `riverpod_annotation` for code generation.
**Rationale**: Integrates cleanly with Drift's `Stream`-based queries; composable providers; less boilerplate than BLoC for a personal app; scoped overrides work well for testing.
**Alternatives Rejected**: BLoC (excessive boilerplate), Provider (superseded by Riverpod).
**Affects Tasks**: TASK-018 and all screen tasks.

#### DEC-002: Local Database — Drift 2.x
**Date**: 2026-05-26
**Context**: Need SQLite-based local storage that works on both Android and Web.
**Decision**: Use `drift ^2.18` with `drift_flutter ^0.2.1` which handles Android (sqflite) and Web (sqlite3 WASM) transparently.
**Rationale**: Type-safe schema with code generation; reactive Stream watchers; built-in migrations; cross-platform.
**Alternatives Rejected**: Isar (no stable Web support); raw sqflite (no Web); Hive (no relational queries needed).
**Affects Tasks**: TASK-007, TASK-008, TASK-010.

#### DEC-003: Navigation — go_router 14.x
**Date**: 2026-05-26
**Context**: Need declarative routing for Flutter with deep links and a bottom nav shell.
**Decision**: Use `go_router ^14.2` with `StatefulShellRoute.indexedStack` for bottom nav.
**Rationale**: Official Flutter team package; deep-link support; declarative; shell routes handle persistent bottom nav correctly.
**Alternatives Rejected**: Navigator 2.0 directly (verbose), auto_route (heavy).
**Affects Tasks**: TASK-004, all screen tasks.

---

### Data Architecture

#### DEC-004: Stable String IDs for All Records
**Date**: 2026-05-26
**Context**: Records need to survive import/export, merge conflict resolution, and future premium cloud backup.
**Decision**: All records use `String id` (UUID v4 generated at creation). Never use auto-increment integers.
**Rationale**: UUIDs are globally unique across devices; required for merge-conflict resolution (UC-17) and future premium cloud backup (UC-21 NFR-M7).
**Alternatives Rejected**: Auto-increment integers (not portable), composite natural keys (fragile on renames/reorders).
**Affects Tasks**: TASK-006, TASK-007, TASK-010, TASK-017.

#### DEC-005: Day Boundary at 06:00 Local Time
**Date**: 2026-05-26
**Context**: PRD requires activity before 6am to credit to the prior calendar day.
**Decision**: `DayBoundaryService.effectiveDate(DateTime)` subtracts 1 day if `hour < 6`. All date strings stored as `'YYYY-MM-DD'` of the *effective* date (already adjusted).
**Rationale**: Matches PRD UC-8 and UC-13 exactly. Applying the boundary at write time simplifies all read queries.
**Alternatives Rejected**: Apply boundary at read time (complex, error-prone in queries).
**Affects Tasks**: TASK-012, TASK-013, TASK-015, TASK-024.

#### DEC-006: DayRecord Created on First S4 View (Snapshot)
**Date**: 2026-05-26
**Context**: S7 (Day Detail) must show the routine "as it was on that day." Master list can change in future updates.
**Decision**: When a user opens S4 (Daily Home) for a given effective date + slot, create a `DayRecord` with `resolvedProductIds` snapshot if one doesn't exist. `snapshotAndGetDayRecord()` in UserDataRepository handles idempotent creation.
**Rationale**: Snapshot must be taken while the current master list is known. Future updates will change the master list; historical records reference product IDs which are stable (never deleted from master, only deprecated).
**Alternatives Rejected**: Reconstruct from current selection (inaccurate after updates); midnight cron (no background tasks in v1.0).
**Affects Tasks**: TASK-010, TASK-024, TASK-028.

#### DEC-007: Export Format — ZIP with JSON + Photo Files
**Date**: 2026-05-26
**Context**: Need a portable, open, single-file backup format for UC-16/17.
**Decision**: ZIP archive containing `manifest.json`, `user_data.json` (UserDataExport serialized), and `photos/` directory with raw JPEG bytes. Using `archive` package for pure-Dart ZIP support.
**Rationale**: ZIP is universally understood; open format; JSON is human-readable and versionable; photo bytes are inline. Works on both Android and Web (pure Dart).
**Alternatives Rejected**: SQLite dump (not portable across schema versions); tar (less tool support); custom binary (opaque).
**Affects Tasks**: TASK-017, TASK-029, TASK-030.

---

### Platform

#### DEC-008: Photo Storage Strategy
**Date**: 2026-05-26
**Context**: Photos must be stored locally on both Android and Web, with platform-specific APIs.
**Decision**: Abstract `PhotoRepository` interface. Android: app documents directory (`{appDocDir}/skin_photos/{key}.jpg`). Web: IndexedDB blob store. Both store photos at max 1080px (compressed via `flutter_image_compress`).
**Rationale**: iOS Safari has no persistent file system; IndexedDB is the most durable Web option (though still evictable). Abstraction allows clean platform-specific implementations.
**Alternatives Rejected**: Force same approach on both (impossible — no file system API in browser); OPFS only (Safari OPFS support is newer and still evictable).
**Affects Tasks**: TASK-011, TASK-025, TASK-034.

#### DEC-009: RTL Configured at MaterialApp Root
**Date**: 2026-05-26
**Context**: The entire UI is Hebrew RTL. Per PRD NFR-L1.
**Decision**: `MaterialApp.router(locale: Locale('he'), localizationsDelegates: AppLocalizations.localizationsDelegates)`. Flutter mirrors RTL automatically. Per-screen `Directionality` override NOT used.
**Rationale**: One configuration point; all widgets mirror automatically; avoids per-screen mistakes.
**Exception**: Product names and category names (admin-authored, may be Latin) must use `Directionality(TextDirection.ltr)` or let Unicode BiDi algorithm handle them naturally. A helper `_isLikelyLatin(String)` detects pure-ASCII names for forced LTR wrapping.
**Affects Tasks**: TASK-003, TASK-004, TASK-019, all screen tasks.

#### DEC-010: COOP/COEP Headers for sqlite3 WASM
**Date**: 2026-05-26
**Context**: sqlite3 WASM (used by drift_flutter for Web) requires SharedArrayBuffer, which needs Cross-Origin isolation.
**Decision**: Add `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` meta tags to `web/index.html`. Admin must configure the web server to send these headers.
**Rationale**: Required for sqlite3 WASM to function on iOS Safari and other browsers.
**Alternatives Rejected**: Polling-based SQLite without SharedArrayBuffer (slower, less reliable).
**Affects Tasks**: TASK-035.

---

### Business Logic

#### DEC-011: Incompatibility Warnings Are Always Advisory
**Date**: 2026-05-26
**Context**: PRD UC-4b specifies conflicts never block user actions.
**Decision**: `IncompatibilityChecker` only returns `ConflictInfo` objects. No UI widget should prevent a user action based on conflict detection. Warnings are displayed as `SoftWarningBanner` which is always dismissible. The mute mechanism is per-rule-id, stored in `muted_conflicts` table.
**Rationale**: PRD is explicit: "advisory only — never prevent a selection or schedule." (UC-4b)
**Affects Tasks**: TASK-014, TASK-021, TASK-022, TASK-024.

#### DEC-012: Weekday Numbering Convention
**Date**: 2026-05-26
**Context**: Schedule weekdays stored as integers. Dart's `DateTime.weekday` uses Mon=1..Sun=7.
**Decision**: Store weekdays as `Set<int>` where 0=Sunday, 1=Monday, ..., 6=Saturday (matching the PRD's "Sunday-first" Sun–Sat week). Conversion: `dartWeekday % 7` converts Dart's Sunday=7 to 0.
**Rationale**: PRD explicitly states Sunday-first for the cap week (UC-5) and calendar display. This avoids confusion in `StreakCalculator` and `RoutineResolver`.
**Affects Tasks**: TASK-006, TASK-012, TASK-013, TASK-015, TASK-022.

#### DEC-013: Products Never Deleted From Master List
**Date**: 2026-05-26
**Context**: PRD UC-2 specifies deprecated, never deleted. User DayRecords reference product IDs from historical snapshots.
**Decision**: The master `products` JSON never removes a product entry. Products get `isDeprecated: true`. UserDataRepository never breaks on orphaned product IDs (old DayRecords may reference IDs not in the current master list — these render with a fallback "unknown product" display).
**Rationale**: Historical accuracy in Day Detail (S7) depends on stable IDs. Deletions would corrupt history.
**Affects Tasks**: TASK-009, TASK-028, TASK-032.
