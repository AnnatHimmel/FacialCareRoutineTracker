import { Page, Locator, expect } from '@playwright/test';

/**
 * Interaction primitives for driving the Flutter **web** build with Playwright.
 *
 * Flutter paints its UI to a canvas, so widgets are not ordinary DOM nodes. We
 * turn on Flutter's accessibility (semantics) tree, which mirrors the widget
 * tree into `<flt-semantics>` elements (inside the `flt-glass-pane` shadow root)
 * that overlay the canvas at each widget's real screen position. Clicking one
 * dispatches a genuine pointer event Flutter handles exactly like a user tap.
 *
 * Observed contract for this app (Flutter 3.44, CanvasKit renderer):
 *   - Plain text  -> `<flt-semantics><span>TEXT</span></flt-semantics>`
 *                    => match with getByText(TEXT).
 *   - Buttons     -> `<flt-semantics role="button">LABEL</flt-semantics>`
 *                    => match with getByRole('button', { name }).
 *     (A few custom CTAs expose only text, no role — fall back to tapText.)
 *   - Text fields -> a real `<input aria-label="...">`
 *                    => match with getByRole('textbox', { name }) / fill().
 * Playwright locators automatically pierce the open shadow root.
 */

export const BOOT_TIMEOUT = 90_000;

/** SharedPreferences keys (see settings_repository_impl.dart). Web stores them
 *  under `flutter.<key>` as JSON-encoded values. */
const PREFS_PREFIX = 'flutter.';

/**
 * Seed SharedPreferences in localStorage *before* the app loads. Used to start a
 * test from an already-onboarded state instead of re-driving the wizard.
 * Must be called before {@link bootFlutter}.
 */
export async function seedPrefs(page: Page, prefs: Record<string, unknown>): Promise<void> {
  await page.addInitScript(
    ([prefix, entries]) => {
      for (const [key, value] of entries as [string, unknown][]) {
        localStorage.setItem(prefix + key, JSON.stringify(value));
      }
    },
    [PREFS_PREFIX, Object.entries(prefs)] as const,
  );
}

/** Convenience: seed a completed-onboarding English session. */
export async function seedOnboardedEnglish(page: Page): Promise<void> {
  await seedPrefs(page, {
    onboarding_completed: true,
    app_language: 'en',
    user_name: 'Test User',
    user_gender: 'female',
  });
}

/**
 * Navigate to `path`, wait for the Flutter engine, and enable the semantics
 * tree. Call at the start of every test.
 */
export async function bootFlutter(page: Page, path = '/'): Promise<void> {
  await page.goto(path, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flutter-view', { timeout: BOOT_TIMEOUT });
  await enableSemantics(page);
}

/**
 * Activate Flutter's hidden "Enable accessibility" placeholder to build the
 * `<flt-semantics>` tree. The placeholder sits outside the viewport, so a
 * pointer click can't reach it — we dispatch a DOM `click()` directly. Safe to
 * call repeatedly.
 */
export async function enableSemantics(page: Page): Promise<void> {
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder') as HTMLElement | null;
    ph?.click();
  });
  // Wait until at least one real semantics node materialises.
  await page
    .waitForFunction(
      () => {
        const seen = (root: Document | ShadowRoot): boolean => {
          if (root.querySelector('flt-semantics[role], flt-semantics span')) return true;
          for (const el of Array.from(root.querySelectorAll('*'))) {
            const sr = (el as Element & { shadowRoot?: ShadowRoot }).shadowRoot;
            if (sr && seen(sr)) return true;
          }
          return false;
        };
        return seen(document);
      },
      { timeout: 20_000 },
    )
    .catch(() => {
      /* Decorative-only screens are acceptable. */
    });
}

// ── Locators ───────────────────────────────────────────────────────────────

/** A button (role=button) by its exact accessible name. */
export function button(page: Page, name: string): Locator {
  return page.getByRole('button', { name, exact: true });
}

