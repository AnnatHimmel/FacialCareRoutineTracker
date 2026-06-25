# Technical Decisions Log
Project: Skincare Routine Tracker

## Purpose
Persists architectural and implementation decisions across task contexts. Each agent reads relevant decisions before starting a task to avoid contradicting earlier choices.

---

## Decisions

### MOD-DEC-BAR-001: Barcode Product Lookup via Open Beauty Facts + UPC Item DB
**Date**: 2026-06-15
**Request**: Wire live product lookups into the barcode scanning stub. Query Open Beauty Facts and UPC Item DB in parallel, merge results, and pre-fill AddCustomProductSheet with the retrieved name/brand/image/ingredients.
**Decision**: New `BarcodeProductLookupService` (injectable `http.Client`) queries both APIs concurrently via `Future.wait`. Merge: OBF values preferred, UPC Item DB used as fallback per field. Result mapped to `ScannedProductInfo` value object. `BarcodeScanSheet` converts to `ConsumerStatefulWidget` and gains three new states: `lookingUp`, `productFound`, `productNotFound`. `AddCustomProductSheet` gains optional `prefillFromScan: ScannedProductInfo?` param that pre-fills name (brand+name concatenated), comment (ingredients), and shows a network image preview.
**Rationale**: Both APIs are free and require no API key, making the feature zero-config. Parallel queries minimize latency. Per-field merge maximises data completeness. Pre-filling reduces user effort without locking any field.
**Alternatives Rejected**: Sequential API calls (higher latency); storing network image URL as photoKey (photoKey is for local storage, not remote URLs); auto-selecting category (categories are admin-curated IDs with no reliable mapping from external taxonomy).
**Future APIs**: EAN-Search.org, Go-UPC.com (require keys), Barcode Monster (free, limited) — service is designed for extension.
**Affects Files**: `pubspec.yaml`, `scanned_product_info.dart` (new), `barcode_lookup_service.dart` (new), `barcode_scan_sheet.dart`, `add_custom_product_sheet.dart`, `root_providers.dart`, ARB l10n files.

**Updated 2026-06-17:** Implementation was extended to 5 APIs total (OpenBeautyFacts, OpenFoodFacts, UPCItemDB, InciBeauty, BarcodeSpider). Master-product matching was also added — see DEC-015 for the full lookup strategy.

**Updated 2026-06-23:** The lookup pipeline is now multi-tier and combines the barcode APIs with HTML scrapers (see also MOD-DEC-001, which describes the same scraping technique in the standalone admin tool). `BarcodeProductLookupService.lookup(barcode)` runs three tiers and merges them (first non-null field wins; images concatenated then deduped at the address level, http/https folded):
- **Tier 1 — barcode-capable scrapers** queried with the raw barcode (highest priority for the fields they return). Scrapers expose `supportsBarcodeSearch`; currently `YesStyleScraper` and `IHerbScraper` return `true`. Site-level / Cloudflare-challenge titles are rejected via a name pattern.
- **Tier 2 — the 5 barcode-lookup APIs** above, merged among themselves (priority OBF > OFF > UPC > InciBeauty > BarcodeSpider). **UPC Item DB is still used** (its `description` is mapped to `comment`, not `ingredients`, since it is marketing copy not INCI).
- **Tier 3 — name-only scrapers** augment gaps using the resolved product name (falling back to the barcode if no name yet).

The registered scrapers (`barcodeProductLookupServiceProvider` in `root_providers.dart`) are: `OpenBeautyFactsNameSearchScraper`, `OliveYoungGlobalScraper`, `YesStyleScraper`, `IHerbScraper`, `IncidecoderScraper` (last — fills ingredients/images, lowest brand confidence). iHerb was added as a source on 2026-06-23. Most scrapers are **Android-only** (web CORS blocks the cross-origin HTML fetches and return null on `kIsWeb`). A separate `lookupByName(name, {brand})` entry point powers the manual "find the details for me" flow, querying only the name-search scrapers.
**Affects Files (additions):** `retailer_search_scraper.dart`, `scrapers/{open_beauty_facts_name_search_scraper,olive_young_global_scraper,yes_style_scraper,iherb_scraper,incidecoder_scraper}.dart`.

