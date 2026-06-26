// tools/send_gym_emails_node.js
// Bulk sender for DFC Shields & Gold Coins gym outreach via SendGrid.
// IMPORTANT: Only sends to gyms where sponsored=yes in the CSV.
//
// Usage: SENDGRID_API_KEY=xxx node tools/send_gym_emails_node.js
// Requires: npm install @sendgrid/mail csv-parse

import fs from "fs/promises";
import path from "path";
import sgMail from "@sendgrid/mail";
import { parse } from "csv-parse/sync";

const SENDGRID_KEY = process.env.SENDGRID_API_KEY;
const FROM = process.env.FROM_EMAIL || "legal@datafightcentral.com";
const FROM_NAME = "DFC Team — DataFight Central";
const LOG_DIR = "docs/legal/email_logs";

if (!SENDGRID_KEY) throw new Error("Set SENDGRID_API_KEY env var");

sgMail.setApiKey(SENDGRID_KEY);

const SIGNATURE = [
  "DFC Team",
  "DataFight Central (DFC) — www.datafightcentral.com",
  "legal@datafightcentral.com",
].join("\n");

async function loadCsv(csvPath) {
  const raw = await fs.readFile(csvPath, "utf8");
  return parse(raw, { columns: true, skip_empty_lines: true });
}

function buildBody(gymName) {
  return [
    `Hi ${gymName} team,`,
    "",
    "We are the DataFight Central (DFC) team — www.datafightcentral.com.",
    "",
    "DFC runs a global promoter and PPV platform. We offer a sponsored gym program called Shields & Gold Coins — exclusively for gyms that become DFC sponsors.",
    "",
    "What sponsored gyms receive:",
    "  - Shields: verified recognition badges displayed on your gym profile and event listings.",
    "  - Extra ads: premium ad placements across DFC app, PPV screens, and social channels.",
    "  - Gold Coins: promotional credits for verified fighter development stories.",
    "  - Mentoring program: connect your coaches with experienced mentors across our network.",
    "",
    "Note: Shields and extra ad placements are available exclusively to sponsored gyms.",
    "",
    "Reply to legal@datafightcentral.com or reply here with a contact and best time for a 10-minute call to discuss sponsorship tiers.",
    "",
    "Regards,",
    SIGNATURE,
  ].join("\n");
}

async function writeLog(gymId, email, status) {
  const entry = {
    timestamp: new Date().toISOString(),
    gymId,
    to: email,
    template: "gym_shields_initial",
    status,
    sender: FROM,
  };
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const logFile = path.join(LOG_DIR, `gym_${gymId}_send_log.json`);
    await fs.appendFile(logFile, JSON.stringify(entry) + "\n");
  } catch (_) {
    // Non-critical
  }
}

async function main() {
  const rows = await loadCsv("data/contacts/gyms.csv");
  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const r of rows) {
    // Only send to sponsored gyms
    if (r.sponsored !== "yes") {
      console.log(`⏭  Skipped ${r.gym_name} — not sponsored`);
      skipped++;
      continue;
    }

    if (!r.contact_email || r.contact_email.startsWith("[")) {
      console.log(`⏭  Skipped ${r.gym_name} — no real email`);
      skipped++;
      continue;
    }

    const msg = {
      to: r.contact_email,
      from: { email: FROM, name: FROM_NAME },
      subject: `DFC Sponsored Gym Program — Shields, Extra Ads & Gold Coins — ${r.gym_name}`,
      text: buildBody(r.gym_name),
      headers: {
        "List-Unsubscribe": `<mailto:legal@datafightcentral.com?subject=unsubscribe>`,
      },
    };

    try {
      await sgMail.send(msg);
      console.log(`✅ Sent to ${r.contact_email} (${r.gym_name})`);
      await writeLog(r.gym_id, r.contact_email, "sent");
      sent++;
    } catch (e) {
      console.error(`❌ Failed ${r.contact_email}:`, e.message);
      await writeLog(r.gym_id, r.contact_email, "failed");
      failed++;
    }
  }

  console.log(
    `\nDone. Sent: ${sent} | Failed: ${failed} | Skipped: ${skipped}`,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
