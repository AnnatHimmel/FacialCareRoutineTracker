import { test, expect } from '@playwright/test';
import { bootFlutter, button } from '../helpers/flutter';

/**
 * App boot + first screen. Confirms the Flutter web app loads, the semantics
 * tree comes up, and the language picker renders both options — which also
 * validates Hebrew (RTL) and Latin text rendering side by side.
 */
test.describe('App boot', () => {
  test('loads and shows the bilingual language picker', async ({ page }) => {
    await bootFlutter(page, '/');

    // Step 0 of onboarding: hard-coded language buttons (shown before any l10n).
    await expect(button(page, 'English')).toBeVisible();
    await expect(button(page, 'עברית')).toBeVisible();
  });

  test('the document is configured for RTL', async ({ page }) => {
    await bootFlutter(page, '/');
    // index.html declares the app as a right-to-left Hebrew document.
    await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
    await expect(page.locator('html')).toHaveAttribute('lang', 'he');
  });
});