### MOD-DEC-BAR-002: Cache Version Guard for Master Content
**Date**: 2026-06-17
**Request**: After adding `barcodes` to `master_products.json` and bumping `contentVersion` to `1.0.1`, existing devices still returned 0/33 products with barcodes because `RemoteCachedMasterContentRepositoryImpl.load()` always preferred the SharedPreferences cache over the bundled asset with no version check.
**Decision**: `load()` always loads the bundled asset first (fast — `MasterContentRepositoryImpl` caches the result in-memory), then reads the cache. If the cached `contentVersion` is older than the bundled version (per semantic version comparison), the cache is cleared and the bundled content is used. If the cache is same or newer (Supabase may have pushed a newer version), the cache wins.
**Rationale**: A new app release may add fields to master products (barcodes, ingredients). Without a version guard, users with a cached version from before the field was added would never see the new data until Supabase refreshed. The bundled asset is always the floor; Supabase refresh can push above the floor.
**Affects Files**: `remote_cached_master_content_repository_impl.dart`, `assets/data/changelog.json` (contentVersion `1.0.0` → `1.0.1`), `remote_cached_master_content_repository_test.dart`.

### MOD-DEC-SUP-001: Supabase Remote Product Database
**Date**: 2026-06-15
**Request**: Replace bundled JSON master product list with live Supabase (PostgreSQL + Storage) data source, fetched on S1 entry and cached locally. Product `name` field split into `brand` + `name`.
**Decision**: Add `RemoteCachedMasterContentRepositoryImpl` that composes: (1) `SupabaseMasterContentDataSource` (single RPC call), (2) `SharedPrefsMasterContentCache` (JSON string in SharedPreferences), (3) `MasterContentRepositoryImpl` as bundled first-launch fallback. `MasterProduct` entity gains `brand: String?`. `ProductThumb` gains HTTPS URL branch using `cached_network_image`.
**Rationale**: Offline-first preserved — network never blocks load; cache outlasts sessions; bundled JSON is permanent fallback. Single RPC avoids 4 round-trips. Existing `MasterContentRepository` interface unchanged.
**Alternatives Rejected**: Static file hosting (no admin CRUD UI for images); 4 separate table fetches (extra latency); replacing bundled JSON (loses first-launch offline).
**Affects Files**: `MasterProduct`, `MasterContentRepositoryImpl`, `ProductThumb`, `root_providers.dart`, `main.dart`, `product_selection_screen.dart`, 8 new files.

**Updated 2026-06-23:** Confirmed against `supabase_master_content_data_source.dart` (single `rpc('get_master_content')` call), `remote_cached_master_content_repository_impl.dart`, and `shared_prefs_master_content_cache.dart`. Notes on current behavior:
- Supabase project ref is `ddrxzzeplokmkzizailn`. The URL and anon key are injected at build time via `--dart-define` (`SupabaseConfig.url` / `.anonKey` are `String.fromEnvironment`), not hardcoded.
- `load()` is offline-first and never hits the network: it loads the bundled asset, then prefers the SharedPreferences cache **only if its `contentVersion` is ≥ the bundled version** (the version guard from MOD-DEC-BAR-002); otherwise it clears the stale cache and uses bundled.
- `refresh()` (separate from `load()`) fetches from Supabase and **merges by ID — remote wins on collision, bundled-only items are appended** (so a Supabase lag never drops bundled products), then writes the merged result to cache. The repo implements `RefreshableRepository`.

