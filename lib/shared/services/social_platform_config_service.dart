import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL PLATFORM CONFIG SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Centralized source of truth for all DFC social platform configuration.
/// Screens read from here — never hardcode handles, URLs, or platform data
/// inside UI widgets.
///
/// Sections:
///  1. DFC's own social handles (all 8 platforms)
///  2. Platform strategy definitions (what DFC does on each platform)
///  3. Partner fight org social handles & partnership roles
///  4. Promo campaign templates (carousel content)
///  5. AI engine toggle defaults
/// ═══════════════════════════════════════════════════════════════════════════

class SocialPlatformConfigService {
  SocialPlatformConfigService._();

  // ─────────────────────────────────────────────────────────────────────────
  // 1. DFC SOCIAL HANDLES — Single source of truth
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<String, String> dfcHandles = {
    'facebook': 'https://www.facebook.com/datafightcentral',
    'instagram': 'https://www.instagram.com/datafightcentral',
    'tiktok': 'https://www.tiktok.com/@datafightcentral',
    'youtube': 'https://www.youtube.com/@datafightcentral',
    'x': 'https://x.com/datafightcentral',
    'whatsapp': 'https://whatsapp.com/channel/dfc',
    'linkedin': 'https://www.linkedin.com/company/datafightcentral',
    'snapchat': 'https://www.snapchat.com/add/datafightcentral',
  };

