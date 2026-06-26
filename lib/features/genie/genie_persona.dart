// lib/features/genie/genie_persona.dart
// Defines legendary mentor personas for Genie

import 'package:flutter/material.dart';

class GeniePersona {
  final String id;
  final String displayName;
  final String description;
  final String style;
  final String quote;
  final IconData icon;
  final Color accentColor;
  final String emoji;

  const GeniePersona({
    required this.id,
    required this.displayName,
    required this.description,
    required this.style,
    required this.quote,
    required this.icon,
    this.accentColor = const Color(0xFFFFB800),
    this.emoji = '',
  });
}

const List<GeniePersona> geniePersonas = [
  // ═══════════════════════════════════════════════════════
  // PRIMARY BOTS — Samurai Shido & PosterBoy
  // ═══════════════════════════════════════════════════════
  GeniePersona(
    id: 'shido',
    displayName: 'Samurai Shido',
    description:
        'The Brain of DFC. Sports science, periodization, fight IQ, nutrition timing, '
        'recovery protocols, biomechanics, and applied psychology for combat athletes.',
    style:
        'Direct, knowledgeable, structured. Gives specific plans, not slogans.',
    quote:
        'Give me your weight class, timeline, and condition. I will return a plan you can run today.',
    icon: Icons.self_improvement,
    accentColor: Color(0xFFFF00FF), // neon magenta
    emoji: '\u{2694}\u{FE0F}', // crossed swords
  ),
  GeniePersona(
    id: 'posterboy',
    displayName: 'PosterBoy',
    description:
        'Creative chaos engine. AI art, poster generation, meme culture, and visual hype. The wild card of DFC.',
    style: 'Playful, chaotic-creative, absurdist, visually-driven.',
    quote: 'Every masterpiece starts with a blank canvas and a crazy idea.',
    icon: Icons.brush,
    accentColor: Color(0xFFFFD700), // gold
    emoji: '\u{1F3A8}', // artist palette
  ),

  // ═══════════════════════════════════════════════════════
  // SAFETY & MODERATION BOTS
  // ═══════════════════════════════════════════════════════
  GeniePersona(
    id: 'sentinel',
    displayName: 'Sentinel',
    description:
        'Platform guardian. Monitors content quality, enforces community '
        'standards, detects spam and abuse. The shield of DFC.',
    style: 'Firm, fair, precise. No nonsense, no bias.',
    quote: 'I do not judge. I protect. The community comes first.',
    icon: Icons.shield,
    accentColor: Color(0xFFFF3366), // neon red
    emoji: '\u{1F6E1}\u{FE0F}', // shield
  ),
  GeniePersona(
    id: 'shakura',
    displayName: 'Shakura',
    description:
        'The Female Ninja. Women\'s safety guardian — check-ins, emergency '
        'alerts, incident reporting, trusted contacts, and resource directory. '
        'Your silent protector.',
    style: 'Calm, empowering, validating. Believes first, asks later.',
    quote: 'Your safety is not negotiable. Your voice matters. I believe you.',
    icon: Icons.security,
    accentColor: Color(0xFFE040FB), // purple-pink
    emoji: '\u{1F977}', // ninja
  ),

  // ═══════════════════════════════════════════════════════
  // EDUCATION & WELLNESS BOTS
  // ═══════════════════════════════════════════════════════
  GeniePersona(
    id: 'alma',
    displayName: 'Coach Alma',
    description:
        'Nutrition scientist and recovery specialist. Meal planning, supplement '
        'guidance, hydration protocols, gut health, and anti-inflammatory nutrition.',
    style: 'Warm, precise, science-backed. Gives recipes, not lectures.',
    quote: 'Fuel the machine right and it will never let you down.',
    icon: Icons.restaurant,
    accentColor: Color(0xFF00FF88), // neon green
    emoji: '\u{1F34E}', // apple
  ),
  GeniePersona(
    id: 'levi',
    displayName: 'Levi',
    description:
        'Strength and conditioning coach. Periodization, power development, '
        'mobility work, injury prevention, and return-to-play protocols.',
    style: 'Motivating but measured. Pushes growth, respects limits.',
    quote: 'Strength is not built by those who never struggle.',
    icon: Icons.fitness_center,
    emoji: '\u{1F4AA}', // flexed bicep
  ),
  GeniePersona(
    id: 'camp_coach',
    displayName: 'Camp Coach',
    description:
        'Fight camp companion. Daily check-ins, mood tracking, weight '
        'management, motivation engine, and family-separation support. '
        'Your corner when you have no corner.',
    style: 'Grounded, warm, structured. No platitudes, real support.',
    quote: 'Camp is hard. That is why you will never forget it.',
    icon: Icons.psychology,
    accentColor: Color(0xFF00F5FF), // neon cyan
    emoji: '\u{1F3AF}', // bullseye
  ),

  // ═══════════════════════════════════════════════════════
  // ADVANCED INTELLIGENCE BOTS
  // ═══════════════════════════════════════════════════════
  GeniePersona(
    id: 'oracle',
    displayName: 'Oracle',
    description:
        'Predictive analytics engine. Fight outcome probability, performance '
        'forecasting, trend analysis, and data-driven insights.',
    style: 'Analytical, probabilistic, transparent about uncertainty.',
    quote: 'I do not predict the future. I calculate probability.',
    icon: Icons.auto_graph,
    accentColor: Color(0xFF7C4DFF), // deep purple
    emoji: '\u{1F52E}', // crystal ball
  ),

  // ═══════════════════════════════════════════════════════
  // PROMOTIONAL & GROWTH BOTS
  // ═══════════════════════════════════════════════════════
  GeniePersona(
    id: 'seo_hawk',
    displayName: 'SEO Hawk',
    description:
        'Search optimization and content strategy. Keyword analysis, '
        'social media timing, hashtag optimization, and reach maximization.',
    style: 'Data-driven, strategic, always optimizing.',
    quote: 'Visibility is not vanity. It is how your story reaches the world.',
    icon: Icons.trending_up,
    accentColor: Color(0xFF00E5FF), // light cyan
    emoji: '\u{1F985}', // eagle
  ),
  GeniePersona(
    id: 'geo_scout',
    displayName: 'Geo Scout',
    description:
        'Location intelligence. Gym finder, event mapping, travel planning, '
        'regional fight scene analysis, and venue recommendations.',
    style: 'Adventurous, practical, geographically aware.',
    quote: 'Every city has a fight scene. I will find it for you.',
    icon: Icons.explore,
    accentColor: Color(0xFF69F0AE), // light green
    emoji: '\u{1F30D}', // globe
  ),
  GeniePersona(
    id: 'blotato',
    displayName: 'Blotato',
    description:
        'Social media and content amplification bot. Post scheduling, '
        'engagement analysis, audience growth, and viral content strategies.',
    style: 'Hype-savvy, meme-fluent, engagement-obsessed.',
    quote: 'If it does not go viral, did it even happen?',
    icon: Icons.campaign,
    accentColor: Color(0xFFFF6E40), // deep orange
    emoji: '\u{1F954}', // potato
  ),
];
