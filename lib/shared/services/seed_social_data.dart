import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeedSocialData {
  static Future<void> runSeed() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final WriteBatch batch = db.batch();
    final CollectionReference postsRef = db.collection('posts');

    debugPrint('🌱 Starting DFC Culture Data Seed...');

    final List<Map<String, dynamic>> initialPosts = [
      {
        'authorId': 'coach_mike_01',
        'displayName': 'Coach Mike Brown',
        'userRole': 'coach',
        'content':
            'Quick tip for all my fighters: Stop chasing the knockout in sparring. Work your setups, develop your timing, and trust the process. The power comes from precision, not from trying to take your partner\'s head off. Train smart, protect your teammates. 🧠',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 142,
        'commentCount': 12,
        'shareCount': 5,
        'postType': 'text',
      },
      {
        'authorId': 'gym_sydney_academy',
        'displayName': 'Sydney Combat Academy',
        'userRole': 'gym',
        'content':
            '🛡️ WOMEN\'S ONLY FUNDAMENTALS CLASS 🛡️\n\nStarting next week, we are launching a 6-week fundamentals program taught by women, for women. BJJ, striking, and self-defense in a 100% safe, supportive, and ego-free environment. First class is completely free. We believe the mats are for everyone. DM us to reserve your spot! 🇦🇺',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 385,
        'commentCount': 44,
        'shareCount': 89,
        'postType': 'announcement',
      },
      {
        'authorId': 'fighter_sarah_m',
        'displayName': 'Sarah "Savage" Mitchell',
        'userRole': 'fighter',
        'content':
            'Just signed my first pro MMA contract! 🎉 After 3 years as an amateur, 12 fights, and working 2 jobs to pay for training — we made it. Never give up on your dreams, and never let anyone tell you this sport isn\'t for you. Shoutout to my team and my coaches for protecting me and pushing me. Let\'s go! ❤️',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': false,
        'likes': 892,
        'commentCount': 105,
        'shareCount': 12,
        'postType': 'text',
      },
      {
        'authorId': 'dfc_official',
        'displayName': 'Data Fight Central',
        'userRole': 'admin',
        'content':
            'FIGHTERS ARE SAFER WITH DFC.\n\nWe are rolling out our new Guardian Mode and CTE tracking protocols globally. We believe in building platforms that protect athletes\' futures, not just their present. Fighting is tough enough; your platform shouldn\'t be.',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 1240,
        'commentCount': 88,
        'shareCount': 340,
        'postType': 'announcement',
      },
      {
        'authorId': 'fighter_luke_m',
        'displayName': 'Luke Modini',
        'userRole': 'fighter',
        'content':
            'Hard loss this weekend. My opponent caught me clean, no excuses. But I\'ll be back stronger. This setback is temporary. Back in the gym on Monday. Respect to the man across from me, we went to war. IBC IV... I\'m coming for redemption. 🔥',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 560,
        'commentCount': 72,
        'shareCount': 4,
        'postType': 'text',
      },
      {
        'authorId': 'dfc_community',
        'displayName': 'DFC Community Hub',
        'userRole': 'community',
        'content':
            '🧠 Post-Career Depression: The Invisible Opponent\n\nFighters describe retirement as the hardest fight. The sudden loss of identity creates a void. DFC\'s global peer support network connects retired fighters who understand. You are never fighting alone. Check the resources tab in the app today.',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 2100,
        'commentCount': 150,
        'shareCount': 500,
        'postType': 'text',
      },
    ];

    try {
      for (var postData in initialPosts) {
        final DocumentReference docRef = postsRef.doc();
        batch.set(docRef, postData);
      }

      await batch.commit();
      debugPrint(
        '✅ DFC Culture Data Seeded Successfully! Added ${initialPosts.length} posts.',
      );
    } catch (e) {
      debugPrint('❌ Error seeding data: $e');
    }
  }
}
