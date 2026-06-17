# Architectural Decision Records

## ADR-001: Replace category-by-category guided flow with unified search+scan

**Status**: Accepted (implemented V3 onboarding)

**Context**: The original guided product-selection flow walked users one category at a time (e.g., "Cleansers", then "Moisturizers"). This created 4–6 friction steps before reaching the schedule setup.

**Decision**: Replace with a single unified screen: a search field (default) and a scan tab. Users add all products in one step. A separate category review step follows where they can correct auto-assigned categories.

**Rationale**:
- Aligns with PRD UC-1 (product selection) — products are expected to come from a unified master list, not a per-category drill-down
- Fewer steps to reach the first meaningful value (daily routine)
- Search handles brand filtering naturally, removing the need for a dedicated "מותגים" tab

**Consequences**: The `_buildGuided()` method in `ProductSelectionScreen` now implements the V3 search+scan+tray UI. The old `_catStep` state and `_ProgressBar`/`_CategoryGlyph` widgets remain in the file but are no longer reachable from the guided flow (dead code, deferred cleanup).

---

## ADR-002: Category overrides are ephemeral in V1

**Status**: Accepted

**Context**: `CategoryReviewScreen` lets users reassign a product to a different display category. This affects ordering on the review screen and potentially which slot a product appears under.

**Decision**: Category overrides are stored only in `_CategoryReviewScreenState._categoryOverrides` (a `Map<String, String>` in widget state). They are not persisted to `UserDataRepository`.

**Rationale**:
- Persisting would require a new schema field and a migration from the existing user data schema version
- The incompatibility rule engine reads `categoryId` from master content; user-side overrides would require the engine to consult user data on every conflict check — a significant change
- The category shown in `CategoryReviewScreen` is a setup-time display aid, not a runtime behavioral change

**Consequences**: If the user backgrounds the app mid-review and it is evicted, overrides are lost. Acceptable in V1 since the user can re-assign on re-entry. Deferred to V1.1.

---

## ADR-003: Remove "מותגים" tab from onboarding product selection

**Status**: Accepted

**Context**: The original V2 design had three tabs: "חיפוש", "מותגים" (brand grid), "סריקה".

**Decision**: Remove "מותגים". Keep only "חיפוש" (search, default) and "סריקה" (scan).

**Rationale**: The search field already filters by brand name. A separate brand grid adds UI surface area without adding capability. The barcode scan handles physical product lookup without knowing the brand in advance.

**Consequences**: Users who want to browse by brand use the search field with a brand name query.

---

## ADR-004: Category chips use `AppColors.primaryFixed` background

**Status**: Accepted

**Context**: An earlier design draft used red/outline styling for category chips in the category review screen.

**Decision**: Category chips use `AppColors.primaryFixed` (very light peach, `#FFDDAD3`) background with `AppColors.primary` text. Error/red colors are reserved exclusively for actual conflict warnings.

**Rationale**: The Radiant Dew design system reserves `errorContainer`/`error` colors for conflicts and destructive actions. A category label is purely informational — using red for it would mislead users into thinking their product selection has a problem.

**Consequences**: `_CalmCategoryChip` is a dedicated widget class. Any chip that signals a real conflict must use a separate widget with error-color styling.
