import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/social/models/social_clip_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL CLIPS SEEDER — Test Data for Viral Arena Testing
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Generates realistic test social clips for:
///   - Trending algorithm testing
///   - Feed display validation
///   - Player modal verification
///   - PPV attribution flow testing
///
/// Usage:
///   await SocialClipSeeder().seedSocialClips(eventId, sessionId);
///
/// ═══════════════════════════════════════════════════════════════════════════

class SocialClipSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed 20 test clips with varied engagement metrics
  Future<List<String>> seedSocialClips(
    String eventId,
    String sessionId,
  ) async {
    debugPrint('🎬 [SEED] Starting social clips seed for event: $eventId');

    final clipIds = <String>[];

    try {
      // ────────────────────────────────────────────────────────────────────
      // CLIP 1: VIRAL KNOCKDOWN (High trending)
      // ────────────────────────────────────────────────────────────────────
      clipIds.add(await _createClip(
        eventId,
        sessionId,
        id: 'clip_knockout_001',
        fightId: 'fight_main_001',
        clipType: ClipType.knockdown,
        title: '💥 DEVASTATING KNOCKOUT – Adesanya Counter-Striking Masterclass',
        description:
            'Isreal Adesanya lands a stunning 3-punch combination, dropping his opponent with precision timing.',
        fighter1Name: 'Israel Adesanya',
        fighter2Name: 'Alex Pereira',
        round: 2,
        durationSeconds: 18,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&h=225&fit=crop',
        videoUrl: 'https://mux.com/clips/knockout_001.m3u8',
        creatorId: 'creator_espn_001',
        views: 45320,
        likes: 3240,
        shares: 890,
        comments: 120,
        ppvConversions: 156,
      ));

      // ────────────────────────────────────────────────────────────────────
      // CLIP 2: VIRAL SUBMISSION
      // ────────────────────────────────────────────────────────────────────
      clipIds.add(await _createClip(
        eventId,
        sessionId,
        id: 'clip_submission_001',
        fightId: 'fight_main_001',
        clipType: ClipType.submission,
        title: '🔐 LIGHTNING-FAST SUBMISSION – Guillotine Choke Victory',
        description:
            'Khamzat Chimaev secures a devastating guillotine choke in under 90 seconds.',
        fighter1Name: 'Khamzat Chimaev',
        fighter2Name: 'Gilbert Burns',
        round: 1,
        durationSeconds: 25,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1517836357463-d25ddfcbf042?w=400&h=225&fit=crop',
        videoUrl: 'https://mux.com/clips/submission_001.m3u8',
        creatorId: 'creator_ufc_001',
        views: 38920,
        likes: 2180,
        shares: 640,
        comments: 95,
        ppvConversions: 134,
      ));

      // ────────────────────────────────────────────────────────────────────
      // CLIP 3: TRENDING HIGHLIGHT
      // ────────────────────────────────────────────────────────────────────
      clipIds.add(await _createClip(
        eventId,
        sessionId,
        id: 'clip_highlight_001',
        fightId: 'fight_main_002',
        clipType: ClipType.highlight,
        title: '⚡ ROUND RECAP – Maximum Chaos & Redemption Arc',
        description:
            'Watch the entire 5-minute round that changed everything. Down. Back up. War.',
        fighter1Name: 'Max Holloway',
        fighter2Name: 'Yair Rodriguez',
        round: 3,
        durationSeconds: 60,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=225&fit=crop',
        videoUrl: 'https://mux.com/clips/highlight_001.m3u8',
        creatorId: 'creator_espn_001',
        views: 28450,
        likes: 1920,
        shares: 520,
        comments: 78,
        ppvConversions: 89,
      ));

      // ────────────────────────────────────────────────────────────────────
      // CLIP 4: RECENT KNOCKDOWN
      // ────────────────────────────────────────────────────────────────────
      clipIds.add(await _createClip(
        eventId,
        sessionId,
        id: 'clip_knockdown_002',
        fightId: 'fight_co_001',
        clipType: ClipType.knockdown,
        title: '💢 ONE-HITTER QUITTER – Technical KO Display',
        description: 'Precision over power. One calculated strike. Game over.',
        fighter1Name: 'Jon Jones',
        fighter2Name: 'Jamahal Hill',
        round: 1,
        durationSeconds: 12,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1552820728-8ac41f1ce891?w=400&h=225&fit=crop',
        videoUrl: 'https://mux.com/clips/knockdown_002.m3u8',
        creatorId: 'creator_mma_001',
        views: 19240,
        likes: 1340,
        shares: 380,
        comments: 56,
        ppvConversions: 72,
      ));

      // ────────────────────────────────────────────────────────────────────
      // CLIP 5: ROUND END RECAP
      // ────────────────────────────────────────────────────────────────────
      clipIds.add(await _createClip(
        eventId,
        sessionId,
        id: 'clip_round_end_001',
        fightId: 'fight_co_002',
        clipType: ClipType.roundEnd,
        title: '⏱️ ROUND 2 BREAKDOWN – Scramble & Reversal',
        description:
            'The momentum shifted in the final 30 seconds. Watch the upset brewing.',
        fighter1Name: 'Kamaru Usman',
        fighter2Name: 'Leon Edwards',
        round: 2,
        durationSeconds: 15,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1552520514-5fefe8c9ef14?w=400&h=225&fit=crop',
        videoUrl: 'https://mux.com/clips/round_end_001.m3u8',
        creatorId: 'creator_analyst_001',
        views: 15680,
        likes: 980,
        shares: 290,
        comments: 42,
        ppvConversions: 58,
      ));

      // ────────────────────────────────────────────────────────────────────
      // CLIP 6-15: SECONDARY TRENDING CLIPS
      // ────────────────────────────────────────────────────────────────────
      final secondaryClips = [
        (
          'Solid Clinch Work – Ground Control Master',
          'Technical grappling exchange in the clinch.',
          'Sean Strickland',
          'Derek Brunson',
          ClipType.highlight,
          3,
          8920,
          620,
          180,
          28,
          45,
        ),
        (
          'Spinning Back Fist Attempt – Risky Aggression',
          'Flashy striking doesn\'t always work.',
          'Dustin Poirier',
          'Conor McGregor',
          ClipType.highlight,
          2,
          7240,
          510,
          145,
          21,
          38,
        ),
        (
          'Head Movement Clinic – Defense Mastery',
          'Boxing drills in an MMA setting.',
          'Anderson Silva',
          'Chris Weidman',
          ClipType.highlight,
          1,
          6150,
          420,
          120,
          18,
          28,
        ),
        (
          'Submission Escape – Breaking the Chain',
          'Fighter escapes from a rear-naked choke.',
          'Daniel Cormier',
          'Stipe Miocic',
          ClipType.comeback,
          3,
          5320,
          360,
          95,
          15,
          22,
        ),
        (
          'Leg Kick Defense – Checking Like a Pro',
          'Perfect timing on kick checks.',
          'Alex Pereira',
          'Sean Strickland',
          ClipType.highlight,
          2,
          4890,
          320,
          85,
          12,
          18,
        ),
        (
          'Takedown Defense – Footwork & Balance',
          'Wrestling showcase with perfect positioning.',
          'Kamaru Usman',
          'Jorge Masvidal',
          ClipType.highlight,
          1,
          4120,
          280,
          75,
          10,
          15,
        ),
        (
          'Combo Chain – Multi-Strike Assault',
          '4-punch combination into a takedown.',
          'Jan Blachowicz',
          'Glover Teixeira',
          ClipType.highlight,
          4,
          3680,
          240,
          65,
          9,
          12,
        ),
        (
          'Ground & Pound Onslaught',
          'Control + damage on the mat.',
          'Khamzat Chimaev',
          'Nate Diaz',
          ClipType.knockout,
          3,
          3240,
          210,
          55,
          7,
          9,
        ),
        (
          'Counter Strike Precision',
          'Reading opponent, landing cleanly.',
          'George St-Pierre',
          'Michael Bisping',
          ClipType.highlight,
          2,
          2890,
          180,
          48,
          6,
          8,
        ),
        (
          'Footwork Masterclass – Ring Positioning',
          'Movement + timing = control.',
          'Vasyl Lomachenko',
          'Teofimo Lopez',
          ClipType.highlight,
          5,
          2450,
          150,
          38,
          5,
          6,
        ),
      ];

      for (int i = 0; i < secondaryClips.length; i++) {
        final clip = secondaryClips[i];
        clipIds.add(await _createClip(
          eventId,
          sessionId,
          id: 'clip_secondary_${i + 1:03d}',
          fightId: 'fight_secondary_${i + 1}',
          clipType: clip.$5 as ClipType,
          title: clip.$1 as String,
          description: clip.$2 as String,
          fighter1Name: clip.$3 as String,
          fighter2Name: clip.$4 as String,
          round: clip.$6 as int,
          durationSeconds: 15,
          thumbnailUrl:
              'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&h=225&fit=crop',
          videoUrl: 'https://mux.com/clips/secondary_${i + 1}.m3u8',
          creatorId: 'creator_seed_${i + 1}',
          views: clip.$7 as int,
          likes: clip.$8 as int,
          shares: clip.$9 as int,
          comments: clip.$10 as int,
          ppvConversions: clip.$11 as int,
        ));
      }

      debugPrint(
        '✅ [SEED] Social clips seed complete!\n'
        '  ├─ Total clips created: ${clipIds.length}\n'
        '  └─ Event: $eventId / Session: $sessionId',
      );

      return clipIds;
    } catch (e) {
      debugPrint('❌ [SEED] Error seeding social clips: $e');
      rethrow;
    }
  }

  /// Internal: Create a single clip with all engagement metrics
  Future<String> _createClip(
    String eventId,
    String sessionId, {
    required String id,
    required String fightId,
    required ClipType clipType,
    required String title,
    required String description,
    required String fighter1Name,
    required String fighter2Name,
    required int round,
    required int durationSeconds,
    required String thumbnailUrl,
    required String videoUrl,
    required String creatorId,
    required int views,
    required int likes,
    required int shares,
    required int comments,
    required int ppvConversions,
  }) async {
    try {
      final clip = SocialClip(
        id: id,
        eventId: eventId,
        sessionId: sessionId,
        fightId: fightId,
        clipType: clipType,
        sourceMarkerId: '${fightId}_marker_${DateTime.now().millisecondsSinceEpoch}',
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        fighter1Id: 'fighter_${fighter1Name.toLowerCase().replaceAll(' ', '_')}',
        fighter2Id: 'fighter_${fighter2Name.toLowerCase().replaceAll(' ', '_')}',
        fighter1Name: fighter1Name,
        fighter2Name: fighter2Name,
        round: round,
        title: title,
        description: description,
        autoGenerated: false, // Manually seeded
        creatorId: creatorId,
        engagement: ClipEngagement(
          views: views,
          likes: likes,
          shares: shares,
          comments: comments,
          ppvConversions: ppvConversions,
        ),
        createdAt: DateTime.now().subtract(Duration(hours: (20 - views ~/ 5000).clamp(0, 20))),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .doc(id)
          .set(clip.toFirestore());

      debugPrint('  ✅ Clip seeded: $title');
      return id;
    } catch (e) {
      debugPrint('  ❌ Error creating clip: $e');
      rethrow;
    }
  }
}
