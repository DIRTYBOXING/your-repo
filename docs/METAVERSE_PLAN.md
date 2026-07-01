# DFC Metaverse & Spatial Features — Technical Plan

## Vision

Extend DataFightCentral into immersive 3D/AR/VR experiences: virtual arenas, holographic fighter cards, spatial training, and metaverse social spaces. All built on DFC's anti-violence, pro-safety mission.

---

## Phase 1: AR Foundation (6-12 months)

### 1.1 AR Fighter Card Viewer

- **Tech:** ARCore (Android) + ARKit (iOS) via `ar_flutter_plugin`
- **Feature:** Users point camera at fight card → 3D holographic fighter stats float above the card
- **Data:** Pull from `fighter_stats/{fighterId}` Firestore doc
- **Safety:** No facial recognition. No unauthorized recording.

### 1.2 Virtual Gym Tour

- **Tech:** 360° panoramic images + hotspot navigation
- **Feature:** Pink Shield gyms offer virtual walk-throughs so victims can preview the environment before visiting
- **Integration:** Maps screen gym detail sheet → "Virtual Tour" button

### 1.3 AR Training Overlay

- **Tech:** Pose estimation (MediaPipe/MoveNet) + AR overlay
- **Feature:** Real-time form feedback during shadowboxing, pad work
- **Privacy:** All processing on-device. No video leaves the phone.

---

## Phase 2: Virtual Arenas (12-24 months)

### 2.1 DFC CageView (3D Spectator)

- **Tech:** Unity WebGL embedded via WebView, or Flutter 3D with `flutter_cube`
- **Feature:** Watch fight events from any angle in a 3D virtual arena
- **Monetization:** Premium viewing angles behind DFC Access Pass

### 2.2 Virtual Sparring Room

- **Tech:** WebRTC video + pose estimation for move tracking
- **Feature:** Remote sparring sessions with real-time movement scoring
- **Safety:** Auto-blur faces if consent not given. Panic button in-session.

### 2.3 Holographic Leaderboard

- **Tech:** WebGL / Three.js rendered leaderboard
- **Feature:** 3D animated rank visualization — fighters "rise" through tiers
- **Data:** Powered by existing `DfcTier` system (bronze → platinum)

---

## Phase 3: Full Metaverse (24-36 months)

### 3.1 DFC World (Spatial Social)

- **Tech:** Evaluate: Meta Horizon SDK, Unity Netcode, or custom Flutter 3D
- **Feature:** Persistent virtual gym/social space where users walk around as avatars
- **Zones:** Training ring, locker room (private chat), stand-up comedy corner, mentor office
- **Safety:** Proximity-based audio (no shouting). Mute/block controls. Safe zones.

### 3.2 NFT Fighter Cards (Optional / Blockchain-Free Alternative)

- **Feature:** Collectible digital fighter cards with rarity tiers
- **Approach:** Start with Firestore-backed digital collectibles (no crypto requirement)
- **Future:** Optional blockchain layer via Polygon/Solana if demand warrants
- **Ethics:** No gambling mechanics. No pay-to-win. Transparent rarity odds.

### 3.3 VR Fight Night

- **Tech:** Meta Quest SDK / WebXR
- **Feature:** Attend DFC events in VR with spatial audio, virtual crowd energy
- **Accessibility:** 2D fallback for users without VR headsets

---

## Technical Architecture

```
┌─────────────────────────────────────────────┐
│           DFC Flutter App (Core)             │
│  ┌───────────┐  ┌────────────┐  ┌─────────┐ │
│  │ AR Module  │  │ 3D Viewer  │  │ WebRTC  │ │
│  │ (ARKit/    │  │ (Unity/    │  │ (Video  │ │
│  │  ARCore)   │  │  WebGL)    │  │  Chat)  │ │
│  └─────┬─────┘  └─────┬──────┘  └────┬────┘ │
│        │              │               │       │
│  ┌─────┴──────────────┴───────────────┴────┐ │
│  │        DFC Metaverse Service Layer       │ │
│  │  - Avatar management                    │ │
│  │  - Spatial state sync (Firestore RT)    │ │
│  │  - AR asset loading (Cloud Storage)     │ │
│  │  - Session management                   │ │
│  └──────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
         │
    Firestore / Cloud Functions / Cloud Storage
```

## Safety-First Metaverse Principles

1. **No unsolicited proximity** — Users can set "approach radius" (others must request to get close)
2. **Panic button in all spatial contexts** — Immediately exits session + optional alert
3. **Age-gated VR content** — Under-16 restricted to supervised sessions
4. **No deepfakes** — AI-generated avatars must be flagged as such
5. **Recording consent** — Screen recording in VR/AR spaces requires all-party consent
6. **Anti-harassment** — Spatial audio harassment triggers auto-mute + report

## Dependencies to Add (When Ready)

```yaml
# pubspec.yaml additions (future)
ar_flutter_plugin: ^0.7.0 # ARCore/ARKit
flutter_cube: ^0.1.1 # Basic 3D rendering
webview_flutter: ^4.0.0 # Unity WebGL embed
camera: ^0.10.0 # Pose estimation input
```

## Estimated Effort

| Phase               | Duration | Team Size | Cost Range  |
| ------------------- | -------- | --------- | ----------- |
| Phase 1 (AR)        | 6-12 mo  | 2-3 devs  | $50K-$100K  |
| Phase 2 (Virtual)   | 12-24 mo | 4-6 devs  | $150K-$300K |
| Phase 3 (Metaverse) | 24-36 mo | 8-12 devs | $500K-$1M+  |
