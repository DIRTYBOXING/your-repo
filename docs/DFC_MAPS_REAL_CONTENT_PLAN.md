# DFC Maps Real Content Plan

Purpose: keep the current DFC maps stack, reduce fake or decorative noise, and turn the map surfaces into trusted operational products with minimal architecture change.

This plan is intentionally narrow.
It does not propose a full maps rebuild.
It keeps the current Google Maps + Flutter path and improves three things only:

- marker semantics
- Earth-screen storytelling
- replacement of weak placeholder content with real, verified, higher-value Google-backed capabilities

Related research docs:

- [docs/architecture/dfc_google_cloud_ai_adoption_memo.md](docs/architecture/dfc_google_cloud_ai_adoption_memo.md)
- [docs/DFC_MAP_PUBLISHING_VERIFICATION_PIPELINE.md](docs/DFC_MAP_PUBLISHING_VERIFICATION_PIPELINE.md)
- [docs/DFC_FEED_EARTH_TRUTH_MODEL.md](docs/DFC_FEED_EARTH_TRUTH_MODEL.md)

## 1. Design Truth

The map only becomes valuable when every visible marker means something operational.

Black maps with neon markers are worth keeping because they create focus and memorability, but they only work if the visual language is disciplined. If the surface contains decorative, fake, duplicated, or unverifiable points, the entire experience drops from command center to game skin.

The rule for DFC should be:

- quiet base map
- loud but sparse signals
- every marker tied to a real data claim
- every map view answering a practical user question

## 2. Current DFC Base

The repo already has the correct foundations:

- unified marker model in [lib/shared/services/map_marker_service.dart](lib/shared/services/map_marker_service.dart)
- custom semantic icon rendering in [lib/shared/services/dfc_map_marker_icon_service.dart](lib/shared/services/dfc_map_marker_icon_service.dart)
- global Earth route in [lib/features/earth/screens/dfc_global_map_screen.dart](lib/features/earth/screens/dfc_global_map_screen.dart)
- community discovery map in [lib/features/maps/screens/community_map_screen.dart](lib/features/maps/screens/community_map_screen.dart)
- route wiring in [lib/core/config/router_config.dart](lib/core/config/router_config.dart)
- dark premium tokens in [lib/core/theme/design_tokens.dart](lib/core/theme/design_tokens.dart)

That means the job is not to invent a new map system.
The job is to tighten what goes on the map and how it earns trust.

## 3. Marker Design System

### Core principle

Marker appearance must encode meaning in this order:

1. type
2. urgency or state
3. trust level
4. commercial or nonprofit significance
5. available action

### Marker roles

Use the current marker types as the permanent top-level taxonomy:

- `gym`
- `event`
- `campaign`
- `mentor`

Do not add new top-level marker categories unless a user can filter them directly and the backend can keep them fresh.

### Visual semantics by role

#### Gyms

Meaning: where people can train now.

- Elite gym: gold core, high-trust, flagship destination
- Premier gym: cyan core, strong regional signal
- Standard or community gym: green core, local utility signal
- Verified ring: thin white or cyan ring only when verification is real
- Closed or stale gym: muted ring, reduced glow, lower z-priority

Primary user question:
Can I trust this place enough to visit, follow, or contact?

#### Events

Meaning: what is happening, when, and how important it is.

- Live event: red core, strongest pulse, highest z-priority
- Upcoming PPV: magenta core, premium/commercial signal
- Upcoming standard event: cyan core, active but lower urgency
- Past event: do not keep on the default global map unless needed for historical views
- Cancelled event: remove from primary views

Primary user question:
What matters now and what is next near me or globally?

#### Campaigns

Meaning: mission or cause surfaces that deserve geographic visibility.

- Pink Shield: pink, health and safety signal
- Gold Coin: gold, donation or aid signal
- Coffee Not Coffin: warm orange, community recovery signal
- Default campaign: subdued purple only if real campaign identity is missing

