# DFC Map Publishing Verification Pipeline

## Purpose

Define the minimum verification pipeline required before a record becomes a visible marker on a DFC map surface.

This pipeline exists to prevent three failures:

- fake or weak content filling empty map space
- stale or duplicate records competing with real ones
- unearned premium signals such as live, verified, elite, or PPV states

## Core Rule

The map is a high-trust surface.
If a record cannot defend its location, freshness, and relevance, it should not render as a primary marker.

## Pipeline Stages

### 1. Intake

Accepted sources:

- official promoter or venue pages
- trusted feed scanners
- partner submissions
- operator-created records
- approved campaign submissions

Each intake record should create a `marker_candidate` object with:

- raw source URL or source key
- ingestion timestamp
- marker candidate type
- extracted location fields
- extracted supporting text
- source trust posture

### 2. Canonicalization

Canonicalization resolves whether the incoming record maps to an existing DFC entity.

Use existing repo concepts:

- canonical event graph for events
- source trust rules for external source weighting
- normalized title, promotion, venue, city, and date logic

Outputs:

- `canonical_match`
- `possible_duplicate`
- `new_entity_candidate`

### 3. Geographic Validation

Every map candidate must prove that the place is real enough to render.

Validation steps:

- address normalization
- coordinate sanity checks
- city and country resolution
- place existence check when applicable
- duplicate coordinate collision check

Recommended Google services:

- Geocoding API for normalization
- Places API for venue existence and canonical place naming

Outputs:

- `geo_valid`
- `geo_confidence`
- `place_match_confidence`

### 4. Entity-Specific Verification

#### Event markers

Required:

- canonical title
- event date and time
- venue or city-level location
- promotion identity
- official ticket or watch signal when available

Optional but valuable:

- poster or banner asset
- official venue page
- broadcast or PPV metadata

Suppress if:

- date is missing
- venue cannot be located at least to city level
- source is weak and no corroboration exists

#### Gym markers

Required:

- canonical gym name
- usable coordinates
- city and country
- at least one real discipline

Useful:

- website
- phone number
- review or verification evidence
- open or unknown status

Suppress if:

- venue cannot be resolved
- record appears synthetic or generic
- duplicate gym already exists with higher confidence

#### Mentor markers

Required:

- approved identity basis
- specialty or reason for map presence
- geographic relevance

Useful:

- public profile link
- operator approval source
- trust tier evidence

Suppress if:

- premium tier is unverified
- location is vague or inferred without evidence

#### Campaign markers

Required:

- real campaign kind
- real landing target
- geographic reason for presence

Useful:

- activation window
- organizer identity
- local partner proof

Suppress if:

- campaign has no real CTA
- campaign is expired or stale

### 5. Trust and Safety Gate

Before publish, the candidate passes through:

- source trust rules
- safety checks
- rights and licensing checks for linked media
- abuse or manipulation checks

This stage should answer:

- is the source trustworthy enough
- is the content safe enough
- are linked assets approved for public use

Outputs:

- `trust_score`
- `safety_state`
- `rights_state`

### 6. Freshness Gate

Markers should not remain equally loud forever.

Freshness should consider:

- published or event date
- last source confirmation time
- last successful revalidation time
- status drift risk

Freshness states:

- `fresh`
- `aging`
- `stale`
- `expired`

Suggested default behavior:

- fresh: render normally
- aging: render but visually subdued
- stale: hide from default primary maps unless operator-approved
- expired: suppress from active surfaces

### 7. Publish Decision

Every candidate ends in one of four states:

- `publish`
- `publish_limited`
- `review`
- `suppress`

Definitions:

- `publish`: high-confidence record safe for Earth and community maps
- `publish_limited`: safe for narrower surfaces or lower zoom prominence
- `review`: human decision required before rendering
- `suppress`: do not render

## Confidence Model

Confidence should be broken into components, not one opaque score.

Suggested dimensions:

- source confidence
- geographic confidence
- canonical identity confidence
- freshness confidence
- safety confidence
- rights confidence

Example publish policy:

- publish when all critical dimensions clear threshold
- review when one critical dimension is uncertain but the candidate may matter
- suppress when geography, identity, or safety fail hard

## Surface Rules

### Earth surface

Strongest verification requirement.

- live events
- major upcoming events
- verified gyms
- approved campaigns
- approved mentor locations

### Community map

Can tolerate a slightly broader set, but not fake fill.

- local gyms
- regional events
- mentor discovery
- active community campaigns

### Feed surface

Can show lower-confidence items with labels and operator review pathways.
The feed is a broader discovery surface than the map.

## Audit Requirements

Every publish or suppress decision should store:

- run ID
- candidate ID
- source evidence list
- verification outputs
- publish decision
- model hints if AI was used
- human reviewer if manual review occurred
- final render surfaces

This should land in Firestore workflow state and be exportable to BigQuery for evaluation.

## Integration Points In This Repo

Primary integration points:

- [lib/shared/services/map_marker_service.dart](lib/shared/services/map_marker_service.dart)
- [lib/shared/services/source_trust_rules_service.dart](lib/shared/services/source_trust_rules_service.dart)
- [lib/shared/services/feed_pipeline_audit_service.dart](lib/shared/services/feed_pipeline_audit_service.dart)
- [lib/shared/services/canonical_event_graph_service.dart](lib/shared/services/canonical_event_graph_service.dart)
- [docs/DFC_CANONICAL_EVENT_GRAPH_V1.md](docs/DFC_CANONICAL_EVENT_GRAPH_V1.md)

## Immediate Implementation Order

1. Add candidate review states before adding more map sources.
2. Normalize venue and event location validation.
3. Introduce freshness decay so stale records stop dominating.
4. Reserve elite, verified, live, and PPV treatments for proven records only.
5. Export verification outcomes for later evaluation and tuning.
