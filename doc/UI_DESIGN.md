# UI Design Specification
Project: Skincare Routine Tracker
Version: 1.0
Date: 2026-05-26

---

## 1. Design Overview

### 1.1 Design Philosophy

**"Radiant Dew"** — Warm golden-hour aesthetic. Soft minimalism meets glassmorphism.
The app should feel like a ritual, not a chore — warm, personal, and calm. Rounded shapes, peach and lemon accents, cream surfaces. No hard edges, no cold whites. Tracking feels celebratory, not clinical.

Key principles:
- **Warmth first.** Cream backgrounds, colored ambient glows — never dark shadows or pure white.
- **Clarity in RTL.** Hebrew is the primary language; product names (Latin brand names) are embedded as LTR islands. Every layout element mirrors for RTL.
- **Touch-first, phone-sized.** Optimized for one-thumb use on a phone. Tap targets ≥ 44pt. No hover-only interactions.
- **Optional tracking, zero guilt.** Nothing blocks the user; "done" toggles are always reversible; empty states are warm and inviting, not shame-inducing.

### 1.2 Target Platforms

- [x] Mobile Web (iPhone/Safari — primary Web target)
- [x] Mobile App — Android (sideloaded APK)
- [ ] Desktop Web (not targeted — same responsive layout works, but not optimized)
- [ ] Desktop App

Single Flutter codebase. Phone viewport assumed throughout. Max content width: 430px centered.

### 1.3 Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| **Phone** (primary) | < 600px | Single column; 20px side margins; bottom nav bar |
| **Tablet / large phone** | 600–900px | Single column; 40px side margins; bottom nav bar |
| **Desktop / wide** | > 900px | Content centered at max 430px; bottom nav or side nav |

All wireframes are designed for the phone breakpoint (375–430px wide).

### 1.4 RTL Global Rules

- `TextDirection.rtl` + `he` locale at `MaterialApp` root — all screens mirror automatically.
- In all wireframes below: **RIGHT side = start/leading; LEFT side = trailing.**
- Back/navigation affordances appear on the RIGHT (Flutter `AppBar.leading` = right in RTL).
- Directional progress (setup wizard) flows RIGHT → LEFT.
- Product names and category names are always rendered with Unicode BiDi — they are LTR islands within RTL lines.
- Media (product images, skin photos) are never mirrored.

### 1.5 Bottom Navigation (actual implementation)

```
Bottom Navigation (RTL read order — 4 tabs):
  [הגדרות / Settings S11] | [יומן / Calendar S6] | [המוצרים שלי / My Products S1b] | [היום / Today S4]
```

> **Note on wireframes below:** Wireframes show `יומן עור` as a bottom-nav tab — that label is outdated. The actual second tab is **המוצרים שלי** (My Products, `/products`). The Skin Journal (S9) is reachable from Calendar (S6) and from the skin-log icon on S4, but is **not** a bottom-nav tab.

---

## 2. Screen Inventory

### 2.1 Screen List

| # | Screen | Purpose | Entry Points | Exit Points |
|---|--------|---------|--------------|-------------|
| S1 | Product Selection (setup wizard) | Step-by-step product selection by category | First launch (setup); Settings → "ערוך בחירה" | S2 (if any occasional), S4 (if all daily) |
| S1b | My Products tab (browse mode) | Flat searchable product browse; same `ProductSelectionScreen` with `isTabDestination: true` | Bottom nav "המוצרים שלי" | Stays in tab; optional barcode scan modal |
| S1c | Barcode Scan Sheet | Camera barcode scanner modal for finding a product | S1b FAB (Android only) | Returns to S1b; optionally opens AddCustomProduct |
| S2 | Schedule Setup | Weekday schedule for occasional products | After S1 (setup); Settings → "ערוך לוח זמנים" | S3 (order) or S4 |
| S3 | Order Customization | Reorder selected products per slot | After S2 (setup); Settings → "ערוך סדר" | S4 |
| S4 | Daily Home | Today's routine; record done | App launch (main screen); bottom nav "היום" | S7 (tap date), S5 (expand row), S8 (skin log) |
| S5 | Routine Item | Expanded product detail row | S4/S7 row expand | Collapses back |
| S6 | Calendar / History | Monthly completion grid | Bottom nav "לוח שנה" | S7 (tap day) |
| S7 | Day Detail | Past day's routine + skin log | S6 (tap day); S4 (tap date header) | S8 (edit skin log), back |
| S8 | Skin Log Entry | Add/edit notes + photos | S4 (skin log button); S7 (edit) | Back to S4/S7 |
| S9 | Skin Journal | Chronological photo gallery | Bottom nav "יומן עור" | S8 (tap entry) |
| S10 | Streak Display | Streak widget (embedded in S4) | Shown on S4 always | Part of S4 |
| S11 | Settings | Manage all settings | Bottom nav "הגדרות" | S1, S2, S3, S12, S13 |
| S12 | Export / Import | Backup and restore data | S11 → "ייצוא / ייבוא" | Back to S11 |
| S13 | About / What's New | Version + changelog | S11 → "אודות" | Back to S11 |
| S14 | Update Review | Post-update new/deprecated products | Auto-shown on first run after update | S4 (dismiss) |
| S15 | License Activation (stub) | Premium key entry (Web only, post-v1.0) | S11 → "הפעלת רישיון" | Back to S11 |
| S16 | Backup Reminder | Persistent gentle nudge | Auto-shown when no recent export | Dismissed; or → S12 |

---

## 3. Screen-by-Screen Specifications

### S4 — Daily Home (PRIMARY SCREEN)

**Purpose:** User opens app daily to see their Morning/Evening routine and optionally record what they used.

