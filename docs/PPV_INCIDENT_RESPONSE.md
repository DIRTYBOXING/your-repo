# DFC PPV Operator Guide + Incident Response Playbook

> **DataFightCentral — How to Run a PPV Event End-to-End + What to Do When Things Go Wrong**
> Last updated: March 12, 2026

---

# PART 1 — PPV SETUP GUIDE (Your End)

---

## STEP 1: CREATE THE PPV EVENT IN FIRESTORE

Either via the app (promoter tools) or directly in Firebase Console, create a doc in `ppv_events`:

```
ppv_events/{your-ppv-id}
├── eventId:              "your-linked-event-id"
├── promoterId:           "your-promoter-id"
├── title:                "IBC 04: GOLD COAST WAR"
├── subtitle:             "Hardman vs Brooks — MW Title"
├── description:          "Full event description..."
├── posterUrl:            "assets/logos/dfc_logo_icon.png"  (or uploaded image URL)
├── trailerUrl:           "https://youtube.com/watch?v=..."  (optional)
├── eventDate:            Timestamp (e.g., 2026-05-15 18:00 AEST)
├── presaleStart:         Timestamp (when early bird pricing opens)
├── onSaleStart:          Timestamp (when standard pricing opens)
├── status:               "announced"  ← START HERE
├── currency:             "AUD"
├── standardPriceCents:   4999          (= $49.99)
├── earlyBirdPriceCents:  3499          (= $34.99)
├── premiumPriceCents:    7999          (= $79.99)
├── vipPriceCents:        12999         (= $129.99)
├── streamPlatforms:      ["DFC"]
├── chatEnabled:          true
├── predictionsEnabled:   true
├── multiCamEnabled:      false
├── purchaseCount:        0
├── peakViewers:          0
├── totalRevenueCents:    0
├── platformFeePct:       0.15          (DFC takes 15%)
├── fightCard:            [array of fights — see below]
└── createdAt:            Timestamp
```

### Fight Card Array Format

```json
[
  {
    "fightId": "f1",
    "fighter1Name": "John Hardman",
    "fighter2Name": "Tyler Brooks",
    "weightClass": "Middleweight",
    "rounds": 5,
    "isMainEvent": true,
    "isTitleFight": true
  },
  {
    "fightId": "f2",
    "fighter1Name": "Sarah Jones",
    "fighter2Name": "Maria Silva",
    "weightClass": "Bantamweight",
    "rounds": 3,
    "isMainEvent": false,
    "isTitleFight": false
  }
]
```

---

## STEP 2: PRICING TIERS (What Each Tier Gets)

| Tier           | Typical Price | What They Get                                                            |
| -------------- | ------------- | ------------------------------------------------------------------------ |
| **Early Bird** | $34.99        | Live stream only (limited window, ends at `onSaleStart`)                 |
| **Standard**   | $49.99        | Live stream + live chat                                                  |
| **Premium**    | $79.99        | Live stream + chat + replay access + bonus content                       |
| **VIP**        | $129.99       | Everything above + multi-cam angles + backstage content + moderated chat |

All prices in **cents** in Firestore (multiply by 100). DFC takes 15%, promoter gets 85%.

---

## STEP 3: SET UP THE LIVE STREAM

### A. Create the Stream Config

Use `DfcStreamingEngine.createLiveStream()` or create directly in `streams` collection:

```
streams/{streamId}
├── ppvEventId:     "your-ppv-id"
├── promoterId:     "your-promoter-id"
├── title:          "IBC 04: GOLD COAST WAR"
├── streamKey:      (auto-generated, e.g., "dfc_ibc04_a7f3b2")
├── rtmpIngestUrl:  "rtmp://ingest-au.datafightcentral.com/live/dfc_ibc04_a7f3b2"
├── hlsPlaybackUrl: "https://stream.datafightcentral.com/dfc_ibc04_a7f3b2/master.m3u8"
├── dashPlaybackUrl:"https://stream.datafightcentral.com/dfc_ibc04_a7f3b2/manifest.mpd"
├── region:         "au"
├── lowLatency:     true
├── multiCam:       false
├── maxCameras:     1
├── status:         "created"
└── createdAt:      Timestamp
```

### B. RTMP Ingest Regions (Pick Closest to Venue)

