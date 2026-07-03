// ═══════════════════════════════════════════════════════════════════════════
// BULLET SYSTEM — Gym Outreach & Email Campaigns (RAILGUN)
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION, sgMail } = require("../config");

// ─── Bullet System Init ──────────────────────────────────────────────────
const bulletSystemInit = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    const regions = {
      AU: ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "NT", "ACT"],
      NZ: [
        "Auckland",
        "Wellington",
        "Canterbury",
        "Waikato",
        "Bay of Plenty",
        "Otago",
        "Hawkes Bay",
        "Manawatu-Whanganui",
        "Taranaki",
        "Southland",
      ],
    };

    const gymTypes = [
      "MMA",
      "Boxing",
      "Muay Thai",
      "BJJ",
      "Wrestling",
      "Kickboxing",
      "Judo",
      "Karate",
      "Taekwondo",
      "Bare Knuckle",
      "Brawling",
    ];

    const batch = db.batch();

    for (const country of Object.keys(regions)) {
      for (const region of regions[country]) {
        const docRef = db
          .collection("bullet_regions")
          .doc(`${country}_${region}`);
        batch.set(
          docRef,
          {
            country,
            region,
            gymTypes,
            gymCount: 0,
            lastCampaignAt: null,
            status: "ready",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    }

    await batch.commit();

    return {
      success: true,
      message: "🔫 Bullet System initialized. Railgun ready.",
      regions: { AU: regions.AU.length, NZ: regions.NZ.length },
      gymTypes,
    };
  },
);

// ─── Load Gym Contacts ───────────────────────────────────────────────────
const loadGymContacts = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    const { gyms } = request.data;
    if (!gyms || !Array.isArray(gyms)) {
      return { success: false, error: "Expected gyms[] array" };
    }

    const batch = db.batch();
    let loaded = 0;

    for (const gym of gyms.slice(0, 1000)) {
      if (!gym.email) continue;

      const docId = gym.email.toLowerCase().replace(/[^a-z0-9]/g, "_");
      const docRef = db.collection("bullet_gyms").doc(docId);

      batch.set(
        docRef,
        {
          email: gym.email.toLowerCase(),
          name: gym.name || "",
          gymName: gym.gymName || "",
          city: gym.city || "",
          region: gym.region || "",
          country: gym.country || "AU",
          gymType: gym.gymType || "MMA",
          phone: gym.phone || "",
          website: gym.website || "",
          status: "active",
          campaignsSent: 0,
          lastContactedAt: null,
          responded: false,
          addedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      loaded++;
    }

    await batch.commit();

    // Update region gym counts
    const countSnap = await db.collection("bullet_gyms").get();
    const regionCounts = {};
    countSnap.docs.forEach((d) => {
      const key = `${d.data().country}_${d.data().region}`;
      regionCounts[key] = (regionCounts[key] || 0) + 1;
    });

    const countBatch = db.batch();
    for (const [key, count] of Object.entries(regionCounts)) {
      const regionRef = db.collection("bullet_regions").doc(key);
      countBatch.update(regionRef, { gymCount: count });
    }
    await countBatch.commit().catch(() => {});

    return {
      success: true,
      loaded,
      message: `🔫 ${loaded} gyms loaded into warehouse`,
    };
  },
);

// ─── Create Campaign Template ────────────────────────────────────────────
const createCampaignTemplate = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    const { templateId, name, subject, htmlBody, tags } = request.data;
    if (!templateId || !subject || !htmlBody) {
      return {
        success: false,
        error: "templateId, subject, htmlBody required",
      };
    }

    await db
      .collection("bullet_templates")
      .doc(templateId)
      .set({
        name: name || templateId,
        subject,
        htmlBody,
        tags: tags || [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        usageCount: 0,
      });

    return { success: true, templateId, message: "📝 Template saved" };
  },
);

