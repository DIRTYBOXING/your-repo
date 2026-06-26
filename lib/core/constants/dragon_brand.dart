import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DRAGON BRAND — THE BEAST OF DFC
/// Visual identity, color palette, animation specs, pass tiers
/// ═══════════════════════════════════════════════════════════════════════════

abstract class DragonBrand {
  DragonBrand._();

  // ── Brand Identity ──────────────────────────────────────────────────────
  static const String name = 'The Dragon';
  static const String tagline = 'Unleash The Beast';
  static const String altTagline = 'Where Fighters Become Legends';
  static const String feedTagline = 'FightCentral — Feed the Fire';
  static const String manifesto =
      'Unleash a symbol that moves, sells, and tells stories. '
      'The Dragon is not just a logo — it\'s the engine for your content, '
      'the badge for your superfans, and the visual roar that turns posters '
      'into conversions.';

  // ── Color Palette ───────────────────────────────────────────────────────
  static const Color crimson = Color(0xFFC62828);
  static const Color crimsonLight = Color(0xFFEF5350);
  static const Color midnight = Color(0xFF0B0F1A);
  static const Color gold = Color(0xFFFFC857);
  static const Color goldBright = Color(0xFFFFD700);
  static const Color ashGray = Color(0xFFE6E9EE);
  static const Color emberOrange = Color(0xFFFF6B35);
  static const Color flameYellow = Color(0xFFFFAB00);

