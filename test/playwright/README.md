# End-to-end tests (Playwright → Flutter web)

Playwright tests that drive the **web build** of *The Glow Protocol* in a real
Chromium browser, exercising the app through its UI exactly as a user would.

## Why this is set up the way it is

Flutter web paints its UI to a **canvas** — there is no ordinary HTML DOM for the
widgets, so you can't select them with normal CSS/text selectors out of the box.
Instead these tests turn on Flutter's **accessibility (semantics) tree**, which
mirrors the widget tree into `<flt-semantics>` DOM nodes (inside the
`flt-glass-pane` shadow root). Those nodes overlay the canvas at each widget's
real position, so Playwright can find them and clicking one dispatches a genuine
tap that Flutter handles like a user's.

Key facts encoded in `helpers/flutter.ts` (Flutter 3.44, CanvasKit renderer):

| Widget | Exposed as | Selector |
|---|---|---|
| Text | `<flt-semantics><span>…</span>` | `getByText()` |
| Button (`role=button`) | `<flt-semantics role="button">Label` | `getByRole('button', { name })` |
| Custom CTA (no role) | text-only node | `tapText()` (match by text) |
| Text field | real `<input aria-label="…">` | `getByRole('textbox', { name })` |
| Bottom-nav tab | node with `aria-current` + doubled label | `navTab()` / `tapNavTab()` |

Two gotchas the helpers work around:

1. **Enabling semantics.** Flutter renders a hidden "Enable accessibility"
   placeholder *outside the viewport*. We activate it with a synthetic DOM
   `click()` (a pointer click can't reach it). `bootFlutter()` does this for you.
2. **Off-viewport overlay.** In the main app the semantics overlay is offset
   horizontally, so the bottom-nav hit points fall outside the viewport and a
   real pointer click is rejected. Flutter's semantics buttons also respond to a
   synthetic `click` event, so `tapNavTab()` dispatches that instead.

The **debug** dev server (`flutter run -d web-server`) first-paints far too
slowly for a fresh browser context, so the tests build and serve an optimized
release build (`flutter build web` + `serve.mjs`).

## Prerequisites

- Flutter SDK on `PATH` (3.44+), able to `flutter build web`.
- Node 18+.

## Install

```bash
cd e2e
npm install
npm run install:browsers   # one-time Chromium download
```

## Run

```bash
npm test            # builds web, serves it, runs all tests headless
npm run test:headed # watch it in a real browser
npm run test:ui     # Playwright UI mode
npm run report      # open the last HTML report
```

`playwright.config.ts` builds + serves the app automatically via its `webServer`
block (first run includes a ~45s `flutter build web`). To iterate faster against
an already-running server:

```bash
npm run serve:web   # or: node serve.mjs  (serves an existing build/web)
# in another shell:
npx playwright test            # reuses the server on :8080
```

Override the URL/port with `GLOW_BASE_URL` / `GLOW_WEB_PORT`.

## What's covered

- **`smoke.spec.ts`** — app boots, semantics come up, the bilingual language
  picker renders (validates load + Hebrew/RTL + Latin text), document is RTL.
- **`onboarding.spec.ts`** — the wizard: language → welcome → personal info →
  product step; both English and Hebrew paths; the Continue gating
  (disabled until name + gender are provided).
- **`navigation.spec.ts`** — starts from a seeded, already-onboarded session and
  exercises the four bottom-nav destinations and the Settings entry points.

## Writing new tests

```ts
import { test } from '@playwright/test';
import { bootFlutter, tapButton, fillField, expectText } from '../helpers/flutter';

test('example', async ({ page }) => {
  await bootFlutter(page, '/');     // load + enable semantics
  await tapButton(page, 'English');
  await fillField(page, 'Your name', 'Dana');
  await expectText(page, 'The Glow Protocol');
});
```

To start past onboarding, call `seedOnboardedEnglish(page)` (or `seedPrefs`)
**before** `bootFlutter` — it seeds `SharedPreferences` in `localStorage`.

### Tips for stable selectors

- Drive the app in **English** (stable Latin labels) where possible; the Hebrew
  strings live in `lib/core/l10n/app_he.arb`.
- Buttons that wrap a `Text` in `Semantics(label:)` expose a **doubled** name
  ("My Day My Day") — match non-exactly or via `navTab`.
- Section headers and some decorative text are **not** exposed in semantics;
  assert on interactive row labels instead. Row labels often concatenate
  title + subtitle into one node, so prefer `expectTextContaining`.
