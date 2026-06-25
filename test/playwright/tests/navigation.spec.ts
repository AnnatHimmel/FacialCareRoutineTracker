import { test, expect } from '@playwright/test';
import {
  bootFlutter,
  seedOnboardedEnglish,
  navTab,
  tapNavTab,
  button,
  text,
  selectProduct,
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
    await expectTextContaining(page, 'Language');

    // Back to My Day
    await tapNavTab(page, 'My Day');
    await expectText(page, 'Add Products');
  });

  test('settings exposes the data and info entry points', async ({ page }) => {
    await tapNavTab(page, 'Settings');
    await expectTextContaining(page, 'Export / Import'); // data
    await expectTextContaining(page, 'About'); // info
    await expectTextContaining(page, 'Language');
  });

  test('Shelf "add / remove product" opens selection; back with no changes returns directly', async ({
    page,
  }) => {
    await tapNavTab(page, 'Shelf');
    await expectTextContaining(page, 'All Products');

    // The non-functional "By category" sort control was removed from the header.
    await expect(text(page, 'By category')).toHaveCount(0);

    // The FAB now reads "Add / remove product" (was "Add product").
    const fab = button(page, 'Add / remove product').first();
    await expect(fab).toBeVisible();
    await fab.dispatchEvent('click');

    // Lands on the guided product-selection screen, which now has a back button.
    await expectText(page, 'Which products do you have?');
    const back = button(page, 'Back').first();
    await expect(back).toBeVisible();

    // No products were toggled → back returns straight to the Shelf, no dialog.
    await back.dispatchEvent('click');
    await expectTextContaining(page, 'All Products');
  });

  test('going back after toggling a product warns about unsaved changes', async ({ page }) => {
    await tapNavTab(page, 'Shelf');
    await expectTextContaining(page, 'All Products');

    await button(page, 'Add / remove product').first().dispatchEvent('click');
    await expectText(page, 'Which products do you have?');

    // Toggle one product on — this marks the selection flow dirty.
    await selectProduct(
      page,
      'Search product or brand...',
      'Argireline',
      'Argireline Solution 10%',
    );

    // Back now prompts to confirm leaving without finishing the flow.
    await button(page, 'Back').first().dispatchEvent('click');
    await expectText(page, 'Unsaved Changes');

    // Cancel keeps us on the selection screen.
    await button(page, 'Cancel').first().dispatchEvent('click');
    await expectText(page, 'Which products do you have?');

    // Going back again and confirming returns to the Shelf.
    await button(page, 'Back').first().dispatchEvent('click');
    await expectText(page, 'Unsaved Changes');
    await button(page, 'Go back').first().dispatchEvent('click');
    await expectTextContaining(page, 'All Products');
  });
});
