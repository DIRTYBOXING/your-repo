/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  DFC CHUCKYA RADAR — Police Evidence Export Module           ║
 * ║  Chain-of-custody, SHA-256 integrity, structured report     ║
 * ║  Designed for law-enforcement handoff (AU/US/UK compliant)  ║
 * ╚══════════════════════════════════════════════════════════════╝
 *
 * Usage:  const { mountPoliceRoutes } = require('./police_export');
 *         mountPoliceRoutes(app, alerts, AUDIT_DIR);
 */
"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const archiver = require("archiver");

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

/** Compute SHA-256 of a buffer or string. */
function sha256(data) {
  return crypto.createHash("sha256").update(data).digest("hex");
}

/** HMAC-SHA256 signature for chain-of-custody entries. */
function hmacSign(payload, secret) {
  return crypto.createHmac("sha256", secret).update(payload).digest("hex");
}

/** Get signing secret — from env or fallback for demo. */
function getSigningSecret() {
  return (
    process.env.CHUCKYA_SIGNING_SECRET ||
    "dfc-demo-signing-key-change-in-production"
  );
}

/** Path-traversal guard: resolve & ensure stays inside base. */
function safeResolve(base, ...segments) {
  const resolved = path.resolve(base, ...segments);
  const realBase = fs.realpathSync(base);
  if (!resolved.startsWith(realBase)) {
    throw new Error("Path traversal detected");
  }
  return resolved;
}

// ─────────────────────────────────────────────────────────────
// Chain-of-Custody Ledger
// ─────────────────────────────────────────────────────────────

/**
 * Append a signed entry to the alert's chain-of-custody log.
 * Each entry has: timestamp, action, actor, detail, prevHash, signature.
 */
function appendCustodyEntry(auditDir, alertId, action, actor, detail) {
  const incidentDir = path.join(auditDir, alertId);
  if (!fs.existsSync(incidentDir)) {
    fs.mkdirSync(incidentDir, { recursive: true });
  }

  const ledgerPath = path.join(incidentDir, "chain_of_custody.json");
  let ledger = [];
  if (fs.existsSync(ledgerPath)) {
    try {
      ledger = JSON.parse(fs.readFileSync(ledgerPath, "utf-8"));
    } catch {
      ledger = [];
    }
  }

  const prevHash =
    ledger.length > 0
      ? sha256(JSON.stringify(ledger[ledger.length - 1]))
      : "0".repeat(64);

  const entry = {
    seq: ledger.length + 1,
    timestamp: new Date().toISOString(),
    action,
    actor: typeof actor === "string" ? actor.slice(0, 128) : "system",
    detail: typeof detail === "string" ? detail.slice(0, 512) : "",
    prevHash,
  };

  entry.signature = hmacSign(JSON.stringify(entry), getSigningSecret());
  ledger.push(entry);

  fs.writeFileSync(ledgerPath, JSON.stringify(ledger, null, 2));
  return entry;
}

// ─────────────────────────────────────────────────────────────
// Structured Police Report (text-based for PDF-conversion)
// ─────────────────────────────────────────────────────────────