/** A text node by exact text (matches the rendered <span>). */
export function text(page: Page, value: string): Locator {
  return page.getByText(value, { exact: true });
}

/** A text node that *contains* the given fragment (dynamic labels). */
export function textContaining(page: Page, fragment: string): Locator {
  return page.getByText(fragment, { exact: false });
}

/** A text input by its accessible name (the field's hint/label). */
export function textbox(page: Page, name: string): Locator {
  return page.getByRole('textbox', { name });
}

/**
 * A bottom-navigation tab by label. Each tab is the only semantics node that
 * carries an `aria-current` attribute *and* the label text, which uniquely
 * distinguishes it from other widgets that happen to contain the same word.
 */
export function navTab(page: Page, label: string): Locator {
  return page.locator('flt-semantics[aria-current]').filter({ hasText: label });
}

// ── Actions ──────────────────────────────────────────────────────────────────

/** Tap a role=button widget by accessible name. */
export async function tapButton(page: Page, name: string): Promise<void> {
  const target = button(page, name).first();
  await target.waitFor({ state: 'visible', timeout: 20_000 });
  await target.scrollIntoViewIfNeeded().catch(() => {});
  await target.click();
}

/**
 * Tap a widget by its visible text. Use for custom CTAs that don't expose a
 * button role (e.g. the onboarding "Continue" / "Finish & Start" buttons).
 *
 * The inner <span> these resolve to has a degenerate 0×0 layout box, so a
 * normal locator.click() targets a zero-area point and Flutter's gesture
 * recognizer misses it. Instead we read Playwright's boundingBox() (which
 * resolves the flt-semantics transform to the real on-screen rect), wait for
 * it to settle — onboarding screens slide in, so the box can briefly report an
 * off-screen position — then deliver a real pointer click to its centre. DPR
 * is 1 and the Flutter canvas is aligned to the viewport origin, so the box
 * coordinates map directly to mouse coordinates with no conversion.
 */
export async function tapText(page: Page, value: string): Promise<void> {
  const target = text(page, value).first();
  await target.waitFor({ state: 'visible', timeout: 20_000 });
  await clickCenter(page, target);
}

/**
 * Deliver a real pointer click to the settled centre of `target`. This is the
 * one tap mechanism observed to reliably reach Flutter's gesture recognizer
 * (a plain locator.click() targets the degenerate 0×0 span; force/dispatch
 * variants are intercepted or ignored). DPR is 1 and the canvas is aligned to
 * the viewport origin, so box coordinates map directly to mouse coordinates.
 */
async function clickCenter(page: Page, target: Locator): Promise<void> {
  const box = await waitForStableBox(target);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
}

/**
 * Poll an element's bounding box until it is non-null, on-screen, and stable
 * across two consecutive reads (so a still-animating screen doesn't yield a
 * transient off-screen position). Returns the settled box.
 */
async function waitForStableBox(
  target: Locator,
  timeout = 20_000,
): Promise<{ x: number; y: number; width: number; height: number }> {
  const deadline = Date.now() + timeout;
  const vp = target.page().viewportSize();
  let prev: { x: number; y: number; width: number; height: number } | null = null;

  while (Date.now() < deadline) {
    const box = await target.boundingBox();
    const onScreen =
      box !== null &&
      box.width > 0 &&
      box.height > 0 &&
      (!vp || (box.y >= 0 && box.y + box.height <= vp.height));
    if (box && onScreen && prev &&
        Math.abs(box.x - prev.x) < 1 && Math.abs(box.y - prev.y) < 1) {
      return box;
    }
    prev = box;
    await target.page().waitForTimeout(100);
  }
  throw new Error(`waitForStableBox: box never settled on-screen`);
}