| Region | Endpoint                                      | Best For              |
| ------ | --------------------------------------------- | --------------------- |
| `au`   | `rtmp://ingest-au.datafightcentral.com/live`  | Australia/NZ events   |
| `us`   | `rtmp://ingest-us.datafightcentral.com/live`  | US/Canada events      |
| `eu`   | `rtmp://ingest-eu.datafightcentral.com/live`  | UK/Europe events      |
| `sea`  | `rtmp://ingest-sea.datafightcentral.com/live` | Southeast Asia events |
| `sa`   | `rtmp://ingest-sa.datafightcentral.com/live`  | South America events  |
| `af`   | `rtmp://ingest-af.datafightcentral.com/live`  | Africa events         |

### C. Encoder Settings (OBS / vMix / Hardware)

| Setting               | Value                                                |
| --------------------- | ---------------------------------------------------- |
| **Server**            | Your RTMP ingest URL from above                      |
| **Stream Key**        | The `streamKey` from Firestore                       |
| **Encoder**           | x264 or NVENC                                        |
| **Rate Control**      | CBR                                                  |
| **Bitrate**           | 5000 Kbps (1080p) or 2800 Kbps (720p)                |
| **Keyframe Interval** | 2 seconds                                            |
| **Audio Bitrate**     | 192 Kbps                                             |
| **Audio Sample Rate** | 48 kHz                                               |
| **Resolution**        | 1920x1080 (or 1280x720 for bandwidth-limited venues) |

---

## STEP 4: STRIPE PAYMENTS SETUP

### Already Configured:

- Stripe account: `acct_1T6WevBSoM6ez8FY`
- Dashboard: https://dashboard.stripe.com/acct_1T6WevBSoM6ez8FY
- Test payment links pre-configured in `lib/core/constants/stripe_config.dart`

### For a New PPV Product:

1. Go to Stripe Dashboard → Products → Create Product
2. Name it: "PPV: [Event Name] — [Tier]"
3. Set the price (one-time, in your currency)
4. Create a Payment Link
5. (Optional) Add the link to `stripe_config.dart` or pass it dynamically

### Webhook Setup:

1. Stripe Dashboard → Developers → Webhooks
2. Endpoint URL: `https://[your-firebase-project].cloudfunctions.net/stripeWebhook`
3. Events to listen for:
   - `charge.succeeded` ← triggers access grant
   - `charge.failed`
   - `charge.refunded`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`

### Environment Variables (Build Time):

```bash
flutter build web \
  --dart-define=STRIPE_PK_TEST=pk_test_your_key_here \
  --dart-define=STRIPE_PK_LIVE=pk_live_your_key_here \
  --dart-define=WEB_DEMO_MODE=false
