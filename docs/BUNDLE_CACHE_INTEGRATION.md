# Firestore Bundle Cache Integration Guide

## Overview

The **BundleCacheService** enables offline-first, cost-optimized data loading by pre-packaging Firestore queries into bundles and caching them on the client.

**Benefits:**

- **Offline Support**: App functions without network
- **Reduced Costs**: Bundles count as 1 read regardless of query complexity
- **Faster Loads**: Client-side cache is instant
- **Better UX**: Pre-load data while users wait for network

---

## Dart/Flutter Setup (Client-Side)

### 1. Using BundleCacheService

```dart
import 'file:../../shared/services/services.dart';

// In your widget or controller
final bundleService = BundleCacheService();

// Load and query in one step
final snapshot = await bundleService.loadAndQuery(
  bundleUrl: 'https://your-server.com/api/fighter-stats-bundle',
  queryName: 'top-fighters-query',
);

// Use the data
for (final doc in snapshot.docs) {
  print('Fighter: ${doc['name']}');
}
```

### 2. Dashboard Integration Example

```dart
class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late BundleCacheService _bundleService;
  late Future<QuerySnapshot<Map<String, dynamic>>> _fighterStatsFuture;

  @override
  void initState() {
    super.initState();
    _bundleService = BundleCacheService();

    // Preload fighter stats on screen load
    _fighterStatsFuture = _bundleService.loadAndQuery(
      bundleUrl: 'https://your-server.com/api/fighter-stats-bundle',
      queryName: 'top-fighters-stats',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _fighterStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final fighter = docs[index].data();
            return FighterCard(fighter: fighter);
          },
        );
      },
    );
  }
}
```

---

## Backend Setup (Firebase Functions)

### Quick Version: Create Bundles on-Demand

Create a Firebase Cloud Function to build and serve bundles:

```javascript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// HTTP endpoint to generate and serve bundles
export const createBundle = functions.https.onRequest(async (req, res) => {
  res.set("Cache-Control", "public, max-age=3600");
  res.set("Content-Type", "application/octet-stream");

  try {
    // Example: Top fighter stats query
    const fighterStatsQuery = db
      .collection("fighter_stats")
      .orderBy("rank")
      .limit(50);

    // Build the bundle
    const bundleBuilder = db.bundle("top-fighters-query");
    bundleBuilder.add("top-fighters-stats", fighterStatsQuery);
    const buffer = await bundleBuilder.build();

    // Send to client
    res.send(buffer);
  } catch (error) {
    console.error("Bundle creation failed:", error);
    res.status(500).send("Error creating bundle");
  }
});

// Add to firebase.json functions deployment
```

### Production Version: Pre-built Bundles

For better performance, pre-build bundles and serve from Firebase Hosting:

```bash
# Generate bundles offline (e.g., daily via scheduled function)
firebase functions:config:set build.enabled=true
firebase deploy --only functions

# Serve static bundles from CDN
gs://your-bucket/bundles/fighter-stats-bundle.bytes → /api/fighter-stats-bundle
```

---

## Query Patterns for Bundles

### Pattern 1: Named Query Bundle

```javascript
// Backend: Create a named query bundle
const latestStories = db
  .collection("feedstore")
  .where("category", "==", "news")
  .orderBy("timestamp", "desc")
  .limit(25);

const bundleBuilder = db.bundle("latest-stories-bundle");
bundleBuilder.add("latest-stories-query", latestStories);
const buffer = await bundleBuilder.build();
```

```dart
// Client: Load and use it
final snapshot = await bundleService.loadAndQuery(
  bundleUrl: '/api/latest-stories-bundle',
  queryName: 'latest-stories-query',
);
```

### Pattern 2: Multiple Queries in One Bundle