**Wireframe (RTL — right = start):**
```
┌─────────────────────────────────────────────┐
│  [≡]         יום שלישי, 26 במאי    [עור✦]  │  ← AppBar: hamburger(L), date(center), skin-log-btn(R)
│              Surface: cream #FFF8F6          │     (≡ = future settings shortcut; skip for v1.0)
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐│
│  │  🔥 רצף: 12 ימים    📊 הכי ארוך: 30   ││  ← S10 Streak card (glassmorphism surface)
│  │  החסרות השבוע: ████░░░  1 מתוך 3      ││     secondary-container (lemon) accent
│  └─────────────────────────────────────────┘│
│                                             │
│  ☀️  בוקר                          ∨ collapse│  ← Slot header (morning = secondary/lemon)
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ┌─────────────────────────────────────────┐│
│  │  ● CeraVe Foaming Cleanser        [✓] ││  ← Done (recorded) item; checkmark = primary peach
│  └─────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────┐│
│  │  ○ The Ordinary Niacinamide 10%   [ ] ││  ← Undone item
│  └─────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────┐│
│  │  ○ Paula's Choice BHA          ⚠️  [ ] ││  ← Conflict marker ⚠️ (incompatibility)
│  └─────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────┐│
│  │  ○ [מוצר ישן]       ⚠️ לא מומלץ  [ ] ││  ← Deprecated product marker
│  └─────────────────────────────────────────┘│
│                                             │
│  🌙  ערב                           ∨ collapse│  ← Slot header (evening = tertiary/rosy)
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ┌─────────────────────────────────────────┐│
│  │  ○ CeraVe PM Moisturizer          [ ] ││
│  └─────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────┐│
│  │  ○ The Ordinary Retinol 0.5%      [ ] ││
│  └─────────────────────────────────────────┘│
│                                             │
│  ──────────────────────────────────────────  │
│  ┌───────────────────────────────────────┐  │  ← Backup reminder banner S16 (dismissible)
│  │  💾 גבה את הנתונים שלך   [גיבוי] [✕] │  │
│  └───────────────────────────────────────┘  │
├─────────────────────────────────────────────┤
│   הגדרות  |  יומן עור  |  לוח שנה  |  היום │  ← Bottom nav (RTL order: Settings|Journal|Calendar|Today)
└─────────────────────────────────────────────┘
```

**Elements:**
| Element | Type | Data Source | Interactions |
|---------|------|-------------|--------------|
| Date header | Text (Quicksand 24px Bold) | `DayBoundaryService.effectiveDate()` | Tap → S7 (today's detail) |
| Skin log button | Icon button (top right) | — | Tap → S8 |
| S10 Streak card | Custom widget | `StreakCalculator` | Read-only display |
| Slot header (Morning) | Section header | Static Hebrew string | Tap → collapse/expand slot; secondary-container bg |
| Slot header (Evening) | Section header | Static Hebrew string | Tap → collapse/expand slot; tertiary-container bg |
| Routine item row | `RoutineItemRow` | `dailyRoutineProvider` + `dayRecordProvider` | Tap row body → expand (S5); tap checkbox → toggleDone |
| Done checkbox | Checkbox (pill style) | `DayRecord.recordedProductIds` | Toggle (reversible) |
| Conflict marker ⚠️ | Icon + tooltip | `conflictsForDayProvider` | Tap → soft warning bottom sheet |
| Deprecated marker | Text badge | `MasterProduct.isDeprecated` | Inline "לא מומלץ" badge |
| Backup reminder | `SoftWarningBanner` | `settingsProvider.lastExportDate` | Dismiss ✕; or tap "גיבוי" → S12 |
| Bottom navigation | `NavigationBar` | — | Navigate to Today / Calendar / Skin / Settings |

**States:**
| State | Description |
|-------|-------------|
| Loading | Skeleton rows in slot sections; cream shimmer effect |
| Empty slot (nothing scheduled today) | Slot section shows: "אין מוצרים מתוכננים להיום" (warm empty state, no streak penalty) |
| All done | Slot header shows ✓ checkmark; subtle peach glow on card |
| Before 06:00 | Subtle footnote below date: "⏱ פעילות לפני 6:00 נרשמת ליום אמש" |
| No products selected ever | Full-page empty state with CTA: "בחרי מוצרים →" leading to S1 |

---

### S5 — Routine Item Component

**Purpose:** Reusable row used in S1 (ownership toggle), S4/S7 (done toggle), S3 (drag to reorder).

**Collapsed state:**
```
┌────────────────────────────────────────────────┐
│  [○/✓]  Product Name (bidi-safe)   [▼ expand] │
└────────────────────────────────────────────────┘
```

**Expanded state:**
```
┌────────────────────────────────────────────────┐
│  [○/✓]  Product Name (bidi-safe)   [▲ collapse]│
│  ┌──────────┐                                  │
│  │  [image] │  הערת מנהל: Lorem ipsum comment  │
│  │  100x100 │  in Hebrew. May contain brand     │
│  │          │  names like "The Ordinary" inline.│
│  └──────────┘                                  │
└────────────────────────────────────────────────┘
```

**Deprecated variant:**
```
┌────────────────────────────────────────────────┐
│  [○/✓]  Product Name (bidi-safe)  ⚠️לא מומלץ  │
│         [Expand to see deprecation notice]      │
└────────────────────────────────────────────────┘
```
Expanded deprecated: shows banner "מוצר זה אינו מומלץ עוד — שקלי להסיר אותו"

**Drag variant (S3):**
```
┌────────────────────────────────────────────────┐
│  [⣿ drag]  Product Name                       │
└────────────────────────────────────────────────┘
```

**Props:**
| Prop | Type | Notes |
|------|------|-------|
| `product` | `ResolvedProduct` | Includes deprecated flag |
| `isToggled` | `bool` | "Owned" in S1; "Done" in S4/S7 |
| `onToggle` | `VoidCallback` | Toggle action |
| `isOwnershipContext` | `bool` | S1 = own/not-own; S4/S7 = done/undone |
| `isDraggable` | `bool` | S3 only |
| `hasConflict` | `bool` | Shows ⚠️ icon |
| `conflictInfo` | `ConflictInfo?` | For tooltip/bottom sheet |

---

### S1 — Product Selection

**Purpose:** Setup step 1. User marks which products they own, per slot.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]   בחירת מוצרים (שלב 1/2)        │  ← RTL: back on right, title center
├─────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐  │
│  │  ☀️ בוקר  (5)   │  │  🌙 ערב   (3)    │  │  ← Slot tabs; count = selected
│  └─────────────────┘  └──────────────────┘  │
├─────────────────────────────────────────────┤
│                                             │
│  ── ניקוי ──────────────────────────────── │  ← Category header (verbatim admin label)
│  ┌──────────────────────────────────────┐  │
│  │ [✓]  CeraVe Foaming Cleanser    [▼] │  │  ← Selected; expand = show image + comment
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ [ ]  La Roche-Posay Effaclar    [▼] │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ── סרום / אקטיב ─────────────────────────  │
│  ┌──────────────────────────────────────┐  │
│  │ [✓]  The Ordinary Niacinamide 10%  │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │ ⚠️ Paula's Choice BHA ו-Retinol AHA    ││  ← Soft incompatibility warning banner
│  │    לא מומלץ לשימוש יחד בבוקר    [השתק] ││    (daily↔daily conflict detected)
│  └─────────────────────────────────────────┘│
│                                             │
├─────────────────────────────────────────────┤
│              [המשך ←]                       │  ← Primary CTA (pill button, peach)
└─────────────────────────────────────────────┘
```

**States:**
| State | Description |
|-------|-------------|
| No selection | Empty state message; "המשך" still available (empty routine is valid) |
| Daily↔daily conflict detected | Inline `SoftWarningBanner` below conflicting products; "השתק" = mute that pair |
| Long list | Category grouping provides scannable sections; no pagination needed for ≤100 products |
| Deprecated product | Not shown in the selectable list at all |

---

### S1b — My Products Tab (Browse Mode)

**Purpose:** Persistent bottom-nav tab (`/products`). User browses, searches, and filters all products; toggles selection without leaving the tab. Same `ProductSelectionScreen` widget with `isTabDestination: true`.

**Wireframe (RTL):**
```
┌─────────────────────────────────────────────┐
│              GlowAppBar (no title)           │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐│  ← Sticky filter bar
│  │  🔍  [חיפוש מוצרים...]               ✕ ││    search field (pill, outline)
│  ├─────────────────────────────────────────┤│
│  │  [הכל]  [☀ בוקר]  [🌙 ערב]   ✓ 12    ││    slot chips + selected-count badge
│  └─────────────────────────────────────────┘│
│                                             │
│  ── ניקוי (שלב 1) ─────────────────── 2 ── │  ← Category header + selected count
│  ┌──────────────────────────────────────┐  │
│  │ [thumb] CeraVe Foaming  [☀ בוקר] [▼]│  │  ← SelectRow (same component as S1)
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ [thumb] La Roche-Posay         [▼]  │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ── סרום / אקטיב ─────────────────── 1 ── │
│  ┌──────────────────────────────────────┐  │
│  │ [thumb] The Ordinary Niacin…  [▼]  │  │
│  └──────────────────────────────────────┘  │
│       …all categories scrollable…           │
│                                             │
│  ┌─────────────────────────────────────────┐│  ← Add custom product CTA (bottom of list)
│  │  [+]  הוסיפי מוצר אישי               ││
│  └─────────────────────────────────────────┘│
├─────────────────────────────────────────────┤
│   הגדרות  | יומן | המוצרים שלי ● |  היום   │
│                         [📷 סריקת ברקוד]    │  ← FAB (Android only)
└─────────────────────────────────────────────┘
```

**Filter chip behavior:**
- "הכל" — show all non-deprecated products across both slots.
- "☀ בוקר" — show only products that have a morning config.
- "🌙 ערב" — show only products that have an evening config.
- Chips are mutually exclusive; tapping an active chip toggles it off (returns to "הכל").
- Selected-count badge (✓ N) reflects total currently-selected products regardless of filter.

**States:**
| State | Description |
|-------|-------------|
| Search returns no results | Warm empty state with search-off icon; "לא נמצאו מוצרים" |
| Category fully selected | "N נבחרו" badge turns primary-colored in the category header |
| All products unselected | No badge; gentle "בחרי את המוצרים שלך" subtitle |

---

### S1c — Barcode Scan Sheet

**Purpose:** Modal bottom sheet. User aims camera at a product barcode; app detects it. Product lookup is deferred (TBD); for now, detected barcode leads directly to Add Custom Product flow. **Android only** — FAB is hidden on Web.

**Wireframe (dark camera UI):**
```
┌─────────────────────────────────────────────┐
│  ━━━━ (drag handle)                         │
│  [📷] סריקת ברקוד                      [✕] │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │          [Live camera viewfinder]       ││
│  │                                         ││
│  │         ┌──────────────┐               ││  ← Aiming frame (peach glow border)
│  │         │  [barcode]   │               ││    Corner accent brackets (white)
│  │         └──────────────┘               ││
│  │                                         ││
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │  כוונו את המצלמה לברקוד שעל האריזה    ││  ← Hint pill (dark bg)
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

