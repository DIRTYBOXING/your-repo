# DFC Google Platform Plan

## Purpose
Define the best-fit Google-native feature set for DFC across Maps, Earth, storefront, PPV, and AI-assisted sales so product, ops, and outreach teams build one coherent platform instead of isolated feature lanes.

## Platform position
DFC should be explicitly Google-native where Google gives operational leverage, trust, scale, or conversion lift.

That means:

- Google Maps Platform for real-world discovery and venue trust
- Firebase and Firestore for canonical truth and app surfaces
- Cloud Run and Artifact Registry for service delivery
- Secret Manager and IAM for runtime safety
- Gemini and Google AI services for ranking, operator assistance, and sales intelligence
- Cloud Monitoring and Logging for production visibility

The goal is not to bolt Google features onto DFC decoratively.
The goal is to make Google services strengthen the DFC spine:

source intake -> normalize -> rank -> publish

## 1. Maps and venue intelligence

### What DFC should use
- Maps JavaScript API for web map rendering
- Places API for venue identity and enrichment
- Geocoding API for canonical place resolution
- Routes API for directions and travel relevance
- Static Maps or map snapshots where full interactive maps are unnecessary

### What DFC should do with it
- resolve event venues to trusted geographic objects
- verify gyms and promoter locations
- power near-me discovery for fighters, fans, and operators
- attach actionability to map objects: directions, tickets, contact, support

### Product rule
The map is not the truth. The canonical object plus evidence is the truth.

That matches [docs/DFC_FEED_EARTH_TRUTH_MODEL.md](c:/Data-Fight-Central-safe-bridge/docs/DFC_FEED_EARTH_TRUTH_MODEL.md) and [docs/DFC_MAPS_REAL_CONTENT_PLAN.md](c:/Data-Fight-Central-safe-bridge/docs/DFC_MAPS_REAL_CONTENT_PLAN.md).

### Immediate implementation priorities
- keep current Flutter plus Google Maps path
- remove decorative markers and weak placeholders
- make venue markers backed by canonical event or gym objects only
- surface ticket and PPV destination routing from verified event markers

## 2. Earth surface

### What the Earth surface is for
DFC Earth should be the stricter, higher-trust geographic surface for:

- live and upcoming verified events
- verified gyms
- campaign points with real-world action paths
- premium commercial objects only when rights and destinations are defensible

### Product rule
Feed and Earth share one truth model but operate at different thresholds.

### Google fit
Google Maps Platform remains the core path unless the product later needs a heavier geospatial stack. DFC does not need a map rebuild first. It needs stronger truth thresholds and marker discipline first.

### Immediate implementation priorities
- share one eligibility pipeline between feed and Earth
- suppress low-confidence commercial markers from Earth
- keep PPV, ticket, and replay surfaces behind the strongest destination-integrity rules

## 3. Storefront and commerce

### What the storefront should be
DFC storefront is the commercial face for event conversion:

- event landing pages
- ticket destinations
- PPV purchase surfaces
- replay access surfaces
- sponsorship and premium upsell blocks

### Google fit
- Firebase Hosting or web delivery for storefront surfaces
- Firebase Analytics for conversion instrumentation
- Remote Config or feature-flag style controls for promotional experiments
- Google Pay as a payment method where the Stripe flow supports it

### DFC rule
Storefront pages should route users cleanly to the next commercial action without losing canonical truth.

That is already aligned with [docs/PPV_STOREFRONT_GUIDE.md](c:/Data-Fight-Central-safe-bridge/docs/PPV_STOREFRONT_GUIDE.md) and the broader product doctrine around verified event destinations.

### Immediate implementation priorities
- unify event page, promo card, and PPV offer language
- attach clean analytics events to each storefront CTA
- ensure map and feed items land on commercially structured event pages

## 4. PPV and replay

### What DFC should support
- PPV event setup
- entitlement checks
- checkout routing
- live watch access
- replay readiness
- settlement and payout visibility

### Google fit
- Firestore for PPV truth and entitlement-adjacent metadata where appropriate
- Cloud Run backend for orchestration and entitlement logic
- Cloud Storage for related media assets and evidence payloads
- Firebase Analytics for funnel measurement

### DFC rule
PPV is not just playback. PPV is a commercial and operator workflow with rights, entitlement, conversion, and replay control.

The repo already reflects that direction in the PPV docs and service modules. The Google-native work is to make those surfaces measurable, reliable, and tightly linked to event truth.

### Immediate implementation priorities
- keep PPV objects tied to canonical event objects
- emit analytics for view, click, purchase intent, purchase success, entitlement success, watch start, and replay access
- preserve a clean path from promo card -> event page -> PPV storefront -> entitlement -> playback

## 5. AI sales and operator intelligence

### What AI sales means in DFC
AI sales should help DFC sell and distribute events better. It should not be a vague chatbot layer.

### Best-fit Google-native AI roles
- Gemini-assisted copy generation for promo cards, event blurbs, and campaign variants
- sales copilot for promoters and operators: recommended bundles, upsell prompts, region-aware language
- ranking assistance for promotional prioritization
- event and storefront summary generation for fast launch workflows
- support triage or ops-assist for event readiness and launch checklists

### Product rules
- AI can draft, rank, and recommend
- AI must not silently publish commercial claims without human approval
- AI outputs must stay within the DFC truth model and rights posture

That aligns with [docs/AI_SYSTEM_ARCHITECTURE.md](c:/Data-Fight-Central-safe-bridge/docs/AI_SYSTEM_ARCHITECTURE.md), especially the principle that each bot has a scoped job.

### Immediate implementation priorities
- use Gemini for operator-facing draft generation first
- add AI-generated promo variants to the campaign workflow, but keep approval human-gated
- feed AI sales suggestions with canonical event, venue, rights, and recency data only

## 6. Recommended Google-first feature set for DFC

### P0
- Maps JavaScript API
- Places API
- Geocoding API
- Firebase Auth
- Firestore
- Cloud Run
- Artifact Registry
- Secret Manager
- Cloud Logging and Monitoring
- Gemini-backed operator assistance

### P1
- Routes API for travel and attendance context
- Firebase Analytics for storefront and PPV funnels
- Remote Config or equivalent feature gating
- App Check where DFC surfaces need stronger abuse protection

### P2
- richer AI sales copilots
- stronger recommendation and bundling flows
- advanced geospatial storytelling for Earth surfaces

## 7. What "fully loaded Google" means for DFC

It does not mean turning on every Google product.

It means using Google services where they directly improve:

- truth
- conversion
- operational control
- observability
- trusted geographic discovery
- AI-assisted revenue and launch execution

## 8. Immediate next actions

1. Keep Maps and Earth tied to the canonical truth model.
2. Keep storefront and PPV tied to verified commercial destinations.
3. Instrument PPV and storefront analytics with a Google-native funnel.
4. Add Gemini-assisted operator and sales drafting before attempting fully autonomous flows.
5. Keep every Google feature subordinate to the DFC spine rather than parallel to it.
