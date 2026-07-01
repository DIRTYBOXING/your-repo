# DataFightCentral — Production Roadmap

> **Platform Vision:** Social-first combat sports discovery that feeds backend-authoritative PPV, live streaming, and operational rigor. Every phase builds on real infrastructure — no demos.

---

## Phase 1 — Foundation Hardening ✅ ACTIVE

**Goal:** Real Firestore + Firebase backbone. No stubs, no mocks in production paths.

| Item                                                  | Status            | Owner Layer                                            |
| ----------------------------------------------------- | ----------------- | ------------------------------------------------------ |
| UserProfileService (Firestore-backed, role-aware)     | ✅ Done           | `lib/shared/services/user_profile_service.dart`        |
| PPV checkout web-safe launch (kIsWeb + LaunchMode)    | ✅ Done           | `lib/features/ppv/services/ppv_service.dart`           |
| MediaAssetUploadService (Storage, 50MB cap, typed)    | ✅ Done           | `lib/shared/services/media_asset_upload_service.dart`  |
| Talk Hub / Fightwire real Firestore feed stream       | ✅ Confirmed live | `lib/features/fightwire/widgets/talk_hub.dart`         |
| FightWire screen URL sanitizer + sport-aware fallback | ✅ Confirmed live | `lib/features/fightwire/screens/fightwire_screen.dart` |
| All 371 tests passing                                 | ✅ Green          | CI                                                     |

**Next in Phase 1:**

- [ ] Fighter + Event Firestore repository layer (typed read/write, not raw `collection().get()`)
- [ ] Firestore indexes audit against `firestore.indexes.json` for new query shapes
- [ ] Security rules redeploy after any new collection

---

## Phase 2 — DFC Image Machine

**Goal:** Every fighter, event, and post has a real image asset. No placeholder fallback in production.

| Item                                                  | Status     |
| ----------------------------------------------------- | ---------- |
| `MediaAssetUploadService` — upload pipeline           | ✅ Ready   |
| Fighter profile photo upload UI                       | 🔲 Pending |
| Event poster upload + Firestore write-back            | 🔲 Pending |
| Post media upload (photo / short clip)                | 🔲 Pending |
| Storage CORS rules + CDN caching headers              | 🔲 Pending |
| Image URL persistence on fighter/event Firestore docs | 🔲 Pending |

---

## Phase 3 — DFC Octane (Video Engine)

**Goal:** Mux-powered live + replay PPV with full entitlement enforcement.

| Item                                           | Status             |
| ---------------------------------------------- | ------------------ |
| Mux token pair in Firebase Secrets             | ✅ Done (via task) |
| Entitlements service (Cloud Functions)         | ✅ Deployed        |
| PPV checkout → Stripe → entitlement grant flow | ✅ Wired           |
| Mux playback URL delivery to entitled users    | ✅ Done            |
| Replay metadata prep + poster art              | 🔲 Pending         |
| Live stream HLS ingest via Mux broadcast API   | 🔲 Pending         |
| PPV page live countdown + status polling       | 🔲 Pending         |

---

## Phase 4 — AI Integration (Kimik2.5 / DFC Brain)

**Goal:** AI-ranked feed, fight predictions, coach insights, n8n content pipeline.

| Item                                                       | Status        |
| ---------------------------------------------------------- | ------------- |
| n8n content brain heartbeat                                | ✅ Task wired |
| AutoFeedOrchestratorService (multi-source normalize/rank)  | ✅ Live       |
| DFCAIPowerhouse (Kimik2.5 insights)                        | ✅ Live       |
| PromoterAI signal cards in FightWire Master                | ✅ Live       |
| AnalyticsService event logging on all flows                | ✅ Live       |
| Fight prediction ML model (inference endpoint)             | 🔲 Pending    |
| Personalized feed ranking (engagement signals → Firestore) | 🔲 Pending    |
| Push notifications via Firebase Messaging                  | 🔲 Pending    |

---

## Infrastructure Reference

| System      | Stack                                                               |
| ----------- | ------------------------------------------------------------------- |
| App         | Flutter 3.43 beta, Provider + GoRouter                              |
| Backend     | Firebase Firestore, Functions (australia-southeast1), Storage, Auth |
| Video       | Mux (live + replay)                                                 |
| Payments    | Stripe                                                              |
| Monitoring  | n8n, Prometheus (`prom-client`), ioredis                            |
| CI          | Azure Pipelines + Cloud Build                                       |
| GCP Project | `datafightcentral`                                                  |
| Branch      | `feature/guardian-protocol-final` → master                          |

---

## Guardrails

- No panel size changes, router rewires, or shared widget replacements without explicit maintainer sign-off.
- Feed changes go through `lib/shared/services`, not screen-layer hacks.
- All external links domain-validated before amplification.
- High-risk content routes through `ContentSafetyService` before promotion.
- Security rules redeploy required after any new Firestore collection.
