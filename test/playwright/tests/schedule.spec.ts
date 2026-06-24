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
    await tapText(page, 'Continue to day selection');

    // ── Step 3c: Morning schedule ─────────────────────────────────────────────
    await expectText(page, 'Morning routine');

    // Rule 1 — Argireline is conflict-resolved to evening-only while Vita C is
    // present, so on the morning schedule it must appear in the "not used"
    // (לא בשימוש) section, not scheduled for any morning day.
    expect(
      (await scanDaySchedule(page, ['Argireline']))['Argireline'],
      'Argireline should be in the "not used" section on morning',
    ).toBe('notUsed');

    await scrollScheduleToTop(page);
    await tapText(page, 'Continue to application order');

    // ── Step 3d: Morning order ────────────────────────────────────────────────
    // Argireline must not appear in the drag list (schedule was cleared to empty,
    // so order_customization_screen excludes it via the isExcluded guard).
    await expectTextContaining(page, 'Looks good, continue to evening routine');
    await expect(text(page, 'Argireline Solution 10%')).not.toBeVisible();
    await tapText(page, 'Looks good, continue to evening routine');

    // ── Step 3e: Evening transition ───────────────────────────────────────────
    await expectText(page, 'Now for the evening routine');
    await tapText(page, 'Continue');

    // ── Step 3f: Evening schedule — compliance checks ─────────────────────────
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
    await tapText(page, 'Continue to application order');
    await tapText(page, 'Finish and show my routine');

    // ── Step 3h: Routine-ready summary ────────────────────────────────────────
    // The auto-sorter now presents a summary of its decisions before handing
    // off to the main app. Its CTA navigates to /week-glance.
    await expectTextContaining(page, 'Your Routine Is Ready');
    await tapText(page, 'View My Routine');

    // Confirm onboarding completed — the weekly glance screen is visible.
    await expectTextContaining(page, 'My Week');
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
    await tapText(page, 'Continue to day selection');

    // ── Morning schedule ─────────────────────────────────────────────────────
    await expectText(page, 'Morning routine');

    // Conflict resolution should have cleared Argireline from every morning day.
    const morningPlacement = await scanDaySchedule(page, ['Argireline']);
    expect(
      morningPlacement['Argireline'],
      'Argireline must be in the "not used" section on the morning schedule after conflict resolution with Vita C',
    ).toBe('notUsed');

    await scrollScheduleToTop(page);
    await tapText(page, 'Continue to application order');

    // ── Morning order ────────────────────────────────────────────────────────
    // Argireline has been removed from morning, so it must not appear in the
    // morning drag-to-order list.
    await expectTextContaining(page, 'Looks good, continue to evening routine');
    await expect(text(page, 'Argireline Solution 10%')).not.toBeVisible();
    await tapText(page, 'Looks good, continue to evening routine');

    // ── Evening transition ───────────────────────────────────────────────────
    await expectText(page, 'Now for the evening routine');
    await tapText(page, 'Continue');

    // ── Evening schedule ─────────────────────────────────────────────────────
    await expectText(page, 'Evening routine');

    // Argireline is daily in the evening — it must be scheduled on the default
    // day shown when the screen first opens.
    const eveningPlacement = await scanDaySchedule(page, ['Argireline']);
    expect(
      eveningPlacement['Argireline'],
      'Argireline must be scheduled in the evening after being conflict-resolved off morning',
    ).toBe('scheduled');

    await scrollScheduleToTop(page);
    await tapText(page, 'Continue to application order');

    // ── Evening order ─────────────────────────────────────────────────────────
    await tapText(page, 'Finish and show my routine');

    // ── Routine-ready summary ─────────────────────────────────────────────────
    await expectTextContaining(page, 'Your Routine Is Ready');
    await tapText(page, 'View My Routine');

    // ── Weekly glance screen ──────────────────────────────────────────────────
    // After onboarding the app routes to /week-glance.
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

    // ── My Day (daily home screen) ────────────────────────────────────────────
    // /week-glance is a standalone route (no bottom nav). Navigate directly to
    // /today — the shell route — which preserves the IndexedDB state written
    // during onboarding.
    await bootFlutter(page, '/today');

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