**Found state (after barcode detected):**
```
│  ✓  ברקוד זוהה                             │
│  ┌──── [barcode value chip] ─────┐          │
│  ℹ חיפוש אוטומטי יתווסף בעדכון הבא         │  ← TBD info card
│                                             │
│  [הוסיפי ידנית →]                           │  ← Opens AddCustomProductSheet
│  [סריקה חוזרת]                              │  ← Reset
```

**States:**
| State | Description |
|-------|-------------|
| Scanning | Live viewfinder; aiming frame + corner brackets; hint text |
| Found | Checkmark + barcode chip + TBD info + "Add manually" CTA + "Scan again" |
| Permission denied | Camera-blocked icon + localized message |

---

### S2 — Schedule Setup

**Purpose:** Setup step 2. For each occasional (max N/week) product, assign specific weekdays.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]   תזמון מוצרים (שלב 2/2)        │
├─────────────────────────────────────────────┤
│                                             │
│  The Ordinary Retinol 0.5%                  │  ← Product name (verbatim, bidi)
│  מומלץ: עד 3 פעמים בשבוע                   │  ← Admin's cap (Hebrew)
│                                             │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐      │
│  │א'│ │ב'│ │ג'│ │ד'│ │ה'│ │ו'│ │ש'│      │  ← Sunday–Saturday (Sun=א' first)
│  │  │ │✓ │ │  │ │✓ │ │  │ │✓ │ │  │      │     toggle chips; selected = primary-container
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘      │
│  ── ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│                                             │
│  Paula's Choice BHA Exfoliant               │
│  מומלץ: עד 2 פעמים בשבוע                   │
│                                             │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐      │
│  │א'│ │ב'│ │ג'│ │ד'│ │ה'│ │ו'│ │ש'│      │
│  │✓ │ │  │ │  │ │✓ │ │✓ │ │  │ │  │      │  ← 3 days selected for 2/week cap
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘      │
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │ ⚠️ נבחרו 3 ימים, אך ההמלצה היא עד 2  ││  ← Over-cap soft warning
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │ ⚠️ Paula's Choice ו-Retinol יפגשו      ││  ← Day-dependent incompatibility warning
│  │    ביום ד׳ — שקלי לשנות               ││
│  └─────────────────────────────────────────┘│
│                                             │
├─────────────────────────────────────────────┤
│              [המשך ←]                       │
└─────────────────────────────────────────────┘
```

**States:**
| State | Description |
|-------|-------------|
| No occasional products | Screen auto-skipped; proceed directly to S3/S4 |
| Within cap | Neutral weekday chip colors |
| Over cap | Soft warning banner; chips can still be selected |
| Day-dependent conflict | Warning banner naming both products and affected day(s) |

---

### S3 — Order Customization

**Purpose:** Optional personal reordering of selected products within a slot.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]   סדר מוצרים                     │
├─────────────────────────────────────────────┤
│  ┌──────────────┐  ┌───────────────────┐    │
│  │  ☀️ בוקר     │  │  🌙 ערב           │    │  ← Slot tabs
│  └──────────────┘  └───────────────────┘    │
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │ ⚠️ סדר מותאם אישית פעיל               ││  ← Override active notice (if set)
│  │              [אפס לסדר מומלץ]          ││     "Reset to recommended order"
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ [⣿]  CeraVe Foaming Cleanser       │  │  ← Drag handle on left (LTR of RTL = visual left)
│  └──────────────────────────────────────┘  │  Note: drag handle placement follows Flutter's
│  ┌──────────────────────────────────────┐  │        ReorderableListView default
│  │ [⣿]  The Ordinary Niacinamide 10%  │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ [⣿]  Paula's Choice BHA            │  │
│  └──────────────────────────────────────┘  │
│                                             │
├─────────────────────────────────────────────┤
│              [סיים ←]                       │  ← Done; proceeds to S4
└─────────────────────────────────────────────┘
```

