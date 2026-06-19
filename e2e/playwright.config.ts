import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config for end-to-end testing the Flutter **web** build of
 * The Glow Protocol.
 *
 * Flutter web renders to a canvas, so there is no conventional HTML DOM for the
 * UI. Instead we drive the app through Flutter's accessibility (semantics) tree,
 * which Flutter exposes as `<flt-semantics>` DOM nodes once enabled. See
 * `helpers/flutter.ts` for the boot/interaction primitives.
 *
 * The `webServer` block builds and serves the Flutter web app automatically.
 * The first run compiles the app and can take a couple of minutes.
 */

const PORT = Number(process.env.GLOW_WEB_PORT ?? 8080);
const BASE_URL = process.env.GLOW_BASE_URL ?? `http://localhost:${PORT}`;

export default defineConfig({
  testDir: './tests',
  // Flutter web is heavy; give each test room and don't hammer the single dev server.
  timeout: 120_000,
  expect: { timeout: 20_000 },
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],

  use: {
    baseURL: BASE_URL,
    // The app is a mobile-first portrait layout.
    viewport: { width: 412, height: 915 },
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], viewport: { width: 412, height: 915 } },
    },
  ],

  webServer: {
    // Build the optimized web app, then serve build/web statically. The release
    // build first-paints in seconds; the debug dev server is far too slow for
    // a fresh (uncached) browser context per test.
    command: 'npm run build:web && node serve.mjs',
    url: BASE_URL,
    timeout: 600_000,
    reuseExistingServer: !process.env.CI,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
