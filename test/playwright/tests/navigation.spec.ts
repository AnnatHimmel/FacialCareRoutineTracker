import { test, expect } from '@playwright/test';
import {
  bootFlutter,
  seedOnboardedEnglish,
  navTab,
  tapNavTab,
  expectText,
  expectTextContaining,
} from '../helpers/flutter';

/**
 * Main app shell. Starts from an already-onboarded English session (seeded in
 * SharedPreferences) so the bottom navigation is present, then exercises the
 * four primary destinations.
 *
 * Nav tabs are matched/clicked via the {@link navTab}/{@link tapNavTab} helpers
 * because they expose a doubled accessible name and sit outside the viewport in
 * the semantics overlay (see helper docs).
 */
test.describe('Main navigation', () => {
  test.beforeEach(async ({ page }) => {
    await seedOnboardedEnglish(page);
    await bootFlutter(page, '/');
    // App auto-routes to /today after onboarding.
    await expectText(page, 'Add Products');
  });

  test('lands on the My Day home screen with the bottom nav', async ({ page }) => {
    await expect(navTab(page, 'My Day')).toBeVisible();
    await expect(navTab(page, 'Shelf')).toBeVisible();
    await expect(navTab(page, 'Skin Log')).toBeVisible();
    await expect(navTab(page, 'Settings')).toBeVisible();
    // Empty-routine state for a fresh profile.
    await expectText(page, 'No products for today');
  });

  test('navigates between the four tabs', async ({ page }) => {
    // Shelf (collection)
    await tapNavTab(page, 'Shelf');
    await expectTextContaining(page, 'All Products');

    // Settings
    await tapNavTab(page, 'Settings');
    await expectTextContaining(page, 'Product Order');

    // Back to My Day
    await tapNavTab(page, 'My Day');
    await expectText(page, 'Add Products');
  });

  test('settings exposes the routine, data and info entry points', async ({ page }) => {
    await tapNavTab(page, 'Settings');
    await expectTextContaining(page, 'Product Order'); // routine
    await expectTextContaining(page, 'Export / Import'); // data
    await expectTextContaining(page, 'About'); // info
    await expectTextContaining(page, 'Language');
  });
});
