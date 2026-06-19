import { defineConfig, devices } from '@playwright/test';

const PORT = Number(process.env.GLOW_WEB_PORT ?? 8080);
const BASE_URL = process.env.GLOW_BASE_URL ?? `http://localhost:${PORT}`;

export default defineConfig({
  testDir: './test/playwright/tests',
  timeout: 120_000,
  expect: { timeout: 20_000 },
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],

  use: {
    baseURL: BASE_URL,
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
    command: 'flutter build web && node test/playwright/serve.mjs',
    url: BASE_URL,
    timeout: 600_000,
    reuseExistingServer: !process.env.CI,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