// ─── RAILGUN BLAST — Mass Email Campaign ─────────────────────────────────
const railgunBlast = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    if (!sgMail) {
      return {
        success: false,
        error: "⚠️ SendGrid not configured. Add SENDGRID_API_KEY to .env",
      };
    }

    const { templateId, filters, testMode } = request.data;
    if (!templateId) {
      return { success: false, error: "templateId required" };
    }

    // Get template
    const templateDoc = await db
      .collection("bullet_templates")
      .doc(templateId)
      .get();
    if (!templateDoc.exists) {
      return { success: false, error: `Template "${templateId}" not found` };
    }
    const template = templateDoc.data();

    // Build query for target gyms
    let query = db.collection("bullet_gyms").where("status", "==", "active");

    if (filters?.country) query = query.where("country", "==", filters.country);
    if (filters?.region) query = query.where("region", "==", filters.region);
    if (filters?.gymType) query = query.where("gymType", "==", filters.gymType);

    const limit = Math.min(filters?.limit || 100, testMode ? 5 : 500);
    const gymsSnap = await query.limit(limit).get();

    if (gymsSnap.empty) {
      return { success: false, error: "No gyms match filters", filters };
    }

    const gyms = gymsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

    // Create campaign record
    const campaignRef = await db.collection("bullet_campaigns").add({
      templateId,
      filters,
      testMode: testMode || false,
      targetCount: gyms.length,
      sentCount: 0,
      failedCount: 0,
      status: "firing",
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      firedBy: request.auth?.uid || "system",
    });

    // Send emails
    const results = { sent: 0, failed: 0, errors: [] };
    const senderEmail = "partnerships@datafightcentral.com";
    const senderName = "Data Fight Central";

    for (const gym of gyms) {
      let personalizedHtml = template.htmlBody
        .replace(/{{gymName}}/g, gym.gymName || "Your Gym")
        .replace(/{{name}}/g, gym.name || "Coach")
        .replace(/{{city}}/g, gym.city || "your city")
        .replace(/{{region}}/g, gym.region || "")
        .replace(/{{country}}/g, gym.country || "AU");

      let personalizedSubject = template.subject
        .replace(/{{gymName}}/g, gym.gymName || "Your Gym")
        .replace(/{{city}}/g, gym.city || "");

      try {
        await sgMail.send({
          to: gym.email,
          from: { email: senderEmail, name: senderName },
          subject: personalizedSubject,
          html: personalizedHtml,
          trackingSettings: {
            clickTracking: { enable: true },
            openTracking: { enable: true },
          },
        });

        await db
          .collection("bullet_gyms")
          .doc(gym.id)
          .update({
            campaignsSent: admin.firestore.FieldValue.increment(1),
            lastContactedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastCampaignId: campaignRef.id,
          });

        results.sent++;
      } catch (err) {
        results.failed++;
        results.errors.push({ email: gym.email, error: err.message });
      }

      // Rate limit: 10 emails per second max
      await new Promise((r) => setTimeout(r, 100));
    }

    // Update campaign record
    await campaignRef.update({
      sentCount: results.sent,
      failedCount: results.failed,
      status: "completed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update template usage
    await db
      .collection("bullet_templates")
      .doc(templateId)
      .update({
        usageCount: admin.firestore.FieldValue.increment(1),
      });

    return {
      success: true,
      campaignId: campaignRef.id,
      results,
      message: `🔫 RAILGUN FIRED! ${results.sent} emails sent, ${results.failed} failed`,
    };
  },
);

// ─── Schedule Campaign ───────────────────────────────────────────────────
const scheduleCampaign = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    const { templateId, filters, scheduledFor } = request.data;
    if (!templateId || !scheduledFor) {
      return { success: false, error: "templateId and scheduledFor required" };
    }

    const scheduleRef = await db.collection("bullet_scheduled").add({
      templateId,
      filters: filters || {},
      scheduledFor: admin.firestore.Timestamp.fromDate(new Date(scheduledFor)),
      status: "scheduled",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: request.auth?.uid || "system",
    });

    return {
      success: true,
      scheduleId: scheduleRef.id,
      message: `⏰ Campaign scheduled for ${scheduledFor}`,
    };
  },
);

