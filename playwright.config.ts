import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'e2e',
  timeout: 30_000,
  retries: 0,
  use: {
    baseURL: process.env.APP_URL || 'http://localhost:5174',
    headless: true,
    viewport: { width: 1280, height: 720 },
  },
}); 