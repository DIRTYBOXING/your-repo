// Serverless promoter outreach function (Node + SendGrid)
// Deploy to Cloud Run, AWS Lambda, or Vercel.
// Required env: SENDGRID_API_KEY
//
// Accepts two calling conventions:
//   A) POST { "eventJsonPath": "/path/to/event.json", "template": "initial" }
//   B) POST { "to": "...", "eventId": "...", "title": "...", "promoter": "...", "template": "initial" }

import sgMail from "@sendgrid/mail";
import fs from "node:fs/promises";
import path from "node:path";

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

const FROM_EMAIL = process.env.FROM_EMAIL || "info@datafightcentral.com";
const SENDER_NAME = "DFC Team — DataFight Central";
const LOG_DIR = "docs/legal/email_logs";

const SIGNATURE = [
  "DFC Team",
  "DataFight Central (DFC) — www.datafightcentral.com",
  FROM_EMAIL,
  "Facebook Messenger: m.me/DataFightCentral",
].join("\n");

function buildEmail(event, template) {
  const promoter = event.promoter || event.promotion || "Promoter";
  const title = event.title || event.eventTitle || event.eventId;
  const venue = event.venue || "";
  const venueSuffix = venue ? ` at ${venue}` : "";
  const price = event.price || "TBD";
  const eventId = event.eventId;

  switch (template) {
    case "initial":
      return {
        subject: `Asset & Event Key Request — ${title} — DataFight Central (DFC)`,
        text: [
          `Hi ${promoter},`,
          "",
          "We are the DataFight Central (DFC) team — www.datafightcentral.com.",
          "",
          "DFC is a global promoter and distribution platform for combat sports. We promote every event and fighter equally, from grassroots shows to major cards, and provide worldwide exposure across our app and social channels. We respect your brand and will promote responsibly: no trolling, accurate event details, and clear refund/terms shown to buyers.",
          "",
          `We're preparing a Pay-Per-View listing for "${title}"${venueSuffix} and request the following so we can list, promote, and sell the PPV on your behalf:`,
          "",
          "  - Official high-res hero poster and portrait poster (min 1600×2400)",
          "  - Fighter headshots (high resolution; please include signed model releases where required)",
          "  - Sponsor logos (transparent PNG) and any sponsor usage rules",
          "  - Official event copy: full card, venue, start time, ticket/door times, and approved legal text",
          "  - Written license confirming DFC may distribute and sell the PPV digitally worldwide",
          "  - Event key or API token (if you use one) and any required metadata fields (e.g., broadcast rights, blackout regions)",
          "  - Preferred contact for legal/licensing and a point person for approvals",
          "",
          "If you prefer, we can send a draft poster for your approval before publishing. Once we receive assets and the license, we will:",
          "",
          "  1. Publish a DFC PPV listing with your approved artwork.",
          "  2. Map the event to an eventId and create the PPV product in our payment gateway.",
          "  3. Promote the event across DFC channels and provide weekly sales reports.",
          "  4. Keep all signed licenses and model releases in our secure legal folder and provide copies on request.",
          "",
          `Please reply to ${FROM_EMAIL} with the assets and signed license, or reply here with a time for a 10-minute call and I'll arrange it.`,
          "",
          "Thanks for partnering — we look forward to promoting your event and building fighters' exposure together.",
          "",
          "Regards,",
          SIGNATURE,
        ].join("\n"),
      };

    case "followup":
      return {
        subject: `Friendly follow-up — assets for ${title}`,
        text: [
          `Hi ${promoter},`,
          "",
          `Following up on my email about "${title}". We've prepared a draft poster and event listing and can publish as soon as we receive the official assets and license.`,
          "",
          "If you prefer, we can schedule a 10-minute call to walk through the listing and revenue options.",
          "",
          "Regards,",
          SIGNATURE,
        ].join("\n"),
      };

    case "approved":
      return {
        subject: `Approved — ${title} listing live on DFC`,
        text: [
          `Hi ${promoter},`,
          "",
          `Thanks — we've received the assets and license for "${title}". Your event listing is now live on DFC and available for PPV sales.`,
          "",
          "Listing details:",
          `  - Event ID: ${eventId}`,
          `  - PPV price: $${price}`,
          "  - Listing URL: https://app.datafightcentral.com/ppv/" + eventId,
          "",
          "We'll send weekly sales reports and can provide promotional assets for your social channels. Please let us know any updates or corrections.",
          "",
          "Regards,",
          SIGNATURE,
        ].join("\n"),
      };

    // ── Gym outreach templates (sponsored gyms only) ──

    case "gym_shields_initial":
      return {
        subject: `DFC Sponsored Gym Program — Shields, Extra Ads & Gold Coins — ${promoter}`,
        text: [
          `Hi ${promoter} team,`,
          "",
          "We are the DataFight Central (DFC) team — www.datafightcentral.com.",
          "",
          "DFC runs a global promoter and PPV platform. We offer a sponsored gym program called Shields & Gold Coins — exclusively for gyms that become DFC sponsors.",
          "",
          "What sponsored gyms receive:",
          "  - Shields: verified recognition badges displayed on your gym profile and event listings (sponsored gyms only).",
          "  - Extra ads: premium ad placements across DFC app, PPV screens, and social channels (sponsored gyms only).",
          "  - Gold Coins: promotional credits for verified fighter development stories and event participation.",
          "  - Mentoring program: connect your coaches with experienced mentors across our network.",
          "",
          "Note: Shields and extra ad placements are available exclusively to sponsored gyms.",
          "",
          `Reply to ${FROM_EMAIL} or reply here with a contact and best time for a 10-minute call to discuss sponsorship tiers.`,
          "",
          "Regards,",
          SIGNATURE,
        ].join("\n"),
      };

    case "gym_shields_followup":
      return {
        subject: `Friendly follow-up — DFC Sponsored Gym Program for ${promoter}`,
        text: [
          `Hi ${promoter} team,`,
          "",
          "Following up on our Shields & Gold Coins sponsorship invitation. We'd love to include your gym as a sponsored gym in the next cycle — giving you Shield badges, extra ad placements, and promotional credits.",
          "",
          "Reply with a contact and we'll schedule a short call.",
          "",
          "Regards,",
          SIGNATURE,
        ].join("\n"),
      };

    case "gym_shields_confirm":
      return {
        subject: `Welcome to DFC Shields (Sponsored Gym) — Next Steps for ${promoter}`,
        text: [
          `Hi ${promoter} team,`,
          "",
          `Welcome — ${promoter} is now enrolled as a sponsored gym in DFC Shields & Gold Coins.`,
          "",
          "As a sponsored gym you will receive:",
          "  - Shield badge on your DFC gym profile and all linked event listings.",
          "  - Extra ad placements across the DFC app, PPV screens, and social channels.",
          "  - Gold Coins promotional credits.",
          "",
          "Next steps:",
          `  - Send signed sponsorship agreement and consent release to ${FROM_EMAIL}.`,
          "  - Provide gym bio and logo (PNG).",
          "  - Share upcoming events or fighter highlights for promotion.",
          "",
          "We'll publish a gym spotlight and activate your Shield badge and ad slots once we receive the signed agreement.",
          "",
          "Regards,",
          SIGNATURE,
        ].join("\n"),
      };

    default:
      throw new Error(`Unknown template: ${template}`);
  }
}

