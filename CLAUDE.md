# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

This is a **pre-implementation** repository. The codebase currently contains only planning and design documentation. No Flutter project has been initialized yet. When implementation begins, this file should be updated with build/test commands.

## Project Overview

A personal skincare routine tracker app. An admin curates a master list of skincare products (with ordering, categories, and frequency rules) bundled into the app; users select the products they own and get a personalized, correctly-ordered routine derived from admin expertise.

**Platform:** Single Flutter codebase targeting Android (sideloaded APK, no app store) and Web (for iPhone/Safari and any browser).

**Language:** Entire UI in **Hebrew** with **RTL layout** — a hard v1.0 requirement, not future localization. Product names and category names are admin-authored and displayed verbatim (bidirectional text handling required).

## Key Documents

- **PRD:** [docs/skincare-tracker-prd.md](docs/skincare-tracker-prd.md) — authoritative source for all functional requirements and use cases (UC-1 through UC-21). When PRD and design references conflict, **PRD governs**.
- **UX Brief:** [docs/skincare-tracker-ux-brief.md](docs/skincare-tracker-ux-brief.md) — screen-by-screen specifications (S1–S16), component library, and edge cases.
- **Design system:** [docs/design-reference/screens/uploads/stitch_application_ux_ui_design/radiant_dew/DESIGN.md](docs/design-reference/screens/uploads/stitch_application_ux_ui_design/radiant_dew/DESIGN.md) — "Radiant Dew" design tokens (colors, typography, spacing, shape language).
- **Screen references:** [docs/design-reference/screens/](docs/design-reference/screens/) — HTML/CSS mockups. **Reference only** — not shipped, not embedded in the app. Implement as native Flutter widgets.

## Architecture Decisions

### Data Model (critical for long-term integrity)
- **Master content** is bundled at build time and read-only to users. Products have stable IDs and are never deleted — only deprecated.
- **User data** (selections, schedules, order overrides, day records, skin logs) is stored locally on-device/in-browser. It must survive app updates via schema versioning independent of master-list versioning.
- Records must carry stable IDs and last-modified metadata from the start — this is the foundation for the deferred premium cloud backup (UC-21) and the merge-conflict resolution in import (UC-17).
- The "replace or merge" import flow (UC-17) and the post-update reconciliation (UC-18) are related: both use stable product IDs to match records.

### Two Conceptually Distinct Data Domains
1. **Master list** — admin-authored, Supabase is the live source; the bundled JSON files are offline fallbacks only. **Any change to master content must be applied to BOTH Supabase (`ddrxzzeplokmkzizailn`) AND the corresponding bundled file — Supabase first:**
   - Products / categories / subcategories → `assets/data/master_products.json`
   - Incompatibility rules → `assets/data/incompatibility_rules.json`
2. **User personalization** — per-device local storage, independently versioned schema, must outlast app updates and Android APK upgrades.

### Routine Data Access — `RoutineScheduler` is the single source of truth
All **routine** device data — `ProductSelection`, `WeekdaySchedule`, `OrderOverride` — is read and written **only** through `RoutineScheduler` (`lib/domain/services/routine_scheduler.dart`), exposed as `routineSchedulerProvider`. **Never** call `userDataRepositoryProvider` directly for these three tables from a screen or provider; use the scheduler's `watch*` streams and mutation methods (`addProduct`/`removeProduct`/`setDays`/`toggleDay`/`removeDay`/`setOrder`/`resetOrder`/`fixProblems`/…). The scheduler also owns the derived reads (`orderForDay`, `warningsForDay`, `weekGlance`) by composing `RoutineResolver`, `WeekGlanceBuilder`, `IncompatibilityChecker`, `ConflictResolver`, `ProductSorter`.

