# Handoff: Product Selection & Weekly Scheduling Flow

## Overview
A redesign of the onboarding **product-selection** experience for the facial-care routine tracker, plus a new **weekly scheduling** step. The goal that drove every decision: **reduce cognitive load** — the original selection screen (a dense 2-column grid of product cubes) was "busy on the eyes." This flow replaces it with a guided, one-decision-at-a-time path that stays calm and surfaces complexity only on demand.

The flow has three connected screens:
1. **Guided selection** — one product category per screen, in routine order.
2. **Summary / overview** — all categories collapsed on one screen, filterable by morning/evening.
3. **Weekly schedule** — assign which days each product runs, with frequency + conflict warnings.

## About the Design Files
The files in this bundle are **design references created in HTML/React (JSX)** — interactive prototypes showing intended look and behavior. **They are not production code to copy.** The target app is **Flutter (Dart)**. The task is to **recreate these designs as Flutter widgets using the app's existing theme, widgets, and patterns** (the project already has a Material 3 color scheme, localization, and a `master_products.json` data layer — use them). Treat the HTML as the source of truth for *layout, behavior, and the cleanliness principles below*, not for literal markup.

Open `Product Selection Flow (latest).html` to interact with all three screens side by side. The prototype is in Hebrew/RTL (the app's language).

## Fidelity
**High-fidelity.** Final colors, typography, spacing, interactions, and copy are all intentional. Recreate pixel-faithfully using the codebase's existing Material 3 theme tokens (the prototype's palette mirrors a Material 3 scheme — map to the app's `ColorScheme` rather than hard-coding hex).

---

## ⭐ Cleanliness Principles (do not regress these)
These are the decisions that make the flow feel calm. They are easy to lose when re-implementing — preserve them explicitly:

1. **One decision per screen (guided path).** The default route walks category-by-category. Never present the full catalog at once.
2. **Badge the exception, not the default.** ~60% of products are "flexible" (usable AM & PM). Flexible is the *default* and carries **no badge**. Only **fixed** products show a chip (`בוקר בלבד` / `ערב בלבד`). A label that appears on the majority is noise — suppress it.
3. **Detail on demand.** Each product row shows only **thumbnail + name** (and the rare fixed-slot chip). The description, how-to-use text, and recommended frequency live **behind an ⓘ button**, revealed inline. Never show comment/frequency text on the resting row.
4. **Select once, choose timing — never twice.** A product is selected a single time. For flexible products, an inline **morning / evening toggle pair** (two independent toggles, NOT a 3-way "both" option) appears under the selected row. Turning both off deselects it.
5. **Color discipline — red means "problem," nothing else.** Healthy/neutral states use hue-neutral grey (`black @ 6% alpha`), never the warm/green "success" tints. Solid red (`error`) is reserved strictly for: over-recommended-frequency, same-slot conflicts, and unscheduled daily products. A glance answers "is anything red?".
6. **Surface problems where the user isn't looking.** Conflicts that exist in a slot the user isn't currently viewing are flagged with a red marker on that slot's tab + a tappable "jump to fix" banner.
7. **Progressive disclosure for conflicts.** Don't show a permanent wall-of-text conflict banner. Flagged days in the week strip are **tappable** to reveal that day's specific clash inline, **with a close (✕) affordance**.

---

## Screens / Views

### 1. Guided Selection (`flow-guided.jsx` → `GuidedFlow`)
- **Purpose:** Build the product list one category at a time without overwhelm.
- **Layout (375–384px wide phone):**
  - Header: step counter (`שלב N מתוך 8`) on the right, a **`דלג לסיכום`** (skip to summary) text button on the left.
  - Progress bar: 8 equal segments, filled up to current step (`primary` filled, `primary-fixed/40` empty).
  - Category header: a 48×48 rounded-square glyph (icon) + English eyebrow label + Hebrew category name.
  - Hint line: one sentence of guidance per category.
  - Vertical list of **SelectRow**s (see Components), `gap: 10px`.
  - Sticky footer: a back button (icon only, appears from step 2) + a full-width primary CTA (`המשך` / `דלג על השלב` / `לסיכום`). Below it, a quiet status line (`N נבחרו · M בסך הכל`).
- **Category order (from `master_products.json`, by `order`):** Cleanse 1 → Cleanse 2 → Retinoid → Toner → Serum → Moisturizer → Oil → SPF/Protect.

### 2. Summary / Overview (`flow-overview.jsx` → `SummaryView` / `OverviewFlow`)
- **Purpose:** See the whole wardrobe at a glance; review each routine separately. This is also where `דלג לסיכום` lands.
- **Layout:**
  - Header: title + one-line subtitle.
  - **SlotFilter** segmented control: `הכל` / `בוקר` / `ערב`, each with a count badge. Filtering re-filters every category by slot availability.
  - Collapsible category cards (one open at a time): header row (glyph + name + "N נבחרו / N אפשרויות" + count chip + chevron). Expanded body lists that category's SelectRows.
  - Sticky footer: morning total (☀ N) + evening total (🌙 N) on the right, primary CTA on the left (`המשך לתזמון`).

### 3. Weekly Schedule (`flow-schedule.jsx` → `ScheduleView` / `ScheduleFlow`)
- **Purpose:** Decide which days each product is used, per slot; catch over-use and conflicts.
- **Layout:**
  - Header: back arrow + title `תזמון שבועי` + one-line hint.
  - **Slot toggle** (`בוקר` / `ערב`): the active slot tints (AM = `primary-container`, PM = `tertiary`). **A red `!` marker appears on a tab whose slot has a conflict**, even when inactive.
  - **Cross-slot hint banner** (only when the *current* slot is clean but the *other* has a conflict): tappable red bar `יש התנגשות ב<routine> — הקישי לתיקון` → switches slots.
  - **Week-at-a-glance card:** 7 day cells showing product count per day. Healthy days = neutral grey; **conflict days = solid red, tappable, with a `!` corner marker**. Header shows `הקישי על יום מסומן` (red) when conflicts exist.
    - **Tapping a conflict day** expands an inline detail panel (`error-container/50` bg): day chip + `לא מומלץ לשלב` + a **close ✕ button**, then the clashing product pair(s) shown as `thumb · name  ✕  name · thumb`, then a soft tip. Tapping the same day again or ✕ closes it.
  - **"לא לשימוש יומי" (occasional) section:** card per product with thumbnail, name, recommended cap (`מומלץ: עד N× בשבוע`), a **count chip** (`count/cap` — neutral grey within limit, **solid red when over**), a 7-day **DayPicker** (round day toggles, selected = `primary`), and a red inline warning when over cap (non-blocking).
  - **"יומיים" (daily) section:** same card; chip shows `כל יום` (neutral) or `N/7`; **solid red when 0 days** with `לא נבחר יום — המוצר לא ישובץ`.
  - Sticky footer: CTA `סיום ושמירת השגרה` + a red summary line if conflicts remain.

---

## Components

### SelectRow (`flows.jsx`)
The atom of selection. Resting state = **thumbnail (50px) + product name** only.
- Tapping the row body toggles selection. Selected: row tints `primary-fixed/30`, border `primary/30`, and a small **check badge** overlays the thumbnail's bottom-corner.
- **Fixed products only:** a small chip under the name — `בוקר בלבד` (`primary` on `primary-fixed/60`) or `ערב בלבד` (`tertiary` on `tertiary-container/50`) with a lock glyph. Flexible products show **nothing** here.
- **ⓘ info button** (40px, trailing): toggles an inline detail panel — product comment, a `tips_and_updates` usage line, and a `event_repeat` recommended-frequency line. Filled/`primary` when open.
- **Flexible + selected:** a **TimingControl** appears at the bottom — label `מתי?` + two independent pill toggles `בוקר` / `ערב` (AM on = `primary-container`, PM on = `tertiary`; off = white w/ outline). Both off → deselects.
- Row shape: pill (`rounded-full`) when collapsed, `rounded-[26px]` when info or timing is expanded.

### SlotFilter (`flows.jsx`)
3-way segmented control (`הכל`/`בוקר`/`ערב`) on `surface-low`, active pill tinted, optional count badge per option.

### DayPicker (`flow-schedule.jsx`)
Row of 7 round day buttons (`א׳…ש׳`). Selected = solid `primary` + white; unselected = `surface-low`. Daily products default to all 7.

---

## Interactions & Behavior
- **Navigation:** Guided `המשך`/`לסיכום` → Summary; Summary `המשך לתזמון` → Schedule; back arrows return one step. `דלג לסיכום` jumps Guided → Summary directly.
- **Selection:** tap row toggles; flexible selected products default timing to all slots they allow (in the slot-filtered Summary, a newly added flexible product defaults to the *filtered* slot only).
- **Info reveal:** per-row, independent, toggled by ⓘ; does not affect selection.
- **Conflict reveal:** tap a red week-strip day → inline panel; ✕ or re-tap closes; switching slots closes it.
- **Warnings are advisory, never blocking** — the user can always proceed/save over a frequency or conflict warning.
- **Transitions:** subtle `active:scale` press feedback (~0.98–0.90); expand/collapse via conditional render. No long animations.

## State Management
- `selection: { [productId]: ['AM'] | ['PM'] | ['AM','PM'] }` — absent = unselected. Single source of truth for which products + their slots.
- `schedule: { [productId]: { [weekdayId 0–6]: 1 } }` — explicit day overrides. **Effective days** = explicit schedule if any set, else every day for daily products, else none.
- `slot: 'AM' | 'PM'` (schedule view), `filter: 'all' | 'AM' | 'PM'` (summary), `openDay`/`openInfo` (disclosure), `step`/`view` (navigation). Reset `openDay` when slot changes.

## Conflict & Frequency Logic
- **Frequency:** from each product's `morningConfig`/`eveningConfig` — `daily` or `weeklyMax { maxPerWeek }`. "Over" = scheduled days > maxPerWeek (warn, don't block).
- **Conflicts:** from `incompatibility_rules.json` (scope `withinSlot`). A rule's entity may be a **product** or a **category**. Two selected items conflict if, on the **same day and same slot**, one matches entity A and the other entity B. Detect per day; flag the day red.
- **Flexible vs fixed:** a product is *flexible* if it has BOTH `morningConfig` and `eveningConfig`; *fixed* if only one. This single fact drives the badge/timing behavior.

