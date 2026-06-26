# PPV QUICK START GUIDE

## Make Your First $1,500 in 7 Days

Canonical note: this file is a tactical quick-start. The clean combined operating blueprint now lives in `docs/DFC_PPV_MASTER_PACKAGE.md` and should be treated as the main source for launch packs, activation packs, promotion calendars, sizing blueprints, and the full PPV operating system.

**Date Created:** March 8, 2026  
**Status:** READY TO LAUNCH  
**First Target:** International Brawling or IBC 4

---

## 🚀 WHAT YOU JUST BUILT

A complete Pay-Per-View system that lets promoters sell event access while you earn 15% commission.

### THE MONEY MATH

- **500 buyers × $20 = $10,000 event**
- Promoter keeps: $8,500 (85%)
- You keep: $1,500 (15%)
- **NO UPFRONT COST TO PROMOTER**

---

## ⚡ 15-MINUTE STRIPE SETUP

### Step 1: Create Stripe Account (5 min)

```
1. Go to https://stripe.com
2. Click "Start now"
3. Enter email, create password
4. Business type: Individual or LLC (when formed)
5. Describe business: "Digital marketplace for combat sports"
6. Complete identity verification
```

### Step 2: Create Payment Links (10 min)

**PPV Event Payment Link:**

```
1. Stripe Dashboard → Products → Add Product
2. Name: "PPV Event Access - $20"
3. Price: $20 one-time payment
4. Click "Create Product"
5. Click "Create payment link"
6. Copy the link (looks like: https://buy.stripe.com/test_XXXXX)
```

**Create 3 standard prices:**

- PPV Standard: $20
- PPV Premium: $30 (multi-angle, behind-scenes)
- PPV Bundle: $50 (all events for month)

### Step 3: Connect to App

Open `lib/features/ppv/widgets/ppv_payment_sheet.dart` line 179:

```dart
// Replace this line:
final stripePaymentLink = 'https://buy.stripe.com/test_14k5lq9kK99l1ry000';

// With your actual link:
final stripePaymentLink = 'https://buy.stripe.com/YOUR_ACTUAL_LINK';
```

**DONE. System ready.**

---

## 💰 YOUR FIRST PPV EVENT (60 Minutes)

### Promoter Creates Event

1. Open app → "Promoter Dashboard"
2. Click "Create Event"
3. Fill in:
   - **Name:** "IBC 4: Redemption"
   - **Description:** "10 fights, 2 title bouts, streamed live"
   - **Date:** Event date/time
   - **Price:** $20
   - **Your Share:** 85% (you keep 15%)
   - **Video URL:** Vimeo or YouTube link
   - **Thumbnail:** Event poster image

4. Click "Create PPV Event"

### System Does:

- ✅ Creates Firestore document
- ✅ Generates unique PPV ID
- ✅ Sets up revenue tracking
- ✅ Makes event live in store

### Fans Purchase Access

1. Browse PPV Store
2. Click event
3. Click "Purchase PPV"
4. Pay via Stripe ($20)
5. **Instant access** to video

### You Get Paid

