# BundleCacheService - Quick Reference

## BEST METHOD (Recommended)

### 🔒 Secure Cloud Function Approach

**1. Backend: Create Cloud Function**

```typescript
// functions/src/index.ts
export const getBundledData = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error("Not authenticated");

  const db = admin.firestore();
  const query = db.collection("fighters").orderBy("rank").limit(50);

  const bundle = db.bundle("fighters-bundle");
  bundle.add("top-fighters", query);
  const buf = await bundle.build();

  return { bundle: buf.toString("base64") };
});
```

**2. Frontend: Call from Controller**

```dart
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

class FightersController {
  Future<void> loadFighterBundle() async {
    try {
      // Step 1: Call secure Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('getBundledData');
      final result = await callable.call();

      // Step 2: Decode bundle
      final bundle = result.data['bundle'] as String;
      final bytes = base64Decode(bundle);

      // Step 3: Load into cache
      final task = FirebaseFirestore.instance.loadBundle(bytes);
      await task.stream.toList();

      // Step 4: Query from cache
      final snapshot = await FirebaseFirestore.instance
          .collection('fighters')
          .get(GetOptions(source: Source.cache));

      return snapshot;
    } catch (e) {
      // Fallback to live query
      return FirebaseFirestore.instance.collection('fighters').get();
    }
  }
}
```

**3. Use in Screen (Correct Pattern)**

```dart
class FightersScreen extends StatefulWidget {
  @override
  State<FightersScreen> createState() => _FightersScreenState();
}

class _FightersScreenState extends State<FightersScreen> {
  final _controller = FightersController();
  late Future<QuerySnapshot> _future;

  @override
  void initState() {
    super.initState();
    // Load ONCE in initState, not in build()
    _future = _controller.loadFighterBundle();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final fighter = docs[index].data() as Map<String, dynamic>;
            return Text(fighter['name'] ?? 'Unknown');
          },
        );
      },
    );
  }
}
```

---

## Security Matrix

| Method                              | API Key } Exposed | Secure   | Easy   | Offline | Best For    |
| ----------------------------------- | ----------------- | -------- | ------ | ------- | ----------- |
| **Cloud Function** (✅ RECOMMENDED) | ❌ No             | ✅✅ Yes | ✅ Yes | ✅ Yes  | Production  |
| Direct Collection Query             | ❌ No             | ✅ Yes   | ✅ Yes | ✅ Yes  | Simple Apps |
| HTTP Endpoint + Key                 | ⚠️ Yes            | ❌ No    | ❌ No  | ❌ No   | Dev Only    |

---

## Implementation Checklist

- [ ] Create Cloud Function in `functions/src/index.ts`
- [ ] Deploy: `firebase deploy --only functions`
- [ ] Add `cloud_functions` dependency: `flutter pub add cloud_functions`
- [ ] Create controller with loadFighterBundle()
- [ ] Use FutureBuilder in screen (initState, not build)
- [ ] Add error handling with fallback query
- [ ] Test in Chrome: `flutter run -d chrome`
- [ ] Check logs: `firebase functions:log`
- [ ] Test offline: DevTools → Offline mode

---

## Common Mistakes

❌ **WRONG**: Loading bundle in build()

```dart
@override
Widget build(BuildContext context) {
  bundleService.loadBundleFromUrl(...); // ❌ Loads every rebuild!
  ...
}
```

✅ **CORRECT**: Loading bundle in initState()

```dart
@override
void initState() {
  super.initState();
  _future = bundleService.loadBundleFromUrl(...); // ✅ Load once
}
```

---

❌ **WRONG**: Exposing API key

```dart
final url = 'https://firestore.googleapis.com/v1/projects/dfc/databases/collections?key=$apiKey';
```

✅ **CORRECT**: Using Cloud Function

```dart
final callable = FirebaseFunctions.instance.httpsCallable('getBundledData');
final result = await callable.call();
```

---

## Testing Your Implementation

```bash
# 1. Deploy Cloud Function
cd functions
firebase deploy --only functions:getBundledData

# 2. Check function was deployed
firebase functions:list

# 3. View logs in real-time
firebase functions:log

# 4. Test in Flutter
flutter run -d chrome

# 5. In console, check for:
# "Bundle loaded successfully" → ✅ Working
# "Failed to load bundle" → ❌ Check error logs
```

---

## FAQ

**Q: Do I need the API key?**
A: No! Cloud Functions handle authentication server-side.

**Q: What if user is offline?**
A: Bundle is cached locally, works offline automatically.

**Q: Can I query without Cloud Function?**
A: Yes, use `queryWithCache()` directly. But Cloud Function is more secure.

**Q: How often should I update bundles?**
A: On app startup, or periodically (hourly/daily based on data freshness needs).

**Q: Is there a size limit?**
A: Bundles can be large, but keep to <5MB for good UX.