### MOD-DEC-SUM-003: Unify the "Routine Ready" Summary on a Single `/routine-ready` Route
**Date**: 2026-06-25
**Request**: The summary screen was inconsistent — "not all paths of adding / removing / selecting show the summary screen." The main shelf "add products" path never showed it at all.
**Decision**: Replace the three divergent mechanisms (onboarding in-tree view swap; the never-reached `/add-product` in-tree swap; a bespoke `rootNavigator.push` / `/routine-summary?extra=` for custom add/remove) with **one** go_router route, `/routine-ready` (`RoutineReadyRoute`, `lib/features/setup/routine_ready_route.dart`). The route **builds the summary itself** from `routineSchedulerProvider.buildRoutineSummary(master, extraProducts: customProducts.map(toMasterProduct))`, renders `RoutineReadySummaryScreen`, and its single CTA hands off to the shelf via `context.go('/collection')`. If the summary can't be built it redirects to `/collection` so the flow never dead-ends. Every routine-changing commit point now `context.go('/routine-ready')` once its mutations are persisted:
- `ScheduleSetupScreen._handleContinue` products-flow branch (was `/today`) — covers the home "add products" button and the Collection "+" FAB (both funnel S1→S2).
- `AddCustomProductSheet._save` (add/edit, when a slot is touched) and both remove/delete flows (was `rootNav.push`/`/routine-summary`). Uses `GoRouter.maybeOf` so plain-`MaterialApp` widget tests stay green.
- `OrderCustomizationScreen._save` `fromSetup` branch (was `/today`) — setup ends with the summary once.
- Onboarding keeps its in-tree summary (well-tested, reliable); only its CTA destination moved to `/collection` via the router's `onFinish`.
The redundant `/routine-summary` route was removed.
**Rationale**: Centralizing the build in the route (a) kills the duplication where each caller re-built the summary, (b) fixes a latent repeat of the MOD-DEC-SUM-002 bug — the custom add/remove callers built the summary **without** `extraProducts`, so any *other* custom product in the routine could still make `buildRoutineSummary` throw, and (c) survives a web refresh (no reliance on `GoRouter` `extra`, which is null after reload). CTA → shelf and "summary after each shelf add/remove, once at setup end" per the product owner's explicit choice.
**Alternatives Rejected**: Passing the pre-built summary via `GoRouter` `extra` (the removed `/routine-summary` approach — loses data on web refresh, re-duplicates the build, keeps the extraProducts bug); migrating onboarding's in-tree swap to the route (working + heavily tested, not worth the regression risk); showing the summary after every individual barcode scan (a scan is mid-session, not a commit point — it surfaces at the S2 continue instead).
**Affects Files**: `lib/features/setup/routine_ready_route.dart` (new), `lib/core/routing/app_router.dart`, `lib/features/setup/schedule_setup_screen.dart`, `lib/features/setup/add_custom_product_sheet.dart`, `lib/features/setup/order_customization_screen.dart`, and the matching tests (`routine_ready_route_test.dart` new, `schedule_setup_screen_test.dart`, `order_customization_screen_test.dart`).

