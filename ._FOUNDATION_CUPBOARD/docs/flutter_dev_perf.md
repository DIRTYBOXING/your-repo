# Flutter Performance Guide

This guide is a focused checklist for keeping DFC UI responsive under heavy feed, media, and combat telemetry workloads.

## Top 12 Fixes

1. Keep expensive work out of `build()`.
2. Use `const` constructors and `const` widgets wherever possible.
3. Use pagination with cursor-based APIs for large lists.
4. Prefetch the next page when the list is within 1000-1200 pixels of end.
5. Cache poster and avatar media with stable cache keys.
6. Use `RepaintBoundary` around charts, gauges, and heavy cards.
7. Avoid rebuilding whole list trees for single-item state updates.
8. Debounce search inputs and map filter updates.
9. Keep image dimensions bounded and avoid full-resolution decode when not needed.
10. Move JSON parsing and heavy transforms off the UI isolate when payloads are large.
11. Keep animation durations predictable and avoid overlapping long implicit animations.
12. Measure every screen with DevTools before and after changes.

## Feed Screen Targets

- First contentful render: under 1 second.
- Feed page fetch: under 300 ms median.
- Card frame budget: under 16 ms while scrolling.

## Quick Instrumentation Snippet

Use this around async sections to track latency:

```dart
final stopwatch = Stopwatch()..start();
await loadNextPage();
stopwatch.stop();
// ignore: avoid_print
print('feed.loadNextPage ms=${stopwatch.elapsedMilliseconds}');
```

## Build Verification

Run before merging UI-heavy work:

```powershell
flutter pub get
dart analyze
flutter test
```