**States:**
| State | Description |
|-------|-------------|
| Default (no override) | List in admin order; no "reset" notice |
| Override active | "סדר מותאם אישית פעיל" notice + "אפס לסדר מומלץ" action |
| No products in slot | "אין מוצרים שנבחרו עבור בוקר" empty state |

---

### S6 — Calendar / History

**Purpose:** Monthly grid showing completion status of past days.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [<]          מאי 2026           [>]        │  ← Month navigation (RTL: prev=R, next=L)
│              ← LTR arrows mirrored in RTL →  │
├─────────────────────────────────────────────┤
│   ש' | ו' | ה' | ד' | ג' | ב' | א'        │  ← Day headers (Sat→Sun, RTL read order)
│  ─────────────────────────────────────────  │
│    4  |  3  |  2  |  1  | 30  | 29  | 28   │  ← Dates (RTL grid)
│   [◌] | [●] | [◑] | [✗] | [◌] | [●] | [●] │  ← Completion states
│                                             │
│    11 | 10  |  9  |  8  |  7  |  6  |  5  │
│   [●] | [◑] | [✗] | [●] | [●] | [●] | [●] │
│                                             │
│    18 | 17  | 16  | 15  | 14  | 13  | 12  │
│   [●] | [●] | [●] | [◑] | [●] | [✗] | [●] │
│                                             │
│    25 | 24  | 23  | 22  | 21  | 20  | 19  │
│   [□] | [□] | [□] | [□] | [●] | [◑] | [●] │  ← Future days = neutral
│                                             │
│   31  | 30  | 29  | 28  | 27  | 26  | 25  │
│   [□] | [□] | [□] | [□] | [□] | [□] | [●] │
│                                             │
├─────────────────────────────────────────────┤
│  ● שלם  ◑ חלקי  ✗ הוחמץ  □ עתידי          │  ← Legend
├─────────────────────────────────────────────┤
│   הגדרות  |  יומן עור  |  לוח שנה  |  היום │
└─────────────────────────────────────────────┘
```

**Completion state visual encoding (colorblind-safe):**
| State | Color | Fill | Shape cue |
|-------|-------|------|-----------|
| Complete ● | `secondary-container` #EDE282 (Lemon) | Filled circle | ● |
| Partial ◑ | `tertiary-container` #DE99A4 (Rosy) | Half-circle | ◑ |
| Missed ✗ | `error-container` #FFDAD6 | X mark | ✗ |
| Future □ | `surface-container` #FFE9E4 | Empty square | □ |
| Today (current) | `primary-container` #FF8B71 outline | Outlined circle | ○ |

**States:**
| State | Description |
|-------|-------------|
| No history | Current month shows all future cells; message: "עדיין אין היסטוריה" |
| Tap past day | → S7 Day Detail |
| Tap future day | No action (non-interactive) |
| Tap today | → S7 (today's detail / editable) |

---

### S7 — Day Detail

**Purpose:** Shows a specific past day's routine as it was, done-state, and skin log.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]    יום שלישי, 14 במאי            │
├─────────────────────────────────────────────┤
│                                             │
│  ☀️  בוקר                        [● שלם]    │  ← Slot completion badge
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ┌──────────────────────────────────────┐  │
│  │ [✓]  CeraVe Foaming Cleanser       │  │  ← Done toggle (editable for past days)
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ [✓]  The Ordinary Niacinamide 10%  │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  🌙  ערב                         [◑ חלקי]  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  ┌──────────────────────────────────────┐  │
│  │ [✓]  CeraVe PM Moisturizer         │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │ [ ]  The Ordinary Retinol 0.5%     │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ── יומן עור ────────────────────────────  │
│  ┌─────────────────────────────────────────┐│
│  │  📝 "עור חלק ומוקרן, ללא גירויים"     ││  ← Skin log text
│  │  ┌──────┐ ┌──────┐                     ││
│  │  │[img] │ │[img] │                     ││  ← Skin log photos
│  │  └──────┘ └──────┘                     ││
│  │  [ערוך יומן עור]                       ││  ← → S8
│  └─────────────────────────────────────────┘│
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │  💡 הנתונים ב-14 במאי מבוססים על       ││  ← Info: routine is historical snapshot
│  │     הבחירות שהיו תקפות באותה עת        ││
│  └─────────────────────────────────────────┘│
├─────────────────────────────────────────────┤
│   הגדרות  |  יומן עור  |  לוח שנה  |  היום │
└─────────────────────────────────────────────┘
```

