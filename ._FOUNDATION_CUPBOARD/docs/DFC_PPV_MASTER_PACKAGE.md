# DFC PPV Master Package

Status: canonical PPV operating blueprint for launch, promotion, activation, playback, replay, and settlement.

Purpose: give DFC one repeatable, professional, deployable system for taking a PPV event from idea to live launch without improvisation.

Use this document when you need one clean source for:

- launch materials
- activation packs
- content packs
- promotion calendars
- poster and fight-card sizing rules
- landing page requirements
- operating diagrams
- execution order from event setup to settlement

Related docs:

- `docs/DFC_MASTER_EXECUTION_CHECKLIST.md` for repo-wide priority order
- `docs/LAUNCH_READINESS_CHECKLIST.md` for launch-critical QA
- `docs/DFCalive_SOCIAL_PACK.md` for social and SEO payload details
- `docs/PPV_INCIDENT_RESPONSE.md` for operator and incident handling
- `docs/DFC_PPV_TEMPLATE_PACK.md` for actual launch-pack templates and activation copy
- `docs/DFC_PPV_PRODUCT_BLUEPRINT_MAP.md` for mapping this blueprint onto the current codebase and backlog
- `docs/DFC_PPV_OPERATOR_CHECKLIST.md` for one operator-grade event launch checklist
- `docs/DFC_PPV_IMPLEMENTATION_CHECKLIST.md` for the ranked PPV build sequence tied to the current codebase
- `docs/DFC_PPV_IBC4_EVENT_PACKAGE.md` for a real event-specific package scaffold based on the current IBC target

---

## 1. The DFC PPV Operating Model

DFC PPV succeeds when seven layers are present and connected:

1. Product: the event page, checkout, watch screen, replay screen, and entitlement flow are trustworthy.
2. Assets: posters, cards, countdowns, trailers, captions, and links are ready in every required format.
3. Activation: fighters, gyms, creators, promoters, and sponsors each receive their own distribution kit.
4. Calendar: every message has a specific posting day, channel, owner, and call to action.
5. Automation: the seed, metadata, feed, and countdown systems generate and distribute content on schedule.
6. Rights: canonical media approval governs what can be shown, sold, replayed, clipped, or syndicated.
7. Settlement: attribution, referral splits, promoter revenue, creator revenue, and payout state are trackable.

The DFC rule is simple: no PPV goes live unless all seven layers are present or explicitly waived by an operator with named risk acceptance.

---

## 2. What You Need Before Launch

Every PPV must have these minimum inputs before promotion starts.

| Area              | Required                                                                              | Notes                                          |
| ----------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------- |
| Event identity    | event title, slug, date, venue, city, timezone, promoter                              | Must match event and PPV documents exactly     |
| Fight card        | main event, co-main, full bout list, fighter spellings, weights, bout order           | Needed for cards, captions, page copy, and SEO |
| Rights-safe media | approved poster, approved banner, approved clips, approved thumbnails                 | Governed by canonical media approval state     |
| Commerce          | PPV price, regional pricing rules, refund policy, replay window, referral structure   | Needed before links are issued                 |
| Broadcast         | stream source, ingest route, failover route, playback policy, replay policy           | Must be confirmed before T-24h                 |
| Distribution      | fighter contacts, gym contacts, creator contacts, sponsor contacts, promoter contacts | Required for activation packs                  |
| Automation        | event metadata, launch schedule, content queue, countdown triggers, analytics tags    | Needed for n8n and social publishing           |
| Support           | operator owner, incident contact, launch approver, settlement owner                   | No anonymous ownership                         |

If any one of these blocks is missing, the launch is not ready. Promotion can start only after the missing item is resolved or consciously deferred.

---

## 3. The DFC PPV Launch Pack

The launch pack is the master asset set distributed to fighters, gyms, creators, promoters, and sponsors.

### 3.1 Required launch-pack contents

