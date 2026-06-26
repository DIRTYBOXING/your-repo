// ─────────────────────────────────────────────────────────────
// DFC Social Config — Constants and channel configuration
// Used by serverless functions and automation scripts.
//
// SECURITY: Tokens must NEVER be hard-coded here.
//           Use env vars / GitHub Secrets / cloud secret manager.
// ─────────────────────────────────────────────────────────────

export const SOCIAL_CONFIG = {
  // ── Brand identity ──
  brand: {
    name: "DataFight Central (DFC)",
    website: "www.datafightcentral.com",
    legalEmail: "legal@datafightcentral.com",
    senderName: "DFC Team — DataFight Central",
    logo: "assets/icons/dfc_logo.png",
  },

  // ── Channel endpoints ──
  channels: {
    email: {
      enabled: true,
      provider: "sendgrid",
      // SENDGRID_API_KEY from env
    },
    messenger: {
      enabled: false, // flip to true once Page token is set
      platform: "facebook",
      pageUrl: "https://www.facebook.com/DataFightCentral",
      messengerUrl: "m.me/DataFightCentral",
      apiBase: "https://graph.facebook.com/v19.0",
      // FB_PAGE_ID and FB_PAGE_ACCESS_TOKEN from env
    },
    instagram: {
      enabled: false, // flip to true once IG Business token is set
      platform: "instagram",
      apiBase: "https://graph.facebook.com/v19.0",
      // IG_BUSINESS_ACCOUNT_ID and IG_ACCESS_TOKEN from env
    },
  },

  // ── DM templates (map to files in tools/social_templates/) ──
  dmTemplates: {
    messenger_promoter_initial:
      "tools/social_templates/messenger_promoter_initial.txt",
    messenger_promoter_followup:
      "tools/social_templates/messenger_promoter_followup.txt",
    messenger_gym_shields: "tools/social_templates/messenger_gym_shields.txt",
    instagram_promoter_initial:
      "tools/social_templates/instagram_promoter_initial.txt",
    instagram_promoter_followup:
      "tools/social_templates/instagram_promoter_followup.txt",
    instagram_gym_shields: "tools/social_templates/instagram_gym_shields.txt",
  },

  // ── Post templates ──
  postTemplates: {
    event_announcement: "tools/social_templates/post_event_announcement.txt",
    gym_spotlight: "tools/social_templates/post_gym_spotlight.txt",
  },

  // ── Follow-up schedule (days after initial send) ──
  followUpSchedule: {
    firstFollowUp: 3,
    secondFollowUp: 7,
  },

  // ── Audit / logging ──
  logging: {
    emailLogDir: "docs/legal/email_logs",
    emailFailureDir: "docs/legal/email_failures",
    socialLogDir: "docs/legal/social_logs",
  },

  // ── Safety rules ──
  rules: {
    onlyContactListedPromoters: true,
    onlyContactOptedInGyms: true,
    sponsoredGymsOnly: true, // Shields/extra ads only for sponsored=yes
    requireSignedReleaseBeforeMedia: true,
    moderationPauseOnFlaggedReply: true,
    domainValidateExternalLinks: true,
  },
};

export default SOCIAL_CONFIG;