### MOD-DEC-SUM-001: "Routine Ready" Summary After the Auto-Sorter
**Date**: 2026-06-24
**Request**: Every time the auto-sorter builds a routine — onboarding completion, after adding a product, after removing a product — show the user a screen summarizing the decisions the sorter made (reference: `auto-reorder message ref.jpg`).
**Decision**: Add `RoutineScheduler.buildRoutineSummary({master})` returning a `RoutineBuildSummary` value object (`lib/domain/services/routine_build_summary.dart`) and a presentation-only full-screen `RoutineReadySummaryScreen` (`lib/features/setup/routine_ready_summary_screen.dart`). The summary carries: distinct/per-slot product counts; a "what we arranged" list (`RoutineChange` — slot + `RoutineChangeKind` {movedDays, reducedFrequency, movedSlot} + the resolver's localized text); and a "worth noting" list (`RoutineAdvisory`). `fixProblems` was extended with an additive `changes` field (slot + kind per resolved conflict) feeding the first list. The screen is pushed via plain `Navigator.push` from all three flows; its single CTA navigates to `/today`.
**Rationale**: All decision data already existed (`RoutineFixResult.changeDescriptions`, `ConflictResolution.description`, `IncompatibilityChecker`); the change is mostly aggregation + presentation. `buildRoutineSummary` lives on the scheduler so routine reads stay funnelled through the single source of truth (§3.0). Advisories are defined as pairs that **still co-occur on a weekday after the fix** — since the resolver separates every conflict it acts on, what remains are the pairs the user chose to keep together (muted), matching the reference's "we didn't block — just a recommendation".
**Alternatives Rejected**: Reporting only the just-added product's changes (header counts in the reference imply a holistic view); a modal bottom sheet (too cramped for header + two sections + CTA); an Undo affordance on the screen (reference shows none — the text says "you can always change", users edit manually in S2/S3); skipping the screen when nothing changed (user chose **always show**, header-only).
**Affects Files**: `routine_scheduler.dart`, new `routine_build_summary.dart`, new `routine_ready_summary_screen.dart`, `onboarding_screen.dart`, `add_product_flow_screen.dart`, `add_custom_product_sheet.dart`, `app_he.arb`/`app_en.arb` (8 `routineReady*` keys), and tests.

### MOD-DEC-FIX-003: Slot-Separation Conflict Not Applied to Pre-Existing Bi-Slot Products
**Date**: 2026-06-24
**Request**: Selecting Argireline (bi-slot, daily) then Vita C (morning-only, daily) did not move Argireline to evening-only at product selection time, leaving a conflict unresolved on the morning schedule screen.
**Decision**: Two bugs were fixed.

**Bug 1 — `_resolveSlotConflicts` guard too broad** (`lib/features/setup/product_selection_screen.dart`): The guard `if (m.productId != newProductId) continue` skipped ALL mutations for existing products, including safe slot-separation mutations. The guard was tightened: if `m.productId != newProductId`, we now only skip the mutation unless (a) the mutated product is bi-slot (has a config in the other slot) AND (b) the mutation completely clears the slot (`days = {}`). These are always-safe: the product still lives in the other slot, so no frequency is lost.

**Bug 2 — supplemented-mutations in `fixProblems` cleared the stayer** (`lib/domain/services/routine_scheduler.dart`): The supplemented-mutations loop (designed to write explicit suppression rows for DailyRule yielders who received `{}` target days via day-separation but no mutation) also fired on the non-mover partner in a slot-separation. For the Vita C + Argireline case this wrote `{vitaC, morning, {}}`, removing Vita C from morning entirely. Fix: before supplementing, check if the conflict partner already has a `days={}` mutation in `supplemented`. If yes, this was a slot-separation — this product is the stayer and must not be suppressed.

**Rationale**: Slot-separation is always safe (the mover retains its other slot). The original guard was a deliberate conservative choice to avoid modifying existing products during onboarding, but it was too broad. The supplemented-mutations fix is targeted: it only changes behavior for the non-mover in a slot-separation, leaving all day-separation logic untouched.
**Alternatives Rejected**: Re-ordering product selection to always add the fixed-slot product first (fragile, depends on user gesture order); always re-running the full resolver from scratch (would require all slots to be rechecked on each selection, O(n²)); removing the supplemented-mutations step entirely (needed for day-separation edge cases where yielder ends up with 0 days).
**Affects Files**: `lib/features/setup/product_selection_screen.dart`, `lib/domain/services/routine_scheduler.dart`, `test/playwright/tests/schedule.spec.ts` (new e2e regression test).

### MOD-DEC-SUM-002: Custom Products Invisible to RoutineScheduler after Add-Product Flow
**Date**: 2026-06-24
**Request**: After adding a custom product through the "add product" flow, the product did not appear in the weekly glance and the RoutineReadySummaryScreen was never shown — only the simpler `_SuccessScreen`.
**Decision**: Three methods in `RoutineScheduler` now accept `List<MasterProduct> extraProducts = const []` and build a combined list `[...master.products, ...extraProducts]`:
- `addProduct` — changed `master.products.firstWhere(...)` → `firstWhereOrNull` on the combined list; null-guards `configForSlot` call; short-circuits index computation for custom products (returns 0).
- `weekGlance` — passes combined list as `allProducts` to `WeekGlanceBuilder.build`.
- `buildRoutineSummary` — `isLive()` and `slotProducts()` use the combined list; `firstWhereOrNull` from `package:collection` replaces manual `.where(...).firstOrNull` chain.
`weekGlanceProvider` in `root_providers.dart` reads `customProductsProvider` and passes `.map(toMasterProduct())` as `extraProducts`. `_save()` in `AddProductFlowScreen` reads `customProductsProvider` and passes `extraProducts` to both `addProduct` and `buildRoutineSummary`.
Additionally, `_save()` in `AddProductFlowScreen` was wrapped in an outer `try/catch` (in addition to the existing inner one for `buildRoutineSummary`) — this ensures `setState(() => _step = _Step.success)` is always reached even if a mid-save step throws, preventing the screen from freezing on the placement step when called without `await`. `package:collection` was also added to `pubspec.yaml` as a direct dependency (previously only transitive).
**Rationale**: `_save()` was called without `await` from `_advance()`, so any exception thrown before `buildRoutineSummary` (e.g., in `addProduct` for custom-product IDs) became an unhandled future — the success step was never reached and the screen froze. The outer catch ensures the screen always advances. Adding `collection` as a direct dependency makes the `firstWhereOrNull` import explicit and resilient to transitive-dependency changes.
**Alternatives Rejected**: Merging custom products into `MasterContent` at the provider level (couples two independent data domains); routing custom-product reads through `UserDataRepository` directly from the screen (violates the single-source-of-truth rule for routine data in §3.0); awaiting `_save()` in `_advance()` (would require converting `_advance` to async and propagating through all callers).
**Affects Files**: `lib/domain/services/routine_scheduler.dart`, `lib/shared/providers/root_providers.dart`, `lib/features/setup/add_product_flow_screen.dart`, `pubspec.yaml`.

### MOD-DEC-ONB-001: Reorder Onboarding Setup-Wizard Stage Sequence
**Date**: 2026-06-25
**Request**: The onboarding wizard showed the auto-sort "routine ready" summary at the very end of Step 3, after the user had already hand-customized every schedule and order — making the auto-sort framing too late to be useful. An evening-transition interstitial between AM and PM steps was also unwanted. The user requested the summary be moved up front (right after category approval) so it frames the per-slot review, and the flow to end on the week-at-a-glance screen with a celebratory CTA.
**Decision**: Reordered the `_SetupStage` enum in `OnboardingScreen` and rewired stage transitions as follows:

1. `products` — product selection (unchanged)
2. `categoryReview` — sub-category approval (unchanged)
3. `routineSummary` (NEW position) — auto-sort summary shown in-tree; CTA label `routineReadyReviewSlotCta(slot)` → first active slot's schedule step
4. `amSchedule` — morning weekly timing
5. `amOrder` — morning order override
6. `pmSchedule` — evening weekly timing (reached directly from `amOrder`; no transition screen)
7. `pmOrder` — evening order override
8. `WeekGlanceScreen` (onboarding mode: `onboarding: true`, no back button) — CTA `weekGlanceStartGlowingCta` ("הכול מסודר, אפשר להתחיל") → `/today`

The `eveningTransition` stage and its `_EveningTransitionStep` widget are removed. `_afterMorningOrder()` advances directly to `pmSchedule`. `pmSchedule` back-target is `amOrder` when morning exists, else `routineSummary`. `_handleFinish()` drops all summary-building; it persists name/gender + `setOnboardingCompleted(true)` then calls `widget.onFinish()` which routes to `/week-glance?onboarding=true`. The `/week-glance` route builder reads `state.uri.queryParameters['onboarding'] == 'true'` and passes it to `WeekGlanceScreen(onboarding: ...)`.

Edge case — evening-only routine (no morning products): stages 4–5 (amSchedule, amOrder) are skipped; the `routineSummary` CTA reads "נתחיל עם שגרת הערב" and navigates directly to `pmSchedule`.

Two new localization keys: `routineReadyReviewSlotCta(slot)` (he/he_MA: "נתחיל עם שגרת ה{slot}"; en: "Let's start with your {slot} routine") and `weekGlanceStartGlowingCta` (he/he_MA: "הכול מסודר, אפשר להתחיל"; en: "You're all set, let's glow").

`RoutineReadySummaryScreen` gains an optional `String? ctaLabel` parameter (defaults to existing `routineReadyCta` when null) to support the in-onboarding slot-specific label without changing existing non-onboarding call sites.

**Rationale**: Showing the auto-sort result up front gives the user context before they start tweaking schedules and order — otherwise they see optimized schedule advice without knowing what the sorter did to their routine. Removing the evening-transition interstitial reduces friction with no information loss. Ending on the week-at-a-glance screen gives a celebratory, at-a-glance confirmation that the whole routine is wired up before entering daily use.
**Alternatives Rejected**: Keeping the summary at the end (too late — user has already made changes on top of an unseen base); keeping the evening-transition screen (per user request, no value added); routing from onboarding directly to `/today` without a week-glance step (loses the celebratory end-of-setup moment and the "see your whole week" orientation).
**Affects Files**: `lib/features/onboarding/onboarding_screen.dart`, `lib/features/setup/routine_ready_summary_screen.dart`, `lib/features/home/week_glance_screen.dart`, `lib/core/routing/app_router.dart`, `lib/l10n/app_he.arb`, `lib/l10n/app_he_MA.arb`, `lib/l10n/app_en.arb`.

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

### Admin Portal

#### MOD-DEC-001: Admin Portal as a Separate Node.js Tool
**Date**: 2026-05-28
**Request**: Admin wants to bulk-import products from YesStyle/OliveYoung/iHerb URLs and edit them before bundling.
**Decision**: Build a standalone Node.js + Express local web server (`admin/`) with a vanilla HTML/JS frontend. The tool scrapes product pages server-side (avoiding CORS), presents editable product cards, and downloads the final `master_products.json`. It is never part of the Flutter app.
**Rationale**: Server-side scraping bypasses CORS entirely. Node.js has mature scraping libraries (axios + cheerio). A separate tool keeps admin authoring logic out of the user app. Local-only run model means no auth needed, no deployment costs.
**Alternatives Rejected**: Client-side fetch (CORS blocked); adding admin screens to Flutter app (bloats APK, poor UX for content authoring); headless browser (heavier, slower startup).
**Affects Tasks**: MOD-001 through MOD-006.

**Updated 2026-06-23:** This decision still holds for the **admin authoring** workflow (master-list curation stays in the standalone Node tool). It is, however, no longer the *only* place scraping happens: the Flutter **user** app now scrapes retailer pages at runtime for the barcode-scan / "find details" flows (see MOD-DEC-BAR-001 update and DEC-015). That in-app scraping is Android-only because the browser CORS rationale above still applies on web — the scrapers return null on `kIsWeb`.

#### MOD-DEC-002: Scraper Fallback to Manual Entry
**Date**: 2026-05-28
**Decision**: If a retailer page fails to scrape (network error, anti-bot, HTML change), the portal creates an empty card with the URL saved as a reference field, allowing admin to fill fields manually. Scraper failures are surfaced per-card, not as a global error.
**Rationale**: Scrapers are brittle by nature. Admin productivity should not be blocked by a single failing URL. The URL is preserved for manual lookup.

#### MOD-DEC-003: Export-Only — No Auto-Write
**Date**: 2026-05-28
**Decision**: The admin portal never writes directly to `assets/data/master_products.json`. The "Save" action always triggers a browser file download. The admin copies the file manually.
**Rationale**: Prevents accidental overwrite. Keeps the tool safe even if run from a wrong directory. Clear audit trail — admin explicitly places the file.

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

---

### UI / Navigation

#### DEC-014: My Products as a Persistent Bottom-Nav Tab
**Date**: 2026-06-15
**Context**: The app needed a way to browse and change product selections post-setup without going through the full guided wizard. The existing `ProductSelectionScreen` already had a `fromSetup` parameter; the browse mode was the natural addition.
**Decision**: The second bottom-nav tab (`/products`) renders `ProductSelectionScreen(isTabDestination: true)` — a browse view with a search bar, slot filter chips (All / Morning / Evening), and a full product list grouped by category. The guided step-by-step wizard (S1) is a separate route (`/setup/selection`) used only during onboarding and from Settings.
**Rationale**: A persistent tab gives users immediate access to product management without re-entering the setup flow. The same `_SelectRow` component works in both modes, keeping the implementation DRY.
**Alternatives Rejected**: Single wizard-only entry from Settings (poor discoverability); separate screen with duplicate widget code (unnecessary duplication).

#### DEC-015: Barcode Scanning — Master-First Lookup with External API Fallback
**Date**: 2026-06-17 (updated from original 2026-06-15)
**Context**: Original decision deferred product lookup. Lookup has now been implemented.
**Decision**: `_performLookup` in `BarcodeScanSheet` checks master products first (by the new `MasterProduct.barcodes` field), then falls through to 5 external APIs only if no master match. External APIs run in parallel via `Future.wait`; results merged by priority (OBF > OFF > UPC > InciBeauty > BarcodeSpider). `masterContentProvider` is awaited via `await ref.read(masterContentProvider.future)` (NOT `.valueOrNull`) to ensure the async provider resolves before the check runs. When a master product is matched: "Recognized product" UI shown with slot chips and one-tap "Add to Routine"; if the product is already in all applicable slots, "Already in your routine" badge is shown instead. When no master match: external API result pre-fills `AddCustomProductSheet`.
**Rationale**: Master-first avoids unnecessary external API calls for known products and gives a higher-quality result (correct name, correct slots, admin-curated). External APIs remain as fallback for products not yet in the master list.
**Key gotcha**: Using `.valueOrNull` instead of `await ...future` returns null when the FutureProvider hasn't resolved yet, causing the master check to be silently skipped. Always await the future.
**Affects Files**: `barcode_scan_sheet.dart`, `master_product.dart`, `master_content_serializer.dart`, `assets/data/master_products.json`, l10n ARBs.

#### DEC-016: Weekly Skin-Tracking Reminder — Cadence Derived From Skin Logs
**Date**: 2026-06-24
**Context**: The Daily Home screen (S4) needed a recurring, dismissible nudge prompting the user to photograph and note her skin roughly once a week.
**Decision**: Eligibility is computed in `DailyHomeScreen` from three signals: (1) the real skin-log stream (`_allSkinLogsProvider` → `UserDataRepository.watchAllSkinLogs`) — the card hides when any entry with a photo is dated within the last 7 days (rolling); (2) a local settings flag `weekly_photo_reminder_dismissed_date` (`SettingsRepository.get/setWeeklyPhotoReminderDismissedDate`) — "אחר כך" snoozes the card for the remainder of that effective day only; and (3) a master on/off flag `weekly_photo_reminder_enabled` (default true, `get/setWeeklyReminderEnabled`, exposed via `weeklyReminderEnabledProvider`) — flipped false by the card's "אל תציג שוב" (never show again) action **and** by a Settings toggle ("תזכורת תיעוד שבועי"), keeping the two in sync via provider invalidation. The card is additionally gated to render only when a routine exists (mirroring the existing bottom journal CTA), and capture is inline (`WeeklySkinReminderCard` writes the photo + optional note to today's skin-log entry). Both the snooze date and the enabled flag are exposed as reactive providers (`weeklyReminderDismissedDateProvider`, `weeklyReminderEnabledProvider`) so toggles reflect on the home screen without a restart. A **debug-only** Settings action ("הצג שוב תזכורת שבועית", gated by `kDebugMode`) re-enables the reminder and clears the day's snooze so it can be re-triggered during development; it is stripped from release/profile builds.
**Rationale**: Deriving "has a recent photo" from the actual skin logs keeps a single source of truth — a photo taken anywhere (S8 or the card) satisfies the reminder, with no separate counter to keep in sync. Only the dismiss-snooze needs persisted state, so the feature adds exactly one local settings key. Gating on an existing routine avoids overflowing the pre-setup empty state and matches the journal CTA's visibility rule.
**Alternatives Rejected**: A dedicated "last weekly photo" timestamp counter (duplicates state already implied by skin logs; can drift); calendar-week (Sun–Sat) cadence and full-week dismiss (rejected per product owner in favor of rolling-7-day cadence + dismiss-until-tomorrow).
**Affects Files**: `daily_home_screen.dart`, `weekly_skin_reminder_card.dart`, `settings_screen.dart`, `settings_repository.dart`, `settings_repository_impl.dart`, `root_providers.dart` (`weeklyReminderEnabledProvider`), l10n ARBs.