## Design Tokens
Map these to the app's Material 3 `ColorScheme` (values shown are the prototype's M3-derived palette):
- **Surfaces:** background `#f0eee9`, surface `#fff8f6`, surface-low `#fff1ed`, surface-high `#fce3dd`
- **On-surface:** `#251815`, on-surface-variant `#56423e`, outline-variant `#dcc0ba`
- **Primary** (morning / selection accent): `#9e412c`, primary-container `#ff8b71`, primary-fixed `#ffdad3`
- **Tertiary** (evening accent): `#874e58`, tertiary-container `#de99a4`, tertiary-fixed `#ffd9de`
- **Error** (problems only): `#ba1a1a`, error-container `#ffdad6`
- **Neutral "healthy" fill:** `rgba(0,0,0,0.06)` (deliberately hue-neutral — do NOT substitute a tinted/success color)
- **Type:** display/body = Quicksand; labels = Plus Jakarta Sans. Row name ~14.5px/700, hints ~13px, chips ~9.5–11px. Icons = Material Symbols (the app uses Material Icons — map names: `wb_sunny`, `dark_mode`, `info`, `schedule`, `event_repeat`, `tips_and_updates`, `warning`, `priority_high`, `expand_more`, `close`, `check`, `add`, `touch_app`).
- **Radius:** pill rows `999px`; expanded rows/cards `22–26px`; day cells `12px`. **Shadows:** soft warm glows (`0 2px 12px rgba(255,139,113,.10)` etc.) — keep elevation subtle.

