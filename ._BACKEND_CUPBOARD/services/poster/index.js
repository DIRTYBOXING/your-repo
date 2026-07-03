const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");

const express = require("express");
const puppeteer = require("puppeteer-core");

const PORT = Number(process.env.PORT || 8081);
const BASE_URL = process.env.POSTER_BASE_URL || `http://localhost:${PORT}`;
const STORAGE_DIR = path.join(process.cwd(), "posters");
const TEMPLATE_PATH = path.join(__dirname, "template.html");

const CHROMIUM_PATH_CANDIDATES = [
  process.env.PUPPETEER_EXECUTABLE_PATH,
  process.env.CHROMIUM_PATH,
  "/usr/bin/chromium",
  "/usr/bin/chromium-browser",
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
].filter(Boolean);

const app = express();
app.use(express.json({ limit: "1mb" }));
app.use("/posters", express.static(STORAGE_DIR));

let browserPromise;

function ensureStorageDir() {
  fs.mkdirSync(STORAGE_DIR, { recursive: true });
}

function resolveChromiumPath() {
  for (const candidate of CHROMIUM_PATH_CANDIDATES) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return undefined;
}

async function getBrowser() {
  if (!browserPromise) {
    const executablePath = resolveChromiumPath();
    browserPromise = puppeteer.launch({
      executablePath,
      headless: true,
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
      ],
    });
  }
  return browserPromise;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function buildFightersBlock(fighters) {
  if (!fighters.length) {
    return '<div class="fighter">TBA</div>';
  }

  if (fighters.length === 1) {
    return `<div class="fighter">${escapeHtml(fighters[0])}</div>`;
  }

  const rows = [];
  fighters.slice(0, 2).forEach((name, index) => {
    rows.push(`<div class="fighter">${escapeHtml(name)}</div>`);
    if (index === 0) {
      rows.push('<span class="versus">vs</span>');
    }
  });

  return rows.join("\n");
}

function fillTemplate(payload) {
  const rawTemplate = fs.readFileSync(TEMPLATE_PATH, "utf8");

  const title = payload.title || "Fight Night";
  const split = title.split(" ");
  const titleAccent = split.length > 1 ? split.pop() : "Main";
  const titleMain = split.length ? split.join(" ") : title;

  return rawTemplate
    .replace("{{TITLE_MAIN}}", escapeHtml(titleMain))
    .replace("{{TITLE_ACCENT}}", escapeHtml(titleAccent))
    .replace("{{FIGHTERS_BLOCK}}", buildFightersBlock(payload.fighters || []))
    .replace("{{EVENT_ID}}", escapeHtml(payload.event_id));
}

async function renderPosterToFile(payload, outputPath) {
  const browser = await getBrowser();
  const page = await browser.newPage();

  try {
    await page.setViewport({ width: 1080, height: 1350, deviceScaleFactor: 1 });
    await page.setContent(fillTemplate(payload), { waitUntil: "networkidle0" });
    await page.screenshot({ path: outputPath, type: "png" });
  } finally {
    await page.close();
  }
}

app.get("/health", (req, res) => {
  res.json({ status: "ok", service: "poster-service" });
});

app.post("/generate", async (req, res) => {
  const { event_id, title, fighters = [] } = req.body || {};

  if (event_id === undefined || title === undefined) {
    return res.status(400).json({
      error: "bad_request",
      message: "event_id and title are required",
    });
  }

  ensureStorageDir();

  const fileName = `${event_id}-${crypto.randomUUID().replaceAll("-", "")}.png`;
  const outputPath = path.join(STORAGE_DIR, fileName);

  try {
    await renderPosterToFile({ event_id, title, fighters }, outputPath);
  } catch (error) {
    return res.status(500).json({
      error: "poster_generation_failed",
      message: error instanceof Error ? error.message : "unknown error",
    });
  }

  res.json({
    storage_path: `posters/${fileName}`,
    cdn_url: `${BASE_URL}/posters/${fileName}`,
  });
});

app.get("/posters/:fileName", (req, res) => {
  const filePath = path.join(STORAGE_DIR, req.params.fileName);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: "not_found" });
  }

  res.sendFile(filePath);
});

const server = app.listen(PORT, () => {
  ensureStorageDir();
  console.log(`poster-service listening on ${PORT}`);
});

async function shutdown() {
  server.close();
  if (browserPromise) {
    const browser = await browserPromise;
    await browser.close();
  }
  process.exit(0);
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