  static const Map<String, String> dfcShortHandles = {
    'facebook': 'facebook.com/datafightcentral',
    'instagram': 'instagram.com/datafightcentral',
    'tiktok': 'tiktok.com/@datafightcentral',
    'youtube': 'youtube.com/@datafightcentral',
    'x': 'x.com/datafightcentral',
    'whatsapp': 'whatsapp.com/channel/dfc',
    'linkedin': 'linkedin.com/company/datafightcentral',
    'snapchat': 'snapchat.com/add/datafightcentral',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // PARTNER SOCIAL HANDLES
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<String, String> ultimateLegendsHandles = {
    'facebook': 'https://www.facebook.com/ultimatelegendsau',
    'instagram': 'https://www.instagram.com/ultimatelegendspromotions/',
    'website': 'https://ultimatelegends.com.au',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // 2. PLATFORM STRATEGY DEFINITIONS
  // ─────────────────────────────────────────────────────────────────────────

  static List<SocialPlatformDef> get platforms => const [
    SocialPlatformDef(
      name: 'Facebook',
      icon: '  f',
      color: Color(0xFF1877F2),
      tagline: 'Community • Events • Live',
      strategy:
          'DFC communities grow fastest on Facebook. Events, groups, watch parties — the algorithm loves fight content.',
      plays: [
        'Fight Night Watch Parties',
        'Local Fighter Features',
        'Event RSVP Campaigns',
        'Sponsor Shoutout Posts',
        'Training Tip Series',
      ],
      handle: 'facebook.com/datafightcentral',
    ),
    SocialPlatformDef(
      name: 'Instagram',
      icon: '📸',
      color: Color(0xFFE1306C),
      tagline: 'Visual • Reels • Stories',
      strategy:
          'Instagram is the fighter showcase. High-quality fight photos + Reels of knockouts = exponential reach.',
      plays: [
        'Fighter Highlight Reels',
        'Behind-the-Scenes Stories',
        'Weigh-In Countdown',
        'Collab With Local Gyms',
        'AI-Generated Event Posters',
      ],
      handle: 'instagram.com/datafightcentral',
    ),
    SocialPlatformDef(
      name: 'TikTok',
      icon: '🎵',
      color: Color(0xFFFF2D55),
      tagline: 'Viral • Short Form • Youth',
      strategy:
          'TikTok moves fastest. DFC posts training clips, fight predictions, fighter day-in-life — native, raw, unfiltered.',
      plays: [
        '30s Fight Highlights',
        'Fighter Lifestyle Vlogs',
        '"Predict the Winner" Polls',
        'AI Fight Analysis Clips',
        'Gym Tour Shorts',
      ],
      handle: 'tiktok.com/@datafightcentral',
    ),
    SocialPlatformDef(
      name: 'YouTube',
      icon: '▶️',
      color: Color(0xFFFF0000),
      tagline: 'Long Form • SEO • Archive',
      strategy:
          "YouTube is the truth machine — long events, full fights, deep dives. DFC's permanent content library.",
      plays: [
        'Full Event Broadcasts',
        'Fighter Documentaries',
        'Technique Breakdowns',
        'Nutrition & Training Srs',
        'Post-Fight Analysis',
      ],
      handle: 'youtube.com/@datafightcentral',
    ),
    SocialPlatformDef(
      name: 'X / Twitter',
      icon: '𝕏',
      color: Color(0xFF1D9BF0),
      tagline: 'Real-Time • News • Debate',
      strategy:
          'X is where fight debates happen. Live fight commentary, breaking news, fighter quotes, instant reaction.',
      plays: [
        'Live Fight Commentary',
        'Breaking Fight News',
        'Poll Predictions',
        'Promoter AMAs',
        'Injury/Result Updates',
      ],
      handle: 'x.com/datafightcentral',
    ),
    SocialPlatformDef(
      name: 'WhatsApp',
      icon: '💬',
      color: Color(0xFF25D366),
      tagline: 'Direct • Groups • Trust',
      strategy:
          'WhatsApp channels build the highest-trust audience. Fighters, fans and gyms get DFC news first.',
      plays: [
        'Event Alerts Channel',
        'Fighter Direct Messaging',
        'Gym Owner Groups',
        'Ticket Flash Sales',
        'VIP Early Access',
      ],
      handle: 'whatsapp.com/channel/dfc',
    ),
    SocialPlatformDef(
      name: 'LinkedIn',
      icon: '💼',
      color: Color(0xFF0A66C2),
      tagline: 'B2B • Sponsors • Careers',
      strategy:
          "LinkedIn is the sponsor gateway. DFC's professional face — investor updates, career paths in fight sports.",
      plays: [
        'Sponsor Case Studies',
        'Fighter Career Profiles',
        'Industry News',
        'Partnership Proposals',
        'Event ROI Reports',
      ],
      handle: 'linkedin.com/company/datafightcentral',
    ),
    SocialPlatformDef(
      name: 'Snapchat',
      icon: '👻',
      color: Color(0xFFFFFC00),
      tagline: 'AR • Youth • Stories',
      strategy:
          'Snapchat AR lenses let fans become their favourite fighters. DFC filters at live events go viral instantly.',
      plays: [
        'Fighter AR Lenses',
        'Event Geofilters',
        'Snap Map Fight Events',
        'Exclusive Fight Stories',
        'Behind The Rope Access',
      ],
      handle: 'snapchat.com/add/datafightcentral',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // 3. PARTNER FIGHT ORG DEFINITIONS
  // ─────────────────────────────────────────────────────────────────────────

  static List<FightOrgDef> get fightOrgs => const [
    FightOrgDef(
      emoji: '🌟',
      name: 'Share Legends',
      fullName: 'Talent Showcase & Community Funnel',
      strategy:
          'Share Legends is the social proof engine for DFC: short clips, fighter stories, and community wins that convert casual viewers into loyal supporters.',
      color: Color(0xFF00E5FF),
      socials: {
        'Facebook': 'Share Legends',
        'Instagram': '@sharelegends',
        'YouTube': 'Share Legends Live',
        'DFC': '/social-connectors',
      },
      partnerRole: 'Partner: Social Proof to DFC Conversion',
    ),
    FightOrgDef(
      emoji: '🥊',
      name: 'Bunty Boxer',
      fullName: 'Fighter Creator & Community Builder',
      strategy:
          'Bunty Boxer content can be used as a talent magnet: hero clips, training culture, and match-day stories that route fans into DFC profiles, events, and paid streams.',
      color: Color(0xFFFFAB00),
      socials: {
        'Facebook': 'Bunty Boxer',
        'Instagram': '@buntyboxer',
        'YouTube': 'Bunty Boxer',
        'DFC': '/discovery',
      },
      partnerRole: 'Partner: Talent Spotlight & Audience Growth',
    ),
    FightOrgDef(
      emoji: '👑',
      name: 'Ultimate Legends Promotions',
      fullName: 'Show Promotion • Legacy Build',
      strategy:
          'Ultimate Legends campaign strategy: publish legacy highlights, upcoming bout teasers, then drive audience to DFC PPV singles + main event offers.',
      color: Color(0xFFFF6B00),
      socials: {
        'Facebook': 'Ultimate Legends Promotions',
        'Instagram': '@ultimatelegendspromotions',
        'YouTube': 'Show Legends Live',
        'DFC': '/ppv/store',
      },
      partnerRole: 'Partner: Legends Campaign Conversion',
    ),
    FightOrgDef(
      emoji: '🏆',
      name: 'UFC',
      fullName: 'Ultimate Fighting Championship',
      strategy:
          'The world\'s largest MMA promotion. 40+ events/year. 700M+ reach. DFC partners with UFC content teams for co-promotion of regional fighters breaking through to world level.',
      color: Color(0xFFD4002C),
      socials: {
        'Instagram': '@ufc',
        'TikTok': '@ufc',
        'X': '@ufc',
        'YouTube': 'UFC',
        'Facebook': 'ufc',
        'LinkedIn': 'ultimate-fighting-championship',
      },
      partnerRole: 'Partner: Regional Fighter Pipeline',
    ),
    FightOrgDef(
      emoji: '⭐',
      name: 'ONE Championship',
      fullName: 'Largest Asian Martial Arts Org',
      strategy:
          'Dominant in Asia with Muay Thai, kickboxing, wrestling, MMA. ONE\'s social-first strategy aligns perfectly with DFC\'s model. Fighter crossover opportunities are massive.',
      color: Color(0xFFFF6B00),
      socials: {
        'Instagram': '@onechampionship',
        'TikTok': '@onechampionship',
        'X': '@onechampionship',
        'YouTube': 'ONE Championship',
        'Facebook': 'ONEChampionship',
      },
      partnerRole: 'Partner: Asian Market Expansion',
    ),
    FightOrgDef(
      emoji: '🥊',
      name: 'Bellator MMA',
      fullName: 'Paramount Global Fight Brand',
      strategy:
          'Strong European and US roster. Bellator\'s open-division format creates paths for DFC-tracked fighters. Co-branded event promotions at regional level.',
      color: Color(0xFF005BAC),
      socials: {
        'Instagram': '@bellatormma',
        'TikTok': '@bellatormma',
        'X': '@bellatormma',
        'YouTube': 'BellatorMMA',
        'Facebook': 'BellatorMMA',
      },
      partnerRole: 'Partner: Open Division Pathway',
    ),
    FightOrgDef(
      emoji: '🔥',
      name: 'PFL — Pro Fighters League',
      fullName: 'Season Format MMA',
      strategy:
          'PFL\'s data-driven season format mirrors DFC\'s analytics philosophy. Fighter salaries are transparent. DFC tracks PFL fighters and broadcasts their journey.',
      color: Color(0xFF00A86B),
      socials: {
        'Instagram': '@pfl',
        'TikTok': '@pfl',
        'X': '@pflmma',
        'YouTube': 'PFL MMA',
        'Facebook': 'PFLmma',
      },
      partnerRole: 'Partner: Data & Analytics Crossover',
    ),
    FightOrgDef(
      emoji: '✊',
      name: 'BKFC — Bare Knuckle FC',
      fullName: 'Fastest Growing Fight Sport',
      strategy:
          'BKFC\'s raw, unfiltered product resonates with DFC\'s authentic fight culture. DFC promotes BKFC events through the grassroots fight community network.',
      color: Color(0xFFCC0000),
      socials: {
        'Instagram': '@bareknucklefc',
        'TikTok': '@bkfc',
        'X': '@bareknucklefc',
        'YouTube': 'Bare Knuckle Fighting Championship',
        'Facebook': 'BareKnuckleFightingChampionship',
      },
      partnerRole: 'Partner: Core Fight Fan Base',
    ),
    FightOrgDef(
      emoji: '🌸',
      name: 'RIZIN Fighting Federation',
      fullName: 'Japan\'s Premier MMA Org',
      strategy:
          'RIZIN\'s spectacle-style events and Japan\'s fanatical fight culture give DFC access to the world\'s most dedicated martial arts audience.',
      color: Color(0xFFE91E8C),
      socials: {
        'Instagram': '@rizin_pr',
        'X': '@rizin_pr',
        'YouTube': 'RIZIN FF',
        'Facebook': 'rizinfightingfederation',
      },
      partnerRole: 'Partner: Japan & Asia Pacific',
    ),
    FightOrgDef(
      emoji: '⚡',
      name: 'Glory Kickboxing',
      fullName: 'World\'s #1 Kickboxing Org',
      strategy:
          'Glory bridges DFC to the striking arts world. DFC tracks and profiles Glory fighters, expanding the platform beyond MMA into all combat sports.',
      color: Color(0xFF7B2FBE),
      socials: {
        'Instagram': '@glorykickboxing',
        'X': '@glorykickboxing',
        'YouTube': 'Glory Kickboxing',
        'Facebook': 'glorykickboxing',
      },
      partnerRole: 'Partner: Striking Arts Community',
    ),
    FightOrgDef(
      emoji: '🐉',
      name: 'KSW — Konfrontacja Sztuk Walki',
      fullName: 'Europe\'s Largest MMA Org',
      strategy:
          'KSW dominates Central & Eastern Europe. DFC\'s global rankings platform gives KSW fighters international visibility beyond the European market.',
      color: Color(0xFF1565C0),
      socials: {
        'Instagram': '@kswmma',
        'X': '@kswmma',
        'YouTube': 'KSW',
        'Facebook': 'kswmma',
      },
      partnerRole: 'Partner: European Fighter Network',
    ),
    FightOrgDef(
      emoji: '🥋',
      name: 'UFC Fight Pass Partners',
      fullName: 'Regional Orgs on Fight Pass',
      strategy:
          'Cage Titans, LFA, ROAD FC, ACB/ACA, Brave CF, Thailand Super Series — DFC tracks fighters from all Fight Pass-affiliated orgs, building profiles before they reach the top.',
      color: Color(0xFFFF8F00),
      socials: {
        'Instagram': '@ufcfightpass',
        'YouTube': 'UFC Fight Pass',
        'Facebook': 'UFCFightPass',
      },
      partnerRole: 'Partner: Fighter Discovery & Scouting',
    ),
    FightOrgDef(
      emoji: '🌍',
      name: 'African & Emerging Market Orgs',
      fullName: 'Talent Pipeline',
      strategy:
          'EFC (Africa), UAE Warriors, Desert Force, IMC, Brave CF — DFC is the connective tissue bringing emerging market fighters to global attention. Where talent is born before the world knows it.',
      color: Color(0xFF00BFA5),
      socials: {
        'Instagram': '@efcworldwide',
        'YouTube': 'EFC Worldwide',
        'Facebook': 'efcworldwide',
      },
      partnerRole: 'Partner: Global Talent Discovery',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // 4. PROMO CAMPAIGN TEMPLATES
  // ─────────────────────────────────────────────────────────────────────────

  static List<PromoCampaignDef> get promoCampaigns => const [
    PromoCampaignDef(
      title: '🇮🇳 INDIA HATCH LAB: BUILD THE NEXT WAVE',
      body:
          'Activate social + economic growth with AI squads and local creator funnels.',
      cta: 'HATCH NOW',
      color: Color(0xFF00E676),
    ),
    PromoCampaignDef(
      title: '🔥 ULTIMATE LEGENDS: FIGHT WEEK IS LIVE',
      body:
          'Push fighter story clips now, then route fans to PPV singles and main event.',
      cta: 'PUSH NOW',
      color: Color(0xFFFFAB00),
    ),
    PromoCampaignDef(
      title: '🌟 SHARE LEGENDS TALENT DROP',
      body:
          'Bunty Boxer + community champions. Build social trust, then convert inside DFC.',
      cta: 'OPEN LEGENDS',
      color: Color(0xFF00E5FF),
    ),
    PromoCampaignDef(
      title: '🥊 FIGHT NIGHT — JAKARTA',
      body: 'March 8 | 8 Featured Bouts | Live on DFC',
      cta: 'BUY TICKETS',
      color: Color(0xFFFF1744),
    ),
    PromoCampaignDef(
      title: '🏆 DFC AMATEUR CHAMPIONSHIPS',
      body: 'Open Registration — 6 Weight Classes',
      cta: 'REGISTER NOW',
      color: Color(0xFFFFAB00),
    ),
    PromoCampaignDef(
      title: '💊 FIGHTER NUTRITION PLAN',
      body: 'AI-Generated 12-Week Cut/Bulk Protocol',
      cta: 'GET YOUR PLAN',
      color: Color(0xFF00E676),
    ),
    PromoCampaignDef(
      title: '🌍 REPOWER HUMANITY FUND',
      body: 'Every DFC ticket sold donates to clean energy',
      cta: 'LEARN MORE',
      color: Color(0xFF00E5FF),
    ),
    PromoCampaignDef(
      title: '🤖 AI FIGHT PREDICTOR',
      body: 'Our model called the last 14/16 main events',
      cta: 'TEST THE AI',
      color: Color(0xFFD500F9),
    ),
    PromoCampaignDef(
      title: '🎓 DFC COACHING CERTIFICATION',
      body: 'World-recognised. Online. 8 weeks.',
      cta: 'ENROLL',
      color: Color(0xFF2979FF),
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // 5. AI ENGINE TOGGLE DEFAULTS
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, bool> get defaultAiToggles => {
    'Auto-post fight results (verified only)': true,
    'AI caption writer (platform-native tone)': true,
    'Cross-platform scheduler': false,
    'Honest performance reporting': true,
    'Smart hashtag engine': true,
    'Engagement response AI (never fake)': false,
    'Competitor gap analysis': false,
    'Viral moment detector': true,
  };

  // ─────────────────────────────────────────────────────────────────────────
  // 6. COMMUNITY VALUES — The DFC Ecosystem Promise
  // ─────────────────────────────────────────────────────────────────────────
  // No keyboard warriors. No degrading fighters. No defamation.
  // Adrenaline is the gateway to health. We protect our people.

  static const String ecosystemMission =
      'DFC is a social media app where fighters connect with fans and fans '
      'connect with fighters — creating a healthier ecosystem that promotes '
      'good health, wellbeing, and uses the adrenaline of combat sports as a '
      'gateway to better living. No keyboard warriors. No putting people down. '
      'Every interaction builds someone up.';

  static const List<String> communityPillars = [
    'RESPECT — Every fighter who steps in the ring deserves respect, win or lose',
    'CONNECT — Fighters talk to fans directly, fans support fighters genuinely',
    'HEALTH — Combat sports channel adrenaline into fitness, discipline, purpose',
    'WELLBEING — Mental health resources, recovery support, community care',
    'PROTECT — Zero tolerance: no bullying, no defamation, no keyboard warriors',
    'GROW — Better humans through martial arts, better communities through sport',
  ];

  static const List<String> zeroTolerancePolicies = [
    'No degrading or defaming fighters — instant moderation',
    'No keyboard warriors — critique technique, never attack the person',
    'No harassment of athletes, coaches, referees, or event staff',
    'No doxxing or sharing personal information without consent',
    'No hate speech, racism, sexism, or discrimination of any kind',
    'No fake accounts impersonating fighters or promoters',
    'No predatory gambling promotion targeting vulnerable users',
    'No glorifying violence outside the sanctioned sporting context',
  ];

  /// Adrenaline Gateway: how combat sports drive positive health outcomes
  static const Map<String, String> adrenalineGatewayBenefits = {
    'Physical Fitness':
        'Combat training builds strength, cardio, flexibility and discipline — '
        'the full-body workout that keeps you coming back because it is never boring.',
    'Mental Resilience':
        'Facing an opponent teaches you to face life. Stress management, '
        'focus under pressure, and confidence that transfers to everything else.',
    'Community Bond':
        'Training partners become family. Gyms become second homes. '
        'DFC connects that local bond to a global fight community.',
    'Adrenaline Health':
        'Controlled adrenaline through sport reduces anxiety, improves '
        'sleep, and creates natural endorphin cycles — healthier than any substance.',
    'Purpose & Identity':
        'Fighters find meaning through discipline. Fans find belonging '
        'through community. Everyone grows through the shared experience.',
    'Recovery & Support':
        'When the adrenaline stops, DFC is still there. Mental health '
        'resources, retirement support, and peer networks for life after fighting.',
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class SocialPlatformDef {
  final String name;
  final String icon;
  final Color color;
  final String tagline;
  final String strategy;
  final List<String> plays;
  final String handle;

  const SocialPlatformDef({
    required this.name,
    required this.icon,
    required this.color,
    required this.tagline,
    required this.strategy,
    required this.plays,
    required this.handle,
  });
}

class FightOrgDef {
  final String emoji;
  final String name;
  final String fullName;
  final String strategy;
  final Color color;
  final Map<String, String> socials;
  final String partnerRole;

  const FightOrgDef({
    required this.emoji,
    required this.name,
    required this.fullName,
    required this.strategy,
    required this.color,
    required this.socials,
    required this.partnerRole,
  });
}

class PromoCampaignDef {
  final String title;
  final String body;
  final String cta;
  final Color color;

  const PromoCampaignDef({
    required this.title,
    required this.body,
    required this.cta,
    required this.color,
  });
}