const FAILURE_LOG_DIR = "docs/legal/email_failures";

async function writeAuditLog(eventId, toEmail, template, status, extra) {
  const entry = {
    timestamp: new Date().toISOString(),
    eventId,
    to: toEmail,
    template,
    status,
    sender: FROM_EMAIL,
    ...extra,
  };
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const logFile = path.join(LOG_DIR, `${eventId}_send_log.json`);
    await fs.appendFile(logFile, JSON.stringify(entry) + "\n");
  } catch (logError) {
    console.warn("writeAuditLog primary log failed:", logError.message);
  }
  // Also write failures to a separate directory for easy triage
  if (status === "failed") {
    try {
      await fs.mkdir(FAILURE_LOG_DIR, { recursive: true });
      const failFile = path.join(FAILURE_LOG_DIR, `${eventId}_failure.json`);
      await fs.appendFile(failFile, JSON.stringify(entry) + "\n");
    } catch (failureLogError) {
      console.warn(
        "writeAuditLog failure log failed:",
        failureLogError.message,
      );
    }
  }
}

export default async function handler(req, res) {
  try {
    const body = req.body || {};
    const template = body.template || "initial";
    const gym = body.gym || null; // Optional gym object { id, name, contact }
    let event;
    let promoterEmail;

    if (body.eventJsonPath) {
      // Convention A: read event from local JSON file
      const raw = await fs.readFile(body.eventJsonPath, "utf8");
      event = JSON.parse(raw);
      promoterEmail = event.contact || event.promoterEmail;
    } else if (body.to && body.eventId) {
      // Convention B: inline payload from bulk script
      event = {
        eventId: body.eventId,
        title: body.title || body.eventId,
        promoter: body.promoter || (gym ? gym.name : "Promoter"),
        venue: body.venue || "",
        price: body.price || "TBD",
      };
      promoterEmail = body.to;
    } else if (gym?.contact) {
      // Convention C: gym outreach (no event context needed)
      event = {
        eventId: `gym-${gym.id || "unknown"}`,
        promoter: gym.name || "Gym",
      };
      promoterEmail = gym.contact;
    } else {
      return res.status(400).json({
        ok: false,
        error: "Provide eventJsonPath, {to, eventId}, or {gym}",
      });
    }

    if (!promoterEmail) {
      return res
        .status(400)
        .json({ ok: false, error: "No recipient email found" });
    }

    const { subject, text } = buildEmail(event, template);

    const msg = {
      to: promoterEmail,
      from: { email: FROM_EMAIL, name: SENDER_NAME },
      subject,
      text,
      headers: {
        "List-Unsubscribe": `<mailto:${FROM_EMAIL}?subject=unsubscribe>`,
      },
    };

    await sgMail.send(msg);

    const auditExtra = gym ? { gymId: gym.id, gymName: gym.name } : {};
    await writeAuditLog(
      event.eventId,
      promoterEmail,
      template,
      "sent",
      auditExtra,
    );

    return res.status(200).json({ ok: true, to: promoterEmail, template });
  } catch (err) {
    console.error("sendPromoterEmail error:", err);
    const eventId = req.body?.eventId || req.body?.gym?.id || "unknown";
    const toEmail = req.body?.to || req.body?.gym?.contact || "unknown";
    const gym = req.body?.gym;
    const auditExtra = gym ? { gymId: gym.id, gymName: gym.name } : {};
    await writeAuditLog(
      eventId,
      toEmail,
      req.body?.template || "unknown",
      "failed",
      auditExtra,
    );
    return res.status(500).json({ ok: false, error: err.message });
  }
}