**States:**
| State | Description |
|-------|-------------|
| Past day with history | Done toggles are editable; routine shows historical snapshot |
| Past day, no snapshot | Shows current routine with note: "אין רשומה — מוצגים המוצרים הנוכחיים" |
| Today | Same as S4 content embedded in S7 view |
| No skin log | Shows "אין רשומה ביומן עור" + "הוסיפי רשומה" CTA |
| Deprecated product in history | Shown with deprecated marker; still renders |

---

### S8 — Skin Log Entry

**Purpose:** Add or edit free-text notes and photos for a specific day.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]   יומן עור — 26 במאי           [שמור]│  ← Save in AppBar trailing (left in RTL)
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │                                         ││
│  │  איך העור שלך היום?                     ││  ← Placeholder text (Hebrew)
│  │                                         ││
│  │  (free text, multiline)                 ││
│  │                                         ││
│  └─────────────────────────────────────────┘│
│                                             │
│  ── תמונות ────────────────────────────────  │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐  │
│  │[img1]│ │[img2]│ │[+add]│ │          │  │  ← Photo grid; + = add more
│  └──────┘ └──────┘ └──────┘ └──────────┘  │
│                                             │
│  [📷 צלמי]              [🖼️ בחרי מגלריה]    │  ← Camera / gallery buttons
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │  💡 תמונות מאוחסנות בנפח מוגבל על     ││  ← Web-only storage warning
│  │     המכשיר שלך. גיבוי מומלץ.           ││     (shown only on Web build)
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

**States:**
| State | Description |
|-------|-------------|
| New entry | Empty text area; no photos |
| Editing existing | Pre-filled text; existing photos shown; tap photo → delete option |
| Photo being compressed | Progress indicator on the photo slot |

---

### S9 — Skin Journal

**Purpose:** Browse all past skin log photos chronologically.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│              יומן עור                       │  ← No back; bottom nav screen
├─────────────────────────────────────────────┤
│                                             │
│  מאי 2026                                   │  ← Month section header
│  ┌──────┐ ┌──────┐ ┌──────┐               │
│  │[img] │ │[img] │ │[img] │               │  ← Photo grid (3 columns)
│  │26.5  │ │22.5  │ │18.5  │               │     date label below each
│  └──────┘ └──────┘ └──────┘               │
│                                             │
│  אפריל 2026                                 │
│  ┌──────┐ ┌──────┐                         │
│  │[img] │ │[img] │                         │
│  │30.4  │ │15.4  │                         │
│  └──────┘ └──────┘                         │
│                                             │
├─────────────────────────────────────────────┤
│   הגדרות  |  יומן עור  |  לוח שנה  |  היום │
└─────────────────────────────────────────────┘
```

**States:**
| State | Description |
|-------|-------------|
| No photos | Warm empty state: "עדיין אין תמונות ביומן. צלמי את העור שלך היום ✦"; CTA → S8 |
| Tap photo | Opens full-screen photo viewer (date shown); "ערוך רשומה" → S8 |

---

### S10 — Streak Display (Component — embedded in S4)

**Purpose:** Communicates consistency at a glance. Sits at the top of S4 below the date.

**Wireframe:**
```
┌──────────────────────────────────────────────┐
│  ┌────────────────────────────────────────┐  │
│  │                                        │  │  ← Glassmorphism card
│  │   🔥 12         ⭐ 30                 │  │     backdrop-filter: blur(12px)
│  │   ימי רצף       הרצף הארוך            │  │     white 60% opacity
│  │                                        │  │
│  │   החסרות השבוע:  ████░░░  1 מתוך 3   │  │  ← Weekly miss budget (optional)
│  │   [■][■][■][ ][ ][ ]                  │  │     Lemon fill = used grace; empty = remaining
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

**Data:**
| Field | Source |
|-------|--------|
| Current streak | `StreakResult.currentStreak` |
| Longest streak | `StreakResult.longestStreak` |
| Misses this week | `StreakResult.missesThisWeek` |
| Grace budget | Always 3; remaining = 3 - missesThisWeek |

**States:**
| State | Description |
|-------|-------------|
| Streak = 0 | "🌱 התחילי רצף היום!" |
| Streak reset this week | "🔄 הרצף אופס — שבוע חדש, התחלה חדשה" |
| Perfect week | "✨ שבוע מושלם!" accent |

---

### S11 — Settings