// ─── Scheduled Runner (Hourly) ───────────────────────────────────────────
const bulletScheduledRunner = onSchedule(
  { schedule: "every 1 hours", region: REGION },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const dueSnap = await db
      .collection("bullet_scheduled")
      .where("status", "==", "scheduled")
      .where("scheduledFor", "<=", now)
      .limit(10)
      .get();

    for (const doc of dueSnap.docs) {
      const schedule = doc.data();

      await doc.ref.update({ status: "processing" });

      try {
        // Internal call to railgunBlast
        const blastResult = await railgunBlast.run({
          data: {
            templateId: schedule.templateId,
            filters: schedule.filters,
          },
          auth: { uid: schedule.createdBy },
        });

        await doc.ref.update({
          status: "completed",
          result: blastResult,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (err) {
        await doc.ref.update({
          status: "failed",
          error: err.message,
        });
      }
    }
  },
);

// ─── Get Campaign Stats ──────────────────────────────────────────────────
const getCampaignStats = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    const { campaignId } = request.data;

    if (campaignId) {
      const doc = await db.collection("bullet_campaigns").doc(campaignId).get();
      if (!doc.exists) return { success: false, error: "Campaign not found" };
      return { success: true, campaign: { id: doc.id, ...doc.data() } };
    }

    const campaignsSnap = await db
      .collection("bullet_campaigns")
      .orderBy("startedAt", "desc")
      .limit(50)
      .get();

    const gymsSnap = await db.collection("bullet_gyms").get();
    const regionsSnap = await db.collection("bullet_regions").get();

    const totalGyms = gymsSnap.size;
    const respondedGyms = gymsSnap.docs.filter(
      (d) => d.data().responded,
    ).length;
    const totalSent = campaignsSnap.docs.reduce(
      (sum, d) => sum + (d.data().sentCount || 0),
      0,
    );

    return {
      success: true,
      stats: {
        totalGyms,
        respondedGyms,
        responseRate:
          totalGyms > 0
            ? ((respondedGyms / totalGyms) * 100).toFixed(1) + "%"
            : "0%",
        totalCampaigns: campaignsSnap.size,
        totalEmailsSent: totalSent,
        regions: regionsSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
      },
      recentCampaigns: campaignsSnap.docs
        .slice(0, 10)
        .map((d) => ({ id: d.id, ...d.data() })),
    };
  },
);

// ─── Mark Gym Responded ──────────────────────────────────────────────────
const markGymResponded = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    const { email, notes, interested } = request.data;
    if (!email) return { success: false, error: "email required" };

    const docId = email.toLowerCase().replace(/[^a-z0-9]/g, "_");
    await db
      .collection("bullet_gyms")
      .doc(docId)
      .update({
        responded: true,
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
        responseNotes: notes || "",
        interested: interested || false,
      });

    return { success: true, message: `✅ ${email} marked as responded` };
  },
);

// ─── Get Gyms By Region ──────────────────────────────────────────────────
const getGymsByRegion = onCall(
  { region: REGION, enforceAppCheck: false },
  async (request) => {
    const { country, region, gymType, status } = request.data;

    let query = db.collection("bullet_gyms");

    if (country) query = query.where("country", "==", country);
    if (region) query = query.where("region", "==", region);
    if (gymType) query = query.where("gymType", "==", gymType);
    if (status) query = query.where("status", "==", status);

    const snap = await query.limit(500).get();

    return {
      success: true,
      count: snap.size,
      gyms: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
    };
  },
);

