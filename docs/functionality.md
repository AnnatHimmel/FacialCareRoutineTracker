# Functionality

## Onboarding V3 Product Selection Flow

### Screen 1 — Product Selection (`ProductSelectionScreen` in guided mode)

**Tab toggle**: "חיפוש" (default) | "סריקה"

**Search tab**:
- Search field with "חפשו מוצר או מותג..." hint
- When query is empty: shows all non-deprecated products sorted by category order, labeled "מוצרים נפוצים"
- When query is non-empty: shows filtered results matching product name
- "לא מצאתם? הוסיפו ידנית" link at bottom → opens `AddCustomProductSheet` modal
- Tapping a product row toggles selection (checkmark shown when selected)

**Scan tab**:
- Tap the viewfinder area or camera button → opens `BarcodeScanSheet` modal
- Barcode lookup checks local master list first, then Supabase if configured

**Bottom tray** (always visible):
- Horizontal scroll of 38px product thumbnails, each with a small × badge (tap to deselect)
- Count label: "{N} מוצרים נבחרו"
- CTA "סידור המדף שלי" — opacity 0.45 + `IgnorePointer` when no products selected, full opacity when ≥1 selected
- Tapping CTA navigates to Screen 2 (category review)

### Screen 2 — Category Review (`CategoryReviewScreen`)

**Header**: Back arrow + title "סידרנו את המוצרים לפי שלבים" + subtitle "בדקו שהקטגוריות נכונות — אפשר לשנות בלחיצה"

**Product list** (one card per selected product):
- Sorted by effective category order (override if set, otherwise master `categoryId`)
- Each card: ProductThumb (46px) + product name + calm category chip + "שינוי קטגוריה" button + remove icon
- **Calm category chip**: background `AppColors.primaryFixed` (very light peach), text `AppColors.primary`. Never uses red/error colors.
- **"שינוי קטגוריה"** (primary): tapping expands an inline category picker showing all categories as pills; tapping a pill reassigns the product's display category (ephemeral)
- **Remove** (secondary): `Icons.close_rounded` icon button, `onSurfaceVariant` color. No text label.

**"הוספת מוצרים נוספים"**: dashed outline button — returns to Screen 1

**Bottom CTA "המשיכי לבחירת ימים"** (feminine) / "המשך לבחירת ימים" (masculine via he_MA locale override): calls `onNext` which pushes `/setup/schedule`

## Streak Logic

- Slot done = ≥1 product recorded in that slot
- Complete day = both Morning and Evening done
- Miss = one empty scheduled slot (blank day = 2 misses)
- Grace: 3 slot-misses forgiven per Sunday–Saturday week; 4th resets streak; unused grace does not carry over

## Day Boundary

Activity before 06:00 counts toward the prior calendar day.

## Incompatibility Rules

Advisory only — never block selection. Rules reference product-pairs or category-pairs within a scope (Morning, Evening, or same-day cross-slot). Conflicts shown as warning chips on routine rows and inline on product selection. Per-conflict mute stored locally.

## Export / Import

Export = single portable JSON archive of all user data. Import = "Replace" (full overwrite) or "Merge" (per-conflict resolution using stable product IDs and `lastModified` timestamps).

## Backup Reminder

Non-blocking, dismissible banner (`BackupReminderBanner`) surfaced after 30 days without export. Links to Export/Import screen.