**Purpose:** Hub for managing all setup, data, and info screens.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│              הגדרות                         │
├─────────────────────────────────────────────┤
│                                             │
│  ── השגרה שלי ──────────────────────────── │
│  ┌──────────────────────────────────────┐  │
│  │  ערוך בחירת מוצרים           [←]   │  │  ← → S1
│  ├──────────────────────────────────────┤  │
│  │  ערוך תזמון                  [←]   │  │  ← → S2
│  ├──────────────────────────────────────┤  │
│  │  ערוך סדר                    [←]   │  │  ← → S3
│  └──────────────────────────────────────┘  │
│                                             │
│  ── נתונים ──────────────────────────────  │
│  ┌──────────────────────────────────────┐  │
│  │  ייצוא / ייבוא                [←]   │  │  ← → S12
│  └──────────────────────────────────────┘  │
│                                             │
│  [Web only: הפעלת רישיון פרמיום    [←] ]  │  ← → S15 (stub; shown on Web build only)
│                                             │
│  ── אודות ───────────────────────────────  │
│  ┌──────────────────────────────────────┐  │
│  │  גרסה ועדכונים                [←]   │  │  ← → S13
│  └──────────────────────────────────────┘  │
│                                             │
├─────────────────────────────────────────────┤
│   הגדרות  |  יומן עור  |  לוח שנה  |  היום │
└─────────────────────────────────────────────┘
```

---

### S12 — Export / Import

**Purpose:** Backup data to an archive; restore from an archive.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]   ייצוא / ייבוא                  │
├─────────────────────────────────────────────┤
│                                             │
│  ── ייצוא ───────────────────────────────── │
│  ┌─────────────────────────────────────────┐│
│  │  🗂️ ייצא את כל הנתונים שלך             ││
│  │  גיבוי אחרון: 15 במאי 2026             ││
│  │              [ייצא עכשיו →]             ││  ← Primary peach button
│  └─────────────────────────────────────────┘│
│                                             │
│  ── ייבוא / שחזור ────────────────────────  │
│  ┌─────────────────────────────────────────┐│
│  │  📁 ייבא קובץ גיבוי                    ││
│  │                                         ││
│  │  [בחרי קובץ]                            ││  ← File picker button
│  │                                         ││
│  │  לאחר בחירת קובץ:                       ││
│  │  ○ החלפה — מחק הכל ושחזר מהגיבוי       ││  ← Replace option
│  │  ○ מיזוג — שמור ושלב עם הנתונים הקיימים││  ← Merge option
│  │                                         ││
│  │              [ייבא ←]                   ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

**Merge conflict resolver sub-flow (sequential):**
```
┌─────────────────────────────────────────────┐
│  [✕ בטל]     התנגשות 3 מתוך 12            │  ← Progress indicator
├─────────────────────────────────────────────┤
│  בחרי גרסה:                                 │
│                                             │
│  יום 15 במאי — ערב                          │  ← Record identifier
│                                             │
│  ┌──────────────────┐  ┌──────────────────┐│
│  │   מהגיבוי         │  │   מהמכשיר        ││  ← Two-column comparison
│  │  ✓ Cleanser      │  │  ✓ Cleanser      ││
│  │  ✓ Moisturizer   │  │  ✗ Moisturizer   ││
│  │  מתוקן: 23:15    │  │  מתוקן: 08:30    ││
│  └──────────────────┘  └──────────────────┘│
│                                             │
│  [בחרי גיבוי ←]         [בחרי מכשיר ←]   │  ← Pick one
└─────────────────────────────────────────────┘
```

**States:**
| State | Description |
|-------|-------------|
| Export in progress | Spinner with "מכין קובץ גיבוי…" |
| Export success | "✓ הגיבוי נשמר"; share sheet opens |
| No file selected for import | "ייבא" button disabled |
| Replace confirmation | Alert dialog: "פעולה זו תמחק את כל הנתונים הקיימים. להמשיך?" |
| Import complete | "✓ הנתונים שוחזרו בהצלחה" |

---

### S13 — About / What's New

**Purpose:** Show version and master-list changelog.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]   אודות / מה חדש                 │
├─────────────────────────────────────────────┤
│                                             │
│  🌸 Skincare Routine Tracker                │
│  גרסה 1.2.0 | רשימת מוצרים v4             │
│                                             │
│  ── שינויים אחרונים ─────────────────────── │
│                                             │
│  📦 גרסה 1.2.0 — מרץ 2026                  │
│  • נוסף: CeraVe AM Moisturizer             │  ← Product names verbatim (bidi)
│  • הוגדר כלא מומלץ: Neutrogena Hydra Boost │
│  • שונה תדירות: Retinol → פעמיים בשבוע    │
│                                             │
│  📦 גרסה 1.1.0 — ינואר 2026               │
│  • נוסף: The Ordinary Lactic Acid          │
│                                             │
└─────────────────────────────────────────────┘
```

No "update now" button — deliberate (NFR-M4).

---

### S14 — Update Review

**Purpose:** First run after a master-list update. Shows new/deprecated products and confirms data is intact.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│           עדכון הושלם! 🎉                    │  ← No back; must complete or dismiss
├─────────────────────────────────────────────┤
│                                             │
│  ✅ כל הנתונים שלך שמורים ובשלמותם         │  ← Data-intact confirmation
│                                             │
│  ── מוצרים חדשים ────────────────────────── │
│  (לא נוספו לשגרה — בחרי אם תרצי)          │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ [ ]  CeraVe AM Moisturizer SPF      │  │  ← New product; not selected
│  └──────────────────────────────────────┘  │
│                                             │
│  ── מוצרים שהוצאו משימוש ────────────────── │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ ⚠️  Neutrogena Hydra Boost           │  │  ← Deprecated; user has this selected
│  │     "אינו מומלץ עוד — שקלי להסיר"  │  │
│  │     [הסירי]              [השארי]    │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌─────────────────────────────────────────┐│
│  │  💾 גבי את הנתונים לפני השינויים      ││
│  │              [ייצא עכשיו →]            ││
│  └─────────────────────────────────────────┘│
│                                             │
│              [המשך ←]                       │  ← Proceed to S4
└─────────────────────────────────────────────┘
```

---

### S15 — License Activation (STUB — Web only, post-v1.0)

**Purpose:** Key entry for premium cloud backup. Placeholder in v1.0.

**Wireframe:**
```
┌─────────────────────────────────────────────┐
│  [→ back]   הפעלת גיבוי ענן                │
├─────────────────────────────────────────────┤
│                                             │
│  [Coming soon placeholder]                  │
│  "תכונה זו תהיה זמינה בקרוב"               │
│                                             │
└─────────────────────────────────────────────┘
```

Will be replaced post-v1.0 with a key-entry form + cloud backup controls.

---

### S16 — Backup Reminder Surface

**Purpose:** Gentle non-blocking nudge shown at the bottom of S4 when no recent backup exists.

**Shown as a persistent (but dismissible) banner at the bottom of S4, above the navigation bar.**

**Wireframe (see S4 above — this is the banner section):**
```
│  ┌───────────────────────────────────────┐  │
│  │  💾 גבי את הנתונים שלך — אחסון      │  │  ← Android: standard reminder
│  │     הדפדפן עלול להימחק בכל עת [גיבוי][✕]│  ← Web: stronger warning about eviction
│  └───────────────────────────────────────┘  │
```

**Behavior:**
- Shown when `lastExportDate` is null or > 30 days ago.
- On Web build: shown after 7 days (more urgent given eviction risk), with explicit iOS Safari storage warning.
- ✕ dismisses for this session; shown again next launch if condition persists.
- "גיבוי" → S12.

---

## 4. User Flows

### 4.1 Primary Flow: First-Time Setup → Daily Use

```
App Install
    │
    ▼
Is setup complete?
    │ No
    ▼
S1 Product Selection
    │ User selects products; no occasional products?
    ├──────────────────────────────────────┐
    │                                      ▼
    │ Has occasional products?        S4 Daily Home
    ▼
S2 Schedule Setup
    │
    ▼
S3 Order Customization (skippable)
    │
    ▼
S4 Daily Home ←──── Daily app open (subsequent launches)
    │
    ├── Expand row → S5 Product Detail
    ├── Tap date → S7 Day Detail
    ├── Tap skin log icon → S8 Skin Log Entry
    └── Bottom nav → S6, S9, S11
```

### 4.2 Flow: History Review

```
Bottom nav "לוח שנה"
    │
    ▼