#### DEC-017: Debug-Only Settings Tools (Resume Reminder, Clear Shelf)
**Date**: 2026-06-25
**Context**: Development/testing needs quick ways to re-trigger the weekly reminder and to reset the user's product shelf to an empty state, without wiping history or reinstalling.
**Decision**: Settings hosts a `kDebugMode`-gated block (stripped from release/profile builds) with two actions: (1) **Resume weekly reminder** (see DEC-016); (2) **Clear the shelf** — empties every product the user owns (selections, custom products, collection-item lifecycle) plus the routine wiring tied to those products (schedules, order overrides, category overrides), while **preserving history** (day records, skin logs, muted conflicts). Clear-shelf is implemented as `UserDataRepositoryImpl.clearShelf()` (one Drift transaction of `deleteAll`s) — **deliberately not added to the `UserDataRepository` abstract interface** to avoid touching the 24 test fakes that implement it; it is reached through `debugClearShelfProvider`, which no-ops when the repository is not the concrete impl (e.g. test fakes). The Drift `watch*` streams make the shelf/routine UI refresh automatically after the wipe; a confirmation dialog guards the destructive tap.
**Rationale**: Interface-level churn across 24 fakes (and merge risk against concurrent work) outweighs the purity benefit of a contract method for a debug-only utility. Preserving history matches the semantic of "shelf" (= products), not "all data".
**Alternatives Rejected**: Adding `clearShelf()` to the abstract `UserDataRepository` (24-fake churn); reusing `replaceAllData` with an emptied export (does not clear custom products and would also wipe history); per-item iteration via public methods (soft-delete leaves custom products visible; leaves deselected selection rows).
**Affects Files**: `user_data_repository_impl.dart` (`clearShelf`), `root_providers.dart` (`debugClearShelfProvider`), `settings_screen.dart`, l10n ARBs, `user_data_repository_clear_test.dart`.