## Assets
- Product images: `products/*.jpg` (already in the app at `assets/images/products/`). Use the app's existing asset paths via `master_products.json` `imageAsset`.
- Icons: Material Symbols in the prototype → use the app's Material Icons.
- No custom illustrations.

## Files (in this bundle)
- `Product Selection Flow (latest).html` — entry point; open to view all three screens.
- `flows.jsx` — shared layer: data helpers, `SelectRow`, `TimingControl`, `SlotFilter`, weekday/conflict logic, `USAGE` copy.
- `flow-guided.jsx` — `GuidedFlow` (screen 1).
- `flow-overview.jsx` — `SummaryView` / `OverviewFlow` (screen 2).
- `flow-schedule.jsx` — `ScheduleView` / `ScheduleFlow` / `DayPicker` (screen 3).
- `product-data.jsx` — catalog + categories generated from `master_products.json` (reference for shape; the app should read its own JSON).
- `components.jsx` — shared primitives (`Icon`, `ProductThumb`, etc.) used by the prototype.
- `canvas-app.jsx`, `design-canvas.jsx` — the side-by-side presentation canvas (presentation only — **not** part of the feature; ignore when implementing).

> Note on `master_products.json` & `incompatibility_rules.json`: the app already owns these. The prototype mirrors them; implement against the app's live files.