| Category     | Deliverables                                                                                       |
| ------------ | -------------------------------------------------------------------------------------------------- |
| Posters      | 1080x1350 portrait, 1080x1080 square, 1920x1080 landscape, 1200x628 OG, 1080x1920 story            |
| Fight cards  | main event card, co-main card, full card, bout-by-bout cards, fighter versions, gym versions       |
| Countdowns   | T-24h, T-6h, T-1h, T-10m, live now, replay available                                               |
| Copy         | hype caption, fighter caption, gym caption, promoter caption, region caption, PPV buy caption      |
| Links        | master buy link, fighter referral links, gym referral links, creator referral links, promoter link |
| Revenue      | payout split summary, referral explanation, promo-code rules, settlement notes                     |
| Instructions | when to post, where to post, what to tag, what hashtags to use, who approves changes               |

### 3.2 Launch-pack acceptance standard

The launch pack is complete only when:

1. every asset exists in the shared asset folder or canonical storage record
2. every caption is approved and mapped to at least one channel
3. every referral link resolves correctly
4. every poster and card passes sizing rules
5. every recipient group has a version tailored to them

---

## 4. Activation Packs By Recipient

DFC should never send one generic pack to everyone. Each audience needs a pack optimized for their role in distribution.

### 4.1 Fighter activation pack

Include:

- fighter-branded poster
- fighter clip or trailer cut
- fighter caption pack
- fighter referral link
- fighter payout or referral explanation
- fighter countdown assets
- fighter posting schedule

Primary goal: turn fighters into trusted direct sellers without making them build their own materials.

### 4.2 Gym activation pack

Include:

- gym-branded poster
- gym-branded social story asset
- gym caption pack
- gym referral link
- gym payout or referral explanation
- gym countdown assets
- instructions for tagging fighters, city, and promoter

Primary goal: turn each gym into a local distribution node.

### 4.3 Creator activation pack

Include:

- short clips cleared for social use
- creator caption variants
- creator referral link
- creator payout rules
- do-not-say and rights guidance
- replay clip policy

Primary goal: scale reach without losing compliance or attribution.

### 4.4 Promoter activation pack

Include:

- master posters and fight cards
- event landing page link
- full countdown set
- promoter copy set
- sponsor-ready versions
- regional messaging variants
- escalation contacts

Primary goal: keep the promoter aligned with DFC’s launch sequence and assets.

### 4.5 Sponsor activation pack

Include:

- sponsor lockup versions
- ad-safe card variants
- approved CTA language
- tracking links
- placement schedule
- delivery specs for paid social, web, email, and in-venue screens

Primary goal: keep sponsor distribution premium and measurable.

---

## 5. Content Pack Structure

The content pack is the production-ready social payload generated or scheduled by DFC systems.

### 5.1 Content-pack inventory

| Asset type         | Purpose                     | Typical format |
| ------------------ | --------------------------- | -------------- |
| Hero poster        | broad launch announcement   | 4:5, 1:1, 16:9 |
| Fight card graphic | show the lineup             | 4:5, 1:1, 9:16 |
| Countdown graphic  | urgency                     | 4:5, 9:16      |
| Face-off clip      | hype and conversion         | 9:16, 16:9     |
| Fighter intro      | character-driven conversion | 9:16           |
| Gym intro          | community distribution      | 9:16, 1:1      |
| Replay promo       | post-event monetization     | 4:5, 1:1, 16:9 |
| Highlight promo    | retention and discovery     | 9:16, 16:9     |

### 5.2 Auto-generation targets

The automation layer should be able to produce:

- poster derivatives
- caption variants by audience and platform
- hype headlines
- countdown posts
- live-now posts
- replay-available posts
- region-specific copy variants

This plugs directly into the seed and feed engine, with output routed into storage, approval, and distribution flows.

---

## 6. Promotion Calendar

This is the canonical DFC PPV promotion sequence. The point is consistency, not improvisation.

| Timing     | Primary action               | Owner                     | Deliverables                        |
| ---------- | ---------------------------- | ------------------------- | ----------------------------------- |
| T-14 days  | poster drop                  | promoter + DFC social     | hero poster, landing page, buy link |
| T-10 days  | fighter clips begin          | fighters + creator team   | fighter intros, clip posts          |
| T-7 days   | gym amplification            | gyms                      | gym poster, local captions          |
| T-5 days   | countdown begins             | DFC automation + promoter | countdown assets, reminders         |
| T-3 days   | hype lines                   | DFC social + creators     | face-off copy, urgency posts        |
| T-2 days   | face-off and final card push | promoter + fighters       | final card, venue reminder          |
| T-1 day    | T-24h push                   | all channels              | T-24h poster, reminder copy         |
| T-6h       | launch warm-up               | promoter + DFC automation | T-6h clips, story posts             |
| T-1h       | final call                   | all channels              | final CTA, buy-now links            |
| T-10m      | live-now blast               | DFC automation + promoter | live asset, direct watch/buy links  |
| Post-fight | replay promo                 | DFC social + promoter     | replay poster, VOD CTA              |
| T+48h      | highlight pack               | creators + DFC feed       | highlight clips, reaction posts     |

