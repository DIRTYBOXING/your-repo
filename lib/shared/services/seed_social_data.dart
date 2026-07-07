import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeedSocialData {
  static Future<void> runSeed() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final WriteBatch batch = db.batch();
    final CollectionReference postsRef = db.collection('posts');

    debugPrint('🌱 Starting DFC Culture Data Seed...');

    final List<Map<String, dynamic>> initialPosts = [
      // ── Real fighters / coaches / gyms ─────────────────────────────────
      {
        'authorId': 'fighter_alex_volkanovski',
        'displayName': 'Alexander Volkanovski',
        'userRole': 'fighter',
        'verifiedBadge': 'UFC',
        'content':
            'Everyone\'s talking about the trilogy. I\'ve never been more prepared in my life. Makhachev is the best in the world — but best in the world has been beaten before. Sydney, get ready. The Great is coming home. 🦅🇦🇺',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 48200,
        'commentCount': 3800,
        'shareCount': 12400,
        'postType': 'text',
        'tags': ['UFC318', 'MakhachevVolkanovski', 'TheGreat'],
      },
      {
        'authorId': 'fighter_islam_makhachev',
        'displayName': 'Islam Makhachev',
        'userRole': 'fighter',
        'verifiedBadge': 'UFC',
        'content':
            'Two times not enough? Come get the third. I respect Alex — he is a great champion. But I am the best lightweight in the world and I will prove it again in Sydney. See you there. 🏆',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 39700,
        'commentCount': 4100,
        'shareCount': 9600,
        'postType': 'text',
        'tags': ['UFC318', 'Lightweight', 'Champion'],
      },
      {
        'authorId': 'fighter_robert_whittaker',
        'displayName': 'Robert Whittaker',
        'userRole': 'fighter',
        'verifiedBadge': 'UFC',
        'content':
            'Fighting in front of a home crowd again. The energy at Sydney events is something else. Chimaev is a beast — that\'s exactly why I want this fight. Been waiting for a challenge like this. Let\'s go. 🔥🇦🇺',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 22900,
        'commentCount': 1700,
        'shareCount': 5300,
        'postType': 'text',
        'tags': ['UFC318', 'Whittaker', 'Chimaev'],
      },
      {
        'authorId': 'fighter_khamzat_chimaev',
        'displayName': 'Khamzat Chimaev',
        'userRole': 'fighter',
        'verifiedBadge': 'UFC',
        'content':
            'Everybody sleep. Borz is coming to Australia. Whittaker is a tough man, but I finish everyone. 13-0. Nothing change in Sydney. 🐺',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 31400,
        'commentCount': 5200,
        'shareCount': 7800,
        'postType': 'text',
        'tags': ['UFC318', 'Borz', 'Chimaev'],
      },
      {
        'authorId': 'fighter_zhang_weili',
        'displayName': 'Zhang Weili',
        'userRole': 'fighter',
        'verifiedBadge': 'UFC',
        'content':
            'I have worked my whole life for this moment. Tatiana Suarez is undefeated. So am I — as champion. This fight determines who is the best women\'s strawweight of this generation. I am ready. Magnum out. ⚡🇨🇳',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 27600,
        'commentCount': 2200,
        'shareCount': 6400,
        'postType': 'text',
        'tags': ['UFC318', 'Weili', 'Strawweight'],
      },
      {
        'authorId': 'fighter_kayla_harrison',
        'displayName': 'Kayla Harrison',
        'userRole': 'fighter',
        'verifiedBadge': 'PFL',
        'content':
            'Two Olympic gold medals. World champion in judo. Now I am coming for another million dollars and a third PFL championship. Nobody works harder than me. Nobody. Madison Square Garden, here we go. 🥇🥇💰',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 19800,
        'commentCount': 1400,
        'shareCount': 4100,
        'postType': 'text',
        'tags': ['PFLWorldChampionships', 'KaylaHarrison', 'OneMillion'],
      },
      {
        'authorId': 'fighter_demetrious_johnson',
        'displayName': 'Demetrious Johnson',
        'userRole': 'fighter',
        'verifiedBadge': 'ONE',
        'content':
            'Round 1 is Muay Thai rules. Round 2+ is MMA. I have never backed down from any challenge. Rodtang is the best Muay Thai striker on earth — but he has never faced anyone like me. This is the fight that proves everything. Singapore, see you soon. 🐭',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 24300,
        'commentCount': 3100,
        'shareCount': 8700,
        'postType': 'text',
        'tags': ['ONEChampionship', 'MightyMouse', 'SuperFight'],
      },
      {
        'authorId': 'fighter_mike_perry',
        'displayName': 'Mike Perry',
        'userRole': 'fighter',
        'verifiedBadge': 'BKFC',
        'content':
            'Artem wants the smoke again? I gave him that work last time. KnuckleMania 5. No gloves. No mercy. Platinum is bringing the belt home. Tampa, be ready. 👊💥',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 14600,
        'commentCount': 2300,
        'shareCount': 3800,
        'postType': 'text',
        'tags': ['BKFC', 'KnuckleMania5', 'Platinum'],
      },
      {
        'authorId': 'fighter_artem_lobov',
        'displayName': 'Artem Lobov',
        'userRole': 'fighter',
        'verifiedBadge': 'BKFC',
        'content':
            'I built this sport. Perry knows who built this sport. Tampa is going to witness something special — the Russian Hammer is coming for everything. No gloves, no mercy, no excuses. Let\'s go. 🔨🇷🇺',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 12100,
        'commentCount': 1900,
        'shareCount': 2900,
        'postType': 'text',
        'tags': ['BKFC', 'KnuckleMania5', 'RussianHammer'],
      },
      {
        'authorId': 'fighter_justin_gaethje',
        'displayName': 'Justin Gaethje',
        'userRole': 'fighter',
        'verifiedBadge': 'UFC',
        'content':
            'People sleep on Dariush but not me. This man is one of the best grapplers in the division. I have to be ready for everything — and I am. If I don\'t win this one, I accept it. But I\'m not losing. The Highlight is back. 💥',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 18700,
        'commentCount': 2700,
        'shareCount': 4400,
        'postType': 'text',
        'tags': ['UFC318', 'Gaethje', 'Dariush'],
      },
      {
        'authorId': 'gym_tristar_montreal',
        'displayName': 'Tristar Gym — Montreal',
        'userRole': 'gym',
        'content':
            '🥊 TRAINING CAMP RECAP — 8 weeks of work before UFC 318. Our fighters are ready. Every rep, every round, every detail matters. If you want to train with world champions, our doors are open. Come find out what elite preparation really looks like. 🇨🇦',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 8400,
        'commentCount': 640,
        'shareCount': 1800,
        'postType': 'announcement',
        'tags': ['Tristar', 'TrainingCamp', 'UFC318'],
      },
      {
        'authorId': 'coach_firas_zahabi',
        'displayName': 'Firas Zahabi',
        'userRole': 'coach',
        'content':
            'The mistake most fighters make when studying tape: they watch what their opponent does. You should be watching what their opponent DOESN\'T do. Where are the holes? Where is the hesitation? The fight is won before the gloves touch. 🧠',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 31200,
        'commentCount': 2100,
        'shareCount': 9800,
        'postType': 'text',
        'tags': ['CoachLife', 'FightIQ', 'Tristar'],
      },
      {
        'authorId': 'dfc_official',
        'displayName': 'Data Fight Central',
        'userRole': 'admin',
        'content':
            '📊 UFC 318 FIGHT CARD IS CONFIRMED — Makhachev vs Volkanovski III, Weili vs Suarez, Whittaker vs Chimaev, Gaethje vs Dariush.\n\nBuy your PPV access now on DFC and get Smart Cage live biometric data overlaid on every round. Combat sports, evolved. 🇦🇺',
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': true,
        'likes': 44700,
        'commentCount': 5600,
        'shareCount': 22100,
        'postType': 'announcement',
        'tags': ['UFC318', 'DFC', 'PPV'],
      },
    ];

    try {
      for (var postData in initialPosts) {
        DocumentReference docRef = postsRef.doc();
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
