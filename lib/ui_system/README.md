# DFC UI System — 2026 Compact Design

## 🎯 Design Rules

**NO MORE GIANT EMPTY CARDS!**

✅ Feature cards max height **160px**
✅ Always include: **icon + title + subtitle + badge + CTA**
✅ Use **glass panels** (opacity 0.03–0.07)
✅ Borders **neon thin 0.6px**
✅ Soft glow **only on hover**
✅ Layout must be **grid-based**
✅ **No square blocky gradients**

---

## 📦 Components

### DfcColors

Centralized color system with neon palette, glass effects, and helper methods.

```dart
import 'package:datafightcentral/ui_system/ui_system.dart';

// Use neon colors
Container(color: DfcColors.neonCyan);

// Glass panel with helper
Container(decoration: DfcColors.glassBox(
  accentColor: DfcColors.neonBlue,
  glassOpacity: 0.03,
  borderOpacity: 0.15,
));

// Hover state
Container(decoration: DfcColors.glassBoxHover(
  accentColor: DfcColors.neonGreen,
));
```

### DfcSpacing

Consistent spacing constants for compact layouts.

```dart
// Padding
EdgeInsets.all(DfcSpacing.md)  // 12px
EdgeInsets.all(DfcSpacing.lg)  // 16px

// Card dimensions
constraints: BoxConstraints(
  minHeight: DfcSpacing.cardMinHeight,  // 140px
  maxHeight: DfcSpacing.cardMaxHeight,  // 170px
)

// Border radius
BorderRadius.circular(DfcSpacing.radiusMedium)  // 12px
```

### DfcText

Typography system with predefined text styles.

```dart
// Titles
Text('AI Brain', style: DfcText.titleSmall())
Text('Hero Title', style: DfcText.titleHero())

// Body text
Text('Description', style: DfcText.bodyMedium())
Text('Helper text', style: DfcText.bodySmall())

// Labels & badges
Text('LIVE', style: DfcText.labelBold(color: DfcColors.neonRed))
```

### DfcButton

Reusable button component with hover states.

```dart
// Primary action button
DfcButton(
  label: 'OPEN MODULE',
  onPressed: () => print('Tapped'),
  accentColor: DfcColors.neonCyan,
  size: DfcButtonSize.medium,
  icon: Icons.arrow_forward,
  fullWidth: true,
)

// Icon button
DfcIconButton(
  icon: Icons.settings,
  onPressed: () {},
  accentColor: DfcColors.neonPurple,
  size: 32,
)
```

### DfcFeatureCard

Large feature card for marketing/landing pages.

```dart
DfcFeatureCard(
  icon: Icons.science,
  title: 'FightLab',
  subtitle: 'Biometric performance tracking',
  badge: 'LIVE',
  ctaLabel: 'EXPLORE',
  onTap: () => context.push('/fightlab'),
  accentColor: DfcColors.neonGreen,
)
```

### DfcSystemCard

Compact system card for dashboard grids (3x2 layout).

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.85,  // Taller for content
  ),
  itemBuilder: (context, i) => DfcSystemCard(
    icon: Icons.smart_toy,
    title: 'AI Brain',
    subtitle: 'Neural Combat Intelligence',
    statusLabel: 'Live Connected',
    accentColor: DfcColors.neonMagenta,
    onTap: () => context.push('/ai-brain'),
  ),
)
```

---

## 🎥 Video Intro System

Three strategic video types for different user journeys.

### Video Types

1. **Welcome Video** (`download (5).mp4`)
   - First-time users
   - Onboarding step 0
   - Landing page background (optional)

2. **Premium Video** (`download (2).mp4`)
   - Subscription purchase success
   - After login if premium detected
   - High-impact premium welcome

3. **Promoter Video** (`download.mp4`)
   - Promoter role activation
   - Promoter dashboard entry
   - Fight show mode

### Usage

```dart
import 'package:datafightcentral/shared/services/video_intro_service.dart';

// Show full-screen video intro
await DfcVideoIntroService.showVideoIntro(
  context,
  DfcVideoType.welcome,
  onComplete: () => print('Video finished'),
  skippable: true,
);

// Background video (for landing pages)
DfcBackgroundVideo(
  videoType: DfcVideoType.welcome,
  muted: true,
  loop: true,
)
```

---

## 🔧 Migration Guide

### Before (Old System)

```dart
// Old bloated card
Container(
  height: 400,  // ❌ Too big!
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    gradient: LinearGradient(...),  // ❌ Blocky gradient
  ),
  child: Column(
    children: [
      Icon(Icons.analytics, size: 64),
      Text('Analytics'),
    ],
  ),
)
```

### After (New UI System)

```dart
// New compact card
DfcSystemCard(
  icon: Icons.analytics,
  title: 'Analytics',
  subtitle: 'Combat Statistics',
  statusLabel: '21 Metrics',
  accentColor: DfcColors.neonCyan,
  onTap: () {},
)
```

---

## 🚀 Best Practices

1. **Always use UI system components** instead of creating one-off widgets
2. **Never exceed 170px** for card heights
3. **Include micro content** in every card (badge, stat, or status)
4. **Use hover states** for desktop/web interfaces
5. **Grid layouts only** — no random floating elements
6. **Glass over gradients** — 0.03–0.07 opacity
7. **Thin neon borders** — 0.6px width

---

## 📁 File Structure

```
lib/
  ui_system/
    dfc_colors.dart      ← Color system & helpers
    dfc_spacing.dart     ← Spacing constants
    dfc_text.dart        ← Typography
    dfc_button.dart      ← Button components
    dfc_card.dart        ← Card components
    ui_system.dart       ← Export all
```

---

## 🎨 Example: Full Landing Grid

```dart
import 'package:datafightcentral/ui_system/ui_system.dart';

Widget buildSystemGrid() {
  final systems = [
    _System('AI Brain', Icons.smart_toy, DfcColors.neonMagenta, 'Live'),
    _System('FightLab', Icons.science, DfcColors.neonGreen, 'Active'),
    _System('Analytics', Icons.analytics, DfcColors.neonCyan, '21 Stats'),
    _System('Training', Icons.fitness_center, DfcColors.neonOrange, 'Phase 2'),
    _System('Recovery', Icons.healing, DfcColors.neonBlue, '24/7'),
    _System('FightWire', Icons.bolt, DfcColors.neonRed, 'Live'),
  ];

  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
    ),
    itemCount: systems.length,
    itemBuilder: (context, i) {
      final sys = systems[i];
      return DfcSystemCard(
        icon: sys.icon,
        title: sys.name,
        subtitle: 'System Description',
        statusLabel: sys.status,
        accentColor: sys.color,
        onTap: () => context.push('/system/${sys.name.toLowerCase()}'),
      );
    },
  );
}
```

---

## ✅ Checklist

When creating new screens:

- [ ] Import `ui_system/ui_system.dart`
- [ ] Use `DfcSystemCard` or `DfcFeatureCard` (never custom cards)
- [ ] Max card height 160px
- [ ] Include icon + title + subtitle + badge/stat
- [ ] Add hover animations
- [ ] Use glass decoration (0.03–0.07 opacity)
- [ ] Neon borders (0.6px)
- [ ] Grid layout with consistent spacing

---

## 🔥 Result

**Before:** Giant empty squares floating in space
**After:** Tight, professional, 2026-style system dashboard

This ensures **zero UI regression** and maintains the premium Apple Vision Pro / Cyber OS aesthetic.
