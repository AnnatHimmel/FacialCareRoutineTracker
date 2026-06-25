import { test, expect } from '@playwright/test';
import {
  bootFlutter,
  tapButton,
  tapText,
  fillField,
  selectProduct,
  scanDaySchedule,
  scrollScheduleToTop,
  tapDayChip,
  tapNavTab,
  text,
  expectText,
  expectTextContaining,
} from '../helpers/flutter';

/**
 * Products to select in the onboarding product-selection step.
 * `search` is typed into the search field to filter the list;
 * `exact` is the product's full name in master_products.json.
 */
const PRODUCTS = [
  { search: 'Cleansing Gel',    exact: 'Generic Cleansing Gel' },
  { search: 'All Clean Balm',   exact: 'All Clean Balm' },
  { search: 'Marula',           exact: 'Anti-Aging Marula Oil' },
  { search: 'Light On Serum',   exact: 'Light On Serum Centella + Vita C' },
  { search: 'Hyper Acid',       exact: 'Hyper Acid 4 AHA BHA PHA LHA 30 Serum' },
  { search: 'Cicapair',         exact: 'Cicapair Intensive Soothing Repair Treatment Lotion' },
  { search: 'Niacinamide 20',   exact: 'Niacinamide 20 Serum' },
  { search: 'Glutathione',      exact: '88B/mL L-Glutathione Flexible Liposome' },
  { search: 'T15 Serum',        exact: 'T15 Serum' },
  { search: 'PDRN',             exact: 'PDRN' },
  { search: 'AZ15',             exact: 'AZ15 Serum' },
  { search: 'Vitamin A-mazing', exact: 'Vitamin A-mazing Bakuchiol Night Cream' },
  { search: 'Dynasty',          exact: 'Dynasty Cream' },
  { search: 'Deep Vita A',      exact: 'Deep Vita A Retinol Serum' },
  { search: 'Argireline',       exact: 'Argireline Solution 10%' },
];

