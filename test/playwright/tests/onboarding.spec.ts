import { test, expect } from '@playwright/test';
import {
  bootFlutter,
  button,
  text,
  tapButton,
  tapText,
  fillField,
  selectProduct,
  expectText,
  expectTextContaining,
} from '../helpers/flutter';

/**
 * The onboarding wizard, driven through the web UI:
 *   Step 0 language → Step 1 welcome → Step 2 personal info → Step 3 products.
 */
test.describe('Onboarding', () => {
  test('English path reaches the product selection step', async ({ page }) => {
    await bootFlutter(page, '/');

    // Step 0 → choose English.
    await tapButton(page, 'English');

    // Step 1 — welcome screen.
    await expectText(page, 'The Glow Protocol');
    await tapButton(page, "Let's Begin");

    // Step 2 — personal info.
    await expectText(page, 'Tell us about you');

    // Continue is gated until both name and gender are provided.
    await expect(button(page, 'Female')).toBeVisible();
    await fillField(page, 'Your name', 'Dana');
    await tapButton(page, 'Female');

    // Step 3 — product setup begins (V3 product selection screen).
    await tapText(page, 'Continue');
    await expectText(page, 'Which products do you have?');
  });

  test('Hebrew path shows a localized welcome screen', async ({ page }) => {
    await bootFlutter(page, '/');

    await tapButton(page, 'עברית');

    // The brand name is constant, but the CTA/body is now Hebrew. The brand
    // title is always present on the welcome step regardless of locale.
    await expectText(page, 'The Glow Protocol');
    // Hebrew "Let's Begin" (onboardingStartNeutral, he locale).
    await expect(button(page, 'נתחיל?')).toBeVisible();
  });

  test('Continue stays disabled until name and gender are set', async ({ page }) => {
    await bootFlutter(page, '/');
    await tapButton(page, 'English');
    await tapButton(page, "Let's Begin");
    await expectText(page, 'Tell us about you');

    // With nothing entered, the Continue CTA is disabled (wrapped in an
    // IgnorePointer), so a tap is a no-op. Attempt it and confirm we have NOT
    // advanced to the product step.
    await text(page, 'Continue')
      .first()
      .click({ force: true, timeout: 3000 })
      .catch(() => {
        /* disabled control is not actionable — expected */
      });
    await expect(page.getByText('Which products do you have?', { exact: true })).toHaveCount(0);
    // Still on the personal-info step.
    await expectText(page, 'Tell us about you');
  });
});

/**
 * Full end-to-end walk of the entire onboarding wizard, screen by screen.
 *
 * Covers every stage of the reordered flow:
 *   0  Language picker        (both options shown → English)
 *   1  Welcome                (brand, tagline, "Let's Begin")
 *   2  Personal info          (name + gender → Continue)
 *   3a Product selection      (bi-slot products → "Organize my shelf")
 *   3b Category review        ("Let's plan your routine")
 *   3c Routine summary        (auto-sort result; "Let's start with your Morning routine")
 *   3d Morning schedule       ("Let's review the layering order")
 *   3e Morning order          ("Looks good, let's continue to your evening routine")
 *   3f Evening schedule       (reached directly — no transition screen)
 *   3g Evening order          ("Let's review your week")
 *   3h Week at a glance        (onboarding mode; "You're all set, let's glow")
 *   →  Daily home             (routine rendered; state persists across reload)
 *
 * The three selected products (Generic Cleansing Gel, Niacinamide 20 Serum,
 * Dynasty Cream) are all bi-slot, so both the morning and evening sub-flows
 * run — exercising amSchedule → amOrder → pmSchedule → pmOrder in full.
 */
test.describe('Onboarding — full wizard walkthrough', () => {
  const PRODUCTS = [
    { search: 'Cleansing Gel',  exact: 'Generic Cleansing Gel' },
    { search: 'Niacinamide 20', exact: 'Niacinamide 20 Serum' },
    { search: 'Dynasty',        exact: 'Dynasty Cream' },
  ];

  test('walks every screen from language picker to the daily home', async ({ page }) => {
    test.setTimeout(300_000);

    // ── Step 0: Language picker ───────────────────────────────────────────────
    await bootFlutter(page, '/');
    await expect(button(page, 'עברית')).toBeVisible();
    await expect(button(page, 'English')).toBeVisible();
    await tapButton(page, 'English');

    // ── Step 1: Welcome ───────────────────────────────────────────────────────
    await expectText(page, 'The Glow Protocol');
    await expectTextContaining(page, 'Your routine, your pace');
    await tapButton(page, "Let's Begin");

    // ── Step 2: Personal info ─────────────────────────────────────────────────
    await expectText(page, 'Tell us about you');
    await expect(button(page, 'Female')).toBeVisible();
    await fillField(page, 'Your name', 'Dana');
    await tapButton(page, 'Female');
    await tapText(page, 'Continue');

    // ── Step 3a: Product selection ────────────────────────────────────────────
    await expectText(page, 'Which products do you have?');
    for (const { search, exact } of PRODUCTS) {
      await selectProduct(page, 'Search product or brand...', search, exact);
    }
    await tapButton(page, 'Organize my shelf');

    // ── Step 3b: Category review ──────────────────────────────────────────────
    await tapText(page, "Let's plan your routine");

    // ── Step 3c: Routine summary (auto-sort, NEW position) ────────────────────
    // The summary now appears right after category review, framing the per-slot
    // review that follows. Its CTA names the first slot to review (Morning).
    await expectTextContaining(page, 'Your Routine Is Ready');
    await expectText(page, "Let's start with your Morning routine");
    await tapText(page, "Let's start with your Morning routine");

    // ── Step 3d: Morning schedule ─────────────────────────────────────────────
    await expectText(page, 'Morning routine');
    await tapText(page, "Let's review the layering order");

    // ── Step 3e: Morning order ────────────────────────────────────────────────
    await expectTextContaining(page, "Looks good, let's continue to your evening routine");
    await tapText(page, "Looks good, let's continue to your evening routine");

    // ── Step 3f: Evening schedule (direct — no transition interstitial) ───────
    await expectText(page, 'Evening routine');
    await tapText(page, "Let's review the layering order");

    // ── Step 3g: Evening order ────────────────────────────────────────────────
    await expectTextContaining(page, "Let's review your week");
    await tapText(page, "Let's review your week");

    // ── Step 3h: Week at a glance (onboarding completion) ─────────────────────
    await expectTextContaining(page, 'My Week');
    await expectText(page, "You're all set, let's glow");
    await tapText(page, "You're all set, let's glow");

    // ── Daily home — onboarding complete, routine rendered ────────────────────
    await expectTextContaining(page, 'Morning Routine');
    await expectTextContaining(page, 'Evening Routine');

    // ── Persistence — a fresh load stays on the app, not the wizard ───────────
    // onboarding_completed is written, so a cold reload routes to the home, not
    // back to the language picker / product step.
    await bootFlutter(page, '/today');
    await expectTextContaining(page, 'Morning Routine');
    await expect(page.getByText('Which products do you have?', { exact: true })).toHaveCount(0);
    await expect(button(page, 'English')).toHaveCount(0);
  });
});
