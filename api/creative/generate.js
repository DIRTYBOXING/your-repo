const fs = require("node:fs");
const path = require("node:path");

function loadTemplateCatalog() {
  try {
    const filePath = path.join(
      __dirname,
      "..",
      "..",
      "assets",
      "poster_templates",
      "templates.json",
    );
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return { version: 1, templates: [] };
  }
}

function chooseTemplate({ sportType, limitedEdition }) {
  if (limitedEdition) return "legacy_gold";
  const sport = (sportType || "").toLowerCase();
  if (sport.includes("boxing")) return "mono_impact";
  if (sport.includes("kick") || sport.includes("muay")) {
    return "velocity_stripes";
  }
  if (sport.includes("bare") || sport.includes("bkfc")) {
    return "grit_duotone";
  }
  return "neon_arena";
}

async function generateCreativeHandler(req, res) {
  const {
    eventId,
    eventTitle,
    fighterNames = [],
    eventDate,
    venue,
    sportType,
    sponsorLogos = [],
    limitedEdition = false,
  } = req.body || {};

  if (!eventId || !eventTitle) {
    return res.status(400).json({
      error: "eventId and eventTitle are required",
    });
  }

  const catalog = loadTemplateCatalog();
  const templateKey = chooseTemplate({ sportType, limitedEdition });
  const template =
    catalog.templates.find((item) => item.id === templateKey) || null;

  const payload = {
    eventId,
    generatedAt: new Date().toISOString(),
    templateKey,
    requiresReview: true,
    reviewStatus: "pending",
    reviewMode: "admin_required",
    template,
    creative: {
      poster: {
        title: eventTitle,
        subtitle: fighterNames.slice(0, 2).join(" vs ") || "Main Event",
        venue: venue || "Venue TBA",
        eventDate: eventDate || null,
        sportType: sportType || "MMA",
        sponsorLogos,
        renderHints: {
          aspectRatio: "2:3",
          includeQrCode: true,
          includeBuyCta: true,
          ctaLabel: "Watch Live on DFC",
        },
      },
      socialTiles: [
        {
          ratio: "1:1",
          headline: `${eventTitle} goes live`,
          cta: "Tap to unlock access",
        },
        {
          ratio: "9:16",
          headline: fighterNames.slice(0, 2).join(" vs ") || eventTitle,
          cta: "Fight night starts here",
        },
      ],
      thumbnail: {
        headline: eventTitle,
        badge: limitedEdition ? "Collector Drop" : "Live PPV",
      },
      copyVariants: [
        {
          id: `${eventId}-copy-hero`,
          tone: "bold_urgent",
          text: `${eventTitle} live on DFC. Lock your seat before the walkouts begin.`,
        },
        {
          id: `${eventId}-copy-sponsor`,
          tone: "sponsor_forward",
          text: sponsorLogos.isNotEmpty
              ? `${eventTitle} presented with sponsor support and premium fight-week access.`
              : `${eventTitle} lands with premium access, replay rights, and fight-week urgency.`,
        },
        {
          id: `${eventId}-copy-community`,
          tone: "community_forward",
          text: `${eventTitle} powers fight-night commerce while backing gym and community momentum.`,
        },
      ],
    },
    dataTest: {
      templateKey,
      posterMetadata: `data-test=poster-template-${templateKey}`,
    },
  };

  return res.json(payload);
}

module.exports = {
  generateCreativeHandler,
};
