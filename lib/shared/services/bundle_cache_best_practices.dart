// ═══════════════════════════════════════════════════════════════════════
// BundleCacheService - Best Practices & Implementation Guide
//
// This file shows the CORRECT way to use BundleCacheService in your app
// ═══════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────
// BEST APPROACH: Behind Cloud Functions (Server-Side Bundle Generation)
// ─────────────────────────────────────────────────────────────────────────

// 1. CREATE A CLOUD FUNCTION (Firebase Functions)
// File: functions/src/index.ts

/*
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Generate fighters bundle via secure Cloud Function
export const createFightersBundle = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to fetch bundles',
    );
  }

  try {
    // Build bundle server-side (secure, no API key needed client-side)
    const query = db
      .collection('fighters')
      .orderBy('rank')
      .limit(50);

    const bundleBuilder = db.bundle('fighters-bundle');
    bundleBuilder.add('top-fighters', query);
    const buffer = await bundleBuilder.build();

    // Return as Base64 for transport
    return {
      success: true,
      bundle: buffer.toString('base64'),
      size: buffer.length,
    };
  } catch (error) {
    console.error('Bundle generation failed:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate bundle',
    );
  }
});
*/

// ─────────────────────────────────────────────────────────────────────────
// 2. USE IN YOUR FLUTTER APP (Best Pattern)
// ─────────────────────────────────────────────────────────────────────────

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../core/utils/app_logger.dart';
import 'bundle_cache_service.dart';

