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
 */
export async function tapText(page: Page, value: string): Promise<void> {
  const target = text(page, value).first();
  await target.waitFor({ state: 'visible', timeout: 20_000 });
  await target.scrollIntoViewIfNeeded().catch(() => {});
  await target.click();
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

/** Type into a text field identified by its accessible name. */
export async function fillField(page: Page, name: string, value: string): Promise<void> {
  const field = textbox(page, name).first();
  await field.waitFor({ state: 'visible', timeout: 20_000 });
  await field.fill(value);
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