// ─── Seed AU/NZ Gym Templates ────────────────────────────────────────────
const seedAUNZGymTemplates = onCall(
  { region: REGION, enforceAppCheck: false },
  async () => {
    const templates = [
      {
        id: "gym_intro_au",
        name: "AU Gym Introduction",
        subject: "{{gymName}} — Free fighter profiles & event promotion",
        htmlBody: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #00D9FF;">G'day {{name}}!</h2>
          <p>I'm reaching out to {{gymName}} because we're building something special for the Australian combat sports community.</p>
          <p><strong>Data Fight Central</strong> is a free platform that gives your fighters:</p>
          <ul>
            <li>✅ Professional fighter profiles (like LinkedIn for fighters)</li>
            <li>✅ Training analytics & performance tracking</li>
            <li>✅ Event discovery & matchmaking</li>
            <li>✅ Free promotion for your gym's events</li>
          </ul>
          <p>We're not charging gyms anything. Our mission is athlete safety and growing grassroots combat sports in Australia.</p>
          <p><a href="https://datafightcentral.web.app/gym-signup?ref={{city}}" style="background: #00D9FF; color: black; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Register Your Gym (Free)</a></p>
          <p>Would love to chat about how we can support {{gymName}}.</p>
          <p>Cheers,<br><strong>Joseph</strong><br>Founder, Data Fight Central</p>
        </div>
      `,
        tags: ["intro", "AU", "gym"],
      },
      {
        id: "gym_intro_nz",
        name: "NZ Gym Introduction",
        subject: "{{gymName}} — Free fighter profiles & event promotion",
        htmlBody: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #00D9FF;">Kia ora {{name}}!</h2>
          <p>I'm reaching out to {{gymName}} because we're building something special for NZ combat sports.</p>
          <p><strong>Data Fight Central</strong> is a free platform that gives your fighters:</p>
          <ul>
            <li>✅ Professional fighter profiles</li>
            <li>✅ Training analytics & performance tracking</li>
            <li>✅ Event discovery & matchmaking</li>
            <li>✅ Free promotion for your gym's events</li>
          </ul>
          <p>We're not charging gyms anything. Our mission is athlete safety and growing grassroots combat sports across NZ.</p>
          <p><a href="https://datafightcentral.web.app/gym-signup?ref={{city}}" style="background: #00D9FF; color: black; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Register Your Gym (Free)</a></p>
          <p>Would love to yarn about how we can support {{gymName}}.</p>
          <p>Chur,<br><strong>Joseph</strong><br>Founder, Data Fight Central</p>
        </div>
      `,
        tags: ["intro", "NZ", "gym"],
      },
      {
        id: "event_promo",
        name: "Event Promotion Offer",
        subject: "Free event promotion for {{gymName}}",
        htmlBody: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #FFD600;">🥊 Got an event coming up?</h2>
          <p>Hey {{name}},</p>
          <p>We'll promote your next fight night to thousands of combat sports fans — <strong>completely free</strong>.</p>
          <p>Data Fight Central features:</p>
          <ul>
            <li>🎬 Video highlights shared across our channels</li>
            <li>📱 Event listing to 10,000+ followers</li>
            <li>🎫 Ticketing integration (optional)</li>
            <li>📊 Post-event analytics</li>
          </ul>
          <p><a href="https://datafightcentral.web.app/submit-event" style="background: #FFD600; color: black; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Submit Your Event</a></p>
          <p>Let's put {{gymName}} on the map.</p>
          <p>— DFC Team</p>
        </div>
      `,
        tags: ["event", "promo"],
      },
      {
        id: "followup_1",
        name: "First Follow-up",
        subject: "Quick follow-up — {{gymName}}",
        htmlBody: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <p>Hey {{name}},</p>
          <p>Just following up on my previous email about Data Fight Central.</p>
          <p>I know you're busy running {{gymName}}, so I'll keep it short:</p>
          <p><strong>We help gyms like yours get more visibility — for free.</strong></p>
          <p>5 minutes to set up. Zero cost. Full control of your gym's profile.</p>
          <p><a href="https://datafightcentral.web.app/gym-signup" style="color: #00D9FF;">→ Quick signup here</a></p>
          <p>Happy to jump on a call if you have questions.</p>
          <p>Cheers,<br>Joseph</p>
        </div>
      `,
        tags: ["followup"],
      },
    ];

    const batch = db.batch();
    for (const t of templates) {
      const ref = db.collection("bullet_templates").doc(t.id);
      batch.set(ref, {
        name: t.name,
        subject: t.subject,
        htmlBody: t.htmlBody,
        tags: t.tags,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        usageCount: 0,
      });
    }
    await batch.commit();

    return {
      success: true,
      message: "📝 4 campaign templates seeded",
      templates: templates.map((t) => t.id),
    };
  },
);

module.exports = {
  bulletSystemInit,
  loadGymContacts,
  createCampaignTemplate,
  railgunBlast,
  scheduleCampaign,
  bulletScheduledRunner,
  getCampaignStats,
  markGymResponded,
  getGymsByRegion,
  seedAUNZGymTemplates,
};
