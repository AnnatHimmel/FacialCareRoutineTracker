import { test, expect } from '@playwright/test';
import {
  bootFlutter,
  seedOnboardedEnglish,
  tapButton,
  tapText,
  tapNavTab,
  button,
  text,
  textContaining,
  selectProduct,
  expectText,
  expectTextContaining,
} from '../helpers/flutter';

/**
 * Skin-log photo regression test.
 *
 * Regression guarded: a bug previously routed the journal "New Entry" FAB to
 * `/skin-log/new` (literal string), so a photo added there landed on a
 * different/garbage entry than the reminder-card photo. The fix makes both
 * paths use today's date (YYYY-MM-DD), so both photos merge onto the same
 * day's entry.
 *
 * Test flow:
 *   1. Create a routine (select one daily product and complete the setup flow)
 *      so the weekly reminder card becomes visible on "My Day".
 *   2. Tap the reminder card's "Take photo" capture box and supply a photo via
 *      the browser file-chooser.
 *   3. Assert the reminder card disappears (photo-within-7-days gate fires).
 *   4. Navigate to "Skin Log", tap "New Entry" FAB, then "Add a photo" on the
 *      entry screen and supply a second photo.
 *   5. Return to Skin Log and assert exactly ONE "Today" entry exists — proving
 *      both photos landed on the same day's record.
 *
 * File upload mechanism: image_picker_for_web creates a hidden
 * `<input type="file" accept="image/*">` and programmatically clicks it.
 * Playwright's `page.waitForEvent('filechooser')` races that click and lets us
 * fulfil the chooser with an in-memory 1×1 PNG without touching the OS picker.
 */

// Minimal valid 1×1 PNG (67 bytes). Generated offline; re-used for both photos.
const PNG_1X1 = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  'base64',
);

/**
 * Select a single daily product and complete the post-selection setup flow
 * (category review → routine summary / schedule / order / week glance) so
 * that at least one product appears in today's routine on "My Day".
 *
 * The product chosen — "Ceramide Ato Concentrate Cream" (prod-011) — has
 * both morning and evening configs with `frequency.type === "daily"`, so it
 * will automatically be scheduled every day in both slots.
 *
 * The flow from the Shelf "Add / remove product" button varies by app state:
 * it may traverse 0-3 intermediate screens before returning to My Day. We use
 * a lenient multi-CTA loop that looks for known forward CTAs and taps the
 * first one visible, up to 12 times, before falling back to the nav tab.
 */
async function setupRoutine(page: import('@playwright/test').Page): Promise<void> {
  // Start from Shelf tab.
  await tapNavTab(page, 'Shelf');
  await expectTextContaining(page, 'All Products');

  // Open product selection.
  await button(page, 'Add / remove product').first().dispatchEvent('click');
  await expectText(page, 'Which products do you have?');

  // Select one daily-frequency product.
  await selectProduct(
    page,
    'Search product or brand...',
    'Ceramide Ato',
    'Ceramide Ato Concentrate Cream',
  );

  // The "Organize my shelf" CTA appears after selecting at least one product.
  await tapText(page, 'Organize my shelf');

  // Walk through however many screens appear between the selection CTA and
  // the home screen. Known forward CTAs in approximate flow order:
  const finishCtAs = [
    "Let's plan your routine",   // category review
    'View My Routine',            // routine ready summary
    "You're all set, let's glow", // week glance
    "Let's review your week",     // order screen finish
    'Continue to Evening',        // morning schedule → evening
    'Continue to Evening Routine',
    'Finish & Save Routine',      // schedule setup save
    'Finish & Start',
    'Save New Order',
    'Continue',
  ];

  // Allow up to 12 CTA taps to reach the home screen.
  for (let step = 0; step < 12; step++) {
    await page.waitForTimeout(600);

    // Check if we're on My Day (routine or empty state visible).
    const morningVisible = await text(page, 'Morning Routine').isVisible().catch(() => false);
    const eveningVisible = await text(page, 'Evening Routine').isVisible().catch(() => false);
    const emptyVisible   = await textContaining(page, 'No products for today').isVisible().catch(() => false);
    if (morningVisible || eveningVisible || emptyVisible) break;

    let tapped = false;
    for (const label of finishCtAs) {
      // Try text locator first (tapText uses clickCenter for non-button widgets).
      const loc = text(page, label).first();
      if (await loc.isVisible().catch(() => false)) {
        await tapText(page, label);
        tapped = true;
        break;
      }
      // Also try role=button (some CTAs are FilledButton/TextButton).
      const btn = button(page, label).first();
      if (await btn.isVisible().catch(() => false)) {
        await btn.dispatchEvent('click');
        tapped = true;
        break;
      }
    }

    if (!tapped) {
      // No known CTA visible — wait another moment for the screen to settle.
      await page.waitForTimeout(1_200);
    }
  }

  // Land on My Day tab.
  await tapNavTab(page, 'My Day');
}

/**
 * Intercept a file-chooser triggered by an image_picker_for_web call and
 * fulfil it with the in-memory PNG. The action that triggers the chooser is
 * executed inside `trigger()`. We race the event with a 5-second timeout
 * before falling back to the input-element approach.
 */
async function supplyPhoto(
  page: import('@playwright/test').Page,
  trigger: () => Promise<void>,
): Promise<void> {
  // image_picker_for_web creates a hidden <input type="file"> and calls
  // .click() on it, which fires the 'filechooser' Playwright event.
  const [chooser] = await Promise.all([
    page.waitForEvent('filechooser', { timeout: 8_000 }),
    trigger(),
  ]);
  await chooser.setFiles([
    { name: 'skin-photo.png', mimeType: 'image/png', buffer: PNG_1X1 },
  ]);
}