- **Scope is routine-only.** Day records, skin logs, collection items, category overrides, and muted conflicts stay on `UserDataRepository` — do not route them through the scheduler.
- The per-product "effective days" rule lives **once** in `effectiveDays`/`defaultDaysFor` (`lib/domain/services/schedule_days.dart`). Never re-derive per-day inclusion inline (it was previously triplicated — don't reintroduce that).
- Need a new routine read/write? **Extend `RoutineScheduler`** (TDD), then consume it — do not bypass it. Full rationale: `doc/ARCHITECTURE.md` §3.0.

### Day Boundary
A "day" ends at **6:00am the following morning** — activity before 6am counts toward the prior calendar day. This affects the home screen's "today," day records, and streak computation everywhere.

### Streak Logic (UC-13)
- Slot done = ≥1 product in that slot recorded.
- Complete day = both Morning and Evening slots done.
- A miss = one empty scheduled slot (blank day = 2 misses; unscheduled slots never count as misses).
- Grace: 3 slot-misses forgiven per Sunday–Saturday week; the 4th resets the streak; unused grace does not carry over.

### Incompatibility Rules (UC-1b, UC-4b)
Advisory only — never block. Rules target product-pairs or category-pairs within a scope (within Morning, within Evening, same-day across both). Because rules can reference categories, a product's **category is a functional attribute**, not just a display label. Daily↔daily conflicts surface at selection time and are user-mutable (per-conflict mute, stored locally).

### Offline-First
The free product requires no network at runtime on either platform. No backend, no accounts, no sync. The deferred premium capability (UC-21) is Web-only, invitation-gated, strictly additive — free product behavior must never depend on it.

## Design System — Radiant Dew

Warm "golden hour" aesthetic: soft minimalism + glassmorphism.

- **Primary:** Vibrant Peach (`#9e412c` / container `#ff8b71`) — CTAs, active states.
- **Secondary:** Soft Lemon (`#67600a` / container `#ede282`) — morning slot, streak highlights.
- **Tertiary:** Rosy Pink (`#874e58` / container `#de99a4`) — evening slot, progress accents.
- **Surface:** Cream (`#fff8f6`) — base background, no pure white.
- **Typography:** Quicksand (headlines/body) + Plus Jakarta Sans (labels/utility text). Both fonts must render Hebrew well alongside inline Latin brand names.
- **Shapes:** Extreme roundness — pill buttons, 32px card radius on mobile, 48px on desktop.
- **Elevation:** Colored ambient glows, not dark shadows. Glassmorphism (`backdrop-filter: blur(12px)`, 60% white) for sticky headers/nav.
- **Spacing:** 8px base unit; 20px side margins on mobile; 40px+ between major sections.

## TDD Requirement

**All new code must follow RED → GREEN → REFACTOR. No exceptions.**

1. **RED:** Write the test file first. Run `flutter test <test_file>` and confirm it **fails**. Do not proceed if the test passes — the test doesn't cover the new behavior yet.
2. **GREEN:** Write the minimal implementation to make the test pass. Run again and confirm green.
3. **REFACTOR:** Clean up if needed. Tests must still pass after.

This applies to every task in `/6-ModifyLoop`, `/4-Execution`, and any ad-hoc code change. Never write implementation code before a failing test exists for it.

### "All tests" means BOTH suites — Dart **and** Playwright

The project has two test suites, and a full test run / verification gate **must include both**:

1. **Dart unit & widget tests** — `flutter test` (from repo root).
2. **Playwright web e2e** — `cd test/playwright && npx playwright test` (drives the Flutter-web build via the accessibility/semantics tree; the config auto-runs `flutter build web` first, so the first run is slow).

**Never report "all tests pass" or treat a change as verified after running only `flutter test`.** The e2e suite catches UI/flow regressions the Dart tests cannot. If a fix touches selection, scheduling, ordering, onboarding, or any screen flow, the Playwright suite is mandatory before declaring done. Run `flutter analyze` as well.

### Subagent Mapping for TDD Phases

Delegate each phase to the matching specialized subagent to protect the main context window:

| Phase | Subagent | When to use |
|---|---|---|
| RED | `test-writer` | Writing a new failing test from a requirement |
| GREEN | `coder` | Implementing minimal code to pass the failing test |
| REFACTOR | `refactorer` | Cleaning up after green — behavior must not change |
| Verify | `test-runner` | Running existing tests to confirm pass/fail |
| Explore | `smart-research` | Any broad codebase search spanning 3+ queries |

Hand each subagent a self-contained prompt: the requirement text, the relevant file paths, and what the previous phase produced. Do not re-derive in the main context what a subagent already found.

## RTL Icon Rules

All Flutter chevron `IconData` values (`Icons.chevron_left`, `Icons.chevron_right`, and their `_rounded`/`_outlined`/`_sharp` variants) have `matchTextDirection: true`. In an RTL app this causes the icon to be **automatically mirrored** — `chevron_left` renders as `>` and `chevron_right` renders as `<`.

**Always add `textDirection: TextDirection.ltr` to every chevron `Icon` widget.** This suppresses the auto-mirror and lets you control the visual direction explicitly with the icon name.

```dart
// Correct — left-pointing chevron that stays left-pointing in RTL
const Icon(
  Icons.chevron_left,
  textDirection: TextDirection.ltr,
  size: 22,
  color: AppColors.outline,
)
```

Use `Icons.chevron_left` (pointing `<`) for all trailing navigation indicators in list rows — this is the correct RTL direction for "navigate to detail." Never use `Icons.chevron_right` without `textDirection: TextDirection.ltr`, or it will appear as `<` due to mirroring and create confusion.

The `Icon` widget in this Flutter version does **not** accept `matchTextDirection` as a constructor parameter — that is a property of `IconData`, not `Icon`.

## Flutter Implementation Notes (PRD §14)

- **Rebuild, don't embed.** HTML references specify appearance only — never use WebView for app screens.
- **Single theme first.** Derive all Radiant Dew design tokens into one shared Flutter `ThemeData` before building screens. Screens consume tokens, never hard-code values.
- **RTL at app root.** Configure Hebrew locale and `TextDirection.rtl` at the `MaterialApp` level — not per screen. Validate bidirectional text (Latin brand names in Hebrew lines) early, on routine rows and category headers.
- **One codebase, both targets.** `flutter build apk` for Android, `flutter build web` for the Web target.
- **Android signing.** Every release must use the same signing key with a strictly increasing `versionCode`. A key change forces uninstall/reinstall and destroys local user data.
- **Photo storage.** Skin-log photos are stored locally at a bounded resolution to manage storage. On Web, browser storage is evictable (iOS Safari); this risk must be surfaced to web users.

## Screens Reference (S1–S16)

| Screen | Key behavior |
|---|---|
| S1 Product Selection | Products grouped by category; deprecated products not shown; daily↔daily incompatibility warnings (mutable) |
| S2 Schedule Setup | Weekday toggles Sunday-first; soft over-cap warning; day-dependent incompatibility warnings |
| S3 Order Customization | Drag-to-reorder; "Reset to recommended order" action |
| S4 Daily Home | Today's routine (6am boundary); streak widget; per-slot collapse/expand; conflict markers |
| S5 Routine Item | Collapsed = record toggle + name; expanded = image + comment; deprecated variant; drag variant |
| S6 Calendar | Monthly RTL grid; 4 completion states (complete/partial/missed/future); colorblind-safe |
| S7 Day Detail | Routine as it was that day; past records editable; deprecated products still render |
| S8 Skin Log Entry | Free-text + photos (camera/gallery on Android; browser picker on Web) |
| S9 Skin Journal | Chronological photo gallery; no before/after comparison (future feature) |
| S10 Streak Display | Current + longest streak; optional weekly-miss budget; embedded in S4 |
| S11 Settings | Entry points to S1–S3, S12, S13; Web build also shows S15 (deferred) |
| S12 Export / Import | Export = single portable archive; Import = Replace or Merge with sequential per-conflict resolution |
| S13 About / What's New | Version ID + changelog; no "update now" button |
| S14 Update Review | New products (unselected); newly deprecated flagged; data-intact confirmation + export offer |
| S15 License Activation | Web-only, deferred post-v1.0; key-entry for cloud backup & restore |
| S16 Backup Reminder | Gentle, dismissible in-app nudge; non-blocking; links to S12 |