---

## ✅ Coherence with the Existing Codebase
**This design is already coherent with the app** — it was built on the same **"Radiant Dew"** design system the app ships (`lib/core/theme/`). Verified 1:1: every color hex, the Quicksand + Plus Jakarta Sans type scale, and the peach-tinted "glow" shadows in the prototype match `AppColors` / `AppTypography` exactly. To *keep* it coherent, the implementation must **reuse the app's existing tokens and widgets — never hard-code values or build parallel components.**

### Use these existing tokens (not raw hex)
- Colors → `AppColors.*` (`primary`, `primaryContainer`, `primaryFixed`, `tertiary`, `tertiaryContainer`, `error`, `errorContainer`, `surface`, `surfaceLow`, `surfaceHigh`, `onSurface`, `onSurfaceVariant`, `outlineVariant`).
- Type → `AppTypography.*` (`headlineMd`, `bodyMd`, `labelMd`, `labelSm`, …).
- Elevation → `AppColors.glow` / `glowSm` / `glowLg` / `soft`; primary CTA fill → `AppColors.primaryGlowGradient`.
- Theme entry: `RadiantDewTheme.light()`.

### Reuse these existing widgets (they already match the prototype)
| Prototype element | Existing Flutter widget |
|---|---|
| `SelectRow` (product row) | `shared/widgets/routine_item_row.dart` |
| `ProductThumb` | `shared/widgets/product_thumb.dart` |
| White glow card | `shared/widgets/glow_card.dart` |
| Capability / count chips | `shared/widgets/radiant_chips.dart` |
| Category section header | `shared/widgets/category_header.dart` |
| Morning/Evening section header | `shared/widgets/slot_section_header.dart` |
| Non-blocking warnings (frequency, conflict) | `shared/widgets/soft_warning_banner.dart` |
| `DayPicker` (7-day toggles) | `shared/widgets/weekday_picker.dart` |
| Top app bar | `shared/widgets/glow_app_bar.dart` |

### These screens already exist — modify, don't recreate from scratch
- `features/setup/product_selection_screen.dart` — the screen being redesigned (selection).
- `features/setup/schedule_setup_screen.dart` — the weekly-schedule screen.
- `features/setup/order_customization_screen.dart`, `add_custom_product_sheet.dart` — adjacent setup screens to stay consistent with.

Claude Code should restructure these existing screens to the new flow/principles, **reusing the widgets above**, rather than introducing new styling.

### The one net-new value to add as a token
The schedule's "healthy" neutral fill is `rgba(0,0,0,0.06)` — a deliberately **hue-neutral** grey (so it can't be confused with the warm peach tints or the red error states; see Cleanliness Principle #5). This is the only value not already in `AppColors`. Add it as a named token (e.g. `AppColors.neutralFill`) rather than reusing a warm `surfaceHigh`/`primaryFixed` tint — using a warm tint here would re-introduce the exact ambiguity we removed.