test.describe('Schedule compliance after onboarding', () => {
  /**
   * Drive the full onboarding flow with the 15 specified products and verify
   * the resulting default evening schedule matches the rules below:
   *
   *   1. Argireline is never in the morning, and is on every evening.
   *   2. Hyper Acid is on Sunday, Tuesday, and Thursday evenings only.
   *   3. Vitamin A-mazing and Deep Vita A are on Monday, Wednesday, Friday,
   *      and Saturday evenings only.
   */
  test('15 products produce the correct default schedule', async ({ page }) => {
    test.setTimeout(600_000);

    // ── Step 0: Language ──────────────────────────────────────────────────────
    await bootFlutter(page, '/');
    await tapButton(page, 'English');

    // ── Step 1: Welcome ───────────────────────────────────────────────────────
    await expectText(page, 'The Glow Protocol');
    await tapButton(page, "Let's Begin");

    // ── Step 2: Profile ───────────────────────────────────────────────────────
    await expectText(page, 'Tell us about you');
    await fillField(page, 'Your name', 'Dana');
    await tapButton(page, 'Female');
    await tapText(page, 'Continue');

    // ── Step 3a: Product selection ────────────────────────────────────────────
    await expectText(page, 'Which products do you have?');

    for (const { search, exact } of PRODUCTS) {
      // selectProduct retries the search+tap until the row actually appears,
      // self-healing the nondeterministic Flutter-web text-input engagement.
      await selectProduct(page, 'Search product or brand...', search, exact);
    }

    await tapButton(page, 'Organize my shelf');

    // ── Step 3b: Category review ──────────────────────────────────────────────
    await tapText(page, "Let's plan your routine");

    // ── Step 3c: Routine summary (auto-sort) ──────────────────────────────────
    // The auto-sorter now runs after category review and shows its results before
    // per-slot customization. Wait for the summary screen to load and tap Continue.
    await expect(page).toHaveTitle(/.*/, { timeout: 30_000 }); // ensure page is stable

    // Look for the primary button on the routine summary (may be "Let's review..." or "נסקור...")
    const routineButton = page.locator('button, [role="button"]').first();
    await expect(routineButton).toBeVisible({ timeout: 20_000 });
    await routineButton.click();

    // ── Step 3d: Morning schedule ─────────────────────────────────────────────
    await expectText(page, 'Morning routine');

    // Rule 1 — Argireline is conflict-resolved to evening-only while Vita C is
    // present, so on the morning schedule it must appear in the "not used"
    // (לא בשימוש) section, not scheduled for any morning day.
    expect(
      (await scanDaySchedule(page, ['Argireline']))['Argireline'],
      'Argireline should be in the "not used" section on morning',
    ).toBe('notUsed');

    await scrollScheduleToTop(page);
    await tapText(page, "Let's review the layering order");

    // ── Step 3e: Morning order ────────────────────────────────────────────────
    // Argireline must not appear in the drag list (schedule was cleared to empty,
    // so order_customization_screen excludes it via the isExcluded guard).
    await expectTextContaining(page, "Looks good, let's continue to your evening routine");
    await expect(text(page, 'Argireline Solution 10%')).not.toBeVisible();
    await tapText(page, "Looks good, let's continue to your evening routine");

    // ── Step 3f: Evening schedule (direct, no transition) ────────────────────
    // No "Now for the evening routine" transition — it goes directly to evening.
    await expectText(page, 'Evening routine');

    // Verify per-day assignments using the default Days view. A product is
    // 'scheduled' when it sits above the Hebrew "לא בשימוש" separator for the
    // selected day, 'notUsed' when below it.
    //
    //   Sun: Argireline ✓  Hyper Acid ✓  Vita A ✗  Deep Vita A ✗
    //   Mon: Argireline ✓  Hyper Acid ✗  Vita A ✓  Deep Vita A ✓
    //   Tue: Argireline ✓  Hyper Acid ✓  Vita A ✗  Deep Vita A ✗
    //   Wed: Argireline ✓  Hyper Acid ✗  Vita A ✓  Deep Vita A ✓
    //   Thu: Argireline ✓  Hyper Acid ✓  Vita A ✗  Deep Vita A ✗
    //   Fri: Argireline ✓  Hyper Acid ✗  Vita A ✓  Deep Vita A ✓
    //   Sat: Argireline ✓  Hyper Acid ✗  Vita A ✓  Deep Vita A ✓
    const want = (on: boolean) => (on ? 'scheduled' : 'notUsed');
    const SCHEDULE = [
      { chip: 'Sun', argireline: true,  hyperAcid: true,  vitA: false, deepVitA: false },
      { chip: 'Mon', argireline: true,  hyperAcid: false, vitA: true,  deepVitA: true  },
      { chip: 'Tue', argireline: true,  hyperAcid: true,  vitA: false, deepVitA: false },
      { chip: 'Wed', argireline: true,  hyperAcid: false, vitA: true,  deepVitA: true  },
      { chip: 'Thu', argireline: true,  hyperAcid: true,  vitA: false, deepVitA: false },
      { chip: 'Fri', argireline: true,  hyperAcid: false, vitA: true,  deepVitA: true  },
      { chip: 'Sat', argireline: true,  hyperAcid: false, vitA: true,  deepVitA: true  },
    ];

    const TARGETS = ['Argireline', 'Hyper Acid', 'Vitamin A-mazing', 'Deep Vita A'];
    for (const { chip, argireline, hyperAcid, vitA, deepVitA } of SCHEDULE) {
      await scrollScheduleToTop(page);
      await tapDayChip(page, chip);
      const placement = await scanDaySchedule(page, TARGETS);

      expect(placement['Argireline'],       `Argireline on ${chip}`).toBe(want(argireline));
      expect(placement['Hyper Acid'],        `Hyper Acid on ${chip}`).toBe(want(hyperAcid));
      expect(placement['Vitamin A-mazing'],  `Vita A on ${chip}`).toBe(want(vitA));
      expect(placement['Deep Vita A'],       `Deep Vita A on ${chip}`).toBe(want(deepVitA));
    }

    await scrollScheduleToTop(page);

    // ── Step 3g: Evening order ────────────────────────────────────────────────
    await tapText(page, "Let's review the layering order");
    await tapText(page, "Let's review your week");

    // ── Step 3h: Week at a glance (onboarding completion) ────────────────────
    // After ordering completes, the app navigates to /week-glance in onboarding mode.
    await expectTextContaining(page, 'My Week');

    // Tap the celebratory CTA to finish onboarding and go to the daily home.
    // The button text may be localized, so find it by pattern.
    const glowButton = page.getByText(/let's glow|אפשר להתחיל/i, { exact: false });
    await glowButton.first().click();

    // ── Onboarding complete: daily home ───────────────────────────────────────
    // The daily home renders the routine section headers once onboarding finishes.
    await expectTextContaining(page, 'Morning Routine');
  });
});

test.describe('Conflict resolution — minimal product set', () => {
  /**
   * Bug regression: selecting only Argireline Solution 10% and
   * Light On Serum Centella + Vita C must trigger conflict-resolution
   * and move Argireline to the evening slot.
   *
   * Why:
   *   - Vita C (prod-016) is morning-only (no eveningConfig).
   *   - Argireline (prod-037) is bi-slot (morning + evening).
   *   - rule-004 forbids argireline + vitamin-C in the same slot.
   *   - ConflictResolver §(a) kicks in: the bi-slot product (Argireline)
   *     is the only one that can leave morning, so it is moved there.
   *
   * Expected outcome:
   *   Morning schedule — Argireline in "not used" section.
   *   Evening schedule — Argireline scheduled every day.
   */
  test('Argireline moves to evening-only when Vita C is the only other product', async ({ page }) => {
    test.setTimeout(300_000);

    // ── Onboarding ──────────────────────────────────────────────────────────
    await bootFlutter(page, '/');
    await tapButton(page, 'English');
    await expectText(page, 'The Glow Protocol');
    await tapButton(page, "Let's Begin");
    await expectText(page, 'Tell us about you');
    await fillField(page, 'Your name', 'Dana');
    await tapButton(page, 'Female');
    await tapText(page, 'Continue');

    // ── Product selection — only two products ────────────────────────────────
    await expectText(page, 'Which products do you have?');
    await selectProduct(page, 'Search product or brand...', 'Argireline',   'Argireline Solution 10%');
    await selectProduct(page, 'Search product or brand...', 'Light On Serum', 'Light On Serum Centella + Vita C');
    await tapButton(page, 'Organize my shelf');

    // ── Category review ──────────────────────────────────────────────────────
    await tapText(page, "Let's plan your routine");

    // ── Routine summary (auto-sort, conflict resolved here) ─────────────────────
    // The conflict between Argireline and Vita C is resolved during the routine
    // summary build: Argireline is moved to evening-only. The CTA proceeds to
    // the morning schedule for review.
    await expect(page).toHaveTitle(/.*/, { timeout: 30_000 }); // ensure page is stable
    const routineButton2 = page.locator('button, [role="button"]').first();
    await expect(routineButton2).toBeVisible({ timeout: 20_000 });
    await routineButton2.click();

    // ── Morning schedule ─────────────────────────────────────────────────────
    await expectText(page, 'Morning routine');

    // Conflict resolution should have cleared Argireline from every morning day
    // (already resolved at the summary step above).
    const morningPlacement = await scanDaySchedule(page, ['Argireline']);
    expect(
      morningPlacement['Argireline'],
      'Argireline must be in the "not used" section on the morning schedule after conflict resolution with Vita C',
    ).toBe('notUsed');

    await scrollScheduleToTop(page);
    await tapText(page, "Let's review the layering order");

    // ── Morning order ────────────────────────────────────────────────────────
    // Argireline has been removed from morning, so it must not appear in the
    // morning drag-to-order list.
    await expectTextContaining(page, "Looks good, let's continue to your evening routine");
    await expect(text(page, 'Argireline Solution 10%')).not.toBeVisible();
    await tapText(page, "Looks good, let's continue to your evening routine");

    // ── Evening schedule (direct, no transition) ────────────────────────────
    await expectText(page, 'Evening routine');

    // Argireline is daily in the evening — it must be scheduled on the default
    // day shown when the screen first opens.
    const eveningPlacement = await scanDaySchedule(page, ['Argireline']);
    expect(
      eveningPlacement['Argireline'],
      'Argireline must be scheduled in the evening after being conflict-resolved off morning',
    ).toBe('scheduled');

    await scrollScheduleToTop(page);
    await tapText(page, "Let's review the layering order");

    // ── Evening order ─────────────────────────────────────────────────────────
    await tapText(page, "Let's review your week");

    // ── Week at a glance (onboarding completion) ──────────────────────────────
    // After ordering, the app navigates directly to /week-glance in onboarding mode.
    await expectTextContaining(page, "My Week");

    // Both slots must show the green "no conflicts" banner — the conflict was
    // fully resolved by moving Argireline off morning, so neither slot retains
    // an incompatibility.
    await expectTextContaining(page, 'No conflicts in morning routine');
    await expectTextContaining(page, 'No conflicts in evening routine');

    // The week matrix must show each product in its resolved slot.
    // Morning matrix row: Light On Serum (Vita C) — the only morning product.
    await expectTextContaining(page, 'Light On Serum');
    // Evening matrix row: Argireline — conflict-moved here, daily every night.
    await expectTextContaining(page, 'Argireline Solution');

    // Tap the celebratory CTA to finish onboarding and go to the daily home.
    const glowButton2 = page.getByText(/let's glow|אפשר להתחיל/i, { exact: false });
    await glowButton2.first().click();

    // ── My Day (daily home screen) ────────────────────────────────────────────
    // After the CTA, we're on the daily home route. The IndexedDB state persists
    // from the onboarding session.
    // Section headers are plain Text widgets — textContaining works for them.
    await expectTextContaining(page, 'Morning Routine');
    await expectTextContaining(page, 'Evening Routine');

    // Routine items use Semantics(label: 'product.name, Not done', button: true),
    // so the product name is in aria-label, not DOM text content. Use an
    // attribute selector that matches aria-label directly.
    await expect(
      page.locator('flt-semantics[role="button"][aria-label*="Light On Serum"]:not([aria-hidden="true"])').first()
    ).toBeVisible({ timeout: 20_000 });

    await expect(
      page.locator('flt-semantics[role="button"][aria-label*="Argireline Solution"]:not([aria-hidden="true"])').first()
    ).toBeVisible({ timeout: 20_000 });
  });
});

test.describe('AHA + Vitamin A conflict resolution', () => {
  /**
   * Regression: selecting Vitamin A-mazing Bakuchiol Night Cream (retinoid,
   * daily) BEFORE Hyper Acid 4 AHA BHA PHA LHA 30 Serum (exfoliate, weeklyMax-3)
   * leaves the conflict unresolved at selection time.
   *
   * Why: when Hyper Acid is selected second, _resolveSlotConflicts skips the
   * mutation for Vitamin A-mazing because it is an existing, evening-only (non-
   * bi-slot) product. The guard that protects user-set schedules from being
   * overwritten by auto-resolve is intentionally strict here.
   *
   * As a result Vitamin A-mazing retains its DailyRule default (all 7 days)
   * while Hyper Acid was seeded to {Sun,Tue,Thu} by _ensureCappedSchedule.
   * This produces 3 conflict days visible on the evening schedule screen.
   *
   * buildRoutineSummary → fixProblems (called when the user finishes the
   * ordering step) fully resolves the conflict: Hyper Acid anchors at {0,2,4}
   * and Vitamin A-mazing yields to {1,3,5,6} (Mon/Wed/Fri/Sat). The routine-
   * ready summary shows "What We Adjusted for You", and both the weekly glance
   * and daily home are thereafter conflict-free.
   */
  test(
    'conflict visible in evening schedule resolves through ordering; weekly glance and daily home are clean',
    async ({ page }) => {
      test.setTimeout(300_000);

      // ── Onboarding ──────────────────────────────────────────────────────────
      await bootFlutter(page, '/');
      await tapButton(page, 'English');
      await expectText(page, 'The Glow Protocol');
      await tapButton(page, "Let's Begin");
      await expectText(page, 'Tell us about you');
      await fillField(page, 'Your name', 'Dana');
      await tapButton(page, 'Female');
      await tapText(page, 'Continue');

      // ── Product selection ────────────────────────────────────────────────────
      // Select Vitamin A-mazing FIRST, then Hyper Acid. This order is what
      // leaves the conflict unresolved at selection time (see test description).
      await expectText(page, 'Which products do you have?');
      await selectProduct(
        page,
        'Search product or brand...',
        'Vitamin A-mazing',
        'Vitamin A-mazing Bakuchiol Night Cream',
      );
      await selectProduct(
        page,
        'Search product or brand...',
        'Hyper Acid',
        'Hyper Acid 4 AHA BHA PHA LHA 30 Serum',
      );
      await tapButton(page, 'Organize my shelf');

      // ── Category review ──────────────────────────────────────────────────────
      await tapText(page, "Let's plan your routine");

      // ── Routine summary (auto-sort, conflict fully resolved here) ─────────────
      // Both products are evening-only, so the summary skips morning and proceeds
      // directly to the evening review. buildRoutineSummary → fixProblems resolves
      // the conflict: Hyper Acid stays {0,2,4} = Sun/Tue/Thu, and Vitamin A-mazing
      // is moved to {1,3,5,6} = Mon/Wed/Fri/Sat.
      await expect(page).toHaveTitle(/.*/, { timeout: 30_000 }); // ensure page is stable
      const routineButton3 = page.locator('button, [role="button"]').first();
      await expect(routineButton3).toBeVisible({ timeout: 20_000 });
      await routineButton3.click();

      // ── Evening schedule — no unresolved conflicts (already fixed at summary step)
      // The conflict was fully resolved at the summary stage, so the evening schedule
      // now shows the post-resolution state without warnings.
      await expectTextContaining(page, 'Evening routine');

      // ── Evening order ─────────────────────────────────────────────────────────
      // Proceed through to ordering.
      await tapText(page, "Let's review the layering order");
      await tapText(page, "Let's review your week");

      // ── Week at a glance (onboarding completion) ──────────────────────────────
      // The conflict was fully resolved at the summary step, so no conflicts appear.
      await expectTextContaining(page, 'My Week');
      await expectTextContaining(page, 'No conflicts in evening routine');

      // Tap the celebratory CTA to finish onboarding — it navigates to the daily home.
      const glowButton3 = page.getByText(/let's glow|אפשר להתחיל/i, { exact: false });
      await glowButton3.first().click();

      // ── Daily home — one of the two products in today's evening routine ───────
      // After resolution: Hyper Acid on Sun/Tue/Thu, Vitamin A-mazing on
      // Mon/Wed/Fri/Sat. Exactly one will be active today.
      // Reload /today for a deterministic fresh render of the persisted routine
      // (lazy ListView slivers may otherwise leave off-screen rows unbuilt).
      await bootFlutter(page, '/today');
      await expectTextContaining(page, 'Evening Routine');

      const hyperAcidToday = await page
        .locator(
          'flt-semantics[role="button"][aria-label*="Hyper Acid"]:not([aria-hidden="true"])',
        )
        .first()
        .isVisible()
        .catch(() => false);
      const vitaAToday = await page
        .locator(
          'flt-semantics[role="button"][aria-label*="Vitamin A-mazing"]:not([aria-hidden="true"])',
        )
        .first()
        .isVisible()
        .catch(() => false);
      expect(
        hyperAcidToday || vitaAToday,
        "One of Hyper Acid or Vitamin A-mazing must appear in today's evening routine",
      ).toBe(true);
    },
  );
});