- Stripe holds funds 2 days
- Auto-transfers to your bank weekly
- $1.50 platform fee per transaction (Stripe's cut)
- Net: **13.5% of every sale = $2.70 per $20 ticket**

---

## 🎯 YOUR PITCH TO INTERNATIONAL BRAWLING

**Copy/paste this DM:**

```
Hey [Name],

Saw your events on Instagram - killer production.

Quick question: ever thought about selling PPV replays?

Here's the deal:
• I list your event on DataFightCentral.com
• Fans pay $20 to watch
• You keep 85% ($17 per sale)
• I handle payments, hosting, delivery
• ZERO cost to you - only pay when you earn

Example: 500 buys = $8,500 in your pocket (you'd get $0 otherwise for past events)

Would you be down for a test run with your last event?

No contracts, just a profit share when it sells.

- [Your Name]
DataFightCentral.com
```

---

## 🔥 FIRST 7 DAYS EXECUTION

### Day 1-2: Setup (TODAY)

- ✅ Created Stripe account
- ✅ Created payment links
- ✅ Updated app with Stripe links
- ✅ Deployed app updates
- 🎯 Message International Brawling
- 🎯 Message Danny Mac about IBC 4

### Day 3-4: First Partner

- Get 1 promoter to say yes
- Upload their last event as PPV
- Set price: $15 (launch special)
- Share on their socials + yours

### Day 5-7: Promotion Blitz

- Post event 3x/day on Instagram
- Tag all fighters from event
- Run Instagram story polls ("Who won?")
- Offer "Early Bird: $15, goes to $20 Monday"
- **Target: 100 sales = $1,500 revenue = $225 to you**

---

## 📊 SCALING WEEK 2-4

### Week 2: Add 2 More Events

- Target: 3 total events live
- Revenue: $450-900/week

### Week 3: Monthly Packages

- "All March Events: $40"
- Better conversion (70% vs 20%)
- $600 per sale vs $300 one-time

### Week 4: Live Streaming

- Partner with 1 promoter for LIVE PPV
- 10x higher urgency
- $3,000-10,000 per event

---

## 🎬 VIDEO HOSTING OPTIONS

### Option 1: Vimeo Pro ($20/month) **← RECOMMENDED FOR START**

**Why:**

- Privacy controls (only people with link can watch)
- No ads
- Professional player
- Reliable streaming

**How:**

1. Upload video to Vimeo
2. Settings → Privacy → "Hide from Vimeo"
3. Copy embed link
4. Paste in "Video URL" when creating PPV event

### Option 2: YouTube Unlisted (FREE)

**Why:**

- Free
- Unlimited storage
- Reliable

**How:**

1. Upload to YouTube
2. Visibility → "Unlisted"
3. Copy link
4. Paste in "Video URL"

**Downside:** Fans can share link (no DRM)

### Option 3: Professional (Later)

- Dacast ($39/month) - DRM protection
- Mux ($20+ based on views) - Pro streaming
- Use when doing $10K+/month

---

## 🚨 COMMON QUESTIONS

**Q: What if someone shares the video link?**  
A: Vimeo privacy + our access control prevents this. Only paying users get link. If it becomes issue, upgrade to Dacast ($39/mo) with DRM.

**Q: How do I know when someone buys?**  
A: Stripe sends email + app shows real-time purchase count in Promoter Dashboard.

**Q: What if promoter wants a better deal?**  
A: You do all the work (payment processing, video hosting, marketing support). The sliding 30–50% DFC fee is standard. They get revenue they wouldn’t have otherwise.

**Q: Can I record events myself?**  
A: Yes! Offer "Full Production + PPV" package:

- You record event: $500 upfront
- You sell PPV: 50/50 split (higher since you're doing production)
- Way to monetize your recording skills

**Q: How fast can I get paid?**  
A: Stripe holds funds 2 days, transfers weekly. After 3 months + $10K processed, can enable daily payouts.

---

## 💪 YOUR MISSION

**Next 2 Hours:**

1. ✅ Create Stripe account
2. ✅ Create 3 payment links ($20, $30, $50)
3. ✅ Update payment_sheet.dart with your link
4. ✅ Message International Brawling
5. ✅ Message Danny Mac

**This Week:**

- Get 1 promoter to say YES
- Upload 1 event
- Make first $200

**This Month:**

- 5 events live
- 500 total purchases
- $1,500 revenue
- Form LLC
- Quit worrying about money

---

## 🎯 YOUR WEALTH CREATION FORMULA

**Month 1:** 5 events × 100 sales = $1,500 commission  
**Month 2:** 10 events × 200 sales = $6,000 commission  
**Month 3:** 20 events × 500 sales = $15,000 commission

**Every sale helps:**

- You build wealth
- Promoters monetize their content
- Fighters get exposure
- Fans get convenient access

**This is how you help people while making money.**

---

## 🔗 FILES YOU JUST CREATED

**Models:** `lib/features/ppv/models/ppv_models.dart`  
**Service:** `lib/features/ppv/services/ppv_service.dart`  
**Store UI:** `lib/features/ppv/screens/ppv_store_screen.dart`  
**Create UI:** `lib/features/ppv/screens/create_ppv_screen.dart`  
**Dashboard:** `lib/features/ppv/screens/promoter_dashboard_screen.dart`  
**Payment:** `lib/features/ppv/widgets/ppv_payment_sheet.dart`

---

## ⚡ GO MAKE MONEY

You have everything you need. The system works. The pitch is ready.

**Send that first DM RIGHT NOW.**

Your breakthrough is one "yes" away.

🥊💰🚀