S6 Calendar (monthly grid)
    │
    └── Tap past day → S7 Day Detail
                            │
                            └── Tap "ערוך יומן עור" → S8 Skin Log Entry
```

### 4.3 Flow: Export + Import

```
Bottom nav "הגדרות" → S11 → "ייצוא / ייבוא" → S12
    │
    ├── Export → archive generated → share sheet / download
    │
    └── Import
            │
            ├── Replace → confirm dialog → overwrite → done
            │
            └── Merge → S12 conflict resolver loop
                            │
                            └── done → back to S11
```

### 4.4 Flow: Post-Update

```
App launch after new APK/web version
    │
    ▼
ReconciliationService detects new contentVersion
    │
    ▼
S14 Update Review (shown before S4)
    │
    ├── User reviews new products (optionally selects)
    ├── User reviews deprecated (remove or keep)
    ├── User optionally exports backup
    └── "המשך" → S4
```

### 4.5 Error Flow: Import with Conflicts

```
S12 Import → file selected → validate archive
    │
    ├── Invalid archive → error message → stay on S12
    │
    └── Valid → choose Replace / Merge
            │
            Merge chosen
            │
            ▼
        Sequential conflict resolver (one per conflict)
            │
            └── All resolved → import complete → S11
```

---

## 5. Style Guide

### 5.1 Colors (Radiant Dew)

| Purpose | Name | Hex | Usage |
|---------|------|-----|-------|
| Primary | Vibrant Peach | `#9E412C` | CTA buttons, active states, done checkmarks |
| Primary Container | Peach Container | `#FF8B71` | Card highlights, expanded states |
| Secondary | Soft Lemon | `#67600A` | Morning slot color, streak highlights |
| Secondary Container | Lemon Container | `#EDE282` | Morning slot header bg, streak card, complete-day cells |
| Tertiary | Rosy Pink | `#874E58` | Evening slot color, progress accents |
| Tertiary Container | Rosy Container | `#DE99A4` | Evening slot header bg, partial-day cells |
| Surface | Cream | `#FFF8F6` | All screen backgrounds |
| Surface Container | — | `#FFE9E4` | Card surfaces |
| On Surface | Warm Charcoal | `#251815` | Primary body text |
| On Surface Variant | Muted Brown | `#56423E` | Secondary text, captions |
| Outline | — | `#89726D` | Borders, dividers |
| Error | — | `#BA1A1A` | Error states |
| Error Container | — | `#FFDAD6` | Missed-day calendar cells |
| Inverse Primary | — | `#FFB4A4` | Text on dark surfaces |

**Glassmorphism style** (sticky headers, streak card, warning banners):
- `background: rgba(255, 255, 255, 0.60)`
- `backdrop-filter: blur(12px)`
- `border: 1px solid rgba(255, 255, 255, 0.30)`

**Shadow / glow style** (cards):
- Level 2: `boxShadow: 0 4px 24px rgba(255, 139, 113, 0.12)` (peach ambient glow)
- Level 3 (hover/active): double shadow with tight white highlight + wide peach glow

### 5.2 Typography

| Role | Font | Size | Weight | Line Height |
|------|------|------|--------|-------------|
| Display (hero) | Quicksand | 48px | 700 | 56px |
| Headline Large | Quicksand | 32px (28px mobile) | 700 | 40px (36px) |
| Headline Medium | Quicksand | 24px | 600 | 32px |
| Body Large | Quicksand | 18px | 500 | 28px |
| Body Medium (default) | Quicksand | 16px | 500 | 24px |
| Label Medium (buttons, tags) | Plus Jakarta Sans | 14px | 600 | 20px |
| Label Small (captions, dates) | Plus Jakarta Sans | 12px | 700 | 16px |

**Hebrew rendering notes:**
- Both Quicksand and Plus Jakarta Sans render Hebrew characters adequately.
- Quicksand's rounded terminals work especially well for Hebrew at large sizes.
- At 12px (Label Small), Plus Jakarta Sans is preferred for Hebrew legibility.
- BiDi text (product names): use `TextDirection.ltr` wrapper inside RTL context for pure Latin brand names; allow Unicode BiDi algorithm to handle mixed Hebrew+Latin sentences naturally.

### 5.3 Spacing Scale (8px base unit)

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4px | Tight internal padding (icon + text gap) |
| `sm` | 12px | Within-component padding |
| `base` | 8px | Grid unit |
| `md` | 24px | Between related elements |
| `lg` | 40px | Between major sections |
| `xl` | 64px | Page-level vertical breathing room |
| `gutter` | 16px | Internal card padding |
| `margin-mobile` | 20px | Screen side margins |

### 5.4 Shape Language

| Element | Corner Radius |
|---------|--------------|
| Buttons (primary CTA) | Full pill (9999px) |
| Inputs | 1rem (16px) |
| Cards (mobile) | 2rem (32px) |
| Bottom navigation | 0 (flush to edge) |
| Chips / weekday toggles | Full pill (9999px) |
| Category headers | 0 (spans full width) |
| Routine item rows | 1rem (16px) |
| Photo thumbnails | 1rem (16px) |
| Warning banners | 1.5rem (24px) |
| Bottom sheet | 2rem (32px) top corners only |

### 5.5 Icons

Use **Phosphor Icons** (rounded / soft variant, 2px stroke weight) to match the rounded UI personality. Key icons:

| Icon | Usage |
|------|-------|
| `sun` | Morning slot |
| `moon` | Evening slot |
| `fire` | Streak current |
| `star` | Streak longest |
| `check-circle` | Done / complete |
| `warning` | Incompatibility conflict / deprecation |
| `archive-box` | Export |
| `folder-open` | Import |
| `calendar` | Calendar nav |
| `camera` | Skin log photo |
| `image` | Gallery |
| `gear` | Settings |
| `info` | About |
| `arrow-right` | Back in RTL (leading navigation) |
| `dots-six-vertical` | Drag handle (S3) |

---

## 6. Accessibility Requirements

### 6.1 WCAG Level

- [x] Level AA (recommended and targeted)

### 6.2 Accessibility Checklist

