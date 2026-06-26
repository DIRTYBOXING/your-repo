import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? "http://127.0.0.1:8088";

export default defineConfig({
  testDir: "test/visual",
  timeout: 60_000,
  workers: 1,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL,
    headless: process.env.PLAYWRIGHT_HEADED != "1",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    {
      name: "desktop",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1440, height: 1080 },
      },
    },
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1440, height: 1080 },
      },
    },
    {
      name: "firefox",
      use: {
        ...devices["Desktop Firefox"],
        viewport: { width: 1440, height: 1080 },
      },
    },
    {
      name: "webkit",
      use: {
        ...devices["Desktop Safari"],
        viewport: { width: 1440, height: 1080 },
      },
    },
    {
      name: "laptop1024",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1024, height: 768 },
      },
    },
    {
      name: "tablet768",
      use: {
        ...devices["iPad (gen 7)"],
        viewport: { width: 768, height: 1024 },
      },
    },
    {
      name: "mobile",
      use: {
        ...devices["Pixel 5"],
        viewport: { width: 430, height: 800 },
      },
    },
    {
      name: "mobile360",
      use: {
        ...devices["Pixel 5"],
        viewport: { width: 360, height: 800 },
      },
    },
    {
      name: "mobile400",
      use: {
        ...devices["Pixel 5"],
        viewport: { width: 400, height: 800 },
      },
    },
    {
      name: "mobile430",
      use: {
        ...devices["Pixel 5"],
        viewport: { width: 430, height: 800 },
      },
    },
  ],
});
