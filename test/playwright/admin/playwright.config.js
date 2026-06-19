const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',
  timeout: 30000,
  retries: 0,
  use: {
    baseURL: 'http://localhost:3001',
    headless: true,
  },
  webServer: {
    command: 'cd ../../../admin && node server.js',
    url: 'http://localhost:3001',
    reuseExistingServer: true,
    timeout: 10000,
  },
  reporter: [['list'], ['html', { open: 'never' }]],
});