### 6.1 Calendar operating rules

1. Every calendar slot must have an owner.
2. Every owner must receive the right activation pack before their slot begins.
3. Every post must include tracking parameters or a traceable referral route.
4. Countdown automation should not fire until the event, entitlement, and playback records are valid.

---

## 7. PPV Landing Page Blueprint

The landing page is the commercial heart of the event. It should convert in one glance.

### 7.1 Required page modules

| Order | Module                                  | Purpose                                  |
| ----- | --------------------------------------- | ---------------------------------------- |
| 1     | hero poster and headline                | establish event identity immediately     |
| 2     | fighters and fight card                 | show what the buyer is paying for        |
| 3     | date, time, venue, timezone             | remove ambiguity                         |
| 4     | trailer or approved clip                | increase confidence and excitement       |
| 5     | countdown                               | urgency                                  |
| 6     | pricing and regional pricing            | clarity before checkout                  |
| 7     | buy now CTA                             | dominant primary action                  |
| 8     | what’s included                         | explain live, replay, highlights, extras |
| 9     | replay information                      | clarify replay window                    |
| 10    | sponsor, promoter, platform trust marks | reduce hesitation                        |

### 7.2 Landing-page wireframe

```text
┌──────────────────────────────────────────────┐
│                DFC PPV PAGE                  │
├──────────────────────────────────────────────┤
│ Hero poster                                 │
│ Event title + promoter                      │
│ Date / time / venue / city                  │
│ Buy now CTA                                 │
├──────────────────────────────────────────────┤
│ Trailer or approved clip                    │
│ Countdown                                   │
│ Pricing and what's included                 │
├──────────────────────────────────────────────┤
│ Main event                                  │
│ Co-main                                     │
│ Full fight card                             │
├──────────────────────────────────────────────┤
│ Replay policy                               │
│ Region pricing                              │
│ Sponsor and promoter trust marks            │
└──────────────────────────────────────────────┘
```

### 7.3 Landing-page quality rules

- no placeholder poster
- no dead CTA
- no hidden price surprises
- no raw or unapproved media URLs
- no missing timezone
- no missing replay policy

---

## 8. Poster And Fight Card Sizing Blueprint

These are the standard output sizes DFC should support for every event.

### 8.1 Poster sizes

| Size      | Use                                                 |
| --------- | --------------------------------------------------- |
| 1080x1350 | Instagram portrait, highest-value static feed asset |
| 1080x1080 | universal square use                                |
| 1080x1920 | stories, reels, TikTok                              |
| 1920x1080 | YouTube, X, landscape web placements                |
| 1200x628  | Facebook and OG previews                            |

### 8.2 Fight-card sizes

| Size      | Use                               |
| --------- | --------------------------------- |
| 1080x1350 | main event and full-card portrait |
| 1080x1080 | bout card and carousel frames     |
| 1920x1080 | full card landscape               |
| 1080x1920 | story card                        |

### 8.3 DFC app feed sizes

| Ratio | Use                          |
| ----- | ---------------------------- |
| 1:1   | posters                      |
| 4:5   | hype cards                   |
| 16:9  | trailers and landscape video |
| 9:16  | clips and stories            |

### 8.4 Layout rules

1. Never stretch images.
2. Crop from center unless a template defines a safe crop zone.
3. Use correct aspect ratio containers in UI.
4. Use safe network image handling and fallback assets.
5. Keep typography legible in every derivative size.

---

## 9. Unified DFC PPV Systems Blueprint

This is the combined system view for how the full PPV business operates.

