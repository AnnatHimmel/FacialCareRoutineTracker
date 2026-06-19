import { test, expect } from '@playwright/test';
import {
  bootFlutter,
  button,
  text,
  tapButton,
  tapText,
  fillField,
  expectText,
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
