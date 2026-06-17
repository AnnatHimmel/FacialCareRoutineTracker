# Architecture

## Onboarding Flow

### Step numbering

| Step | Screen | Widget |
|---|---|---|
| 0 | Language selection | `_LanguageSelectionStep` |
| 1 | Welcome | `_buildStep1` |
| 2 | Personal info (name + gender) | `_buildStep2` |
| 3a | Product selection V3 (search + scan + tray) | `ProductSelectionScreen` (guided mode) |
| 3b | Category review | `CategoryReviewScreen` |
| push | Schedule setup | `ScheduleSetupScreen` (via GoRouter `/setup/schedule`) |
| push | Order customization | `OrderCustomizationScreen` (via GoRouter `/setup/order`) |

### State ownership

- `_OnboardingScreenState._step` (int 0–3) — outer step
- `_OnboardingScreenState._showingCategoryReview` (bool) — inner sub-step within step 3
- `_CategoryReviewScreenState._categoryOverrides` (Map<String, String>) — ephemeral, not persisted
- `_CategoryReviewScreenState._editingProductId` (String?) — which card's picker is expanded

### Navigation model

`OnboardingScreen` uses `setState` for steps 0–3; schedule and order are separate GoRouter pushes. `context.push<bool>('/setup/schedule')` returns `true` when the user finishes setup, which triggers `_handleFinish()`.

Back from schedule pops the GoRouter stack and returns to category review (step 3b), not to step 3a or step 2.

## Category Overrides — Why Ephemeral in V1

Category overrides in `CategoryReviewScreen` live in component state only (not written to the user data repository). Reasons:

1. **Schema migration risk**: persisting overrides would require adding an `overrides` table/field to user data schema with a version bump and migration path.
2. **Conflict rule engine**: overriding a product's category changes which incompatibility rules apply. The rule engine reads `categoryId` from master content; a user-side override would require rule evaluation to consult overrides too — a non-trivial change.
3. **V1 scope**: category overrides are a display/routing hint only (which step a product appears under). Their functional impact (rule engine) is deferred to V1.1.

## Data Domain Separation

Two independent data domains coexist:

- **Master content** — bundled at build time, read-only at runtime, versioned per release. Loaded via `masterContentProvider` → `MasterContentRepository`.
- **User data** — per-device local storage, schema-versioned independently, must survive app updates. Written via `userDataRepositoryProvider` → `UserDataRepository`.

These never share a database or migration path.

## Day Boundary

A "day" ends at 06:00 the following morning. All streak computation, daily home screen "today" logic, and day record snapshots use this boundary.

## Offline-First

No network call is required for any free-tier feature. All providers operate on local SQLite (Android) or browser storage (Web). The deferred premium cloud backup (UC-21) is web-only and strictly additive.
