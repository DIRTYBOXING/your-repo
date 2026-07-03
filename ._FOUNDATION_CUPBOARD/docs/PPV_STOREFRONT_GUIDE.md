# PPV Storefront Production Guide

## Overview

The DFC PPV Storefront is now a **mobile-first, responsive** application with professional features:

- 📱 Fully responsive design (mobile, tablet, desktop)
- 🎬 Real-time Firestore event data loading
- 🖼️ Optimized image caching & compression
- 💰 Integrated pricing & checkout flow
- 🎯 Professional fight card rendering
- ⚡ Performance-optimized with minimal repaints

---

## Firestore Setup

### 1. Create PPV Events Collection

```bash
firebase firestore:indexes --project datafightcentral
```

### 2. Add Seed Data

Add the following to your `main.dart` `initState` or as a one-time admin task:

```dart
import 'package:datafightcentral/core/utils/ppv_seeder.dart';

// Run once to seed data
await PPVSeeder.seedPPVEvents();
```

### 3. Firestore Document Structure

```
ppv_events/
├── {eventId}
│   ├── title: string
│   ├── subtitle: string
│   ├── description: string
│   ├── promotion: string (UFC, BKFC, etc)
│   ├── sportType: string (MMA, Boxing, etc)
│   ├── eventDate: timestamp
│   ├── eventStatus: string (announced, presale, onSale, live, replay, expired)
│   ├── posterUrl: string (CDN URL)
│   ├── heroImageUrl: string (CDN URL)
│   ├── hasDrmProtection: boolean
│   ├── hasReplayAccess: boolean
│   ├── hasMultiCam: boolean
│   ├── peakViewers: number
│   ├── pricingTiers: map
│   │   ├── {tierId}: map
│   │   │   ├── title: string
│   │   │   ├── description: string
│   │   │   ├── amountCents: number
│   │   │   ├── currency: string
│   │   │   ├── isRecommended: boolean
│   │   │   └── features: array<string>
│   └── fightCard: array
│       └── {fight}: map
│           ├── order: number
│           ├── mainTitle: string (MAIN EVENT, CO-MAIN, etc)
│           ├── fighter1Name: string
│           ├── fighter2Name: string
│           ├── fighterId1: string (ref)
│           ├── fighterId2: string (ref)
│           ├── weightClass: string
│           ├── fighter1ImageUrl: string
│           └── fighter2ImageUrl: string
```

### 4. Firestore Security Rules

```javascript
match /ppv_events/{document=**} {
  allow read: if true;  // Public read for storefront
  allow write: if request.auth.token.admin == true;  // Admin only
}
```

---

## Performance Optimization

### Image Caching

Images are automatically cached with:

- **14-day retention** via `CacheManager`
- **Automatic compression** at optimal quality (80%)
- **Memory-aware sizing** based on device width
- **Placeholder loading states** for smooth UX

Usage:

```dart
import 'package:datafightcentral/features/ppv/services/ppv_image_optimization.dart';

// Optimized images auto-cache and compress
CachedNetworkImage(
  imageUrl: PPVImageOptimization.optimizeUrl(url, width: 800),
  // ...
)
```

### Responsive Layout

The storefront automatically adapts:

- **Mobile** (<600px): Full-width stacked layout
- **Tablet** (600-800px): Two-column layout
- **Desktop** (>800px): Three-column layout

No manual breakpoint management needed—responsive widgets handle all orientations.

### Bundle Size Impact

- **Base**: ~4.2MB (Flutter engine + DFC core)
- **PPV module**: +890KB (cached_network_image, models, services)
- **Cache manager**: Included in cached_network_image dependency

### Firestore Query Optimization

The storefront uses efficient queries:

```dart
// Loads ONE active event (minimal read cost)
final snapshot = await db
    .collection('ppv_events')
    .where('eventStatus', isNotEqualTo: 'expired')
    .limit(1)
    .get();  // ~1 read operation
```

---

## Ad Integration (Optional)

### Adding Google Mobile Ads

1. Add to `pubspec.yaml`:

```yaml
google_mobile_ads: ^5.0.0
```

2. Initialize in `main.dart`:

```dart
import 'package:datafightcentral/features/ppv/services/ppv_ad_service.dart';

void main() async {
  // ...
  await PPVAdService().initialize();
  runApp(const MyApp());
}
```

3. Add banner ads in the storefront:

```dart
BannerAd? _bannerAd;

@override
void initState() {
  _bannerAd = PPVAdService().loadBannerAd(
    adUnitId: PPVAdUnitIds.bannerUnitId,
    size: AdSize.banner,
  );
}

// In build():
PPVAdService.buildBannerAdWidget(bannerAd: _bannerAd)
```

---

## Mobile Testing Checklist

- [ ] Load time on 4G (target: <2s)
- [ ] Image rendering quality on various screen sizes
- [ ] Scroll performance (60 FPS target)
- [ ] Touch responsiveness on pricing selector
- [ ] Checkout button visibility and tappability
- [ ] Portrait and landscape orientations
- [ ] Safe area handling (notch, home indicator)

### Testing Commands

```bash
# Profile performance
flutter run --profile

# Check frame rate
flutter run -v 2>&1 | grep "frame time"

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

---

## Troubleshooting

### Firestore Connection Errors

**Symptom**: "net::ERR_ABORTED" in browser console

**Solution**:

1. Verify Firebase project is configured
2. Check Firestore security rules allow public reads
3. Check internet connectivity
4. Fallback to sandbox event automatically triggers (no user action needed)

### Images Not Loading

**Symptom**: Broken image icons

**Solution**:

1. Verify image CDN URLs are valid and CORS-enabled
2. Check `cached_network_image` is initialized
3. Clear cache: `await PPVImageOptimization.clearOldCache()`

### Slow Event Loading

**Symptom**: Loading spinner shows >3 seconds

**Solution**:

1. Check Firestore query is using limit(1)
2. Verify no complex aggregations in Firestore query
3. Profile with `flutter run --profile`
4. Consider pre-caching event data at app start

---

## Deployment

### Web Deployment

```bash
# Build optimized
flutter build web --release --web-renderer canvaskit

# Deploy to Firebase Hosting
firebase deploy --only hosting:datafightcentral
```

### Mobile Deployment

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## Monitoring

Track performance metrics in Firebase Console:

- **Performance Monitoring**: Frame rate, network latency, app startup
- **Analytics**: Event selection, checkout attempts, checkout success
- **Crashlytics**: Any runtime errors

---

## Support & Maintenance

- Monitor Firestore read costs (aim <$1/day for dev)
- Update event data weekly via `PPVSeeder`
- Clear image cache monthly: `PPVImageOptimization.clearOldCache()`
- Review performance dashboards weekly
