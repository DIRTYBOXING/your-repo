# DFC Feed and Earth Truth Model

## Purpose

Define one shared truth model for DFC content surfaces so the feed and the Earth experience do not drift into separate realities.

The feed can be broader.
The Earth surface must be stricter.
But both should derive from the same underlying evidence, trust, and freshness model.

## Core Doctrine

The feed is not the truth.
The map is not the truth.
The truth is the canonical DFC object plus the evidence attached to it.

All visible surfaces should derive from:

- canonical identity
- source evidence
- trust posture
- freshness state
- safety state
- rights state

## Canonical Objects

### 1. Canonical Event

The commercial and editorial source of truth for any fight event.

Key responsibilities:

- resolve event identity
- connect official poster and banner assets
- hold promoter, venue, date, and commercial link truth
- support PPV and replay pathways

### 2. Place or Venue

The geographic source of truth.

This should represent:

- event venues
- gyms
- mentor locations when appropriate
- campaign locations when geography is meaningful

### 3. Promotion

The commercial and source-authority object behind events and approved assets.

### 4. Campaign

A mission or community initiative that has both identity and a real-world action path.

### 5. Mentor

A person or operator-approved profile with a reason to appear as a discovery surface.

### 6. Media Asset

Approved public media attached to canonical objects.

### 7. Evidence Record

The proof layer for any claim.

An evidence record should capture:

- source URL or source system
- source type
- capture time
- extraction result
- trust posture
- licensing or rights notes

## Truth Dimensions

Every object should carry explicit status across multiple dimensions.

### Identity confidence

How sure DFC is that the object is what it claims to be.

### Geographic confidence

How sure DFC is that the location is usable and correct.

### Source trust

How much weight DFC gives the origin of the information.

### Freshness

How recently the object was confirmed and whether it may have drifted.

### Safety

Whether the content is safe to show on the target surface.

### Rights

Whether assets and linked media are approved for public use.

### Actionability

Whether the object gives the user a meaningful next step.

## Surface Eligibility Rules

### Feed eligibility

The feed can show objects that are:

- relevant
- interesting
- lower confidence than map objects
- clearly labelled when uncertain

Feed examples:

- developing fight rumors with explicit source context
- soft partner signals
- early campaign activity
- low-risk preview items awaiting stronger verification

### Earth eligibility

Earth should only show objects that are:

- geographically valid
- fresh enough to matter
- trusted enough to represent spatial truth
- useful to act on or understand

Earth examples:

- live and upcoming events with real locations
- verified gyms
- active campaigns with real local action paths
- approved mentor locations

### Commerce eligibility

Ticket, PPV, and replay surfaces should require the strongest rights and destination integrity.

## Render States

Objects should move through render states instead of being treated as permanently equal.

Suggested states:

- `candidate`
- `review`
- `approved`
- `approved_limited`
- `aging`
- `suppressed`
- `expired`

### Surface behavior

- candidate: internal only
- review: operator queues and internal previews
- approved: full eligible surface rendering
- approved_limited: narrower visibility or reduced visual weight
- aging: subdued visibility and lower priority
- suppressed: not publicly rendered
- expired: archived or historical only

## Unified Decision Model

The feed and Earth should share one decision pipeline with different thresholds.

### Same object, different bar

An item may be:

- feed-approved but Earth-suppressed
- Earth-approved but not promoted in feed
- commerce-approved only after stronger rights checks

This avoids duplicated systems while still respecting different product goals.

## Truth Before Styling

Visual treatments should come after truth decisions.

Examples:

- `live` should only render when live state is evidenced
- `verified` should only render when verification evidence exists
- `elite` or `diamond` should only render when the tier is defended
- premium glow or prominence should follow trust and freshness, not aesthetic preference

## DFC Product Consequences

### For feed surfaces

- richer discovery without pretending everything is confirmed
- ability to surface early signals with labels and review hooks
- safer experimentation with AI-assisted ranking

### For Earth surfaces

- fewer but better markers
- stronger geographic trust
- cleaner narrative about what matters now
- less demo-style filler

### For operator tools

- one review model instead of separate feed and map review logic
- clearer explanation for why something published or was suppressed
- better auditability and later evaluation

## Recommended Shared Data Fields

At minimum, shared objects should expose:

- `canonicalId`
- `entityType`
- `sourceEvidence[]`
- `identityConfidence`
- `geoConfidence`
- `trustScore`
- `freshnessState`
- `safetyState`
- `rightsState`
- `surfaceEligibility`
- `renderState`
- `reviewReason`
- `lastVerifiedAt`

## Integration With Existing Repo Doctrine

This truth model should sit on top of existing DFC components:

- [docs/DFC_CANONICAL_EVENT_GRAPH_V1.md](docs/DFC_CANONICAL_EVENT_GRAPH_V1.md)
- [docs/trust_safety.md](docs/trust_safety.md)
- [docs/DFC_MAPS_REAL_CONTENT_PLAN.md](docs/DFC_MAPS_REAL_CONTENT_PLAN.md)
- [lib/shared/services/map_marker_service.dart](lib/shared/services/map_marker_service.dart)

The main principle is simple:

Feed and Earth may rank differently, but they should not disagree about what is real.