```javascript
// Backend: Add multiple named queries
const bundleBuilder = db.bundle("multi-data-bundle");

// Add top fighters
bundleBuilder.add(
  "top-fighters",
  db.collection("fighters").orderBy("rank").limit(10),
);

// Add upcoming events
bundleBuilder.add(
  "upcoming-events",
  db
    .collection("events")
    .where("date", ">=", new Date())
    .orderBy("date")
    .limit(5),
);

// Add recent posts
bundleBuilder.add(
  "recent-posts",
  db.collection("posts").orderBy("createdAt", "desc").limit(20),
);

const buffer = await bundleBuilder.build();
```

```dart
// Client: Query any of the named queries
final fighters = await bundleService.getFromCache('top-fighters');
final events = await bundleService.getFromCache('upcoming-events');
final posts = await bundleService.getFromCache('recent-posts');
```

---

## Firestore Rules for Bundles

Update `firestore.rules` to allow bundle reading:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow bundle reads for authenticated users
    match /{document=**} {
      allow read: if request.auth != null;
    }

    // Or make public if not sensitive
    match /fighter_stats/{document=**} {
      allow read: if true;
    }
  }
}
```

Deploy with:

```bash
firebase deploy --only firestore:rules
```

---

## Performance Tips

### 1. Bundle Size Optimization

```dart
// ❌ Bad: Large bundles
final largeQuery = db.collection('posts'); // Could be millions of docs

// ✅ Good: Reasonable limits
final optimizedQuery = db
  .collection('posts')
  .orderBy('popularity')
  .limit(100);
```

### 2. Bundle Caching Strategy

```dart
// Preload on app startup
void initializeApp() async {
  final bundleService = BundleCacheService();

  // Don't await - fire and forget for non-critical data
  bundleService.loadBundleFromUrl('/api/initial-bundle').catchError((e) {
    debugPrint('Bundle preload failed, app continues: $e');
  });
}
```

### 3. Handle Network Timeouts

```dart
final bundleService = BundleCacheService();

try {
  await bundleService.loadBundleFromUrl(url);
} catch (e) {
  // App still works with previous cache
  debugPrint('Network error, using cached data: $e');
}
```

---

## Testing Bundles Locally

### Test Bundle Creation

```bash
# In your Firebase emulator
firebase emulators:start

# In a separate terminal, run this Node.js snippet
node -e "
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'demo-' });
const db = admin.firestore();

const query = db.collection('fighters').limit(10);
const bundle = db.bundle('test-bundle');
bundle.add('test-query', query);
bundle.build().then(buffer => {
  const fs = require('fs');
  fs.writeFileSync('test-bundle.bytes', buffer);
  console.log('Bundle created: ', buffer.length, 'bytes');
});
"
```

### Load in Flutter

```dart
// Load local test bundle
final file = File('test-bundle.bytes');
final bytes = await file.readAsBytes();
await FirebaseFirestore.instance.loadBundle(bytes);
```

---

## Troubleshooting

| Issue                       | Solution                                                                           |
| --------------------------- | ---------------------------------------------------------------------------------- |
| **"Named query not found"** | Named query name must match exactly. Check `bundle.add('name', query)` spelling.   |
| **Bundle too large**        | Add `.limit()` to queries, or split into multiple bundles.                         |
| **Cache inconsistent**      | Call `bundleService.clearCache()` and reload.                                      |
| **Network timeout**         | Increase timeout in `bundle_cache_service.dart` or serve from CDN closer to users. |
| **No offline data**         | Ensure `loadBundle()` succeeded before going offline.                              |

---

## Next Steps

1. **Set up Cloud Function** to generate bundles (see Backend Setup above)
2. **Deploy** function: `firebase deploy --only functions`
3. **Update firestore.rules** for bundle access
4. **Integrate BundleCacheService** into your dashboard/screens
5. **Test offline** - disconnect network and verify cached data loads

---

## References

- [Firestore Bundles Documentation](https://firebase.google.com/docs/firestore/bundles)
- [Cloud Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Firebase Cloud Functions Guide](https://firebase.google.com/docs/functions)
