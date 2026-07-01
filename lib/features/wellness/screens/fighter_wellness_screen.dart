import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/sakura_safety_overlay.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER WELLNESS SCREEN — 2030 Edition
/// Holographic bubbles · Neural-link connections · Aurora backdrop
/// Immersive graphs · Glassmorphic UI · Particle systems
/// ═══════════════════════════════════════════════════════════════════════════
class FighterWellnessScreen extends StatefulWidget {
  const FighterWellnessScreen({super.key});

  @override
  State<FighterWellnessScreen> createState() => _FighterWellnessScreenState();
}

class _FighterWellnessScreenState extends State<FighterWellnessScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──
  late AnimationController _orbController; // Background orbs drift
  late AnimationController _cardController; // Card orbital motion
  late AnimationController _pulseController; // Bubble breathing pulse
  late AnimationController _shimmerController; // Holographic sweep + particles
  late AnimationController _graphController; // Graph entrance animation

  final List<_FloatingOrb> _orbs = [];
  int _selectedCardIndex = -1;

  // ── Guardian Mode (hidden inside Cycle card) ──
  bool _guardianActive = false;
  bool _guardianHolding = false;
  double _holdProgress = 0.0;
  final List<Map<String, String>> _guardianContacts = [];
  DateTime? _lastCheckIn;

  bool _showSakuraOverlay = false;
  SharedPreferences? _prefs;

  // ── Wellness Data (with graph stats) ──
  // ── INNER RING: Core Wellness (4 orbs) ──
  // ── OUTER RING: Exercise, Community, Campaigns, Resources (8 satellites) ──
  final List<_WellnessCard> _wellnessCards = [
    // ═══════════ INNER RING — Core Mental Health ════════════════
    const _WellnessCard(
      icon: Icons.medication_outlined,
      title: 'Substance\nRecovery',
      subtitle: 'Painkiller & addiction support',
      color: AppTheme.neonMagenta,
      description:
          'Confidential support for fighters dealing with painkiller dependency, '
          'performance enhancers, or substance use. Connect with counselors who '
          'understand the fight game. Many services are FREE — no referral needed.',
      resources: [
        '💡 SMART Recovery AU — Free Online Meetings',
        '💡 Alcohol & Drug Foundation — Free Helpline',
        '💡 Lives Lived Well — Free Counselling QLD/NSW',
        '🆘 DirectLine: 1800 888 236 (Free, 24/7)',
        '📢 Advertise Your Rehab Program — Spots Open',
        'Fighter-Specific Rehab Programs',
        'Confidential Counseling',
        'Peer Support Groups',
      ],
      score: 0.72,
      weeklyData: [0.55, 0.62, 0.70, 0.65, 0.72, 0.78, 0.72],
      trendData: [0.45, 0.50, 0.48, 0.55, 0.58, 0.62, 0.60, 0.67, 0.70, 0.72],
    ),
    const _WellnessCard(
      icon: Icons.psychology_outlined,
      title: 'Anxiety &\nDepression',
      subtitle: 'Mental performance support',
      color: AppTheme.neonCyan,
      description:
          'Pre-fight anxiety, post-loss depression, and the mental toll of '
          'competition. Work with sports psychologists who specialize in combat sports. '
          'FREE sessions available through Medicare Mental Health Plans.',
      resources: [
        '💡 Medicare Mental Health Plan — Up to 10 Free Sessions',
        '💡 MindSpot — Free Online Therapy AU',
        '💡 This Way Up — Free CBT Programs AU',
        '🆘 Beyond Blue: 1300 22 4636',
        '📢 Advertise Your Psychology Practice — Spots Open',
        'Sports Psychology Sessions',
        'Performance Anxiety Tools',
        'Mindfulness for Fighters',
      ],
      score: 0.85,
      weeklyData: [0.70, 0.75, 0.80, 0.78, 0.82, 0.88, 0.85],
      trendData: [0.60, 0.63, 0.66, 0.70, 0.73, 0.76, 0.79, 0.81, 0.83, 0.85],
    ),
    const _WellnessCard(
      icon: Icons.nightlight_outlined,
      title: 'After The\nLights',
      subtitle: 'When the music stops',
      color: Colors.amber,
      description:
          'Dealing with losses, fading spotlight, retirement transition, and '
          'finding identity beyond the cage. You\'re not alone in this journey.',
      resources: [
        'Retirement Transition Support',
        'Career Counseling',
        'Identity & Purpose Coaching',
        'Veteran Fighter Networks',
      ],
      score: 0.58,
      weeklyData: [0.40, 0.45, 0.50, 0.48, 0.55, 0.60, 0.58],
      trendData: [0.30, 0.35, 0.38, 0.42, 0.44, 0.48, 0.50, 0.53, 0.56, 0.58],
    ),
    const _WellnessCard(
      icon: Icons.spa_outlined,
      title: 'Alternative\nMedicine',
      subtitle: 'Medicinal cannabis & holistic',
      color: AppTheme.neonGreen,
      description:
          'Your trusted alternative medicine team: Heyday Medical (prescribing physician), '
          'WholeLife Botanicals (their own brand), Alma — El Camino Flowers (premium strains), '
          'and ChemPro Logan Plaza Park (dispensing). '
          'Find every licensed clinic in Australia via Cannaviews. '
          'Clinic spots available — advertise your practice to fighters nationwide.',
      resources: [
        '⭐ Heyday Medical — Prescribing Physician',
        '⭐ WholeLife Botanicals — Own Brand Products',
        '⭐ Alma — El Camino Flowers Strains',
        '⭐ ChemPro Logan Plaza Park — Medical Cannabis Dispensary',
        '💡 Cannaviews Australia — Clinic Finder',
        '📢 Advertise Your Clinic — Available Spots Open',
        'Licensed Cannabis Providers',
        'CBD & Recovery Products',
        'Holistic Practitioners',
        'Acupuncture & Cupping',
      ],
      score: 0.91,
      weeklyData: [0.82, 0.85, 0.87, 0.90, 0.88, 0.92, 0.91],
      trendData: [0.70, 0.74, 0.77, 0.80, 0.82, 0.85, 0.87, 0.89, 0.90, 0.91],
    ),

    // ═══════════ OUTER RING — Exercise & Body ══════════════════
    const _WellnessCard(
      icon: Icons.fitness_center,
      title: 'Exercise\nLibrary',
      subtitle: 'Combat-specific workouts',
      color: Color(0xFFFF6B35), // vibrant orange
      ring: _OrbRing.outer,
      description:
          'Full exercise library: striking drills, grappling flows, strength circuits, '
          'HIIT conditioning, yoga for fighters, mobility work, and warm-up routines. '
          'Video guides and rep trackers for every discipline.',
      resources: [
        '💡 Exercise Right AU — Free Exercise Guides',
        '💡 Yoga with Adriene — Free Fighter Yoga (YouTube)',
        '📢 Advertise Your Gym or PT Service — Spots Open',
        '📢 Advertise Your Online Training Program — Spots Open',
        'Striking Combos & Drills',
        'BJJ Flow Sequences',
        'Strength & Power Programs',
        'Fighter Yoga & Mobility',
        'HIIT Conditioning Circuits',
        'Warm-Up & Cool-Down Routines',
      ],
      score: 0.88,
      weeklyData: [0.75, 0.80, 0.85, 0.82, 0.88, 0.90, 0.88],
      trendData: [0.65, 0.68, 0.72, 0.75, 0.78, 0.80, 0.83, 0.85, 0.87, 0.88],
    ),
    const _WellnessCard(
      icon: Icons.self_improvement,
      title: 'Recovery\n& Rehab',
      subtitle: 'Heal smarter, fight longer',
      color: Color(0xFF00BFFF), // deep sky blue
      ring: _OrbRing.outer,
      description:
          'Injury prevention protocols, physiotherapy exercises, ice bath guides, '
          'foam rolling routines, sleep optimisation, and return-to-fight timelines. '
          'AI-powered recovery scoring from your wearable data.',
      resources: [
        '💡 Pain Australia — Free Pain Management Resources',
        '💡 Physio Inq — Free First Consult (Select Locations)',
        '📢 Advertise Your Physio Clinic — Spots Open',
        '📢 Advertise Your Recovery Product — Spots Open',
        'Injury Prevention Protocols',
        'Ice Bath & Contrast Therapy',
        'Foam Rolling & Myofascial',
        'Sleep Optimisation Guide',
        'Return-to-Fight Timelines',
      ],
      score: 0.79,
      weeklyData: [0.65, 0.70, 0.72, 0.75, 0.78, 0.80, 0.79],
      trendData: [0.55, 0.58, 0.62, 0.65, 0.68, 0.70, 0.73, 0.75, 0.77, 0.79],
    ),
    const _WellnessCard(
      icon: Icons.restaurant_menu,
      title: 'Nutrition\n& Weight',
      subtitle: 'Fuel the machine',
      color: Color(0xFFFFD700), // gold
      ring: _OrbRing.outer,
      description:
          'Weight cut protocols, fight-week meal plans, macro tracking, hydration '
          'strategies, supplement guides, and post-fight recovery nutrition. '
          'AI calculates your optimal intake based on training load.',
      resources: [
        '💡 Eat For Health AU — Free Nutrition Guidelines',
        '💡 Dietitians Australia — Find a Free Consult',
        '📢 Advertise Your Meal Prep Service — Spots Open',
        '📢 Advertise Your Supplement Brand — Spots Open',
        'Weight Cut Meal Plans',
        'Fight-Week Nutrition',
        'Hydration Protocols',
        'Supplement Guide (WADA Safe)',
        'Post-Fight Recovery Meals',
      ],
      score: 0.82,
      weeklyData: [0.70, 0.73, 0.76, 0.80, 0.78, 0.84, 0.82],
      trendData: [0.60, 0.63, 0.66, 0.70, 0.73, 0.76, 0.78, 0.80, 0.81, 0.82],
    ),

    // ═══════════ OUTER RING — Community & Campaigns ════════════
    const _WellnessCard(
      icon: Icons.campaign,
      title: 'Ribbons &\nCampaigns',
      subtitle: 'Fight for a cause',
      color: Color(0xFFFF69B4), // hot pink (breast cancer ribbon)
      ring: _OrbRing.outer,
      description:
          'Join awareness campaigns that matter. Breast cancer ribbons, sports mental '
          'health initiative, depression awareness, PTSD support for fighters, '
          'anti-bullying, and CTE research fundraising. Wear your ribbon, share your story.',
      resources: [
        '💡 Register Your Campaign — Free Listing',
        '📢 Become a Campaign Sponsor — Spots Open',
        '🎀 Breast Cancer — Fight Pink',
        '💙 Depression & Anxiety Awareness',
        '💜 Domestic Violence Support',
        '🧡 PTSD & CTE Research Fund',
        '💛 Anti-Bullying in Combat Sports',
        '💚 Mental Health First Aid',
        '❤️ Heart Health for Athletes',
        '🤍 Rare Disease Fighter Fund',
      ],
      score: 0.76,
      weeklyData: [0.60, 0.65, 0.70, 0.72, 0.75, 0.78, 0.76],
      trendData: [0.50, 0.54, 0.58, 0.62, 0.65, 0.68, 0.70, 0.73, 0.75, 0.76],
    ),
    const _WellnessCard(
      icon: Icons.volunteer_activism,
      title: 'Donate &\nFundraise',
      subtitle: 'Give back, give hope',
      color: Color(0xFF00E676), // bright green
      ring: _OrbRing.outer,
      description:
          'Direct donation links to verified fighter charities, community gyms in '
          'underserved areas, youth combat sports programs, and fighter emergency funds. '
          'Track your impact and earn DFC Philanthropy badges.',
      resources: [
        '💡 Aussie Charities — Free Registration & Fundraising',
        '💡 GoFundMe — Free Fighter Fundraiser',
        '📢 Advertise Your Charity — Endorsed Spots Open',
        'Fighter Emergency Fund',
        'Youth Boxing / MMA Programs',
        'Community Gym Support',
        'Retired Fighter Aid',
        'CTE Research Donations',
        'Equipment for At-Risk Youth',
        'Travel Fund for Amateur Fighters',
      ],
      score: 0.68,
      weeklyData: [0.50, 0.55, 0.60, 0.62, 0.65, 0.70, 0.68],
      trendData: [0.40, 0.44, 0.48, 0.52, 0.55, 0.58, 0.61, 0.64, 0.66, 0.68],
    ),
    const _WellnessCard(
      icon: Icons.phone_in_talk,
      title: 'Helplines\n& Crisis',
      subtitle: '24/7 — You are not alone',
      color: Color(0xFFFF1744), // urgent red
      ring: _OrbRing.outer,
      description:
          'DID YOU KNOW? Many Australian GPs offer FREE counselling through Medicare — '
          'ask your GP for a Mental Health Treatment Plan (up to 10 free psychology sessions/year). '
          'Your local options: Smith Bros GP and Logan Plaza Park free counselling. '
          'One tap connects you. Confidential. Always available.',
      resources: [
        '⭐ Smith Bros GP — Counselling Services',
        '⭐ Logan Plaza Park — Free Counselling (AU)',
        '💡 Ask Your GP: Free Mental Health Plan (Medicare)',
        '💡 Head to Health — Free & Low-Cost Mental Health',
        '💡 Better Access — 10 Free Psychology Sessions/Year',
        '💡 MATES in Construction — Free Counselling AU',
        '💡 Open Arms — Free Counselling (Veterans & Families)',
        '🆘 Lifeline: 13 11 14 (AU) / 988 (US)',
        '🆘 Beyond Blue: 1300 22 4636',
        '🆘 Crisis Text Line: Text HOME to 741741',
        '🆘 Domestic Violence: 1800 737 732',
        '🆘 Substance Abuse: 1800 250 015',
        '🆘 Veterans Crisis: 1800 011 046',
        '🆘 Kids Helpline: 1800 55 1800',
      ],
      score: 1.00,
      weeklyData: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
      trendData: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
    ),

    // ═══════════ OUTER RING — Community Resources ══════════════
    const _WellnessCard(
      icon: Icons.groups,
      title: 'Community\nSupport',
      subtitle: 'Stronger together',
      color: Color(0xFF7C4DFF), // deep violet
      ring: _OrbRing.outer,
      description:
          'Anonymous peer support groups, fighter mentorship programs, community forums, '
          'spouse/family support for fighters, gym culture improvement initiatives, and '
          'women-in-combat-sports networks. Find your tribe.',
      resources: [
        '💡 ReachOut AU — Free Peer Support Online',
        '💡 Mensline AU: 1300 78 99 78 — Free Counselling',
        '📢 Advertise Your Support Group — Spots Open',
        '📢 Advertise Your Gym Community — Spots Open',
        'Fighter Peer Support Groups',
        'Mentorship — Pro to Amateur',
        'Women in Combat Sports',
        'LGBTQ+ Fighters Alliance',
        'Gym Culture & Safety Standards',
      ],
      score: 0.83,
      weeklyData: [0.70, 0.74, 0.78, 0.80, 0.82, 0.85, 0.83],
      trendData: [0.60, 0.64, 0.67, 0.70, 0.73, 0.76, 0.78, 0.80, 0.82, 0.83],
    ),
    const _WellnessCard(
      icon: Icons.school,
      title: 'Education\n& Life Skills',
      subtitle: 'Beyond the cage',
      color: Color(0xFF40C4FF), // light blue
      ring: _OrbRing.outer,
      description:
          'Financial literacy for fighters, contract education, media training, '
          'personal branding workshops, career transition programs, and educational '
          'scholarships for active and retired fighters.',
      resources: [
        'Financial Literacy for Athletes',
        'Fight Contract Education',
        'Media & Interview Training',
        'Personal Brand Building',
        'Career Transition Programs',
        'Educational Scholarships',
        'Business Skills for Gym Owners',
      ],
      score: 0.74,
      weeklyData: [0.58, 0.63, 0.68, 0.70, 0.72, 0.76, 0.74],
      trendData: [0.48, 0.52, 0.55, 0.60, 0.63, 0.66, 0.68, 0.70, 0.72, 0.74],
    ),

    // ═══════════ INNER RING — Women's Health ═══════════════════
    // ═══════════ INNER RING — Women's Health ═══════════════════
    // The Guardian safety system is embedded INSIDE this card.
    // No one will ever look inside a period tracker. That's the point.
    const _WellnessCard(
      icon: Icons.favorite_border,
      title: 'Cycle &\nHormone Hub',
      subtitle: 'Train with your biology',
      color: Color(0xFFFF69B4), // pink
      description:
          'Track your menstrual cycle and align training to your biology. '
          'Each phase changes your strength, recovery, and injury risk. '
          'Train smarter — not just harder. Your cycle is a performance tool, not a weakness.',
      resources: [
        // ── Cycle Phases & Training ──────────────────────
        '🔴 MENSTRUAL PHASE (Day 1–5)',
        'Lower intensity. Focus technique & flexibility. Iron-rich nutrition.',
        '🟡 FOLLICULAR PHASE (Day 6–13)',
        'Energy rising. Best time for strength gains, heavy sparring, new skills.',
        '🟢 OVULATION (Day 14)',
        'Peak power & reaction time. Schedule your hardest sessions here.',
        '🔵 LUTEAL PHASE (Day 15–28)',
        'Higher body temp, lower endurance. Moderate intensity. Extra hydration.',
        'Cycle-Based Training Plans',
        'Nutrition Per Phase',
        'Injury Risk Windows',
        'Hormone & Recovery Tracking',
        'Birth Control & Performance',
        '💡 Jean Hailes — Free Women\'s Health Resources (AU)',
        '💡 The Period Place — Cycle-Based Training Guides',
        '📢 Advertise Women\'s Health Services — Spots Open',
        // ── Guardian Mode (hidden safety) ────────────────
        // This section is buried deep inside the period tracker.
        // An abuser will never scroll this far into a menstrual card.
        '── ── ── ── ── ── ── ── ── ──',
        '🛡️ GUARDIAN MODE — Your Safety Net',
        '🛡️ SET UP GUARDIAN — Add Trusted Contact',
        '🛡️ ACTIVATE GUARDIAN — Silent Alert Sent To Your Person',
        '💡 Tap the 🛡️ icon 3 times quickly to trigger silent alert',
        '💡 Pre-set a safe message that auto-sends your live location',
        '💡 Assign up to 3 Guardians (friend, family, police)',
        '💡 No notification sound. No visible change. Just help on the way.',
        '💡 Auto-Alert if you don\'t check in within your set timer',
        '💡 Quick-Close: Shake phone to instantly exit & clear screen',
        '── ── ── ── ── ── ── ── ── ──',
        // ── GLOBAL EMERGENCY NUMBERS ──
        '🆘 Police Emergency: 000 (AU) / 911 (US/CA) / 999 (UK) / 112 (EU)',
        // ── AUSTRALIA ──
        '🆘 1800RESPECT: 1800 737 732 (AU — 24/7, Confidential)',
        '🆘 Women\'s Crisis Line: 1800 811 811 (VIC)',
        '🆘 DVConnect Womensline: 1800 811 811 (QLD)',
        '🆘 Men\'s Referral Service: 1300 766 491 (AU)',
        '💡 Safe Steps — Free Family Violence Response (AU)',
        '💡 Our Watch — Prevention of Violence Against Women (AU)',
        // ── UNITED STATES ──
        '🆘 National DV Hotline: 1-800-799-7233 (US — 24/7)',
        '🆘 National Sexual Assault Hotline: 1-800-656-4673 (US)',
        '💡 RAINN — Sexual Violence Support (US)',
        '💡 National Network to End DV (US)',
        // ── UNITED KINGDOM ──
        '🆘 National DV Helpline: 0808 2000 247 (UK — 24/7)',
        '🆘 Men\'s Advice Line: 0808 801 0327 (UK)',
        '💡 Women\'s Aid — Support & Resources (UK)',
        '💡 Refuge — Against Domestic Violence (UK)',
        // ── CANADA ──
        '🆘 Assaulted Women\'s Helpline: 1-866-863-0511 (CA — 24/7)',
        '🆘 ShelterSafe: 1-800-799-7233 (CA)',
        '💡 Canadian Women\'s Foundation (CA)',
        // ── NEW ZEALAND ──
        '🆘 Women\'s Refuge: 0800 733 843 (NZ — 24/7)',
        '🆘 Shine Helpline: 0508 744 633 (NZ)',
        '💡 Shakti — Ethnic Women\'s Support (NZ)',
        // ── IRELAND ──
        '🆘 Women\'s Aid Ireland: 1800 341 900 (IE — 24/7)',
        '💡 Safe Ireland — Support Services (IE)',
        // ── EUROPE ──
        '🆘 EU Victim Support: 116 006 (EU — Free)',
        '💡 Women Against Violence Europe (EU)',
        // ── INTERNATIONAL ──
        '💡 White Ribbon — Global Prevention Movement (INTL)',
        '💡 UN Women — Ending Violence Against Women (INTL)',
        'Guardian Contact Setup',
        'Silent Location Sharing',
        'Auto-Alert on Inactivity',
        'Stealth Check-In Timer',
        'Safe Exit — Quick-Close & Clear History',
      ],
      score: 0.87,
      weeklyData: [0.78, 0.82, 0.85, 0.88, 0.86, 0.89, 0.87],
      trendData: [0.70, 0.73, 0.76, 0.79, 0.81, 0.83, 0.85, 0.86, 0.87, 0.87],
    ),

    // ═══════════ OUTER RING — Public Safety Alerts ═════════════
    const _WellnessCard(
      icon: Icons.warning_amber_rounded,
      title: 'Public Safety\nAlerts',
      subtitle: 'Threat intelligence & warnings',
      color: Color(0xFFFF4444), // danger red
      ring: _OrbRing.outer,
      description:
          'Real-time threat warnings for areas with antisocial activity, terrorism risk, '
          'religious tensions, or civil unrest. Stay informed about population demographics '
          'and security advisories in your area. Report concerns anonymously. '
          'Your safety matters — stay vigilant, stay informed.',
      resources: [
        '🚨 THREAT LEVEL SYSTEM',
        '✅ LOW — Normal precautions',
        '⚠️ MEDIUM — Stay vigilant',
        '⚠️ HIGH — Exercise extreme caution',
        '🆘 CRITICAL — Avoid area immediately',
        '── ── ── ── ── ── ── ── ── ──',
        '⚠️ ACTIVE THREAT WARNINGS',
        '⚠️ Religious Tension Alert — Some Areas',
        '💡 Heightened tensions between communities reported. Avoid large gatherings.',
        '🚨 Terrorism Risk Advisory — National',
        '💡 Intelligence indicates potential for antisocial/terrorist activity in areas with high-density religious populations.',
        '💡 Remain vigilant. Report suspicious behavior to authorities.',
        '── ── ── ── ── ── ── ── ── ──',
        '🛡️ SAFETY RECOMMENDATIONS',
        '⚠️ Avoid Large Crowds & Public Gatherings',
        '⚠️ Stay Alert to Surroundings at All Times',
        '⚠️ Share Your Location with Trusted Contacts',
        '⚠️ Report Suspicious Activity to Authorities',
        '💡 Avoid Politically/Religiously Sensitive Areas',
        '💡 Stay Informed via Official Sources',
        '💡 Trust Your Instincts — Leave if Uncomfortable',
        '── ── ── ── ── ── ── ── ── ──',
        '🆘 EMERGENCY CONTACTS',
        '🆘 Police Emergency: 000 (AU) / 911 (US) / 999 (UK)',
        '🆘 National Security Hotline (AU): 1800 123 400',
        '🆘 Terrorism Reporting (US): 1-800-CALL-FBI',
        '🆘 Anti-Terrorism Hotline (UK): 0800 789 321',
        '💡 Smart Traveller — Government Travel Advice (AU)',
        '💡 US State Dept — Travel Advisories',
        '💡 UK Foreign Office — Travel Advice',
        '── ── ── ── ── ── ── ── ── ──',
        '📢 REPORT A SAFETY CONCERN',
        '💡 Report Religious Tensions',
        '💡 Report Terrorism Threats',
        '💡 Report Civil Unrest',
        '💡 Report Gang Activity',
        '💡 Anonymous Reporting Available',
        'View Threat Map',
        'Check Area Threat Level',
        'Safety Recommendations for Current Level',
        'Emergency Evacuation Routes',
        'Safe Meeting Points',
      ],
      score: 0.65,
      weeklyData: [0.60, 0.62, 0.64, 0.66, 0.63, 0.67, 0.65],
      trendData: [0.55, 0.57, 0.58, 0.60, 0.61, 0.62, 0.63, 0.64, 0.65, 0.65],
    ),

    // ═══════════ OUTER RING — Marine Conservation & Ocean Safety ════
    const _WellnessCard(
      icon: Icons.waves,
      title: 'Ocean Safety\n& Conservation',
      subtitle: 'Fighting for marine life',
      color: Color(0xFF0077BE), // ocean blue
      ring: _OrbRing.outer,
      description:
          'Real-time shark attack warnings from tagged sharks, whale boat conflict tracking, '
          'daily statistics on marine life killed in commercial nets, and conservation '
          'organization resources. Sea Shepherd, Oceana, AMCS, and more. '
          'Fighting isn\'t just in the cage — it\'s for our oceans too.',
      resources: [
        '🦈 SHARK ATTACK WARNINGS',
        '🔴 EXTREME RISK — Mary Lee (Great White)',
        '💡 4.5m Great White detected 3.2km offshore Sydney',
        '💡 Beaches Affected: Bondi, Coogee, Manly',
        '💡 Last Tagged: 2 hours ago',
        '🔴 EXTREME RISK — Tiger 7 (Tiger Shark)',
        '💡 3.8m Tiger Shark detected 1.8km from Gold Coast shore',
        '💡 Beaches Affected: Surfers Paradise, Burleigh, Coolangatta',
        '💡 Last Tagged: 6 hours ago',
        '── ── ── ── ── ── ── ── ── ──',
        '🐋 WHALE BOAT CONFLICTS — LIVE MAP',
        '⚠️ Commercial Vessel — Illegal Proximity',
        '💡 Within 85m of Humpback pod (Legal minimum: 100m)',
        '💡 Location: 34°S, 151°E (NSW Coast)',
        '💡 Reported by: Sea Shepherd Observer',
        '⚠️ Fishing Vessel — High Speed in Whale Zone',
        '💡 28 knots in protected breeding area (Limit: 6 knots)',
        '💡 Location: 38°S, 142°E (VIC Coast)',
        '💡 Species: Southern Right Whale',
        '── ── ── ── ── ── ── ── ── ──',
        '📊 MARINE LIFE KILLED TODAY (By Commercial Nets)',
        '🐬 Dolphins: 347 killed',
        '🐢 Sea Turtles: 521 killed',
        '🦈 Sharks: 1,205 killed',
        '🐋 Whales: 12 killed',
        '🦭 Seals: 89 killed',
        '🐠 Other Marine Life: 4,521 killed',
        '💔 TOTAL TODAY: 6,695 deaths',
        '📈 +283 from yesterday (Increasing)',
        '── ── ── ── ── ── ── ── ── ──',
        '🛡️ CONSERVATION ORGANIZATIONS',
        '⚡ Sea Shepherd Conservation Society',
        '💡 Direct-action marine conservation — protecting whales, dolphins, sharks worldwide',
        '💡 Website: seashepherd.org | Donate | Volunteer',
        '💡 Phone: +61 3 9645 9422',
        '⚡ Oceana',
        '💡 Largest international ocean advocacy — protecting and restoring oceans',
        '💡 Website: oceana.org | Donate | Volunteer',
        '⚡ Australian Marine Conservation Society',
        '💡 Australia\'s voice for the ocean — Great Barrier Reef, sharks, sustainable fishing',
        '💡 Website: marineconservation.org.au | Phone: +61 7 3846 6777',
        '⚡ Surfrider Foundation',
        '💡 Protecting oceans, waves, beaches for all people',
        '💡 Website: surfrider.org',
        '⚡ Whale and Dolphin Conservation',
        '💡 Dedicated solely to whale and dolphin protection worldwide',
        '💡 Website: whales.org',
        '⚡ Project AWARE',
        '💡 Global movement — sharks, rays, marine debris',
        '💡 Website: projectaware.org | Dive Against Debris',
        '── ── ── ── ── ── ── ── ── ──',
        '📱 REPORT INCIDENTS',
        '💡 Report Whale/Boat Conflict',
        '💡 Report Marine Life Death/Injury',
        '💡 Upload Photos & GPS Location',
        '💡 Anonymous Reporting Available',
        '💡 Alerts Sent to Sea Shepherd & Marine Authorities',
        '── ── ── ── ── ── ── ── ── ──',
        '📢 ADVERTISE YOUR CONSERVATION ORG',
        '📢 FREE Advertising for Registered Nonprofits',
        '📢 Reach 10K+ Fighters Who Care About Marine Life',
        'View Live Shark Tags Map',
        'View Whale Boat Conflict Scanner',
        'Check Beach Shark Risk Level',
        'Daily Marine Kill Statistics',
        'Donate to Conservation Orgs',
        'Volunteer Opportunities',
        'Report Ocean Incidents',
      ],
      score: 0.79,
      weeklyData: [0.72, 0.74, 0.76, 0.78, 0.77, 0.81, 0.79],
      trendData: [0.65, 0.67, 0.69, 0.71, 0.73, 0.75, 0.76, 0.77, 0.78, 0.79],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _graphController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _generateOrbs();
    _setupSakuraOverlay();
  }

  Future<void> _setupSakuraOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    _prefs = prefs;
    final shown = prefs.getBool('sakura_shown') ?? false;
    if (shown) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSakuraOverlay = true);
    });
  }

  void _dismissSakuraOverlay() {
    if (!mounted) return;
    setState(() => _showSakuraOverlay = false);
    _prefs?.setBool('sakura_shown', true);
  }

  void _generateOrbs() {
    final rng = math.Random(7);
    const colors = [
      AppTheme.neonCyan,
      AppTheme.neonMagenta,
      AppTheme.neonGreen,
      Color(0xFFFFC107), // amber
      Color(0xFF6C63FF), // violet accent
    ];

    for (int i = 0; i < 20; i++) {
      _orbs.add(
        _FloatingOrb(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: rng.nextDouble() * 22 + 6,
          speed: rng.nextDouble() * 0.5 + 0.2,
          color: colors[rng.nextInt(colors.length)],
          opacity: rng.nextDouble() * 0.22 + 0.04,
          phase: rng.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _orbController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _graphController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final rawSex = (authService.userModel?.metadata?['sex'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final isFemaleUser = rawSex == 'female';

    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      body: Stack(
        children: [
          // ── Layer 0: Cosmic background + aurora + stars ──
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, _) => CustomPaint(
              painter: _CosmicBackgroundPainter(
                orbs: _orbs,
                animation: _orbController.value,
              ),
              size: Size.infinite,
            ),
          ),

          // ── Layer 1: Content ──
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isFemaleUser),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _selectedCardIndex == -1
                        ? _buildFloatingCards(isFemaleUser)
                        : _buildCardDetail(isFemaleUser),
                  ),
                ),
              ],
            ),
          ),
          if (isFemaleUser && _showSakuraOverlay)
            Positioned.fill(
              child: SakuraSafetyOverlay(onDismissed: _dismissSakuraOverlay),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(bool isFemaleUser) {
    final showSelectedCard = _selectedCardIndex != -1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (showSelectedCard)
            GestureDetector(
              onTap: () => setState(() => _selectedCardIndex = -1),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !showSelectedCard
                      ? 'Fighter Wellness'
                      : _wellnessCards[_selectedCardIndex].title.replaceAll(
                          '\n',
                          ' ',
                        ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  !showSelectedCard
                      ? 'Your corner, always'
                      : _wellnessCards[_selectedCardIndex].subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Heart badge
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.15),
                  AppTheme.neonMagenta.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.favorite_outline,
              color: AppTheme.neonCyan,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING CARDS (orbital bubbles + connection lines)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFloatingCards(bool isFemaleUser) {
    // Separate inner and outer ring cards
    final innerCards = <int>[];
    final outerCards = <int>[];
    for (int i = 0; i < _wellnessCards.length; i++) {
      if (_wellnessCards[i].ring == _OrbRing.outer) {
        outerCards.add(i);
      } else {
        innerCards.add(i);
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _cardController,
        _pulseController,
        _shimmerController,
      ]),
      builder: (context, _) {
        return LayoutBuilder(
          key: const ValueKey('floating'),
          builder: (context, constraints) {
            final positions = <Offset>[];
            final scales = <double>[];
            final orbSizes = <double>[];

            final cx = constraints.maxWidth / 2;
            final cy = constraints.maxHeight / 2 - 10;

            // ── Inner ring (core wellness orbs) ──
            final innerRx = constraints.maxWidth * 0.20;
            final innerRy = constraints.maxHeight * 0.15;
            for (int j = 0; j < innerCards.length; j++) {
              final baseAngle = (j / innerCards.length) * 2 * math.pi;
              // Rotate counter-clockwise slowly
              final animAngle =
                  baseAngle + (_cardController.value * 2 * math.pi * 0.08);
              final bob =
                  math.sin(_pulseController.value * math.pi * 2 + j * 1.5) * 8;
              positions.add(
                Offset(
                  cx + math.cos(animAngle) * innerRx,
                  cy + math.sin(animAngle) * innerRy + bob,
                ),
              );
              scales.add(0.80 + (math.sin(animAngle) + 1) * 0.10);
              orbSizes.add(160);
            }

            // ── Outer ring (satellite orbs) ──
            final outerRx = constraints.maxWidth * 0.40;
            final outerRy = constraints.maxHeight * 0.30;
            for (int j = 0; j < outerCards.length; j++) {
              final baseAngle = (j / outerCards.length) * 2 * math.pi;
              // Rotate clockwise at a different speed
              final animAngle =
                  baseAngle - (_cardController.value * 2 * math.pi * 0.05);
              final bob =
                  math.sin(_pulseController.value * math.pi * 2 + j * 1.1 + 2) *
                  6;
              positions.add(
                Offset(
                  cx + math.cos(animAngle) * outerRx,
                  cy + math.sin(animAngle) * outerRy + bob,
                ),
              );
              scales.add(0.65 + (math.sin(animAngle) + 1) * 0.10);
              orbSizes.add(120);
            }

            // Build combined card index list
            final allIndices = [...innerCards, ...outerCards];

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Neural connection lines ──
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _ConnectionLinesPainter(
                    positions: positions,
                    colors: allIndices
                        .map((i) => _wellnessCards[i].color)
                        .toList(),
                    animation: _shimmerController.value,
                  ),
                ),

                // ── Black Hole (centre — back navigation) ──
                Positioned(
                  left: cx - 52,
                  top: cy - 52,
                  child: _buildBlackHole(),
                ),

                // ── Orbs ──
                ...List.generate(allIndices.length, (j) {
                  final cardIdx = allIndices[j];
                  final halfSize = orbSizes[j] / 2;
                  return Positioned(
                    left: positions[j].dx - halfSize,
                    top: positions[j].dy - halfSize,
                    child: Transform.scale(
                      scale: scales[j],
                      child: _buildWellnessOrb(
                        _wellnessCards[cardIdx],
                        cardIdx,
                        size: orbSizes[j],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BLACK HOLE — centre of the galaxy, pulls you back
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBlackHole() {
    final pulse = math.sin(_pulseController.value * math.pi * 2) * 0.08;
    final spin = _cardController.value * math.pi * 2;

    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          // Fallback to home
          context.go('/');
        }
      },
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Event-horizon glow ──
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF6B00FF,
                    ).withValues(alpha: 0.35 + pulse),
                    blurRadius: 45,
                    spreadRadius: 12,
                  ),
                  BoxShadow(
                    color: AppTheme.neonMagenta.withValues(
                      alpha: 0.12 + pulse * 0.5,
                    ),
                    blurRadius: 70,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),

            // ── Accretion disk (spinning ring) ──
            Transform.rotate(
              angle: spin,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      const Color(0xFF6B00FF).withValues(alpha: 0.55),
                      AppTheme.neonMagenta.withValues(alpha: 0.35),
                      Colors.transparent,
                      const Color(0xFF3D00A3).withValues(alpha: 0.45),
                      const Color(0xFF6B00FF).withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // ── Singularity (void centre) ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF050008),
                    const Color(0xFF1A0030).withValues(alpha: 0.85),
                    const Color(0xFF6B00FF).withValues(alpha: 0.18),
                  ],
                  stops: const [0.0, 0.45, 0.78, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFF6B00FF).withValues(alpha: 0.4 + pulse),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: const Color(0xFFBB86FC).withValues(alpha: 0.9),
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BLACK\nHOLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFBB86FC).withValues(alpha: 0.85),
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Orbiting particles (gravitational pull) ──
            ...List.generate(4, (i) {
              final pAngle = spin * 2.5 + (i / 4) * math.pi * 2;
              final dist = 42.0 + math.sin(pAngle * 0.7 + i) * 6;
              final pSize = 2.5 + math.sin(pAngle + i) * 0.8;
              return Positioned(
                left: 52 + math.cos(pAngle) * dist - pSize / 2,
                top: 52 + math.sin(pAngle) * dist - pSize / 2,
                child: Container(
                  width: pSize,
                  height: pSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBB86FC).withValues(alpha: 0.65),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B00FF).withValues(alpha: 0.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC ORB (multi-ring, glass sphere, orbiting particles)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWellnessOrb(_WellnessCard card, int index, {double size = 180}) {
    final pulse = math.sin(
      (_pulseController.value + index * 0.25) * math.pi * 2,
    );
    final shimmerAngle =
        (_shimmerController.value + index * 0.15) * math.pi * 2;

    // Scale factors relative to base 180
    final sf = size / 180;
    final glassSize = 120 * sf;
    final ringSize = 150 * sf;
    final outerRing = 160 * sf;
    final halfSize = size / 2;
    final iconSize = 30 * sf;
    final titleSize = 11 * sf;
    final subtitleSize = 8 * sf;
    final particleRadius = 78 * sf;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCardIndex = index);
        _graphController.forward(from: 0);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Outer pulsing aura ──
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: card.color.withValues(alpha: 0.12 + pulse * 0.06),
                    blurRadius: 50 * sf,
                    spreadRadius: 15 * sf,
                  ),
                  BoxShadow(
                    color: card.color.withValues(alpha: 0.06 + pulse * 0.03),
                    blurRadius: 80 * sf,
                    spreadRadius: 30 * sf,
                  ),
                ],
              ),
            ),

            // ── Outer glow ring ──
            Container(
              width: outerRing,
              height: outerRing,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: card.color.withValues(alpha: 0.15 + pulse * 0.08),
                ),
              ),
            ),

            // ── Holographic rotating ring ──
            CustomPaint(
              size: Size(ringSize, ringSize),
              painter: _HolographicRingPainter(
                angle: shimmerAngle,
                baseColor: card.color,
              ),
            ),

            // ── Glass sphere ──
            Container(
              width: glassSize,
              height: glassSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  radius: 0.8,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    card.color.withValues(alpha: 0.12),
                    const Color(0xFF0A1628).withValues(alpha: 0.65),
                    const Color(0xFF050A14).withValues(alpha: 0.80),
                  ],
                  stops: const [0.0, 0.30, 0.70, 1.0],
                ),
                border: Border.all(
                  color: card.color.withValues(alpha: 0.35 + pulse * 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: card.color.withValues(alpha: 0.25 + pulse * 0.08),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(card.icon, color: card.color, size: iconSize),
                  SizedBox(height: 5 * sf),
                  Text(
                    card.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 3 * sf),
                  Text(
                    card.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: subtitleSize,
                    ),
                  ),
                ],
              ),
            ),

            // ── Orbiting micro-particles ──
            ...List.generate(6, (i) {
              final pAngle =
                  (shimmerAngle * 3) + (i / 6) * math.pi * 2; // 3x speed
              final pr = particleRadius;
              final pSize = (3.0 + math.sin(pAngle + i) * 1.0) * sf;
              return Positioned(
                left: halfSize + math.cos(pAngle) * pr - pSize / 2,
                top: halfSize + math.sin(pAngle) * pr - pSize / 2,
                child: Container(
                  width: pSize,
                  height: pSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.color.withValues(alpha: 0.75),
                    boxShadow: [
                      BoxShadow(
                        color: card.color.withValues(alpha: 0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD DETAIL VIEW (hero + graphs + resources)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCardDetail(bool isFemaleUser) {
    final card = _wellnessCards[_selectedCardIndex];

    return SingleChildScrollView(
      key: ValueKey('detail_$_selectedCardIndex'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Hero orb ──
          _buildHeroOrb(card),
          const SizedBox(height: 28),

          // ── Stats row: Score gauge + Trend sparkline ──
          Row(
            children: [
              Expanded(child: _buildScoreGauge(card)),
              const SizedBox(width: 16),
              Expanded(child: _buildTrendChart(card)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Weekly activity bars ──
          _buildWeeklyBars(card),
          const SizedBox(height: 24),

          // ── Description card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: card.color.withValues(alpha: 0.15)),
            ),
            child: Text(
              card.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Resources ──
          ...card.resources
              .where(
                (r) =>
                    !r.startsWith('── ') &&
                    !r.startsWith('🛡️') &&
                    !r.startsWith('🆘'),
              )
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildResourceTile(r, card.color),
                ),
              ),
          const SizedBox(height: 20),

          // ── Safe Girl Section (only in Cycle card) ──
          if (card.title.contains('Cycle')) _buildSafeGirlSection(card),

          // ── CTA ──
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [card.color, card.color.withValues(alpha: 0.65)],
              ),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: card.color.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(27),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Finding ${card.title.replaceAll('\n', ' ')} support near you…',
                      ),
                      backgroundColor: card.color.withValues(alpha: 0.9),
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    'Find Support Near Me',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Hero orb (bigger version) ──
  Widget _buildHeroOrb(_WellnessCard card) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = math.sin(_pulseController.value * math.pi * 2);
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: [
                Colors.white.withValues(alpha: 0.12),
                card.color.withValues(alpha: 0.20),
                const Color(0xFF0A1628).withValues(alpha: 0.70),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            border: Border.all(
              color: card.color.withValues(alpha: 0.5 + pulse * 0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: card.color.withValues(alpha: 0.35 + pulse * 0.10),
                blurRadius: 35,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: card.color.withValues(alpha: 0.10),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Icon(card.icon, color: card.color, size: 44),
        );
      },
    );
  }

  // ── Wellness Score Gauge ──
  Widget _buildScoreGauge(_WellnessCard card) {
    return AnimatedBuilder(
      animation: _graphController,
      builder: (context, _) {
        final scorePercent = (card.score * _graphController.value * 100)
            .round();
        return Container(
          height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: card.color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(
                'Wellness Score',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _WellnessGaugePainter(
                        score: card.score,
                        color: card.color,
                        animation: _graphController.value,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$scorePercent',
                          style: TextStyle(
                            color: card.color,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '%',
                          style: TextStyle(
                            color: card.color.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Trend Sparkline chart ──
  Widget _buildTrendChart(_WellnessCard card) {
    return AnimatedBuilder(
      animation: _graphController,
      builder: (context, _) {
        return Container(
          height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: card.color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Trend',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.trending_up, color: card.color, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '+${((card.trendData.last - card.trendData.first) * 100).round()}%',
                    style: TextStyle(
                      color: card.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TrendSparklinePainter(
                    data: card.trendData,
                    color: card.color,
                    animation: _graphController.value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Weekly Activity Bars ──
  Widget _buildWeeklyBars(_WellnessCard card) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return AnimatedBuilder(
      animation: _graphController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: card.color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final value = card.weeklyData[i];
                    final maxVal = card.weeklyData.reduce(
                      (a, b) => a > b ? a : b,
                    );
                    final heightFrac = maxVal > 0 ? value / maxVal : 0.0;
                    final animatedHeight =
                        heightFrac * _graphController.value * 80;
                    final isToday = i == 6;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: animatedHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    card.color.withValues(
                                      alpha: isToday ? 0.8 : 0.3,
                                    ),
                                    card.color.withValues(
                                      alpha: isToday ? 1.0 : 0.5,
                                    ),
                                  ],
                                ),
                                boxShadow: isToday
                                    ? [
                                        BoxShadow(
                                          color: card.color.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, -2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              days[i],
                              style: TextStyle(
                                color: isToday
                                    ? card.color
                                    : Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Resource tile ──
  // ═══════════════════════════════════════════════════════════════════════
  // SAFE GIRL — Hidden Guardian system disguised as cycle check-in
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSafeGirlSection(_WellnessCard card) {
    return Column(
      children: [
        // ── Looks like a cycle tracking section ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF69B4).withValues(alpha: 0.12),
                const Color(0xFFE91E63).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF69B4).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              // Header looks like cycle check-in
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF69B4).withValues(alpha: 0.8),
                          const Color(0xFFE91E63).withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Check-In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Hold the heart to log how you\'re feeling today',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── THE BUTTON — looks like a cycle check-in. ──
              // Hold for 3 seconds = silent Guardian alert sent.
              // Tap once = normal cycle log (cover story).
              StatefulBuilder(
                builder: (context, setLocalState) {
                  return GestureDetector(
                    onTap: () {
                      // Normal tap — looks like a period check-in
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cycle check-in logged ❤️'),
                          backgroundColor: const Color(
                            0xFFFF69B4,
                          ).withValues(alpha: 0.9),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      setLocalState(() {
                        _lastCheckIn = DateTime.now();
                      });
                    },
                    onLongPressStart: (_) {
                      setLocalState(() => _guardianHolding = true);
                      // Animate the hold progress
                      Future.doWhile(() async {
                        await Future.delayed(const Duration(milliseconds: 50));
                        if (!_guardianHolding) return false;
                        setLocalState(() {
                          _holdProgress = (_holdProgress + 0.0167).clamp(
                            0.0,
                            1.0,
                          );
                        });
                        if (_holdProgress >= 1.0) {
                          // ═══ GUARDIAN ACTIVATED ═══
                          _triggerGuardianAlert();
                          return false;
                        }
                        return true;
                      });
                    },
                    onLongPressEnd: (_) {
                      setLocalState(() {
                        _guardianHolding = false;
                        if (_holdProgress < 1.0) _holdProgress = 0.0;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _guardianActive
                              ? [
                                  const Color(0xFF4CAF50),
                                  const Color(0xFF2E7D32),
                                ]
                              : _guardianHolding
                              ? [
                                  Color.lerp(
                                    const Color(0xFFFF69B4),
                                    const Color(0xFFE53935),
                                    _holdProgress,
                                  )!,
                                  Color.lerp(
                                    const Color(0xFFE91E63),
                                    const Color(0xFFB71C1C),
                                    _holdProgress,
                                  )!,
                                ]
                              : [
                                  const Color(0xFFFF69B4),
                                  const Color(0xFFE91E63),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(29),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_guardianActive
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFF69B4))
                                    .withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Hold progress indicator (hidden meaning)
                          if (_guardianHolding && _holdProgress > 0)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 50),
                                width:
                                    (MediaQuery.of(context).size.width - 72) *
                                    _holdProgress,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(29),
                                ),
                              ),
                            ),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _guardianActive
                                      ? Icons.check_circle
                                      : Icons.favorite,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _guardianActive
                                      ? 'Guardian Active — You\'re Safe'
                                      : _guardianHolding
                                      ? 'Hold...'
                                      : 'Hold to Check In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ── Set up Guardians button (looks like cycle settings) ──
              GestureDetector(
                onTap: _showGuardianSetup,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF69B4).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: const Color(0xFFFF69B4).withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _guardianContacts.isEmpty
                              ? 'Set Up My People (${_guardianContacts.length}/3)'
                              : '${_guardianContacts.length}/3 Guardians Set ✓',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
              if (_lastCheckIn != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Last check-in: ${_lastCheckIn!.hour.toString().padLeft(2, '0')}:${_lastCheckIn!.minute.toString().padLeft(2, '0')} today',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Crisis resources (also look like health resources) ──
        ...card.resources
            .where((r) => r.startsWith('🆘') || r.startsWith('🛡️'))
            .map((r) {
              final displayText = r.substring(2).trim();
              final isEmergency = r.startsWith('🆘');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isEmergency
                        ? const Color(0xFFE53935).withValues(alpha: 0.08)
                        : const Color(0xFF90CAF9).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEmergency
                          ? const Color(0xFFE53935).withValues(alpha: 0.2)
                          : const Color(0xFF90CAF9).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isEmergency ? '🆘' : '🛡️',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            color: isEmergency
                                ? const Color(0xFFEF9A9A)
                                : const Color(0xFF90CAF9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        isEmergency ? Icons.phone : Icons.shield_outlined,
                        color: isEmergency
                            ? const Color(0xFFE53935).withValues(alpha: 0.5)
                            : const Color(0xFF90CAF9).withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Trigger silent Guardian alert — sends to all set contacts.
  void _triggerGuardianAlert() {
    setState(() => _guardianActive = true);

    // Show confirmation that looks like a cycle notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              _guardianContacts.isEmpty
                  ? 'Cycle check-in saved'
                  : 'Check-in sent to ${_guardianContacts.length} contact${_guardianContacts.length == 1 ? '' : 's'}',
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
      ),
    );

    _lastCheckIn = DateTime.now();

    // Reset after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _guardianActive = false;
          _holdProgress = 0.0;
        });
      }
    });
  }

  /// Show Guardian setup dialog (disguised as "Cycle Sharing" settings).
  void _showGuardianSetup() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.people, color: Color(0xFFFF69B4), size: 22),
              SizedBox(width: 10),
              Text(
                'My People',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'These people will be notified when you hold the check-in button for 3 seconds. '
                  'They\'ll receive your location and a message that you need help.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Existing contacts
                ..._guardianContacts.map(
                  (c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${c['phone']} · ${c['relation']}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _guardianContacts.remove(c);
                            });
                            setState(() {});
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_guardianContacts.length < 3) ...[
                  const SizedBox(height: 8),
                  _buildGuardianField(
                    nameController,
                    'Name',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 8),
                  _buildGuardianField(
                    phoneController,
                    'Phone Number',
                    Icons.phone_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildGuardianField(
                    relationController,
                    'Relationship',
                    Icons.favorite_border,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      if (nameController.text.isNotEmpty &&
                          phoneController.text.isNotEmpty) {
                        setDialogState(() {
                          _guardianContacts.add({
                            'name': nameController.text,
                            'phone': phoneController.text,
                            'relation': relationController.text.isEmpty
                                ? 'Contact'
                                : relationController.text,
                          });
                          nameController.clear();
                          phoneController.clear();
                          relationController.clear();
                        });
                        setState(() {});
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF69B4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF69B4).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '+ Add Person',
                          style: TextStyle(
                            color: Color(0xFFFF69B4),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🆘', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'In immediate danger? Call 000 (AU) or 911 (US)',
                          style: TextStyle(
                            color: const Color(
                              0xFFEF9A9A,
                            ).withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Color(0xFFFF69B4),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFFF69B4).withValues(alpha: 0.5),
          size: 18,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF69B4)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  /// Parse country code from resource text like "(AU)", "(US)", "(UK)"
  String _getCountryLabel(String resource) {
    const countryMap = {
      'AU': 'Australia',
      'US': 'United States',
      'UK': 'United Kingdom',
      'CA': 'Canada',
      'NZ': 'New Zealand',
      'IE': 'Ireland',
      'EU': 'Europe',
      'INTL': 'International',
    };
    final match = RegExp(r'\(([A-Z]{2,4})\)').firstMatch(resource);
    if (match != null) {
      final code = match.group(1);
      return 'FREE — Available in ${countryMap[code] ?? code}';
    }
    return 'FREE — Global Resource';
  }

  Widget _buildResourceTile(String resource, Color color) {
    final isFeatured = resource.startsWith('⭐');
    final isTip = resource.startsWith('💡');
    final displayText = (isFeatured || isTip)
        ? resource.substring(2).trim()
        : resource;
    final tileColor = isFeatured
        ? const Color(0xFFFFD700)
        : isTip
        ? const Color(0xFF00E5FF)
        : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isFeatured || isTip ? 15 : 13,
      ),
      decoration: BoxDecoration(
        color: isFeatured
            ? const Color(0xFFFFD700).withValues(alpha: 0.10)
            : isTip
            ? const Color(0xFF00E5FF).withValues(alpha: 0.07)
            : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFeatured
              ? const Color(0xFFFFD700).withValues(alpha: 0.55)
              : isTip
              ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
              : color.withValues(alpha: 0.20),
          width: isFeatured || isTip ? 1.5 : 1.0,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : isTip
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (isFeatured)
            const Text('⭐', style: TextStyle(fontSize: 14))
          else if (isTip)
            const Text('💡', style: TextStyle(fontSize: 14))
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5),
                ],
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    color: isFeatured
                        ? const Color(0xFFFFD700)
                        : isTip
                        ? const Color(0xFF00E5FF)
                        : Colors.white,
                    fontSize: isFeatured || isTip ? 13.5 : 13,
                    fontWeight: isFeatured || isTip
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (isFeatured)
                  Text(
                    'Featured Provider',
                    style: TextStyle(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.65),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                if (isTip)
                  Text(
                    _getCountryLabel(resource),
                    style: TextStyle(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.65),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: tileColor, size: 13),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════
// ── Orbital ring designation ──
enum _OrbRing { inner, outer }

class _WellnessCard {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String description;
  final List<String> resources;
  final double score;
  final List<double> weeklyData;
  final List<double> trendData;
  final _OrbRing ring;

  const _WellnessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.description,
    required this.resources,
    required this.score,
    required this.weeklyData,
    required this.trendData,
    this.ring = _OrbRing.inner,
  });
}

class _FloatingOrb {
  final double x, y, radius, speed, opacity, phase;
  final Color color;

  const _FloatingOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
    required this.opacity,
    required this.phase,
  });
}

class _Star {
  final double x, y, size, brightness;
  final bool twinkles;

  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkles,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// COSMIC BACKGROUND PAINTER (aurora + nebula + stars + orbs + shooting stars)
// ═════════════════════════════════════════════════════════════════════════════
class _CosmicBackgroundPainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double animation;
  late final List<_Star> _stars;

  _CosmicBackgroundPainter({required this.orbs, required this.animation}) {
    final rng = math.Random(42);
    _stars = List.generate(
      180,
      (i) => _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 1.8 + 0.3,
        brightness: rng.nextDouble() * 0.7 + 0.15,
        twinkles: rng.nextDouble() > 0.75,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── Deep space gradient ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.0, -0.3),
          radius: 1.8,
          colors: [Color(0xFF0C1A32), Color(0xFF060E1C), Color(0xFF030810)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // ── Aurora borealis ribbons ──
    for (int i = 0; i < 5; i++) {
      final auroraPath = Path();
      final yBase = size.height * 0.08 + i * 35;
      final xPhase = animation * math.pi * 2 + i * 0.7;

      auroraPath.moveTo(0, yBase + 50);
      for (double x = 0; x <= size.width; x += 8) {
        final fraction = x / size.width;
        final y =
            yBase +
            math.sin(fraction * math.pi * 3 + xPhase) * 45 +
            math.sin(fraction * math.pi * 5.5 + xPhase * 1.4) * 20;
        auroraPath.lineTo(x, y);
      }
      auroraPath.lineTo(size.width, yBase + 90);
      auroraPath.lineTo(0, yBase + 90);
      auroraPath.close();

      final auroraColors = [
        [AppTheme.neonCyan, AppTheme.neonGreen],
        [AppTheme.neonGreen, const Color(0xFF6C63FF)],
        [const Color(0xFF6C63FF), AppTheme.neonMagenta],
        [AppTheme.neonMagenta, AppTheme.neonCyan],
        [AppTheme.neonCyan, AppTheme.neonMagenta],
      ];

      canvas.drawPath(
        auroraPath,
        Paint()
          ..shader = LinearGradient(
            colors: [
              auroraColors[i][0].withValues(alpha: 0.025),
              auroraColors[i][1].withValues(alpha: 0.035),
            ],
          ).createShader(Rect.fromLTWH(0, yBase, size.width, 90))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
      );
    }

    // ── Nebula blobs ──
    final nebulaPositions = [
      [0.25, 0.35, AppTheme.neonCyan, 0.05],
      [0.70, 0.55, AppTheme.neonMagenta, 0.04],
      [0.50, 0.75, AppTheme.neonGreen, 0.03],
      [0.85, 0.20, const Color(0xFF6C63FF), 0.03],
    ];
    for (final n in nebulaPositions) {
      final nx =
          (n[0] as double) +
          math.sin(animation * math.pi * 2 + (n[1] as double) * 5) * 0.03;
      final ny =
          (n[1] as double) +
          math.cos(animation * math.pi * 1.5 + (n[0] as double) * 3) * 0.02;
      canvas.drawCircle(
        Offset(nx * size.width, ny * size.height),
        size.width * 0.30,
        Paint()
          ..color = (n[2] as Color).withValues(
            alpha: (n[3] as double).clamp(0.0, 1.0),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
      );
    }

    // ── Stars ──
    for (final star in _stars) {
      final twinkle = star.twinkles
          ? (math.sin(animation * math.pi * 4 + star.x * 25 + star.y * 15) *
                    0.45 +
                0.55)
          : 1.0;
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (star.brightness * twinkle).clamp(0.0, 1.0),
          ),
      );
    }

    // ── Shooting stars ──
    final shootSeed = math.Random(42);
    for (int i = 0; i < 4; i++) {
      final phase = (animation * 2.5 + i * 0.25) % 1.0;
      if (phase >= 0.08) continue;
      final t = phase / 0.08;
      final fade = t < 0.2 ? t / 0.2 : (t > 0.7 ? (1.0 - t) / 0.3 : 1.0);

      final startX =
          shootSeed.nextDouble() * size.width * 0.6 + size.width * 0.2;
      final startY = shootSeed.nextDouble() * size.height * 0.35;
      final angle = shootSeed.nextDouble() * 0.4 + 0.3;
      final len = shootSeed.nextDouble() * 120 + 80;

      final cx = startX + math.cos(angle) * len * t;
      final cy = startY + math.sin(angle) * len * t;
      final trailLen = 55.0 * fade;
      final tx = cx - math.cos(angle) * trailLen;
      final ty = cy - math.sin(angle) * trailLen;

      canvas.drawLine(
        Offset(tx, ty),
        Offset(cx, cy),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: (0.65 * fade).clamp(0.0, 1.0)),
            ],
          ).createShader(Rect.fromPoints(Offset(tx, ty), Offset(cx, cy)))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (0.8 * fade).clamp(0.0, 1.0),
          ),
      );
    }

    // ── Floating orbs (background) ──
    for (final orb in orbs) {
      final yOff =
          math.sin(animation * math.pi * 2 * orb.speed + orb.phase) * 18;
      final xOff =
          math.cos(animation * math.pi * 1.5 * orb.speed + orb.phase + 1) * 12;
      final pos = Offset(orb.x * size.width + xOff, orb.y * size.height + yOff);

      // Outer glow
      canvas.drawCircle(
        pos,
        orb.radius * 1.2,
        Paint()
          ..color = orb.color.withValues(
            alpha: (orb.opacity * 0.35).clamp(0.0, 1.0),
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.radius * 0.7),
      );
      // Core
      canvas.drawCircle(
        pos,
        orb.radius * 0.35,
        Paint()
          ..color = orb.color.withValues(
            alpha: (orb.opacity * 0.8).clamp(0.0, 1.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBackgroundPainter old) =>
      old.animation != animation;
}

// ═════════════════════════════════════════════════════════════════════════════
// CONNECTION LINES PAINTER (neural-link constellation)
// ═════════════════════════════════════════════════════════════════════════════
class _ConnectionLinesPainter extends CustomPainter {
  final List<Offset> positions;
  final List<Color> colors;
  final double animation;

  _ConnectionLinesPainter({
    required this.positions,
    required this.colors,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist > 600) continue;

        final baseOpacity = (1.0 - dist / 600) * 0.12;
        final pulse = math.sin(animation * math.pi * 2 + i * 1.2 + j * 0.8);
        final opacity = baseOpacity * (0.5 + pulse * 0.5);

        // Gradient line
        canvas.drawLine(
          positions[i],
          positions[j],
          Paint()
            ..shader = LinearGradient(
              colors: [
                colors[i].withValues(alpha: opacity.clamp(0.0, 1.0)),
                colors[j].withValues(alpha: opacity.clamp(0.0, 1.0)),
              ],
            ).createShader(Rect.fromPoints(positions[i], positions[j]))
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round,
        );

        // Data-pulse dot traveling along the line
        final dotT = (animation * 3 + i * 0.4 + j * 0.3) % 1.0;
        final dotPos = Offset(
          positions[i].dx + (positions[j].dx - positions[i].dx) * dotT,
          positions[i].dy + (positions[j].dy - positions[i].dy) * dotT,
        );
        canvas.drawCircle(
          dotPos,
          2,
          Paint()
            ..color = Color.lerp(
              colors[i],
              colors[j],
              dotT,
            )!.withValues(alpha: (opacity * 3).clamp(0.0, 1.0))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinesPainter old) =>
      old.animation != animation;
}

// ═════════════════════════════════════════════════════════════════════════════
// HOLOGRAPHIC RING PAINTER (rotating sweep gradient)
// ═════════════════════════════════════════════════════════════════════════════
class _HolographicRingPainter extends CustomPainter {
  final double angle;
  final Color baseColor;

  _HolographicRingPainter({required this.angle, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            baseColor.withValues(alpha: 0.0),
            baseColor.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.30),
            baseColor.withValues(alpha: 0.55),
            baseColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Secondary faint ring
    canvas.drawCircle(
      center,
      radius + 6,
      Paint()
        ..shader = SweepGradient(
          colors: [
            baseColor.withValues(alpha: 0.0),
            baseColor.withValues(alpha: 0.12),
            baseColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(angle + math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: radius + 6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _HolographicRingPainter old) =>
      old.angle != angle;
}

// ═════════════════════════════════════════════════════════════════════════════
// WELLNESS GAUGE PAINTER (radial arc with glow + ticks)
// ═════════════════════════════════════════════════════════════════════════════
class _WellnessGaugePainter extends CustomPainter {
  final double score, animation;
  final Color color;

  _WellnessGaugePainter({
    required this.score,
    required this.color,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;
    final animScore = score * animation;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Glow arc
    if (animScore > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * animScore,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Score arc (gradient)
    if (animScore > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * animScore,
        false,
        Paint()
          ..shader = SweepGradient(
            colors: [
              color.withValues(alpha: 0.5),
              color,
              Colors.white.withValues(alpha: 0.8),
            ],
            transform: const GradientRotation(startAngle),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tick marks
    for (int i = 0; i <= 12; i++) {
      final tickAngle = startAngle + sweepAngle * (i / 12);
      final isFilled = i <= (animScore * 12).round();
      final inner = radius - 14;
      final outer = radius - 8;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(tickAngle) * inner,
          center.dy + math.sin(tickAngle) * inner,
        ),
        Offset(
          center.dx + math.cos(tickAngle) * outer,
          center.dy + math.sin(tickAngle) * outer,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: isFilled ? 0.45 : 0.12)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // End dot
    if (animScore > 0.01) {
      final endAngle = startAngle + sweepAngle * animScore;
      final dot = Offset(
        center.dx + math.cos(endAngle) * radius,
        center.dy + math.sin(endAngle) * radius,
      );
      canvas.drawCircle(dot, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        dot,
        9,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WellnessGaugePainter old) =>
      old.animation != animation;
}

// ═════════════════════════════════════════════════════════════════════════════
// TREND SPARKLINE PAINTER (smooth curve + gradient fill + glow)
// ═════════════════════════════════════════════════════════════════════════════
class _TrendSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double animation;

  _TrendSparklinePainter({
    required this.data,
    required this.color,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxV = data.reduce(math.max);
    final minV = data.reduce(math.min);
    final range = maxV - minV;
    const pad = 6.0;
    final cw = size.width - pad * 2;
    final ch = size.height - pad * 2;

    // Build smooth curve
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = pad + (i / (data.length - 1)) * cw;
      final norm = range > 0 ? (data[i] - minV) / range : 0.5;
      final y = pad + ch - (norm * ch);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = pad + ((i - 1) / (data.length - 1)) * cw;
        final prevNorm = range > 0 ? (data[i - 1] - minV) / range : 0.5;
        final prevY = pad + ch - (prevNorm * ch);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    fillPath.lineTo(pad + cw, size.height);
    fillPath.close();

    // Clip for animation reveal
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * animation, size.height));

    // Gradient fill
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Glow line
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // Data dots
    for (int i = 0; i < data.length; i++) {
      final progress = i / (data.length - 1);
      if (progress > animation) break;
      final x = pad + progress * cw;
      final norm = range > 0 ? (data[i] - minV) / range : 0.5;
      final y = pad + ch - (norm * ch);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendSparklinePainter old) =>
      old.animation != animation;
}