class FightersListController {
  final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );
  final _bundleService = BundleCacheService();

  /// BEST METHOD: Call Cloud Function to get bundle
  Future<QuerySnapshot<Map<String, dynamic>>> getFightersBundled() async {
    try {
      // 1. Call secure Cloud Function (no API key exposed)
      final callable = _functions.httpsCallable('createFightersBundle');
      final result = await callable.call();

      // 2. Decode Base64 bundle from server
      final data = Map<String, dynamic>.from(result.data as Map);
      final bundleBase64 = data['bundle'] as String;
      final bundleBytes = base64Decode(bundleBase64);

      // 3. Load bundle into Firestore cache
      final task = FirebaseFirestore.instance.loadBundle(bundleBytes);
      await task.stream.toList();

      // 4. Query from cache (instant, no network needed)
      final snapshot = await _bundleService.queryWithCache('fighters');

      return snapshot;
    } catch (e) {
      AppLogger.error('Bundle fetch failed: $e', tag: 'FightersController');
      // Fallback to live query
      return FirebaseFirestore.instance
          .collection('fighters')
          .orderBy('rank')
          .limit(50)
          .get();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 3. USE IN YOUR DASHBOARD SCREEN (Correct Implementation)
// ─────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _fightersFuture;
  late FightersListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FightersListController();

    // Load bundle ONCE on init (not every build)
    _fightersFuture = _controller.getFightersBundled();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _fightersFuture,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _fightersFuture = _controller.getFightersBundled();
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Success state
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final fighter = docs[index].data();
            return ListTile(
              title: Text(fighter['name']?.toString() ?? 'Unnamed fighter'),
              subtitle: Text('Rank: ${fighter['rank']?.toString() ?? 'N/A'}'),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ALTERNATIVE: Direct Collection Query (No Bundle Server Needed)
// ─────────────────────────────────────────────────────────────────────────

class SimpleFightersList extends StatefulWidget {
  const SimpleFightersList({super.key});

  @override
  State<SimpleFightersList> createState() => _SimpleFightersListState();
}

class _SimpleFightersListState extends State<SimpleFightersList> {
  final _bundleService = BundleCacheService();

  Future<QuerySnapshot<Map<String, dynamic>>> _loadFighters() async {
    try {
      // Query fighters from cache (if bundle loaded), else from network
      return await _bundleService.queryWithCache('fighters');
    } catch (e) {
      // Fallback to live query
      return FirebaseFirestore.instance.collection('fighters').get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _loadFighters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');

        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) => Text(docs[index]['name'] ?? 'N/A'),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RECOMMENDED ARCHITECTURE
// ─────────────────────────────────────────────────────────────────────────

/*
┌─────────────────────────────────────────────────────────────────┐
│                         Data Fight Central                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │               Flutter Client (Web/App)                    │   │
│  │  • BundleCacheService (queryWithCache)                    │   │
│  │  • Controllers (DashboardController, etc.)                │   │
│  │  • UI Widgets (Screens)                                   │   │
│  └──────────────────────┬───────────────────────────────────┘   │
│                         │ Calls Cloud Function                  │
│  ┌──────────────────────▼───────────────────────────────────┐   │
│  │          Firebase Cloud Functions                         │   │
│  │  • createFightersBundle()                                │   │
│  │  • createStoriesBundle()                                 │   │
│  │  • createEventsBundle()                                  │   │
│  │  (Generates bundles server-side)                         │   │
│  └──────────────────────┬───────────────────────────────────┘   │
│                         │ Returns Base64 Bundle                 │
│  ┌──────────────────────▼───────────────────────────────────┐   │
│  │            Firestore (Backend)                            │   │
│  │  • fighters (collection)                                 │   │
│  │  • posts (collection)                                    │   │
│  │  • events (collection)                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

Flow:
1. App initializes
2. Dashboard calls Cloud Function: "Give me fighters bundle"
3. Cloud Function queries Firestore secretly (no key needed)
4. Returns Base64 bundle to client
5. Client loads bundle into local cache
6. Dashboard queries cache (instant, offline works)
*/

// ─────────────────────────────────────────────────────────────────────────
// SECURITY COMPARISON
// ─────────────────────────────────────────────────────────────────────────

/*
❌ BAD: Expose API key in client
  → Anyone with the key can make Firestore requests
  → Easy to exceed quota or abuse

✅ GOOD: Use Cloud Functions (recommended)
  → Server generates bundle securely
  → Client has no Firestore API key
  → Server-side authentication (context.auth)
  → Quota protected

✅ ALSO GOOD: Direct Firestore queries + Rules
  → Use Firebase Auth tokens
  → Firestore rules limit access
  → No exposed API key
*/

// ─────────────────────────────────────────────────────────────────────────
// STEP-BY-STEP SETUP
// ─────────────────────────────────────────────────────────────────────────

/*
Step 1: Deploy Cloud Function
   $ cd functions
   $ npm install
   $ firebase deploy --only functions:createFightersBundle

Step 2: In your Flutter app, add cloud_functions dependency:
   flutter pub add cloud_functions

Step 3: Use BundleCacheService in your controller/screen (see above)

Step 4: Test it
   - Run: flutter run -d chrome
   - Open Dashboard
   - Check AppLogger output for "Bundle loaded successfully"
*/

// ─────────────────────────────────────────────────────────────────────────
// ERROR HANDLING CHECKLIST
// ─────────────────────────────────────────────────────────────────────────

/*
✓ Try/catch around loadBundle (it can fail)
✓ Fallback to live query if bundle fails
✓ Handle network timeouts (30s limit)
✓ Log errors with AppLogger for debugging
✓ Don't expose API errors to user (show "Loading..." instead)
✓ Cache bundles locally for offline (handled by Firestore SDK)
✓ Verify user authentication before serving bundles
*/

// ─────────────────────────────────────────────────────────────────────────
// DO's and DON'Ts
// ─────────────────────────────────────────────────────────────────────────

/*
✅ DO:
   - Call cloud functions from client
   - Use BundleCacheService.queryWithCache() for cached queries
   - Load bundles once on app init, not every screen build
   - Handle errors gracefully with fallbacks
   - Use Firebase Auth tokens for security
   - Log bundle operations for debugging

❌ DON'T:
   - Expose API keys in client code
   - Load bundles on every build (use Future/initState)
   - Ignore bundle errors (always have fallback)
   - Query large collections (add .limit())
   - Store sensitive data in bundles
   - Forget to update security rules
*/