```

---

## STEP 5: PPV LIFECYCLE — STATUS TRANSITIONS

```
announced → presale → onSale → live → replay → expired
```

| Status      | When                        | What Happens                                                 |
| ----------- | --------------------------- | ------------------------------------------------------------ |
| `announced` | Event created               | Visible on app, no purchases yet                             |
| `presale`   | `presaleStart` date arrives | Early bird pricing active, purchase button enabled           |
| `onSale`    | `onSaleStart` date arrives  | Standard pricing, early bird closes                          |
| `live`      | You go live                 | Stream URL set, player visible, chat opens, predictions open |
| `replay`    | Event ends                  | Replay URL set, available to Premium/VIP buyers              |
| `expired`   | You decide                  | Remove from active listings, archive                         |

### How to Transition Status:

**From the app** (promoter tools):

```dart
await ppvService.updatePPVStatus('your-ppv-id', PPVStatus.live, streamUrl: 'https://...');
```

**From Firebase Console** (manual):
Update the `status` field on the `ppv_events/{id}` document. If going live, also set `streamUrl`.

---

## STEP 6: FIGHT NIGHT — GO LIVE CHECKLIST

### 2 Hours Before:

- [ ] Encoder on, OBS/vMix configured with RTMP URL + stream key
- [ ] Test stream: start → verify in Firebase `streams` doc → stop
- [ ] Pricing confirmed in `ppv_events` doc
- [ ] Fight card confirmed and complete
- [ ] Chat moderation team briefed
- [ ] Backup encoder ready (2nd laptop/PC with same stream key)

### 30 Minutes Before:

- [ ] Start encoder — begin streaming countdown/pre-show
- [ ] Verify `streams/{id}.status` flipped to `live`
- [ ] Set `ppv_events/{id}.streamUrl` to the HLS playback URL
- [ ] Set `ppv_events/{id}.status` to `live`
- [ ] Confirm at least 1 test purchase goes through
- [ ] Monitor Stripe Dashboard for incoming payments

### During the Event:

- [ ] Watch `ppv_events/{id}.purchaseCount` climb
- [ ] Monitor chat for issues (toggle `chatEnabled` if problems)
- [ ] Watch stream health in `stream_analytics` collection
- [ ] Keep backup encoder on standby

### After the Event:

- [ ] Stop encoder
- [ ] Set `ppv_events/{id}.status` to `replay`
- [ ] Set `ppv_events/{id}.replayUrl` to the VOD asset URL
- [ ] Run reconciliation (see After Event section below)

---

## STEP 7: CONTENT PROTECTION (DRM)

Already built in `content_protection_engine.dart`. Four levels:

| Level        | What It Does                                        | Use For                        |
| ------------ | --------------------------------------------------- | ------------------------------ |
| **Basic**    | Token-gated URLs (expire after purchase window)     | Free events, low-value content |
| **Standard** | Token gate + AES-128 encryption                     | Standard PPV                   |
| **Premium**  | Token + AES-128 + DRM (Widevine/FairPlay/PlayReady) | Premium PPV ($50+)             |
| **Maximum**  | All above + forensic watermarking + device binding  | VIP PPV, exclusive content     |

Geo-restrictions configured per event in Firestore. Watermarks trace pirated streams back to the leaker.

---

## STEP 8: AFTER THE EVENT — MONEY

### Revenue Split (Automatic):

- **DFC Platform**: 15% of gross PPV revenue
- **Promoter**: 85% of gross PPV revenue
- Stripe fees deducted from gross before split

### Check Your Numbers:

1. Firebase Console → `ppv_events/{id}` → `purchaseCount` and `totalRevenueCents`
2. Stripe Dashboard → Payments → filter by product
3. Run `getRevenueSnapshot()` for platform-wide numbers
4. Run `getPromoterRevenue(promoterId)` for promoter-specific breakdown

### Payout to Promoter:

Handled by `CreatorPayoutEngine`:

- Earnings tracked in `creator_earnings` collection
- Payout schedule: Weekly, Fortnightly, or Monthly
- Minimum payout: $25 AUD
- Tax: W-9 (US), W-8BEN (international), withholding auto-calculated
- Invoice generated via `InvoiceGenerationService`

---

## STEP 9: SUPPORTED CURRENCIES

15 currencies supported. Set in `ppv_events.currency`:

| Code | Currency           | Stripe Min |
| ---- | ------------------ | ---------- |
| AUD  | Australian Dollar  | $0.50      |
| USD  | US Dollar          | $0.50      |
| GBP  | British Pound      | £0.30      |
| EUR  | Euro               | €0.50      |
| NZD  | New Zealand Dollar | $0.50      |
| CAD  | Canadian Dollar    | $0.50      |
| THB  | Thai Baht          | ฿10        |
| JPY  | Japanese Yen       | ¥50        |
| PHP  | Philippine Peso    | ₱20        |
| SGD  | Singapore Dollar   | $0.50      |
| MYR  | Malaysian Ringgit  | RM2        |
| IDR  | Indonesian Rupiah  | Rp7000     |
| BRL  | Brazilian Real     | R$0.50     |
| ZAR  | South African Rand | R3         |
| NGN  | Nigerian Naira     | ₦100       |

---

# PART 2 — INCIDENT RESPONSE (When Things Go Wrong)

---

## BEFORE THE EVENT

- [ ] Stream key tested on backup RTMP region (6 regions in `dfc_streaming_engine`)
- [ ] Stripe webhook endpoint verified — test charge → refund cycle
- [ ] CDN warm-up: pre-cache static assets in target geo regions
- [ ] Load test: simulate 2x expected concurrent viewers
- [ ] Verify `firestore.indexes.json` deployed (compound indexes for `transactions`, `ppv_purchases`)
- [ ] Confirm DRM license servers responding (Widevine, FairPlay, PlayReady)
- [ ] Check `ppv_events` doc has correct `streamUrl`, `replayUrl`, pricing tiers
- [ ] Backup encoder ready with identical stream key + RTMP config
- [ ] Promoter comms channel open (Discord/Signal/WhatsApp group)
- [ ] Support team briefed on refund authority limits

---

## DURING THE EVENT — STREAM ISSUES

| Problem                          | Severity | Action                                                                                                                         |
| -------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Stream goes down**             | CRITICAL | Failover to backup RTMP ingest region → update `streamUrl` in Firestore → viewers auto-reconnect via `streamPPVEvent()` stream |
| **Buffering / quality drops**    | HIGH     | Downshift ABR ladder — push lower quality profile via `dfc_streaming_engine` quality configs                                   |
| **Audio desync**                 | HIGH     | Kill stream, restart encoder with fresh keyframe alignment, resume                                                             |
| **CDN overload**                 | CRITICAL | Activate secondary CDN origin, update DNS or edge routing                                                                      |
| **Black screen but audio works** | HIGH     | Encoder video input lost — check HDMI/SDI capture, restart encoder, resume                                                     |
| **Geo-block bypass detected**    | MEDIUM   | Check `content_protection_engine` geo-restriction logs, revoke tokens for flagged IPs                                          |
| **Watermark/piracy detected**    | MEDIUM   | Trace forensic watermark → identify leaking user → revoke access token                                                         |
| **Stream latency >30s**          | MEDIUM   | Switch from HLS to low-latency HLS or DASH — reduce segment duration                                                           |

### Stream Recovery Steps (in order)

1. Check encoder output — is it actually sending?
2. Check RTMP ingest — is the region accepting connections?
3. Check CDN origin — is it pulling from ingest?
4. Check edge delivery — are viewers getting segments?
5. If steps 1-4 fail: failover to backup region, update Firestore `streamUrl`

---

## DURING THE EVENT — PAYMENT ISSUES

| Problem                            | Severity | Action                                                                                                                                             |
| ---------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Double charges reported**        | CRITICAL | Idempotency check is in place — query `transactions` by `paymentIntentId` to verify. If duplicate exists, issue refund via `_handleChargeRefunded` |
| **Payment succeeds but no access** | CRITICAL | Check `failed_transactions` collection for orphaned intents. Manually call `_grantPPVAccess(userId, productId)`                                    |
| **Stripe webhook not firing**      | HIGH     | Check `webhook_events` collection for gaps. Manually process from Stripe Dashboard → Events                                                        |
| **Wrong price charged**            | HIGH     | Verify `ppv_events` doc pricing fields. If wrong: pause sales, fix price, issue partial refunds for overcharges                                    |
| **Currency mismatch**              | MEDIUM   | Check `supportedCurrencies` map in stripe engine — refund + retry in correct currency                                                              |
| **Refund flood (>50 requests)**    | HIGH     | Throttle via Stripe Dashboard. Fix root cause (usually stream issue) first, then process refunds in batches                                        |
| **Stripe is down entirely**        | CRITICAL | Enable "free preview" mode, collect emails, bill post-event                                                                                        |

### Payment Recovery Steps

1. Check Stripe Dashboard status page (status.stripe.com)
2. Check `webhook_events` in Firestore — look for 'failed' status entries
3. Check `failed_transactions` — these are payments that charged but didn't record
4. Cross-reference `ppv_purchases` count vs `ppv_events.purchaseCount`
5. Run `getRevenueSnapshot()` and compare with Stripe Dashboard totals

---

## DURING THE EVENT — APP / UX ISSUES

| Problem                            | Severity | Action                                                                                                                                |
| ---------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Chat flooding / toxicity**       | MEDIUM   | Toggle `chatEnabled: false` on the `ppv_events` doc — UI respects this flag                                                           |
| **Predictions not working**        | LOW      | Toggle `predictionsEnabled` on the doc, check Firestore rules for predictions subcollection                                           |
| **App crash on PPV screen**        | HIGH     | Check Flutter error logs. Most likely: null `streamUrl`, missing fight card data, or unhandled stream error                           |
| **White screen / loading forever** | HIGH     | Firestore query timeout — check if indexes are deployed. Fallback: demo data kicks in automatically                                   |
| **Purchase button unresponsive**   | HIGH     | `_isProcessing` flag may be stuck true. User fix: force-close app and reopen. Dev fix: check for unresolved Future in `purchasePPV()` |
| **Fight card not displaying**      | MEDIUM   | Check `fightCard` array in `ppv_events` doc — may be empty or malformed                                                               |
| **User count showing wrong**       | LOW      | Firestore listener lag — `purchaseCount` updates via batch write, may take 1-2s to propagate                                          |

---

## AFTER THE EVENT — RECONCILIATION CHECKLIST

- [ ] Verify `purchaseCount` and `totalRevenueCents` on `ppv_events` doc match actual `ppv_purchases` count
- [ ] Run `getRevenueSnapshot()` — compare with Stripe Dashboard totals
- [ ] Check `failed_transactions` collection — reconcile any orphaned payments
- [ ] Flip event status to `expired`, ensure `replayUrl` is set for VOD access
- [ ] Export promoter revenue via `getPromoterRevenue()` — confirm sliding split correct
- [ ] Review `dunning_events` for any failed subscription renewals during event
- [ ] Archive `webhook_events` older than 30 days
- [ ] Generate invoices for promoter via `InvoiceGenerationService`
- [ ] Process creator payouts via `CreatorPayoutEngine`
- [ ] Post-mortem: document what broke, how fast it was fixed, what to automate

---

## EMERGENCY ESCALATION LADDER

| Level             | Trigger                                       | Action                                                                             |
| ----------------- | --------------------------------------------- | ---------------------------------------------------------------------------------- |
| **L1 — Minor**    | Chat spam, minor UI glitch                    | Toggle Firestore flags, monitor                                                    |
| **L2 — Moderate** | Stream buffering, single payment failure      | Failover stream, manual payment fix                                                |
| **L3 — Major**    | Stream down >2 min, multiple payment failures | Activate backup region, pause sales, notify promoter                               |
| **L4 — Critical** | Full outage, mass double-charges, Stripe down | Kill event → set status `postponed` → mass notification → auto-refund window opens |

### L4 Nuclear Option — Full Event Kill

1. Set `ppv_events/{id}.status` to `postponed` in Firestore
2. Push notification: "Technical difficulties — event postponed. All purchases will be refunded."
3. Batch refund all `ppv_purchases` where `status == 'completed'` for this event
4. Communicate new date within 24 hours
5. Offer free upgrade to premium tier for affected buyers

---

## KEY FIRESTORE COLLECTIONS TO MONITOR

| Collection            | What to Watch                                                     |
| --------------------- | ----------------------------------------------------------------- |
| `ppv_events`          | `status`, `streamUrl`, `purchaseCount`, `totalRevenueCents`       |
| `ppv_purchases`       | New docs appearing = sales working                                |
| `transactions`        | `status: 'completed'` count should match purchases                |
| `failed_transactions` | **Should be empty** — any docs here = money lost                  |
| `webhook_events`      | `status: 'failed'` = Stripe can't talk to us                      |
| `payment_intents`     | `status: 'succeeded'` without matching `transactionId` = orphaned |
| `refunds`             | Volume spike = something went wrong                               |
| `dunning_events`      | Subscription payment failures during event                        |

---

## QUICK COMMANDS

```bash
# Check failed transactions (Firebase CLI)
firebase firestore:get failed_transactions --project datafightcentral

# Force-deploy Firestore indexes
firebase deploy --only firestore:indexes --project datafightcentral

# Check Stripe webhook delivery
# Go to: https://dashboard.stripe.com/webhooks → click endpoint → Recent deliveries

# Rebuild and deploy web app
flutter build web --dart-define=WEB_DEMO_MODE=false
firebase deploy --only hosting --project datafightcentral
```

---

## REVENUE SPLIT REFERENCE

| Product       | Promoter/Seller   | DFC Platform                 |
| ------------- | ----------------- | ---------------------------- |
| PPV           | 85%               | 15%                          |
| Tickets       | 90%               | 10%                          |
| Marketplace   | 80%               | 20%                          |
| Subscriptions | 0%                | 100%                         |
| Donations     | 100% to recipient | 0% (DFC absorbs Stripe fees) |

---

_This document is your fight-night war room playbook. Print it. Pin it. Know it._