Primary user question:
Is this a real action point for help, support, or community participation?

#### Mentors

Meaning: people with reputation and access value.

- Pink Diamond: pink, elite trust and care signal
- Gold Diamond: gold, premium expertise signal
- Community mentor: lower-brightness accent if introduced later

Primary user question:
Who here is worth reaching out to and why?

### State rules

Every marker should resolve to one of these states:

- hidden
- idle
- highlighted
- selected
- stale
- suppressed

Definitions:

- `hidden`: filtered out or too low priority for this zoom level
- `idle`: visible but not emphasized
- `highlighted`: selected by search, list hover, or campaign focus
- `selected`: active detail panel target
- `stale`: still present but visually downgraded because freshness is weak
- `suppressed`: blocked from rendering because data quality or trust failed

### Zoom rules

The current global map should evolve toward zoom-aware behavior:

- Zoom 2 to 4: only clusters, live flagship events, and the highest-trust global anchors
- Zoom 5 to 8: regional gyms, current campaigns, major mentors
- Zoom 9+: full local discovery set

If a marker is not meaningful at the current zoom, do not render it.

### Interaction rules

- Tap should always answer why this marker exists.
- First line of detail must be factual, not hype.
- CTA set should stay small: `zoom`, `details`, `directions`, `tickets`, `contact`, or `support`.
- Avoid decorative CTA labels that do not trigger a concrete action.
- Selection should increase semantic clarity, not just brightness.

## 4. What To Remove Or Downgrade

This is the key cleanup pass.

### Remove from default primary map views

- placeholder locations that look real but are seeded only for visual fill
- outdated events that still compete with current events
- unverifiable mentors presented as premium assets
- duplicate gyms or events with inconsistent naming or coordinates
- vanity markers with no next action

### Downgrade visually

- nice-to-have campaign points with low freshness
- community points with weak verification
- historical activity that belongs in archive or replay mode, not live discovery

### Keep only if backed by a real claim

- verification badges
- live indicators
- premium or PPV treatments
- trust labels like elite, premier, or diamond tiers

If the backend cannot defend the claim, the map should not display the claim.

## 5. Minimal Real Content Standard

Before a marker reaches the main Earth or community map, it should satisfy a minimum content standard.

### Required fields by marker

All markers:

- canonical name
- valid coordinates
- city and country
- marker type
- freshness timestamp or known source timestamp

Gym markers:

- discipline list
- verification source or confidence
- open or unknown status

Event markers:

- event date and time
- organization
- live, upcoming, or past state
- ticket or watch path when relevant

Campaign markers:

- campaign kind
- real landing target or support action

Mentor markers:

- specialty
- profile basis or approval source

If these are missing, either suppress the marker or move it to an internal triage list.

## 6. Google Products Worth Using

Do not chase every Maps product.
Only use products that make the current DFC map more truthful or more actionable.

### Use now

#### Maps JavaScript API and Maps SDKs

This remains the rendering base.
No stack change needed.

#### Cloud-based map styling / Map ID

Use this to lock the black-map neon-marker look into a managed style instead of hand-maintained JSON drift.

Value:

- consistent black map across web and mobile lanes
- quieter labels and roads
- premium DFC identity without overpainting the UI

#### Places API

Use only for venue verification and enrichment, not for dumping generic nearby businesses onto the map.

Good uses:

- venue existence check
- canonical place naming
- website or phone recovery for real gyms and venues
- place-based confidence scoring for human review

Bad use:

- spraying uncontrolled third-party place results directly into the product map

#### Geocoding API

Use to normalize incomplete or inconsistent addresses before markers are published.

Value:

- cleaner coordinates
- fewer duplicate location records
- better clustering and viewport results

#### Routes API

Use for the parts of the product that answer travel questions.

Best fits:

- near me gym travel time
- how far the venue is from the user
- event access planning for major fights