```text
┌──────────────────────────────────────────────────────────────┐
│                        SEED ENGINE                           │
│  events, users, payments, media, social, SMS, Meta          │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                     METADATA ENGINE                          │
│  extract, classify, rights, hash, audit                     │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                      STORAGE LAYER                           │
│  Firestore, media assets, Stripe, Mux, analytics            │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                       FEED ENGINE                            │
│  rank, build feed, send to portals and social               │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                      PORTAL ENGINE                           │
│  promoter, fighter, gym, creator, fan, sponsor              │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                    BROADCAST ENGINE                          │
│  live ingest, health, playback, replay, timeline            │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                    COUNTDOWN ENGINE                          │
│  T-24h, T-6h, T-1h, T-10m, live, replay                     │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                     PAYMENT ENGINE                           │
│  checkout, receipts, access, SMS, email                     │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                   SETTLEMENT ENGINE                          │
│  promoter, fighter, gym, creator, sponsor splits            │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                    CREATOR ENGINE                            │
│  referral links, clips, payouts, analytics                  │
└───────────────┬──────────────────────────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────┐
│                   PROMOTER ENGINE                            │
│  event creation, rights, broadcast controls, launch state   │
└──────────────────────────────────────────────────────────────┘
```

### 9.1 What this means operationally

- the product is not just a watch screen
- promotion is not just posters
- launch is not just checkout
- the real system is event creation, rights, media, automation, activation, playback, replay, and settlement working as one pipeline

---

## 10. DFC PPV Execution Pipeline

This is the exact repeatable flow from idea to real event.

| Step | Action                                           | Owner                    | Output                         |
| ---- | ------------------------------------------------ | ------------------------ | ------------------------------ |
| 1    | create event in DFC                              | promoter or operator     | event record                   |
| 2    | upload canonical poster and media                | promoter or media ops    | approved media assets          |
| 3    | build fight card                                 | promoter ops             | finalized card metadata        |
| 4    | create PPV product and pricing                   | commerce ops             | purchasable PPV record         |
| 5    | generate launch pack and activation packs        | content ops              | downloadable distribution kits |
| 6    | issue referral links and payout logic            | creator and commerce ops | trackable attribution          |
| 7    | activate countdown engine                        | automation ops           | scheduled reminders and blasts |
| 8    | execute promotion calendar                       | all distribution owners  | daily outbound content         |
| 9    | go live                                          | broadcast ops            | live playback state            |
| 10   | enable replay                                    | broadcast and media ops  | replay state and replay pack   |
| 11   | publish highlights                               | creators and DFC social  | post-event discovery content   |
| 12   | reconcile purchases and attribution              | finance ops              | settlement basis               |
| 13   | pay promoter, fighters, gyms, creators, sponsors | settlement ops           | payout completion              |

---

## 11. Deployment-Ready Event Checklist

Use this list right before announcing a PPV.

- landing page resolves and has approved media
- price is correct and visible
- buy flow works from the page and from PPV hub surfaces
- watch route handles stale or missing state safely
- replay policy is defined
- launch pack is generated and distributed
- referral links are issued and tested
- countdown schedule is loaded
- fighters and gyms have their pack
- creators have approved clips and copy
- operator has broadcast, failover, and replay contacts
- settlement owner is named

If any line above is false, delay public launch.

---

## 12. What DFC Must Still Do In Product

Based on current repo state, these are the product-side gaps that matter most for this blueprint.

### 12.1 Already strong

- core PPV hub, store, library, watch, access, and checkout surfaces exist
- Stripe-backed PPV logic exists
- Mux-backed live and replay foundations exist
- canonical media approval now gates playback and social visibility

### 12.2 Still needs tightening

- standardize the event to checkout to entitlement to playback to replay to settlement lifecycle across all PPV entry points
- finish promoter payout and settlement ledger surfaces
- complete a dedicated launch-pack generator workflow in the product or content pipeline
- expose referral, creator, fighter, and gym activation tools in one operational UI
- make landing-page modules consistent across all PPV events

This document is the operating blueprint. The product backlog should mirror these gaps.

---

## 13. Decision Rule: No More Winging It

Before launch, ask four questions:

1. Is the product ready to convert and play safely?
2. Do all distribution owners have their pack and their schedule?
3. Is every public asset rights-approved and correctly sized?
4. Can the team reconcile, attribute, and settle the event after broadcast?

If the answer to any question is no, the launch is not complete.

That is the DFC PPV master package.
