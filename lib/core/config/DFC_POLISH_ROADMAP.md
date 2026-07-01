# 🛡️ DFC 30-DAY POLISH & HARDENING ROADMAP

This roadmap transitions Data Fight Central from a feature-complete architecture to a financially bulletproof, semiconductor-grade Bettaverse platform. 

## WEEK 1: DEAD CODE PURGE & REFACTORING
**Goal: Eliminate technical debt and standardize the codebase.**

- [ ] **Day 1:** Run `flutter analyze` and resolve all warnings. Delete deprecated screens, unused widgets, and orphaned imports.
- [ ] **Day 2:** Centralize all hardcoded strings (e.g., `"demo_fight_123"`) into a `constants.dart` or environment variables file.
- [ ] **Day 3:** Audit State Management. Ensure `Provider` instances dispose of controllers and streams to prevent memory leaks in the `NeuralCoachScreen` and `BroadcastOverlayScreen`.
- [ ] **Day 4:** Consolidate UI Theme. Ensure all buttons and panels strictly use `AppColors` and `DfcGlassPanel` to maintain the neon cyberpunk aesthetic.
- [ ] **Day 5:** Clean up `package.json` and `pubspec.yaml`. Remove unused dependencies.
- [ ] **Day 6:** Audit Firestore paths. Ensure all paths rely on a unified `FirestorePaths` class rather than hardcoded strings scattered across 87 services.
- [ ] **Day 7:** Docker Compose Cleanup. Verify `docker-compose.minimal.yml` perfectly mirrors the production deployment environment locally.

## WEEK 2: FINANCIAL LOCKDOWN
**Goal: Zero vulnerabilities in the DFC Economy.**

- [ ] **Day 8:** Stripe Webhook Idempotency. Verify `webhook_events` collection properly rejects double-delivered Stripe events.
- [ ] **Day 9:** Stripe Connect Onboarding. Test the promoter/fighter `/finance/onboarding` flow end-to-end using Stripe Test mode.
- [ ] **Day 10:** Revenue Split Bounds. Enforce a strict `sum == 100%` validation in `splitValidation.ts` before ANY purchase is approved.
- [ ] **Day 11:** Negative Balance Prevention. Implement rules in `payoutEngine.ts` to freeze accounts if a refund causes a payout balance to dip below zero.
- [ ] **Day 12:** Audit Firestore Rules. Verify `firestore.rules` strictly prevents clients from writing to `payoutBalances`, `revenueEvents`, and `payoutStatements`.
- [ ] **Day 13:** Payout Thresholds. Ensure the sweep script only transfers funds > $50.00 to avoid excessive Stripe transfer fees.
- [ ] **Day 14:** Manual Financial Audit Run. Push a test PPV purchase, confirm the 10/60/30 (Platform/Promoter/Fighter) split, and verify the `payoutStatements` document is created perfectly.

## WEEK 3: SAFETY, MODERATION & RATE LIMITING
**Goal: Protect users, infrastructure, and brand reputation.**

- [ ] **Day 15:** Rate Limiting. Implement Cloud Armor or API Gateway limits on Cloud Functions (e.g., max 5 Octane renders per promoter per hour) to prevent runaway GPU billing.
- [ ] **Day 16:** Content Moderation API. Integrate Google Vision API to auto-flag NSFW or extremely violent imagery uploaded to the `feedPosts` or `gyms` collections.
- [ ] **Day 17:** Sakura / Guardian Mode Tests. Rigorously test the silent SOS trigger to ensure it securely routes without exposing the user in the UI.
- [ ] **Day 18:** Medical Suspension Logic. Confirm that if a `MedicalSafetyScreen` flags a concussion, the Fighter is completely excluded from the Matchmaker dropdown queries.
- [ ] **Day 19:** Identity Verification. Enforce ID checks before a promoter can toggle an event to `isLive == true`.
- [ ] **Day 20:** App Check. Enable Firebase App Check to ensure only the genuine compiled Flutter app can ping the backend, locking out scrapers.
- [ ] **Day 21:** GDPR/CCPA Compliance. Add user account deletion protocols that cleanly scrub `users`, `fighters`, and `telemetry` while anonymizing historical `revenueEvents`.

## WEEK 4: GPU TUNING & BETTAVERSE PREP
**Goal: Scale the visual and intelligence engine for global load.**

- [ ] **Day 22:** Octane Performance. Use NVIDIA Nsight to profile the Cloud Run FFmpeg container. Ensure `h264_nvenc` is actively utilizing the L4 GPU.
- [ ] **Day 23:** Omniverse OpenUSD Prep. Define the `/bettaverse/worlds/` schema in cloud storage for 3D arena assets.
- [ ] **Day 24:** Mux Stream Quality. Enable adaptive bitrate (ABR) streaming configurations on the Mux live stream ingestion endpoints.
- [ ] **Day 25:** BigQuery Export Validation. Verify the Firebase Extensions are cleanly piping `telemetry` and `fightStats` into BigQuery for the Vertex AI models.
- [ ] **Day 26:** SamurAI Swarm Stress Test. Run the `data_seeders.py` script to generate 10,000 mock events and ensure the 53 AI agents do not hit execution timeouts.
- [ ] **Day 27:** Control Room Alerts. Verify that if `systemIntegrityCheck` flags an orphaned document, the red banner appears instantly on the Web Admin UI.
- [ ] **Day 28:** Production Environment Variables. Migrate all hardcoded keys to Google Secret Manager. Update `deploy.sh` to inject them at runtime.
- [ ] **Day 29:** Chaos Engineering. Simulate a Stripe API outage and verify that the app gracefully degrades without crashing the user interface.
- [ ] **Day 30:** GO / NO-GO LAUNCH DECISION. Complete the `LAUNCH_CHECKLIST.md`.

---
*Executing this roadmap transforms the DFC prototype into a global combat sports operating system capable of sustaining millions of users and millions of dollars.*