/**
 * Tap a bottom-navigation tab by label.
 *
 * In the main app the semantics overlay is offset horizontally relative to the
 * viewport, so the tab's hit point lands outside the viewport and a real
 * pointer click is rejected. Flutter's semantics buttons also respond to a
 * synthetic DOM `click`, which has no coordinate requirement — so we dispatch
 * that instead (the same mechanism {@link enableSemantics} relies on).
 */
export async function tapNavTab(page: Page, label: string): Promise<void> {
  const target = navTab(page, label).first();
  await target.waitFor({ state: 'visible', timeout: 20_000 });
  await target.dispatchEvent('click');
}

/**
 * Type `value` into the text field with accessible name `name`.
 *
 * A real pointer click (clickCenter) — not focus() — is needed to establish
 * Flutter's text-editing connection; key events then reach its controller.
 * fill() alone does not work: it sets the DOM input value without notifying
 * Flutter. We engage, clear, type at the browser level, and retry until the
 * DOM input reflects `value`.
 */
export async function fillField(page: Page, name: string, value: string): Promise<void> {
  const field = textbox(page, name).first();
  await field.waitFor({ state: 'visible', timeout: 20_000 });

  for (let attempt = 0; attempt < 5; attempt++) {
    await engageAndType(page, field, value);
    if ((await field.inputValue()) === value) return;
    await page.waitForTimeout(200);
  }
  throw new Error(
    `fillField: "${name}" never reached "${value}" (last: "${await field.inputValue()}")`,
  );
}

/** Engage a text field via a real pointer tap, clear it, and type `value`. */
async function engageAndType(page: Page, field: Locator, value: string): Promise<void> {
  await clickCenter(page, field);
  await page.keyboard.press('Control+a');
  await page.keyboard.press('Delete');
  await page.keyboard.type(value);
}

/**
 * Search for and select a product on the onboarding product-selection screen.
 *
 * The product row exposes TWO buttons in the Flutter semantics tree:
 *   1. `button "<product name>"` — tapping this opens the product-detail sheet
 *   2. `button` (no accessible name) — the circular toggle that selects/deselects
 *
 * We locate the toggle by:
 *   1. Searching and waiting for the named product button to appear.
 *   2. Getting its bounding-box y-coordinate (the row's vertical centre).
 *   3. Finding all unlabeled buttons on the page and clicking the one whose
 *      y-centre is within 20px of the named button — that is the row's toggle.
 *
 * A synthetic `dispatchEvent('click')` is used (as with tapNavTab / tapDayChip)
 * because the toggle is a role=button that responds to synthetic DOM clicks
 * without needing coordinate accuracy.
 *
 * Success signal: the search field is still visible after the tap (a detail
 * sheet opening would cover it). If the detail sheet opens anyway, we dismiss
 * it with Escape and retry.
 */