  // ── Gradient Presets ────────────────────────────────────────────────────
  static const LinearGradient fireGradient = LinearGradient(
    colors: [crimson, emberOrange, flameYellow],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient crestGradient = LinearGradient(
    colors: [midnight, Color(0xFF1A0A2E), crimson],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldShimmer = LinearGradient(
    colors: [gold, goldBright, gold],
  );

  // ── Animation Specs ─────────────────────────────────────────────────────
  static const Duration wingFlick = Duration(milliseconds: 600);
  static const Duration breathFlare = Duration(milliseconds: 400);
  static const Duration crestReveal = Duration(milliseconds: 1000);
  static const Duration idlePulse = Duration(milliseconds: 800);
  static const Duration notificationPop = Duration(milliseconds: 600);

  // ── Dragon Pass Tiers ───────────────────────────────────────────────────
  static const List<DragonPassTier> passTiers = [
    DragonPassTier(
      id: 'bronze',
      name: 'Bronze Dragon',
      priceMonthly: 0,
      color: Color(0xFFCD7F32),
      perks: ['Basic feed access', 'Community chat', 'Event notifications'],
    ),
    DragonPassTier(
      id: 'silver',
      name: 'Silver Dragon',
      priceMonthly: 4.0,
      color: Color(0xFFC0C0C0),
      perks: [
        'Early ticket access',
        'Exclusive Discord channel',
        'Silver badge',
        'Monthly merch drops',
        'Ad-lite experience',
      ],
    ),
    DragonPassTier(
      id: 'gold',
      name: 'Gold Dragon',
      priceMonthly: 8.0,
      color: goldBright,
      perks: [
        'All Silver perks',
        'VIP meet & greet access',
        'Gold badge + AR filters',
        'Priority PPV pre-sale',
        'Ad-free experience',
        'Exclusive fight analysis',
        'Limited collectible drops',
      ],
    ),
  ];

  // ── Platform Distribution Config ────────────────────────────────────────
  static const Map<String, PlatformConfig> platforms = {
    'tiktok': PlatformConfig(
      id: 'tiktok',
      name: 'TikTok',
      icon: Icons.music_note,
      color: Color(0xFF010101),
      accent: Color(0xFFEE1D52),
      strength: 'Viral discovery',
      bestContent: '15-60s highlights, knockouts, walkouts',
      aspectRatio: '9:16',
      maxDuration: Duration(seconds: 60),
      leadCapture: 'Bio link → landing page → email capture',
    ),
    'youtube': PlatformConfig(
      id: 'youtube',
      name: 'YouTube',
      icon: Icons.play_circle_fill,
      color: Color(0xFFFF0000),
      accent: Color(0xFFFF0000),
      strength: 'Highest creator revenue',
      bestContent: 'Full fights, analysis, documentaries',
      aspectRatio: '16:9',
      maxDuration: Duration(hours: 4),
      leadCapture: 'End-screen CTAs, memberships, merch shelf',
    ),
    'instagram': PlatformConfig(
      id: 'instagram',
      name: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE4405F),
      accent: Color(0xFFC13584),
      strength: 'Visual commerce',
      bestContent: 'Reels, shoppable posts, story swipeups',
      aspectRatio: '1:1',
      maxDuration: Duration(seconds: 90),
      leadCapture: 'Shoppable posts, lead gen forms, story links',
    ),
    'x': PlatformConfig(
      id: 'x',
      name: 'X',
      icon: Icons.tag,
      color: Color(0xFF000000),
      accent: Color(0xFF1DA1F2),
      strength: 'Real-time buzz',
      bestContent: 'Live commentary, ticket threads, trending hooks',
      aspectRatio: '16:9',
      maxDuration: Duration(minutes: 2),
      leadCapture: 'Ticketed Spaces, reply CTAs, trending hooks',
    ),
    'discord': PlatformConfig(
      id: 'discord',
      name: 'Discord',
      icon: Icons.forum,
      color: Color(0xFF5865F2),
      accent: Color(0xFF5865F2),
      strength: 'Retention & superfans',
      bestContent: 'AMAs, voice rooms, exclusive drops',
      aspectRatio: 'N/A',
      maxDuration: Duration.zero,
      leadCapture: 'Paid tiers, exclusive drops, direct CRM',
    ),
  };

  // ── Ad Format Specs ─────────────────────────────────────────────────────
  static const Map<String, AdFormatSpec> adFormats = {
    'portrait': AdFormatSpec(
      id: 'portrait',
      name: 'Portrait (9:16)',
      width: 1080,
      height: 1920,
      platforms: ['tiktok', 'instagram', 'youtube_shorts'],
      useCase: 'Short-form discovery, stories, reels',
    ),
    'square': AdFormatSpec(
      id: 'square',
      name: 'Square (1:1)',
      width: 1080,
      height: 1080,
      platforms: ['instagram', 'facebook', 'x'],
      useCase: 'Feed posts, shoppable cards, carousels',
    ),
    'landscape': AdFormatSpec(
      id: 'landscape',
      name: 'Landscape (16:9)',
      width: 1920,
      height: 1080,
      platforms: ['youtube', 'x', 'ooh_screens'],
      useCase: 'Long-form, OOH displays, train wraps',
    ),
  };

  // ── Merch SKUs ──────────────────────────────────────────────────────────
  static const List<MerchSKU> initialMerch = [
    MerchSKU(
      id: 'tee-dragon',
      name: 'Dragon Tee',
      priceCents: 5499,
      type: 'apparel',
    ),
    MerchSKU(
      id: 'hoodie-dragon',
      name: 'Dragon Hoodie',
      priceCents: 10999,
      type: 'apparel',
    ),
    MerchSKU(
      id: 'cap-dragon',
      name: 'Dragon Cap',
      priceCents: 4499,
      type: 'apparel',
    ),
    MerchSKU(
      id: 'pin-dragon',
      name: 'Dragon Enamel Pin',
      priceCents: 1799,
      type: 'collectible',
    ),
    MerchSKU(
      id: 'poster-dragon',
      name: 'Dragon Poster',
      priceCents: 2999,
      type: 'print',
    ),
  ];
}

// ── Supporting Models ─────────────────────────────────────────────────────

class DragonPassTier {
  final String id;
  final String name;
  final double priceMonthly;
  final Color color;
  final List<String> perks;

  const DragonPassTier({
    required this.id,
    required this.name,
    required this.priceMonthly,
    required this.color,
    required this.perks,
  });
}

class PlatformConfig {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Color accent;
  final String strength;
  final String bestContent;
  final String aspectRatio;
  final Duration maxDuration;
  final String leadCapture;

  const PlatformConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.accent,
    required this.strength,
    required this.bestContent,
    required this.aspectRatio,
    required this.maxDuration,
    required this.leadCapture,
  });
}

class AdFormatSpec {
  final String id;
  final String name;
  final int width;
  final int height;
  final List<String> platforms;
  final String useCase;

  const AdFormatSpec({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.platforms,
    required this.useCase,
  });
}

class MerchSKU {
  final String id;
  final String name;
  final int priceCents;
  final String type;

  const MerchSKU({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.type,
  });

  String get priceFormatted => '\$${(priceCents / 100).toStringAsFixed(2)}';
}
