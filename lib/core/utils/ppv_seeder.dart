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
      {
        'id': 'ufc-smith-jones',
        'title': 'Smith vs Jones',
        'subtitle': 'UFC Championship Fight Night',
        'description':
            'Experience the ultimate in combat sports with crystal-clear 4K streaming, multiple camera angles, and expert commentary. This main event features two of the best fighters in the sport competing for the championship title. Watch live or catch the full replay within 30 days of the event.',
        'promotion': 'UFC',
        'sportType': 'MMA',
        'eventDate': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
        'eventStatus': 'onSale',
        'posterUrl':
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&q=80',
        'heroImageUrl':
            'https://images.unsplash.com/photo-1544390623-df9c1db162e4?w=1200&q=80',
        'hasDrmProtection': true,
        'hasReplayAccess': true,
        'hasMultiCam': true,
        'peakViewers': 250000,
        'pricingTiers': {
          'standard': {
            'title': 'Standard Access',
            'description': 'Full live event + 7-day replay',
            'amountCents': 4999,
            'currency': 'aud',
            'features': [
              'Live HD stream',
              '7-day replay access',
              'Match highlights',
              'Community chat',
            ],
          },
          'premium': {
            'title': 'Premium Bundle',
            'description': 'Everything + multi-cam & analysis',
            'amountCents': 6999,
            'currency': 'aud',
            'isRecommended': true,
            'features': [
              '4K + 60fps stream',
              'Multiple camera angles',
              'Expert commentary',
              '30-day replay access',
              'Exclusive fighter insights',
            ],
          },
          'ultimate': {
            'title': 'Ultimate VIP',
            'description': 'All access + VIP perks',
            'amountCents': 8999,
            'currency': 'aud',
            'features': [
              '4K + 60fps stream',
              'All camera angles',
              'Multi-language commentary',
              'Lifetime replay access',
              'VIP live chat',
              'Post-fight interviews',
            ],
          },
        },
        'fightCard': [
          {
            'order': 0,
            'mainTitle': 'MAIN EVENT',
            'fighter1Name': 'Alex Smith',
            'fighter2Name': 'Jon Jones Jr',
            'fighterId1': 'fighter_smith',
            'fighterId2': 'fighter_jones',
            'weightClass': 'Light Heavyweight',
            'fighter1ImageUrl':
                'https://images.unsplash.com/photo-1566576912321-d58ddd5df601?w=200',
            'fighter2ImageUrl':
                'https://images.unsplash.com/photo-1577805643773-11d1cb8e4acc?w=200',
          },
          {
            'order': 1,
            'mainTitle': 'CO-MAIN EVENT',
            'fighter1Name': 'Sarah Anderson',
            'fighter2Name': 'Maria Rodriguez',
            'fighterId1': 'fighter_anderson',
            'fighterId2': 'fighter_rodriguez',
            'weightClass': 'Women Bantamweight',
            'fighter1ImageUrl':
                'https://images.unsplash.com/photo-1532384748853-8f68a7ec4c5e?w=200',
            'fighter2ImageUrl':
                'https://images.unsplash.com/photo-1544367567-0d6fcffe7f1f?w=200',
          },
          {
            'order': 2,
            'mainTitle': 'PRELIMINARY',
            'fighter1Name': 'Mike Johnson',
            'fighter2Name': 'Chris Lee',
            'fighterId1': 'fighter_johnson',
            'fighterId2': 'fighter_lee',
            'weightClass': 'Welterweight',
          },
        ],
      },
      {
        'id': 'boxing-mayweather-legacy',
        'title': 'Exhibition Match',
        'subtitle': 'Floyd Mayweather Legacy Event',
        'description':
            'Join us for an extraordinary exhibition featuring legendary boxing talent. This special event showcases elite-level boxing technique, strategy, and athleticism. Perfect for boxing enthusiasts and newcomers alike. Full 4K broadcast with expert analysis and detailed fight breakdown.',
        'promotion': 'Showtime Boxing',
        'sportType': 'Boxing',
        'eventDate': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'eventStatus': 'presale',
        'posterUrl':
            'https://images.unsplash.com/photo-1517130038641-a774d04afb3c?w=800&q=80',
        'heroImageUrl':
            'https://images.unsplash.com/photo-1517130038641-a774d04afb3c?w=1200&q=80',
        'hasDrmProtection': true,
        'hasReplayAccess': true,
        'hasMultiCam': true,
        'pricingTiers': {
          'standard': {
            'title': 'Standard Access',
            'description': 'Live event + 30-day replay',
            'amountCents': 5499,
            'currency': 'aud',
            'features': [
              'Live HD stream',
              '30-day replay access',
              'Knockdown replays',
            ],
          },
          'premium': {
            'title': 'Premium Bundle',
            'description': 'All + expert commentary',
            'amountCents': 7499,
            'currency': 'aud',
            'isRecommended': true,
            'features': [
              '4K stream',
              'Expert expert commentary',
              '90-day replay',
              'Training breakdown videos',
            ],
          },
        },
        'fightCard': [
          {
            'order': 0,
            'mainTitle': 'MAIN EVENT',
            'fighter1Name': 'Floyd Mayweather Jr',
            'fighter2Name': 'Oscar De La Hoya',
            'fighterId1': 'fighter_mayweather',
            'fighterId2': 'fighter_oscar',
            'weightClass': 'Middleweight',
          },
        ],
      },
      {
        'id': 'bkfc-heavyweight-championship',
        'title': 'Heavyweight Championship',
        'subtitle': 'Bare Knuckle Fighting Championship',
        'description':
            'The most intense heavyweight matchup of the year. Two of the toughest bare knuckle fighters face off in an epic battle for championship glory. No padding, pure skill, and incredible heart. Watch in stunning 4K with multiple angles and expert analysis.',
        'promotion': 'BKFC',
        'sportType': 'Bare Knuckle Boxing',
        'eventDate': DateTime.now()
            .add(const Duration(days: 14))
            .toIso8601String(),
        'eventStatus': 'announced',
        'posterUrl':
            'https://images.unsplash.com/photo-1511379938547-c1f69b13d835?w=800&q=80',
        'heroImageUrl':
            'https://images.unsplash.com/photo-1511379938547-c1f69b13d835?w=1200&q=80',
        'hasDrmProtection': true,
        'hasReplayAccess': true,
        'hasMultiCam': false,
        'pricingTiers': {
          'standard': {
            'title': 'Standard Access',
            'description': 'Live event only',
            'amountCents': 2999,
            'currency': 'aud',
            'features': ['Live HD stream', 'Championship bout'],
          },
          'premium': {
            'title': 'Premium',
            'description': 'Live + replay access',
            'amountCents': 4999,
            'currency': 'aud',
            'isRecommended': true,
            'features': [
              'Live 4K stream',
              'Lifetime replay',
              'Exclusive fighter interviews',
              'Behind-the-scenes content',
            ],
          },
        },
        'fightCard': [
          {
            'order': 0,
            'mainTitle': 'HEAVYWEIGHT CHAMPIONSHIP',
            'fighter1Name': 'Hanz Brown',
            'fighter2Name': 'Frank Anderson',
            'fighterId1': 'fighter_brown',
            'fighterId2': 'fighter_anderson_bkfc',
            'weightClass': 'Heavyweight',
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