export async function selectProduct(
  page: Page,
  searchHint: string,
  search: string,
  exact: string,
): Promise<void> {
  const field = textbox(page, searchHint).first();
  await field.waitFor({ state: 'visible', timeout: 20_000 });

  // The named product button (opens detail sheet — do NOT tap this).
  const productButton = page.getByRole('button', { name: exact, exact: false }).first();

  for (let attempt = 0; attempt < 6; attempt++) {
    // Dismiss any modal covering the search field before each attempt.
    if (!(await field.isVisible())) {
      await dismissDetailSheetIfOpen(page);
      await field.waitFor({ state: 'visible', timeout: 10_000 });
    }

    await engageAndType(page, field, search);

    // Wait for the named product button to appear in filtered results.
    try {
      await productButton.waitFor({ state: 'visible', timeout: 5_000 });
    } catch {
      continue; // Flutter filter didn't fire — re-engage and retry.
    }

    // Get the row's vertical centre from the named product button.
    const productBox = await productButton.boundingBox();
    if (!productBox) continue;
    const rowCenterY = productBox.y + productBox.height / 2;

    // Find the toggle: the small (24×24) button in the same row as the named
    // product button. In the semantics tree, each product row is a group with
    // two buttons: a large named button (opens detail) and a small unnamed
    // toggle (selects/deselects). We target the toggle via the named product
    // button's ancestor group, then select the small-sized sibling button.
    //
    // dispatchEvent('click') is used because the toggle is outside the viewport
    // in RTL mode (x ≈ 744 on a 412 px viewport); synthetic DOM clicks don't
    // require coordinate accuracy (same pattern as tapNavTab / tapDayChip).
    //
    // The toggle is the following-sibling button of the named button inside the
    // same flt-semantics[role="group"] container. XPath identifies it directly.
    const toggleLocator = productButton.locator(
      'xpath=ancestor::flt-semantics[@role="group"]//flt-semantics[@role="button"][not(normalize-space())]',
    );
    const toggleAlt = productButton.locator(
      'xpath=../following-sibling::flt-semantics[@role="button"]',
    );

    // Attempt to dispatch click on the toggle found via ancestor group.
    let tapped = false;
    const tCount = await toggleLocator.count().catch(() => 0);
    if (tCount > 0) {
      await toggleLocator.first().dispatchEvent('click');
      tapped = true;
    } else {
      // Fallback: sibling following the named button in the DOM.
      const aCount = await toggleAlt.count().catch(() => 0);
      if (aCount > 0) {
        await toggleAlt.first().dispatchEvent('click');
        tapped = true;
      }
    }
    if (!tapped) continue;

    // Verify no detail sheet opened (search field must still be visible).
    await page.waitForTimeout(300);
    if (await field.isVisible()) {
      return; // Toggle tap succeeded — search field is uncovered.
    }

    // Detail sheet opened — dismiss and retry.
    await dismissDetailSheetIfOpen(page);
  }
  throw new Error(`selectProduct: could not select "${exact}" after searching "${search}"`);
}

/**
 * Dismiss an open product-detail bottom sheet.
 * Flutter bottom sheets respond to the Escape key.
 */
async function dismissDetailSheetIfOpen(page: Page): Promise<void> {
  await page.keyboard.press('Escape');
  await page.waitForTimeout(400);
}

// ── Schedule (days-view) scanning ────────────────────────────────────────────

/** Where a product sits in a days-view schedule list, relative to the
 *  "לא בשימוש" (not-used) section header for the selected day. */
export type DayPlacement = 'scheduled' | 'notUsed' | 'absent';

/** A point inside the scrollable schedule list, away from the day strip (top)
 *  and the bottom CTA, so wheel events scroll the list rather than a control. */
const LIST_SCROLL_POINT = { x: 206, y: 480 };

const _DAY_FULL: Record<string, string> = {
  Sun: 'Sunday', Mon: 'Monday', Tue: 'Tuesday', Wed: 'Wednesday',
  Thu: 'Thursday', Fri: 'Friday', Sat: 'Saturday',
};

/**
 * Tap a day chip in the schedule day-strip by its weekday abbreviation, and
 * confirm the day actually switched.
 *
 * Each chip is exposed as a single button whose accessible name merges the
 * abbreviation and the product count (e.g. "Sun 12"), so it can't be matched by
 * exact text — we match the button whose name starts with the abbreviation.
 * The chip is a role=button, so (like tapNavTab) a synthetic DOM click triggers
 * Flutter's tap without depending on coordinates. We then wait for the day's
 * full name (which the body's summary/section headers render) to appear, and
 * retry the click if the switch didn't take. The strip must be at the top
 * (see scrollScheduleToTop).
 */
export async function tapDayChip(page: Page, abbrev: string): Promise<void> {
  const chip = page.getByRole('button', { name: new RegExp(`^${abbrev}\\b`) }).first();
  await chip.waitFor({ state: 'visible', timeout: 20_000 });
  const dayName = textContaining(page, _DAY_FULL[abbrev]).first();

  for (let attempt = 0; attempt < 4; attempt++) {
    await chip.dispatchEvent('click');
    try {
      await dayName.waitFor({ state: 'visible', timeout: 4_000 });
      return;
    } catch {
      /* switch didn't take — retry */
    }
  }
  throw new Error(`tapDayChip: day never switched to "${abbrev}"`);
}

