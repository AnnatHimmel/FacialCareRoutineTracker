# Radiant Dew — Screen Implementation Guide

You are restyling **one** Flutter screen to match its design reference. The
shared visual foundation is already built — **consume it, do not rebuild it.**

## The look (what "Radiant Dew" means)
Warm "golden hour" minimalism + glassmorphism. **White pebble cards floating on
a cream background**, with soft *peach-tinted glow* shadows (never dark drop
shadows). Extreme roundness — pills and 28px cards. Hebrew, RTL, Quicksand.

A screen looks wrong when: content sits flat on one cream sheet with no cards;
shadows are grey; rows are bare `ListTile`s; headers are plain text + a divider.
A screen looks right when: each logical group is a white pebble card with a glow;
product rows are **pills** with a circular thumbnail + a circular action button;
section headers are a peach title with a lemon count-chip.

## HARD RULES
1. **Edit ONLY the screen file(s) assigned to you.** Never edit anything under
   `lib/core/theme/`, and never edit these shared widgets:
   `glow_card.dart`, `product_thumb.dart`, `radiant_chips.dart`,
   `routine_item_row.dart`, `slot_section_header.dart`, `category_header.dart`,
   `streak_widget.dart`, `glass_bottom_nav.dart`, `soft_warning_banner.dart`,
   `backup_reminder_banner.dart`. Also never edit other screens, `app_router.dart`,
   `app.dart`, l10n, providers, or domain/data code.
2. **Preserve all behavior.** Keep every existing provider/`ref.watch`, callback,
   navigation, loading/empty/error branch, and Hebrew string. This is a *visual*
   restyle, not a logic change. Do not change method signatures the router calls.
3. **Do NOT run any `flutter` command** (no `analyze`, `test`, `build`, `pub`).
   A separate consolidation pass runs analysis. Just write correct Dart.
4. **RTL + Hebrew stay intact.** The app is RTL at root; don't add `Directionality`
   unless wrapping an inline **Latin** string (brand/product names) — the shared
   widgets already handle that. Right-align headers/titles.
5. Don't add new packages. Use Material + the foundation widgets only.

## Design tokens — `lib/core/theme/app_colors.dart` (import `AppColors`)
- Background: `AppColors.surface` (#fff8f6 cream). **Cards: `surfaceContainerLowest` (pure white).**
- Surface ramp: `surfaceLow` #fff1ed, `surfaceContainer` #ffe9e4, `surfaceHigh` #fce3dd, `surfaceHighest` #f6ddd8.
- Primary (peach): `primary` #9e412c, `primaryContainer` #ff8b71, `primaryFixed` #ffdad3, `primaryFixedDim` #ffb4a4, `onPrimaryFixedVariant` #7f2a18.
- Secondary (lemon): `secondary` #67600a, `secondaryContainer` #ede282, `secondaryFixed` #f0e585, `secondaryFixedDim` #d3c96c, `onSecondaryContainer`.
- Tertiary (rosy): `tertiary` #874e58, `tertiaryContainer` #de99a4, `tertiaryFixed` #ffd9de, `onTertiaryContainer`.
- Text: `onSurface` #251815, `onSurfaceVariant` #56423e. Outlines: `outline`, `outlineVariant`.
- **Glow shadows** (use these, not `BoxShadow` you invent):
  `AppColors.glow` (cards), `AppColors.glowLg` (hero/gradient), `AppColors.glowSm` (rows/chips), `AppColors.soft`, `AppColors.navGlow`.
- Gradients: `AppColors.streakGradient` (warm peach sweep), `AppColors.primaryGlowGradient`.
- Glass: `AppColors.glassFill` + `AppColors.glassBlurSigma` (wrap in `BackdropFilter`).

## Typography — `lib/core/theme/app_typography.dart` (import `AppTypography`)
`displayLg, headlineLg, headlineLgMobile, headlineMd, bodyLg, bodyMd, labelMd, labelSm`.
Headlines/titles = Quicksand; labels = Plus Jakarta Sans. Prefer `Theme.of(context).textTheme` where natural; otherwise `AppTypography.*`. Page/section titles use `headlineMd` in `AppColors.primary`.

## Foundation widgets you SHOULD reuse (all under `lib/shared/widgets/`)
- **`GlowCard`** — white pebble. `GlowCard(child:, padding:, radius:, pill:, color:, shadow:, onTap:)`. Default radius 28, default shadow `glow`. Wrap every logical group in one.
- **`ProductThumb`** — `ProductThumb(imageAsset:, size: 52, fallbackIcon:)` circular image/fallback disc.
- **`CategoryHeader`** — `CategoryHeader(categoryName:, count:, countSuffix:'פריטים')` → peach title (right) + lemon count chip (left).
- **`SlotSectionHeader`** — `SlotSectionHeader(slot:, productCount:, doneCount:, isExpanded:, onToggle:)` morning=peach sun, evening=lemon moon, optional lemon "done/total" chip.
- **`RoutineItemRow`** — pill row. `RoutineItemRow(product:, isToggled:, onToggle:, isOwnershipContext:, isDraggable:, hasConflict:, onConflictTap:, subtitle:)`. `isOwnershipContext`→select(+/✓); `isDraggable`→drag handle; else→done(check, peach fill + strikethrough when checked).
- **`StreakWidget`** — `StreakWidget(currentStreak:, longestStreak:, weekMissesUsed:, weekMissBudget:)` peach gradient banner.
- **`CountChip(text)`** — lemon count pill. **`TagChip(label, {background, foreground, icon})`** — small status/AM-PM chip.
- **`GlowButton` pattern** — use `ElevatedButton`/`FilledButton` (already pill-themed) for primary CTAs; full-width primary CTA = pill, peach, white text.

## Layout conventions
- Screen body: `ListView`/`CustomScrollView` with `padding: EdgeInsets.fromLTRB(20, 16, 20, 24)` (20px side margins). 16px gaps between cards, ~24–40px between major sections.
- AppBar: centered Quicksand title in `primary` (theme already does this). Back arrow in RTL points **forward** (`Icons.arrow_forward`) — but default `AppBar` leading already flips correctly under RTL, so prefer the default.
- Inputs: filled white, 16px radius, peach focus border (theme handles it).
- Sticky bottom CTAs: a `GlowCard`/`Container` with white bg + top glow, full-width pill button inside.

## Reference materials (read your assigned ones closely)
- **Design system in React (most precise layout source):**
  `doc/design-reference/screens/components.jsx` (shared comps),
  `doc/design-reference/screens/screens.jsx` (every screen),
  `doc/design-reference/screens/onboarding.jsx` (onboarding).
- **Rendered PNGs (visual target):** `doc/design-reference/screens/uploads/stitch_application_ux_ui_design/{_1.._5,curator_1,curator_3}/screen.png` and `doc/design-reference/screens/screenshots/*.png`.
- **Exact CSS (shadows/gradients):** `doc/design-reference/screens/index.html` and the `curator_*/code.html` files.
- Tokens spec: `.../radiant_dew/DESIGN.md`. PRD/UX: `doc/skincare-tracker-prd.md`, `doc/skincare-tracker-ux-brief.md`.

## Definition of done
Screen visually matches its reference (cards, glows, pills, headers, RTL, fonts),
all prior functionality intact, no shared files touched, code compiles cleanly
(no obvious analyzer errors — final lints handled in consolidation). End your
report with: the file(s) you changed, and a 3–6 line summary of the visual
changes you made vs. the reference.
