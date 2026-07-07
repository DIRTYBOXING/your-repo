import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV Events Seed Data
/// ═══════════════════════════════════════════════════════════════════════════
/// Creates realistic PPV events in Firestore for development and demo

class PPVSeeder {
  static final _db = FirebaseFirestore.instance;

  /// Seed realistic PPV events
  static Future<void> seedPPVEvents() async {
    developer.log('Seeding PPV events...', name: 'PPVSeeder');

    final events = [
      // ── UFC 318: Makhachev vs Volkanovski III ────────────────────────────
      {
        'id': 'ufc-318-makhachev-volkanovski-3',
        'title': 'Makhachev vs Volkanovski III',
        'subtitle': 'UFC 318 — Lightweight World Championship',
        'description':
            'The trilogy fight the world has been waiting for. Islam Makhachev defends the UFC Lightweight Championship against Alexander Volkanovski in the rubber match of one of the greatest rivalries in MMA history. Live from Qudos Bank Arena, Sydney. 4K multi-cam with fighter cams, dual commentary, and full replay access.',
        'promotion': 'UFC',
        'sportType': 'MMA',
        'venue': 'Qudos Bank Arena, Sydney NSW',
        'eventDate': DateTime.now()
            .add(const Duration(days: 12))
            .toIso8601String(),
        'eventStatus': 'onSale',
        'posterUrl':
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&q=80',
        'heroImageUrl':
            'https://images.unsplash.com/photo-1544390623-df9c1db162e4?w=1200&q=80',
        'hasDrmProtection': true,
        'hasReplayAccess': true,
        'hasMultiCam': true,
        'peakViewers': 1800000,
        'pricingTiers': {
          'standard': {
            'title': 'Standard Access',
            'description': 'Full live event + 7-day replay',
            'amountCents': 5499,
            'currency': 'aud',
            'features': [
              'Live HD stream',
              '7-day replay access',
              'Round-by-round stats',
              'Community fight chat',
            ],
          },
          'premium': {
            'title': 'Premium Bundle',
            'description': 'Everything + multi-cam & analysis',
            'amountCents': 7999,
            'currency': 'aud',
            'isRecommended': true,
            'features': [
              '4K + 60fps stream',
              'Fighter corner cams',
              'Joe Rogan + Daniel Cormier commentary',
              '30-day replay access',
              'Exclusive post-fight press conference',
            ],
          },
          'ultimate': {
            'title': 'Ultimate VIP',
            'description': 'All access + VIP perks',
            'amountCents': 9999,
            'currency': 'aud',
            'features': [
              '4K + 60fps stream',
              'All camera angles including Octagon-side',
              'Multi-language commentary (EN / ES / PT)',
              'Lifetime replay access',
              'VIP backstage pass stream',
              'Post-fight fighter interviews',
            ],
          },
        },
        'fightCard': [
          {
            'order': 0,
            'mainTitle': 'UFC LIGHTWEIGHT WORLD CHAMPIONSHIP — 5 Rounds',
            'fighter1Name': 'Islam Makhachev',
            'fighter1Nickname': 'The Eagle 2.0',
            'fighter1Record': '26-1',
            'fighter1Country': 'Russia',
            'fighter2Name': 'Alexander Volkanovski',
            'fighter2Nickname': 'The Great',
            'fighter2Record': '26-4',
            'fighter2Country': 'Australia',
            'fighterId1': 'fighter_makhachev',
            'fighterId2': 'fighter_volkanovski',
            'weightClass': 'Lightweight (155 lb)',
            'isTitleFight': true,
          },
          {
            'order': 1,
            'mainTitle': 'CO-MAIN — UFC WOMEN\'S STRAWWEIGHT CHAMPIONSHIP',
            'fighter1Name': 'Zhang Weili',
            'fighter1Nickname': 'Magnum',
            'fighter1Record': '24-3',
            'fighter1Country': 'China',
            'fighter2Name': 'Tatiana Suarez',
            'fighter2Nickname': 'Baby Hulk',
            'fighter2Record': '10-0',
            'fighter2Country': 'USA',
            'fighterId1': 'fighter_zhang_weili',
            'fighterId2': 'fighter_suarez',
            'weightClass': 'Women\'s Strawweight (115 lb)',
            'isTitleFight': true,
          },
          {
            'order': 2,
            'mainTitle': 'MAIN CARD',
            'fighter1Name': 'Robert Whittaker',
            'fighter1Nickname': 'The Reaper',
            'fighter1Record': '25-7',
            'fighter1Country': 'Australia',
            'fighter2Name': 'Khamzat Chimaev',
            'fighter2Nickname': 'Borz',
            'fighter2Record': '13-0',
            'fighter2Country': 'Sweden',
            'fighterId1': 'fighter_whittaker',
            'fighterId2': 'fighter_chimaev',
            'weightClass': 'Middleweight (185 lb)',
            'isTitleFight': false,
          },
          {
            'order': 3,
            'mainTitle': 'MAIN CARD',
            'fighter1Name': 'Justin Gaethje',
            'fighter1Nickname': 'The Highlight',
            'fighter1Record': '25-5',
            'fighter1Country': 'USA',
            'fighter2Name': 'Beneil Dariush',
            'fighter2Nickname': 'Benny',
            'fighter2Record': '22-5-1',
            'fighter2Country': 'USA',
            'fighterId1': 'fighter_gaethje',
            'fighterId2': 'fighter_dariush',
            'weightClass': 'Lightweight (155 lb)',
            'isTitleFight': false,
          },
          {
            'order': 4,
            'mainTitle': 'PRELIMS',
            'fighter1Name': 'Dan Hooker',
            'fighter1Nickname': 'The Hangman',
            'fighter1Record': '24-13',
            'fighter1Country': 'New Zealand',
            'fighter2Name': 'Mateusz Gamrot',
            'fighter2Nickname': 'Gamer',
            'fighter2Record': '22-2',
            'fighter2Country': 'Poland',
            'fighterId1': 'fighter_hooker',
            'fighterId2': 'fighter_gamrot',
            'weightClass': 'Lightweight (155 lb)',
            'isTitleFight': false,
          },
        ],
      },

      // ── ONE Championship: Angels of Death ───────────────────────────────
      {
        'id': 'one-fc-angels-of-death',
        'title': 'Demetrious Johnson vs Rodtang Jitmuangnon',
        'subtitle': 'ONE Championship: Angels of Death — Super Fight',
        'description':
            'ONE Championship returns with the must-see super fight between MMA legend Demetrious "Mighty Mouse" Johnson and Muay Thai superstar Rodtang "The Iron Man" Jitmuangnon. Mixed rules: Round 1 Muay Thai, Round 2+ MMA. Live from Singapore Indoor Stadium. Four world title fights on the card.',
        'promotion': 'ONE Championship',
        'sportType': 'MMA / Muay Thai',
        'venue': 'Singapore Indoor Stadium',
        'eventDate': DateTime.now()
            .add(const Duration(days: 19))
            .toIso8601String(),
        'eventStatus': 'onSale',
        'posterUrl':
            'https://images.unsplash.com/photo-1517130038641-a774d04afb3c?w=800&q=80',
        'heroImageUrl':
            'https://images.unsplash.com/photo-1517130038641-a774d04afb3c?w=1200&q=80',
        'hasDrmProtection': true,
        'hasReplayAccess': true,
        'hasMultiCam': true,
        'peakViewers': 900000,
        'pricingTiers': {
          'standard': {
            'title': 'Standard Access',
            'description': 'Live event + 14-day replay',
            'amountCents': 3999,
            'currency': 'aud',
            'features': ['Live HD stream', '14-day replay', 'Full fight card'],
          },
          'premium': {
            'title': 'Super Fight Bundle',
            'description': 'Premium + behind-the-scenes',
            'amountCents': 5999,
            'currency': 'aud',
            'isRecommended': true,
            'features': [
              '4K stream',
              'Multi-cam angles',
              '60-day replay',
              'Pre-fight open workouts',
              'Post-fight press conference',
            ],
          },
        },
        'fightCard': [
          {
            'order': 0,
            'mainTitle': 'SUPER FIGHT — Mixed Rules',
            'fighter1Name': 'Demetrious Johnson',
            'fighter1Nickname': 'Mighty Mouse',
            'fighter1Record': '32-4-1',
            'fighter1Country': 'USA',
            'fighter2Name': 'Rodtang Jitmuangnon',
            'fighter2Nickname': 'The Iron Man',
            'fighter2Record': '273-42-10',
            'fighter2Country': 'Thailand',
            'fighterId1': 'fighter_demetrious_johnson',
            'fighterId2': 'fighter_rodtang',
            'weightClass': 'Flyweight',
            'isTitleFight': false,
          },
          {
            'order': 1,
            'mainTitle': 'ONE FLYWEIGHT MMA WORLD CHAMPIONSHIP',
            'fighter1Name': 'Adriano Moraes',
            'fighter1Nickname': 'Mikinho',
            'fighter1Record': '20-4',
            'fighter1Country': 'Brazil',
            'fighter2Name': 'Yuya Wakamatsu',
            'fighter2Record': '17-7-1',
            'fighter2Country': 'Japan',
            'fighterId1': 'fighter_moraes',
            'fighterId2': 'fighter_wakamatsu',
            'weightClass': 'Flyweight MMA',
            'isTitleFight': true,
          },
          {
            'order': 2,
            'mainTitle': 'ONE BANTAMWEIGHT MUAY THAI WORLD CHAMPIONSHIP',
            'fighter1Name': 'Nong-O Hama',
            'fighter1Record': '270-54-10',
            'fighter1Country': 'Thailand',
            'fighter2Name': 'Felipe Lobo',
            'fighter2Record': '30-5',
            'fighter2Country': 'Brazil',
            'fighterId1': 'fighter_nong_o',
            'fighterId2': 'fighter_lobo',
            'weightClass': 'Bantamweight Muay Thai',
            'isTitleFight': true,
          },
        ],
      },

      // ── BKFC KnuckleMania 5 ──────────────────────────────────────────────
      {
        'id': 'bkfc-knucklemania-5',
        'title': 'Artem Lobov vs Mike Perry II',
        'subtitle':
            'BKFC KnuckleMania 5 — Heavyweight & Cruiserweight Championships',
        'description':
            'BKFC\'s biggest night returns. Artem Lobov and Mike "Platinum" Perry collide in the most anticipated bare knuckle rematch of the decade. Five title fights, no gloves, pure heart. Filmed live from Tampa, Florida with cage-side cameras and slow-motion replay on every exchange.',
        'promotion': 'BKFC',
        'sportType': 'Bare Knuckle Boxing',
        'venue': 'MidFlorida Credit Union Amphitheatre, Tampa FL',
        'eventDate': DateTime.now()
            .add(const Duration(days: 26))
            .toIso8601String(),
        'eventStatus': 'presale',
        'posterUrl':
            'https://images.unsplash.com/photo-1511379938547-c1f69b13d835?w=800&q=80',
        'heroImageUrl':
            'https://images.unsplash.com/photo-1511379938547-c1f69b13d835?w=1200&q=80',
        'hasDrmProtection': true,
        'hasReplayAccess': true,
        'hasMultiCam': true,
        'peakViewers': 400000,
        'pricingTiers': {
          'standard': {
            'title': 'Standard Access',
            'description': 'Live event + 7-day replay',
            'amountCents': 2999,
            'currency': 'aud',
            'features': ['Live HD stream', '7-day replay', 'All 10 bouts'],
          },
          'premium': {
            'title': 'KnuckleMania Premium',
            'description': 'Live + slow-mo replays + backstage',
            'amountCents': 4999,
            'currency': 'aud',
            'isRecommended': true,
            'features': [
              '4K stream',
              'Cage-side camera',
              'Slow-motion replay every exchange',
              'Lifetime replay access',
              'Exclusive fighter walkout footage',
              'Post-fight locker room interviews',
            ],
          },
        },
        'fightCard': [
          {
            'order': 0,
            'mainTitle': 'BKFC CRUISERWEIGHT CHAMPIONSHIP',
            'fighter1Name': 'Artem Lobov',
            'fighter1Nickname': 'The Russian Hammer',
            'fighter1Record': '4-1 (BKFC)',
            'fighter1Country': 'Russia',
            'fighter2Name': 'Mike Perry',
            'fighter2Nickname': 'Platinum',
            'fighter2Record': '5-0 (BKFC)',
            'fighter2Country': 'USA',
            'fighterId1': 'fighter_lobov',
            'fighterId2': 'fighter_mike_perry',
            'weightClass': 'Cruiserweight',
            'isTitleFight': true,
          },
          {
            'order': 1,
            'mainTitle': 'BKFC HEAVYWEIGHT CHAMPIONSHIP',
            'fighter1Name': 'Joey Beltran',
            'fighter1Nickname': 'The Mexican Warrior',
            'fighter1Record': '3-1 (BKFC)',
            'fighter1Country': 'USA',
            'fighter2Name': 'Dillon Cleckler',
            'fighter2Record': '6-1 (BKFC)',
            'fighter2Country': 'USA',
            'fighterId1': 'fighter_beltran',
            'fighterId2': 'fighter_cleckler',
            'weightClass': 'Heavyweight',
            'isTitleFight': true,
          },
          {
            'order': 2,
            'mainTitle': 'BKFC WOMEN\'S FLYWEIGHT CHAMPIONSHIP',
            'fighter1Name': 'Paige VanZant',
            'fighter1Nickname': '12 Gauge',
            'fighter1Record': '3-1 (BKFC)',
            'fighter1Country': 'USA',
            'fighter2Name': 'Britain Hart',
            'fighter2Record': '4-2 (BKFC)',
            'fighter2Country': 'USA',
            'fighterId1': 'fighter_pvz',
            'fighterId2': 'fighter_brit_hart',
            'weightClass': 'Women\'s Flyweight',
            'isTitleFight': true,
          },
        ],
      },

      // ── PFL 2026: Smart Cage World Championships ─────────────────────────
      {
        'id': 'pfl-2026-world-championships',
        'title': 'PFL 2026 World Championships',
        'subtitle': 'Professional Fighters League — \$1M Prize Finals',
        'description':
            'The PFL Season Finals are here. Six weight classes, \$1 million on the line in every division. The PFL Smart Cage tracks real-time fighter data: speed, distance, heart rate, and significant strikes delivered live to your screen. Experience the most data-driven night in combat sports history.',
        'promotion': 'PFL',
        'sportType': 'MMA',
        'venue': 'Madison Square Garden, New York NY',
        'eventDate': DateTime.now()
            .add(const Duration(days: 35))
            .toIso8601String(),
        'eventStatus': 'announced',
        'posterUrl':
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&q=80',
        'heroImageUrl':
            'https://images.unsplash.com/photo-1544390623-df9c1db162e4?w=1200&q=80',
        'hasDrmProtection': true,
        'hasReplayAccess': true,
        'hasMultiCam': true,
        'peakViewers': 600000,
        'pricingTiers': {
          'standard': {
            'title': 'Standard Access',
            'description': 'All 6 finals + 14-day replay',
            'amountCents': 4999,
            'currency': 'aud',
            'features': [
              'Live HD stream',
              'All six championship bouts',
              '14-day replay access',
              'Smart Cage live stats overlay',
            ],
          },
          'premium': {
            'title': 'Data Pack',
            'description': 'Everything + real-time analytics',
            'amountCents': 6999,
            'currency': 'aud',
            'isRecommended': true,
            'features': [
              '4K stream',
              'Smart Cage live biometric data',
              'Strike accuracy tracker',
              'Round-by-round scoring overlay',
              '60-day replay',
              'Post-fight analytics report',
            ],
          },
        },
        'fightCard': [
          {
            'order': 0,
            'mainTitle': 'PFL LIGHTWEIGHT WORLD CHAMPIONSHIP — \$1M',
            'fighter1Name': 'Kayla Harrison',
            'fighter1Nickname': 'The Knight',
            'fighter1Record': '20-1',
            'fighter1Country': 'USA',
            'fighter2Name': 'Larissa Pacheco',
            'fighter2Record': '19-5',
            'fighter2Country': 'Brazil',
            'fighterId1': 'fighter_kayla_harrison',
            'fighterId2': 'fighter_pacheco',
            'weightClass': 'Women\'s Lightweight (155 lb)',
            'isTitleFight': true,
          },
          {
            'order': 1,
            'mainTitle': 'PFL HEAVYWEIGHT WORLD CHAMPIONSHIP — \$1M',
            'fighter1Name': 'Ante Delija',
            'fighter1Record': '20-5',
            'fighter1Country': 'Croatia',
            'fighter2Name': 'Denis Goltsov',
            'fighter2Record': '28-6',
            'fighter2Country': 'Russia',
            'fighterId1': 'fighter_delija',
            'fighterId2': 'fighter_goltsov',
            'weightClass': 'Heavyweight (265 lb)',
            'isTitleFight': true,
          },
        ],
      },
    ];

    try {
      for (final event in events) {
        await _db
            .collection('ppv_events')
            .doc(event['id'] as String)
            .set(event);
        developer.log('Seeded: ${event['title']}', name: 'PPVSeeder');
      }
      developer.log('PPV events seeded successfully', name: 'PPVSeeder');
    } catch (e) {
      developer.log('Error seeding PPV events: $e', name: 'PPVSeeder');
      rethrow;
    }
  }

  /// Clear all PPV events (for reset)
  static Future<void> clearPPVEvents() async {
    developer.log('Clearing PPV events...', name: 'PPVSeeder');
    try {
      final snapshot = await _db.collection('ppv_events').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      developer.log('PPV events cleared', name: 'PPVSeeder');
    } catch (e) {
      developer.log('Error clearing PPV events: $e', name: 'PPVSeeder');
      rethrow;
    }
  }

  /// Get PPV event count
  static Future<int> getPPVEventCount() async {
    try {
      final snapshot = await _db.collection('ppv_events').get();
      return snapshot.docs.length;
    } catch (e) {
      developer.log('Error counting PPV events: $e', name: 'PPVSeeder');
      return 0;
    }
  }
}
