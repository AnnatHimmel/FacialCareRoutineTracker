import { test, expect } from '@playwright/test';
import {
  bootFlutter,
  seedOnboardedEnglish,
  tapButton,
  tapText,
  tapNavTab,
  navTab,
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
 * The flow from the Shelf "Add / remove product" button runs the returning-user
 * wizard (ProductsWizardScreen, lib/features/setup/products_wizard_screen.dart):
 *
 *   product selection → routine-ready summary → AM schedule → AM order →
 *   PM schedule → PM order → week-at-a-glance → My Day
 *
 * Each screen carries a single forward CTA whose label comes straight from
 * app_en.arb; the labels below MUST stay in sync with that file. We tap the
 * first visible forward CTA each iteration until the bottom-nav "My Day" tab
 * re-appears (i.e. we are back in the app shell).
 *
 * The wizard's terminal week-glance is the non-onboarding variant: it shows a
 * home/back button in the app bar rather than a "let's glow" CTA, so we detect
 * that screen by its title and tap the app-bar "Back" button (which routes to
 * /today because the week-glance route can't pop).
 */
async function setupRoutine(page: import('@playwright/test').Page): Promise<void> {
  // Start from Shelf tab.
  await tapNavTab(page, 'Shelf');
  await expectTextContaining(page, 'All Products');

  // Open product selection.
  await button(page, 'Add / remove product').first().dispatchEvent('click');
  await expectText(page, 'Which products do you have?');

  // Select one daily-frequency product (scheduled morning AND evening, daily).
  await selectProduct(
    page,
    'Search product or brand...',
    'Ceramide Ato',
    'Ceramide Ato Concentrate Cream',
  );

  // The "Organize my shelf" CTA appears after selecting at least one product.
  await tapText(page, 'Organize my shelf');

  // Forward CTAs across the wizard, in flow order. These are the exact
  // app_en.arb strings; if a screen's CTA changes, update it here.
  const forwardCtAs = [
    "Let's plan your routine",                            // category review (onboarding only)
    "Let's start with your Morning routine",              // routine-ready (AM-first)
    "Let's start with your Evening routine",              // routine-ready (PM-first)
    'View My Routine',                                    // routine-ready (no-slot fallback)
    "Let's review the layering order",                    // schedule setup → order (AM & PM)
    "Looks good, let's continue to your evening routine", // AM order → PM schedule
    "Let's review your week",                             // PM order → week glance
    "You're all set, let's glow",                         // week glance (onboarding variant)
  ];

  // Walk forward until the "My Day" bottom-nav tab exists again.
  for (let step = 0; step < 20; step++) {
    if (await navTab(page, 'My Day').first().isVisible().catch(() => false)) {
      break;
    }

    // Wizard week-glance terminal: no CTA, just an app-bar home/back button.
    if (
      await textContaining(page, "My Week's Routine")
        .first()
        .isVisible()
        .catch(() => false)
    ) {
      await button(page, 'Back').first().dispatchEvent('click').catch(() => {});
      await page.waitForTimeout(700);
      continue;
    }

    let tapped = false;
    for (const label of forwardCtAs) {
      // role=button first (most wizard CTAs are PrimaryButton => button role).
      const btn = button(page, label).first();
      if (await btn.isVisible().catch(() => false)) {
        await btn.dispatchEvent('click');
        tapped = true;
        break;
      }
      // Fall back to a plain text tap for CTAs that expose no button role.
      const txt = text(page, label).first();
      if (await txt.isVisible().catch(() => false)) {
        await tapText(page, label);
        tapped = true;
        break;
      }
    }

    // Settle: shorter pause after a tap, longer while a screen is still loading
    // (e.g. the routine-ready summary builds asynchronously).
    await page.waitForTimeout(tapped ? 600 : 1_000);
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
  // .click() on it, which fires the 'filechooser' Playwright event. The tap can
  // occasionally miss Flutter's gesture recognizer (semantics still settling),
  // so re-trigger up to 3 times before giving up.
  let lastErr: unknown;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const [chooser] = await Promise.all([
        page.waitForEvent('filechooser', { timeout: 10_000 }),
        trigger(),
      ]);
      await chooser.setFiles([
        { name: 'skin-photo.png', mimeType: 'image/png', buffer: PNG_1X1 },
      ]);
      return;
    } catch (err) {
      lastErr = err;
      await page.waitForTimeout(500);
    }
  }
  throw lastErr;
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