/** Scroll the active schedule list back to the top. */
export async function scrollScheduleToTop(page: Page): Promise<void> {
  await page.mouse.move(LIST_SCROLL_POINT.x, LIST_SCROLL_POINT.y);
  for (let i = 0; i < 14; i++) {
    await page.mouse.wheel(0, -600);
    await page.waitForTimeout(60);
  }
  await page.waitForTimeout(150);
}

/**
 * Determine, for the currently selected day in days-view, whether each product
 * fragment is in the scheduled section or the "not used" (לא בשימוש) section.
 *
 * Flutter web only renders on-screen list items into the semantics tree, so a
 * product and the separator are rarely visible at once. We scroll the list from
 * top to bottom and record the first scroll step at which the separator and each
 * product become visible: a product seen *before* the separator is scheduled;
 * one seen at/after it is not-used. Ties (same step) fall back to a y compare.
 *
 * A day with no not-used section (separator never appears) means every product
 * present is scheduled. A fragment never seen at all is reported 'absent'.
 */
export async function scanDaySchedule(
  page: Page,
  fragments: string[],
): Promise<Record<string, DayPlacement>> {
  await scrollScheduleToTop(page);

  const separator = page.getByText(/לא בשימוש/, { exact: false }).first();
  const locators = fragments.map((f) => ({ f, loc: textContaining(page, f).first() }));

  let sepStep = -1;
  let sepY: number | null = null;
  const seen: Record<string, { step: number; y: number }> = {};

  const MAX_STEPS = 30;
  for (let step = 0; step < MAX_STEPS; step++) {
    if (sepStep < 0 && (await separator.isVisible())) {
      sepStep = step;
      sepY = (await separator.boundingBox())?.y ?? 0;
    }
    for (const { f, loc } of locators) {
      if (seen[f] === undefined && (await loc.isVisible())) {
        seen[f] = { step, y: (await loc.boundingBox())?.y ?? 0 };
      }
    }
    const allFound = locators.every(({ f }) => seen[f] !== undefined);
    if (allFound && sepStep >= 0) break;

    // Scroll down a step; detect the bottom by the separator no longer moving.
    const beforeY = sepStep >= 0 ? (await separator.boundingBox())?.y ?? null : null;
    await page.mouse.move(LIST_SCROLL_POINT.x, LIST_SCROLL_POINT.y);
    await page.mouse.wheel(0, 400);
    await page.waitForTimeout(150);
    if (beforeY !== null) {
      const afterY = (await separator.boundingBox())?.y ?? null;
      if (afterY !== null && Math.abs(afterY - beforeY) < 1) break; // at bottom
    }
  }

  const result: Record<string, DayPlacement> = {};
  for (const { f } of locators) {
    const r = seen[f];
    if (!r) {
      result[f] = 'absent';
    } else if (sepStep < 0) {
      result[f] = 'scheduled'; // no not-used section ⇒ all present are scheduled
    } else if (r.step !== sepStep) {
      result[f] = r.step < sepStep ? 'scheduled' : 'notUsed';
    } else {
      result[f] = (sepY !== null && r.y < sepY) ? 'scheduled' : 'notUsed';
    }
  }
  return result;
}

// ── Assertions ─────────────────────────────────────────────────────────────

/** Assert a widget with the exact text is visible. */
export async function expectText(page: Page, value: string): Promise<void> {
  await expect(text(page, value).first()).toBeVisible({ timeout: 20_000 });
}

/** Assert some widget's text contains the fragment. */
export async function expectTextContaining(page: Page, fragment: string): Promise<void> {
  await expect(textContaining(page, fragment).first()).toBeVisible({ timeout: 20_000 });
}