### Use later, only if the data layer is already disciplined

#### Photorealistic or immersive Earth-style experiences

Only after the core map contains real, trustworthy content.

Use case:

- flagship event fly-ins
- city-to-city fight route storytelling
- premium sponsor or broadcast presentation moments

This is a layer for impact, not the foundation.

### Do not prioritize now

- 3D spectacle features with no data advantage
- broad POI ingestion
- static maps for primary product surfaces
- any Google API that increases cost without improving trust or actionability

## 7. DFC Earth Screen Spec

The Earth view should feel like a command surface, not a postcard.

### Product job

Answer these questions quickly:

- what is live now
- where the next important events are
- which cities or venues matter most
- where trusted gyms and mentors exist
- where campaigns have active, real-world presence

### Screen structure

#### Layer 1: globe map

- near-black satellite or hybrid base
- restrained labels
- strong contrast between land, water, and markers
- smooth fly-to motion when moving between regions

#### Layer 2: mission header

Top bar should show:

- screen title
- live event count
- current filter scope
- optional region context after search or camera jump

This exists already in early form in [lib/features/earth/screens/dfc_global_map_screen.dart](lib/features/earth/screens/dfc_global_map_screen.dart).

#### Layer 3: filter rail

Keep the existing filter set narrow:

- all
- gyms
- events
- campaigns
- mentors

Do not expand the taxonomy until current content quality is reliable.

#### Layer 4: global signal cards

Replace emoji-heavy summary language with factual operational stats:

- live now
- upcoming this week
- verified gyms
- active cities
- campaigns with open action paths

#### Layer 5: detail drawer

The selected marker drawer should always answer:

- what it is
- why it matters
- what action the user can take next

### Tone

The Earth view should feel:

- premium
- cinematic
- quiet
- credible

It should not feel:

- arcade-like
- cluttered
- over-glowing
- full of unearned urgency

## 8. Minimal Implementation Sequence

This is the narrowest useful sequence.

### Phase 1: content cleanup

- audit every marker source in [lib/shared/services/map_marker_service.dart](lib/shared/services/map_marker_service.dart)
- classify markers as `trusted`, `needs_review`, or `suppress`
- remove or suppress fake fill content from default surfaces
- make stale or uncertain records visually weaker instead of equally loud

### Phase 2: semantic UI cleanup

- keep the current marker taxonomy
- tighten icon rules in [lib/shared/services/dfc_map_marker_icon_service.dart](lib/shared/services/dfc_map_marker_icon_service.dart)
- remove decorative language and emoji-heavy summaries from Earth overlays
- make detail drawers more factual and action-oriented

### Phase 3: Google enrichment

- use Geocoding for address normalization
- use Places only for venue verification and enrichment workflows
- use Routes for travel-time features that clearly help users
- move map styling to a managed cloud style or Map ID

### Phase 4: premium Earth moments

- add intentional fly-to sequences for major events and regions
- add city or country-level clustering stories
- introduce premium Earth-style presentation only for flagship flows

## 9. Immediate Repo Guidance

If the goal is to improve the DFC maps without overbuilding, do these first:

1. Keep [lib/features/earth/screens/dfc_global_map_screen.dart](lib/features/earth/screens/dfc_global_map_screen.dart) as the main Earth route.
2. Treat [lib/shared/services/map_marker_service.dart](lib/shared/services/map_marker_service.dart) as the authority for what gets rendered.
3. Tighten [lib/shared/services/dfc_map_marker_icon_service.dart](lib/shared/services/dfc_map_marker_icon_service.dart) so loud visuals are reserved for high-confidence markers.
4. Remove demo-style filler before adding more Google APIs.
5. Add Places, Geocoding, and Routes only where they directly improve truth, trust, or action.

This is the right bar for DFC:

- fewer markers
- better markers
- better verified content
- stronger geographic story
- selective Google capability upgrades instead of API sprawl