function generatePoliceReport(alert, custodyLedger, evidenceManifest) {
  const divider = "═".repeat(70);
  const lines = [
    divider,
    "  DATAFIGHTCENTRAL — CONFIDENTIAL EVIDENCE REPORT",
    "  CHUCKYA RADAR ANTI-PIRACY INTELLIGENCE",
    divider,
    "",
    `Report ID:        ${alert.alertId}`,
    `Generated:        ${new Date().toISOString()}`,
    `Classification:   LAW ENFORCEMENT — RESTRICTED`,
    "",
    divider,
    "  1. INCIDENT SUMMARY",
    divider,
    "",
    `Alert ID:         ${alert.alertId}`,
    `Type:             ${alert.type}`,
    `Risk Score:       ${alert.riskScore}/100`,
    `Status:           ${alert.status}`,
    `Created:          ${alert.createdAt}`,
    `Source:           ${alert.source || "automated detection"}`,
    `Session ID:       ${alert.sessionId || "N/A"}`,
    "",
    "Signals Detected:",
    ...(alert.topSignals || []).map((s, i) => `  ${i + 1}. ${s}`),
    "",
    "Metadata:",
    `  Event ID:       ${alert.metadata?.eventId || "N/A"}`,
    `  User ID:        ${alert.metadata?.userId || "N/A"}`,
    `  Timestamp:      ${alert.metadata?.timestamp || "N/A"}`,
    "",
    divider,
    "  2. EVIDENCE INVENTORY",
    divider,
    "",
    "Files included in this export:",
    "",
    "  #   Filename                        SHA-256",
    "  " + "─".repeat(66),
    ...evidenceManifest.map(
      (f, i) =>
        `  ${String(i + 1).padStart(2)}  ${f.name.padEnd(32)} ${f.sha256}`,
    ),
    "",
    divider,
    "  3. CHAIN OF CUSTODY",
    divider,
    "",
    "  Seq  Timestamp                    Action          Actor",
    "  " + "─".repeat(66),
    ...custodyLedger.map(
      (e) =>
        `  ${String(e.seq).padStart(3)}  ${e.timestamp}  ${e.action.padEnd(14)}  ${e.actor}`,
    ),
    "",
    divider,
    "  4. INTEGRITY VERIFICATION",
    divider,
    "",
    "Each file in this bundle has a SHA-256 hash listed in the manifest.",
    "Each chain-of-custody entry is HMAC-SHA256 signed and hash-chained",
    "to the previous entry, forming a tamper-evident ledger.",
    "",
    "To verify:",
    "  1. Compute SHA-256 of each file and compare to manifest.json.",
    "  2. Recompute HMAC-SHA256 of each custody entry using the signing",
    "     key and verify the signature field matches.",
    "  3. Verify each entry's prevHash matches SHA-256 of the prior entry.",
    "",
    divider,
    "  5. LEGAL NOTICE",
    divider,
    "",
    'This report was generated by DataFightCentral Pty Ltd ("DFC") CHUCKYA',
    "Radar system. Contents are provided in good faith for law-enforcement",
    "purposes. DFC makes no warranty regarding the completeness of evidence",
    "and recommends independent forensic verification.",
    "",
    "All personal data in this report is subject to the Australian Privacy",
    "Act 1988, GDPR (where applicable), and US state privacy laws.",
    "Disclosure is limited to authorized law-enforcement officers.",
    "",
    "Contact: legal@datafightcentral.com",
    "",
    divider,
    `  END OF REPORT — ${alert.alertId}`,
    divider,
    "",
  ];

  return lines.join("\n");
}

// ─────────────────────────────────────────────────────────────
// Express Route Mounter
// ─────────────────────────────────────────────────────────────

/**
 * Mount police-grade export routes onto an Express app.
 *
 * @param {import('express').Application} app
 * @param {Object} alerts - In-memory alerts store (demo mode)
 * @param {string} auditDir - Absolute path to ops-audit directory
 */