#### DEC-018: go_router-Safe Back Navigation (No More Black Screen)
**Date**: 2026-06-25
**Context**: Pressing the `GlowAppBar` back arrow on a screen reached via `context.go(...)` crashed with *"You have popped the last page off of the stack, there are no pages left to show"* (`GoRouterDelegate._debugAssertMatchListNotEmpty`) and dropped the user onto a black screen (the bleed-through showed the `WelcomeScreen` streak number / system status bar). `go()` replaces go_router's match list with a single entry; the old `GlowAppBar` default `onPressed: () => Navigator.of(context).pop()` popped that lone entry and emptied `currentConfiguration`. The routine-changing flows (`/routine-ready`, reached from the add/remove-from-shelf sheet via `go('/routine-ready')`) had the same exposure on system back.
**Decision**: (1) `GlowAppBar`'s default back action is now go_router-aware — `_defaultBack` uses `GoRouter.maybeOf(context)`; with a router it calls `router.pop()` only when `router.canPop()`, otherwise `router.go('/today')`; with no router (plain-`MaterialApp` widget tests) it falls back to a guarded `Navigator.pop()`. An explicit `onBack` still overrides everything. (2) `RoutineReadyRoute` (which has no `GlowAppBar`) wraps its body in `PopScope(canPop: false)` and, on intercepted back, routes to `/collection`; `_goToShelf` is idempotent (`_navigatedAway` guard) and defers the `context.go` via `addPostFrameCallback` to avoid the `!_debugLocked` re-entrancy assertion (navigating synchronously from inside a pop handler is illegal).
**Rationale**: The fix belongs at the shared `GlowAppBar` level because *every* screen reachable via `go()` had the latent crash, not just the shelf flow. A safe home fallback (`/today`) guarantees back never dead-ends. Deferring navigation out of the pop callback is the correct pattern for go_router + `PopScope`.
**Alternatives Rejected**: Per-screen `onBack` handlers (would have to be added to ~10 screens and is easy to forget on the next one); switching the shelf flow from `go()` to `push()` (the routine-ready summary is intentionally terminal — it should not leave the mutating screen underneath); raw `context.pop()` without the `canPop()` guard (still crashes when the stack is a single entry).
**Affects Files**: `lib/shared/widgets/glow_app_bar.dart` (`_defaultBack`), `lib/features/setup/routine_ready_route.dart` (`PopScope` + guarded/deferred `_goToShelf`), `test/shared/widgets/glow_app_bar_back_test.dart`.