test.describe('Skin-log photo regression: both photos land on today\'s entry', () => {
  test.setTimeout(300_000);

  test('reminder-card photo and journal "New Entry" photo merge onto today\'s entry', async ({
    page,
  }) => {
    // ── Boot into an onboarded English session ──────────────────────────────
    await seedOnboardedEnglish(page);
    await bootFlutter(page, '/');

    // Fresh profile shows "Add Products" CTA before any routine exists.
    await expectText(page, 'Add Products');

    // ── Create a routine so the weekly reminder becomes visible ────────────
    await setupRoutine(page);

    // Verify we are on My Day with at least one routine slot visible.
    // Use a single locator that matches either slot header.
    await expect(
      textContaining(page, 'Morning Routine').first(),
    ).toBeVisible({ timeout: 20_000 });

    // ── Verify the weekly reminder card is shown ───────────────────────────
    // The card appears when: reminder enabled (default) && hasRoutine &&
    // no photo within last 7 days && not dismissed today.
    // All conditions are met for a fresh session with a newly added routine.
    await expect(
      textContaining(page, 'Weekly check-in').first(),
    ).toBeVisible({ timeout: 20_000 });

    // ── Upload photo 1 via the reminder card capture box ──────────────────
    // The capture box is a Semantics(button=true, label="Take photo") widget.
    // Flutter may concatenate child text with the semantic label, so the
    // accessible name in the semantics tree can be "Take photo Take photo or
    // from gallery" — use a non-exact prefix match.
    // On web, tapping it calls ImagePicker().pickImage(source: gallery)
    // directly (no bottom sheet), which triggers a file-chooser.
    const captureBoxLocator = page.getByRole('button', { name: 'Take photo', exact: false }).first();
    await captureBoxLocator.waitFor({ state: 'visible', timeout: 20_000 });

    await supplyPhoto(page, async () => {
      await captureBoxLocator.dispatchEvent('click');
    });

    // Wait for the saving spinner to resolve (the card calls upsertSkinLog
    // and then clears the force-show flag; the host re-evaluates and hides
    // the card because a photo now exists for today).
    await expect(
      textContaining(page, 'Weekly check-in').first(),
    ).not.toBeVisible({ timeout: 30_000 });

    // ── Navigate to Skin Log ───────────────────────────────────────────────
    await tapNavTab(page, 'Skin Log');

    // The journal should now show one timeline entry for today, since the
    // reminder-card photo was saved to today's skin-log entry.
    // Flutter merges the date + relative label into one button accessible name
    // (e.g. "June 25th, 2026 Today"), so match the "Today" fragment non-exactly.
    await expect(
      textContaining(page, 'Today').first(),
    ).toBeVisible({ timeout: 20_000 });

    // ── Upload photo 2 via "New Entry" FAB → entry screen ─────────────────
    // The FAB ("New Entry") exposes role=button in the semantics tree.
    await tapButton(page, 'New Entry');

    // We should be on today's skin-log entry screen.
    // The "Add a photo" button is an _AddPhotoButton (GestureDetector, no
    // button role) labelled with skinLogAddPhotoLabel = "Add a photo".
    await expectText(page, 'Add a photo');

    const addPhotoLocator = text(page, 'Add a photo').first();
    await addPhotoLocator.waitFor({ state: 'visible', timeout: 20_000 });

    await supplyPhoto(page, async () => {
      // clickCenter delivers a real pointer tap, which triggers the
      // GestureDetector → _showPhotoSourceSheet → on web, _pickPhoto directly.
      const box = await addPhotoLocator.boundingBox();
      if (box) {
        await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      } else {
        await addPhotoLocator.dispatchEvent('click');
      }
    });

    // Wait a moment for the upsert to complete.
    await page.waitForTimeout(2_000);

    // ── Navigate back to Skin Log and assert exactly ONE "Today" entry ─────
    // The skin-log entry screen is a full-screen route (/skin-log/YYYY-MM-DD)
    // with no bottom nav — use the "Back" button to return to the journal.
    await tapButton(page, 'Back');

    // Allow the journal list to settle after navigation.
    await page.waitForTimeout(1_500);

    // Confirm we are on the Skin Log screen (journal).
    await expect(textContaining(page, 'Progress Tracking').first()).toBeVisible({ timeout: 15_000 });

    // Primary assertion: exactly one journal-entry card whose accessible name
    // contains "Today" (the relative date label). Flutter merges the formatted
    // date + relative label into a single group node accessible name, e.g.
    // "June 26th, 2026 Today". If both photos were incorrectly routed to
    // different entries (e.g. one to today and one to a literal "new" garbage
    // entry from the old /skin-log/new bug) we would see two separate "Today"
    // groups.
    //
    // The timeline entry card is rendered by GlowCard (a Semantics container
    // that Flutter maps to role="group" in the a11y tree).
    const todayEntryCards = page.getByRole('group', { name: /Today/ });
    await expect(todayEntryCards).toHaveCount(1, { timeout: 15_000 });

    // Bonus: verify the single entry has 2 images (both photos in one record).
    // Flutter semantics exposes images as <flt-semantics role="img"> — use
    // Playwright's getByRole rather than CSS img selector.
    const imagesInEntry = todayEntryCards.getByRole('img');
    await expect(imagesInEntry).toHaveCount(2, { timeout: 10_000 });
  });
});