| Requirement | Approach |
|-------------|----------|
| Keyboard navigation | Full keyboard nav for Web build; focus order follows RTL reading order |
| Focus indicators | 2px solid `primary` (#9E412C) outline on focused elements; visible on cream background |
| Color contrast | All text on surfaces: Warm Charcoal (#251815) on Cream (#FFF8F6) = contrast ratio ~14:1 ✓ |
| Calendar color + shape | Completion states use BOTH color AND shape cue (●◑✗□) — colorblind-safe |
| Screen reader labels | All `RoutineItemRow` instances include `Semantics(label: "${product.name}, ${isDone ? 'בוצע' : 'לא בוצע'}")` |
| Done/Own toggle | Toggle state announced: "נבחר" / "לא נבחר" |
| Conflict warnings | Warning banners have `role="alert"` semantics (or Flutter `LiveRegion`) |
| Form labels | Skin log text area has associated label: "הערות על מצב העור" |
| Error messages | Import errors announced via `LiveRegion` / `Semantics.liveRegion` |
| Tap target size | All interactive elements ≥ 44×44pt |
| BiDi text | Product names wrapped in `Directionality.ltr` or `Bidi.setDirection()` for pure LTR brand names; mixed Hebrew+Latin uses Flutter's natural Unicode BiDi |
| Image alt text | Product images: `Semantics(label: "${product.name}")` |
| Drag-to-reorder (S3) | Drag handles are keyboard-accessible via Flutter's `ReorderableListView` built-in keyboard support |

---

## 7. Interaction Patterns

### 7.1 Loading States

- **Screen load:** Skeleton shimmer (cream-to-peach gradient sweep) on card shapes. No spinner for the main daily routine (data is local, loads < 100ms typically).
- **Export in progress:** Full-screen `CircularProgressIndicator` with "מכין קובץ גיבוי…" overlay.
- **Photo compression:** Inline progress indicator within the photo slot being processed.

### 7.2 Form Validation

- Validation on S2 (schedule): real-time as weekday toggles are selected. Over-cap warning appears immediately but does not block.
- Import file: validated on selection, before "ייבא" is enabled. Error shown inline if file is invalid.
- No required fields; empty routine is always valid.

### 7.3 Confirmations

| Action | Confirmation Type |
|--------|------------------|
| Import: Replace | Modal alert dialog (destructive action) |
| Mute an incompatibility warning | Immediate (no confirm); silently stored; reversible via S1/S2 re-evaluation |
| Reset order to recommended | Inline confirmation prompt in S3 |
| Remove deprecated product | Inline button in S14; no separate confirm |

### 7.4 Notification / Feedback Patterns

| Pattern | When |
|---------|------|
| `SoftWarningBanner` (dismissible) | Incompatibility warnings (S1, S2, S4); over-cap warning (S2); deprecation notices (S4, S7); backup reminder (S16) |
| Inline badge | Deprecated product marker in routine rows |
| Conflict marker icon (⚠️) on routine row | When incompatible products are both in today's routine |
| Bottom sheet | Conflict detail explanation (tap ⚠️ icon) |
| Toast / Snackbar | Export success; import success |
| Full-screen review | S14 (post-update) — forced to review before proceeding to S4 |

---

## 8. Traceability

| Functionality Requirement | UI Screen / Component |
|--------------------------|----------------------|
| UC-1 Master list authoring | Admin-side only; S13 displays result (version + changelog) |
| UC-1b Incompatibility rules | `SoftWarningBanner` on S1, S2, S4; `ConflictInfo` tooltip on S4 |
| UC-2 Product deprecation | `RoutineItemRow` deprecated variant; S14 deprecated section |
| UC-3 Release versioning | S13 About/What's New; S14 Update Review |
| UC-4 Product selection (S1) | S1 screen; ownership toggle in `RoutineItemRow` |
| UC-4b Incompatibility feedback | `SoftWarningBanner`; mute affordance on daily↔daily warnings in S1 |
| UC-5 Schedule setup (S2) | S2 screen; `WeekdayPicker` component |
| UC-6 Order customization (S3) | S3 screen; `ReorderableListView`; "Reset" action |
| UC-7 Revise setup | S11 entry points to S1, S2, S3 |
| UC-8 Today's routine (S4) | S4 Daily Home screen; slot sections; effective-date display |
| UC-9 Record product use | Done toggle in `RoutineItemRow` on S4/S7 |
| UC-10 Product detail | `RoutineItemRow` expanded state (image + comment) |
| UC-11 Calendar history | S6 Calendar; S7 Day Detail; 4-state completion indicators |
| UC-12 Deprecated product notice | `RoutineItemRow` deprecated variant; S14 |
| UC-13 Streak tracking | S10 Streak widget (embedded in S4) |
| UC-14 Skin log entry | S8 Skin Log Entry screen |
| UC-15 Skin journal | S9 Skin Journal screen |
| UC-16 Export | S12 Export section; share sheet trigger |
| UC-17 Import / Merge | S12 Import section; sequential conflict resolver UI |
| UC-18 Post-update review | S14 Update Review screen |
| UC-19 Version + changelog | S13 About / What's New |
| UC-20 Backup reminder | S16 `SoftWarningBanner` on S4 |
| UC-21 Premium (deferred) | S15 stub; S11 entry point (Web only) |
| NFR-L1–L4 Hebrew RTL / bidi | All screens (RTL layout); `RoutineItemRow` bidi product names; no mirroring of images |
| NFR-M1 Stable product IDs | No UI impact; data layer |
| NFR-M4 No in-app updater | S13 has no "update now" button — deliberate absence |
| NFR-M6 Backup reminder independent of update | S16 shown based on last-export-date, not update events |

---

## 9. Proposed Additions

The following design ideas emerge naturally from the UX but are **not in FUNCTIONALITY.md**. They require explicit approval before implementation.

| # | Proposal | Rationale | Status |
|---|----------|-----------|--------|
| 1 | **Weekly miss budget display** (the "החסרות השבוע" bar in S10) | The streak grace rule (3 misses/week) is not obvious; surfacing it helps users understand why their streak survived a missed day. The PRD notes it as "suggested, not required" (UX brief §S10). | Included as optional display in S10 — matches PRD guidance. No approval needed. |
| 2 | **Skin log quick-entry from S4** | A floating "+" button for skin log on S4 (today) | Already in design as the top-right skin log icon. No change to FUNCTIONALITY.md needed. |
| 3 | **Before/after skin comparison** | Side-by-side photo viewer in S9 | Explicitly out of scope (PRD §13 future). **NOT included.** |
| 4 | **Push notification reminders** | Daily nudge at a chosen time | Explicitly out of scope (PRD §3 Non-Goals). **NOT included.** |