#### MOD-DEC-ONB-002: Onboarding CTA Copy Refresh
**Date**: 2026-06-25
**Request**: Reword the primary CTA on each onboarding setup screen so each button reads as a forward-looking, conversational hand-off to the next step.
**Decision**: Updated CTA strings only (no flow/logic change). The schedule CTA (`scheduleContinueToOrder`) is shared by both the morning and evening schedule screens, so a single change gives both the same "layering order" wording. The morning-order Hebrew (`orderCtaMorning`) and the product-selection CTA (`productSelV3ShelfCTA`) already matched the requested copy and were left unchanged.

| Screen | Key | English | Hebrew (he / he_MA) |
|---|---|---|---|
| 3a Product selection | `productSelV3ShelfCTA` | Organize my shelf *(unchanged)* | סידור המדף שלי *(unchanged)* |
| 3b Category review | `categoryReviewCTA` | Let's plan your routine | נמשיך לתכנון השגרה |
| 3c Routine summary (onboarding only) | `routineReadyReviewSlotCta(slot)` | Let's start with your {slot} routine | נתחיל עם שגרת ה{slot} |
| 3d + 3f Schedule (AM & PM) | `scheduleContinueToOrder` | Let's review the layering order | נמשיך לסדר המריחה |
| 3e Morning order | `orderCtaMorning` | Looks good, let's continue to your evening routine | נראה טוב, נמשיך לשגרת הערב *(he unchanged)* |
| 3g Evening order | `orderCtaFinish` | Let's review your week | נמשיך לסקירת השבוע |
| 3h Week at a glance | `weekGlanceStartGlowingCta` | You're all set, let's glow | הכול מסודר, אפשר להתחיל |

The routine-summary CTA change applies only to the onboarding in-tree summary (`routineReadyReviewSlotCta`); the standalone `/routine-ready` route keeps its own `routineReadyCta` ("View My Routine"). `orderCtaFinish`/`orderCtaMorning` are only used in the order screen's onboarding-mode branch, and `scheduleContinueToOrder` only in `_OnboardingScheduleCta`, so no non-onboarding surface is affected.
**Rationale**: First-person, next-step phrasing ("Let's review the layering order", "Let's review your week") reads as a guided hand-off and sets expectation for the screen that follows, instead of a generic "Continue".
**Affects Files**: `app_en.arb`, `app_he.arb`, `app_he_MA.arb` (+ regenerated `generated/app_localizations*.dart`); tests `onboarding_screen_test.dart`, `onboarding_back_navigation_test.dart`, `week_glance_screen_test.dart`, `test/playwright/tests/onboarding.spec.ts`, `test/playwright/tests/schedule.spec.ts`.