function mountPoliceRoutes(app, alerts, auditDir) {
  // ── POST /v1/radar/alerts/:id/police-export ──────────────
  // One-click police evidence pack (zip with report, manifest,
  // chain-of-custody, and all evidence files).
  app.post("/v1/radar/alerts/:id/police-export", (req, res) => {
    const id = req.params.id;
    const alert = alerts[id];
    if (!alert) return res.status(404).json({ error: "Alert not found" });

    // Require approval header (two-person rule placeholder)
    const approver = req.headers["x-dfc-approver"];
    if (!approver) {
      return res.status(403).json({
        error:
          "Police export requires X-DFC-Approver header (two-person approval rule).",
      });
    }

    const incidentDir = path.join(auditDir, id);
    if (!fs.existsSync(incidentDir)) {
      fs.mkdirSync(incidentDir, { recursive: true });
    }

    // ── Record custody entry: export initiated ──────────────
    appendCustodyEntry(
      auditDir,
      id,
      "EXPORT_INIT",
      approver,
      `Police export initiated by ${approver} from ${req.ip}`,
    );

    // ── Build manifest ──────────────────────────────────────
    const manifest = {
      exportedAt: new Date().toISOString(),
      exportedBy: approver,
      exporterIP: req.ip || "unknown",
      alertId: id,
      exportType: "police_evidence_pack",
      files: [],
    };

    // ── Archive setup ───────────────────────────────────────
    const safeId = id.replace(/[^a-zA-Z0-9_-]/g, "_");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${safeId}_police_evidence.zip"`,
    );
    res.setHeader("Content-Type", "application/zip");

    const archive = archiver("zip", { zlib: { level: 9 } });
    archive.on("error", (err) => {
      appendCustodyEntry(auditDir, id, "EXPORT_FAIL", "system", err.message);
      if (!res.headersSent) res.status(500).json({ error: err.message });
    });
    archive.pipe(res);

    // ── 1. Alert JSON ───────────────────────────────────────
    const alertJson = JSON.stringify(alert, null, 2);
    const alertHash = sha256(alertJson);
    manifest.files.push({
      name: "alert.json",
      sha256: alertHash,
      type: "alert_data",
    });
    archive.append(alertJson, { name: "alert.json" });

    // ── 2. Evidence files (from incident dir) ───────────────
    if (fs.existsSync(incidentDir)) {
      const files = fs.readdirSync(incidentDir);
      for (const f of files) {
        if (f === "alert.json") continue; // already added
        if (f === "chain_of_custody.json") continue; // added separately

        let fullPath;
        try {
          fullPath = safeResolve(auditDir, id, f);
        } catch {
          continue; // skip path-traversal attempts
        }

        const stat = fs.statSync(fullPath);
        if (!stat.isFile() || stat.size > 500 * 1024 * 1024) continue; // 500MB cap

        const buf = fs.readFileSync(fullPath);
        const hash = sha256(buf);
        manifest.files.push({
          name: f,
          sha256: hash,
          bytes: stat.size,
          type: "evidence",
        });
        archive.file(fullPath, { name: `evidence/${f}` });
      }
    }

    // ── 3. Chain of custody ─────────────────────────────────
    const custodyPath = path.join(incidentDir, "chain_of_custody.json");
    let custodyLedger = [];
    if (fs.existsSync(custodyPath)) {
      try {
        custodyLedger = JSON.parse(fs.readFileSync(custodyPath, "utf-8"));
      } catch {
        custodyLedger = [];
      }
    }

    // Add export-complete entry
    appendCustodyEntry(
      auditDir,
      id,
      "EXPORT_DONE",
      approver,
      `Bundle contains ${manifest.files.length} files`,
    );

    // Re-read ledger (now includes EXPORT_DONE)
    if (fs.existsSync(custodyPath)) {
      try {
        custodyLedger = JSON.parse(fs.readFileSync(custodyPath, "utf-8"));
      } catch {
        // keep previous
      }
    }

    const custodyJson = JSON.stringify(custodyLedger, null, 2);
    const custodyHash = sha256(custodyJson);
    manifest.files.push({
      name: "chain_of_custody.json",
      sha256: custodyHash,
      type: "custody_ledger",
    });
    archive.append(custodyJson, { name: "chain_of_custody.json" });

    // ── 4. Structured police report ─────────────────────────
    const report = generatePoliceReport(alert, custodyLedger, manifest.files);
    const reportHash = sha256(report);
    manifest.files.push({
      name: "POLICE_REPORT.txt",
      sha256: reportHash,
      type: "report",
    });
    archive.append(report, { name: "POLICE_REPORT.txt" });

    // ── 5. Final manifest (with all hashes) ─────────────────
    manifest.bundleHash = sha256(JSON.stringify(manifest.files));
    const manifestJson = JSON.stringify(manifest, null, 2);
    archive.append(manifestJson, { name: "manifest.json" });

    // ── Audit log ───────────────────────────────────────────
    const logLine = `[${new Date().toISOString()}] POLICE_EXPORT ${id} approver:${approver} files:${manifest.files.length} ip:${req.ip}\n`;
    fs.appendFileSync(path.join(auditDir, "access.log"), logLine);

    archive.finalize();
  });

  // ── GET /v1/radar/alerts/:id/custody — view chain of custody ──
  app.get("/v1/radar/alerts/:id/custody", (req, res) => {
    const id = req.params.id;
    if (!alerts[id]) return res.status(404).json({ error: "Alert not found" });

    const custodyPath = path.join(auditDir, id, "chain_of_custody.json");
    if (!fs.existsSync(custodyPath)) {
      return res.json({ alertId: id, entries: [] });
    }

    try {
      const ledger = JSON.parse(fs.readFileSync(custodyPath, "utf-8"));
      res.json({ alertId: id, entries: ledger });
    } catch {
      res.json({ alertId: id, entries: [] });
    }
  });

  // ── POST /v1/radar/alerts/:id/custody — add custody entry ────
  app.post("/v1/radar/alerts/:id/custody", (req, res) => {
    const id = req.params.id;
    if (!alerts[id]) return res.status(404).json({ error: "Alert not found" });

    const { action, actor, detail } = req.body;
    if (!action || !actor) {
      return res.status(400).json({ error: "action and actor are required" });
    }

    const entry = appendCustodyEntry(
      auditDir,
      id,
      String(action).slice(0, 64),
      String(actor).slice(0, 128),
      String(detail || "").slice(0, 512),
    );

    res.json({ alertId: id, entry });
  });

  // ── POST /v1/radar/alerts/:id/evidence — upload evidence file ──
  app.post("/v1/radar/alerts/:id/evidence", (req, res) => {
    const id = req.params.id;
    if (!alerts[id]) return res.status(404).json({ error: "Alert not found" });

    // Expect raw body (set limit in main app bodyParser)
    const filename = req.headers["x-dfc-filename"];
    if (!filename || !/^[a-zA-Z0-9._-]+$/.test(filename)) {
      return res.status(400).json({
        error:
          "X-DFC-Filename header required (alphanumeric, dots, dashes, underscores only).",
      });
    }

    const incidentDir = path.join(auditDir, id);
    if (!fs.existsSync(incidentDir)) {
      fs.mkdirSync(incidentDir, { recursive: true });
    }

    let targetPath;
    try {
      targetPath = safeResolve(auditDir, id, filename);
    } catch {
      return res.status(400).json({ error: "Invalid filename." });
    }

    // Collect raw body chunks
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      const buf = Buffer.concat(chunks);
      if (buf.length === 0) {
        return res.status(400).json({ error: "Empty body." });
      }
      if (buf.length > 100 * 1024 * 1024) {
        // 100MB limit
        return res.status(413).json({ error: "File exceeds 100MB limit." });
      }

      fs.writeFileSync(targetPath, buf);
      const hash = sha256(buf);

      // Record in custody ledger
      appendCustodyEntry(
        auditDir,
        id,
        "EVIDENCE_ADD",
        req.ip || "unknown",
        `${filename} (${buf.length} bytes, sha256:${hash})`,
      );

      // Update alert's evidence list
      if (!alerts[id].evidence) alerts[id].evidence = [];
      alerts[id].evidence.push({
        filename,
        sha256: hash,
        bytes: buf.length,
        addedAt: new Date().toISOString(),
      });

      res.json({ alertId: id, filename, sha256: hash, bytes: buf.length });
    });
  });
}

module.exports = { mountPoliceRoutes, appendCustodyEntry, sha256 };
