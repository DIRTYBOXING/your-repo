# DFC Canonical Event Graph V1

## Purpose

Data Fight Central should not behave like a passive upload bin. DFC is a promoter-first operating system that resolves each combat sports event into a canonical commercial object with trusted metadata, approved artwork, ticketing links, playback surfaces, pricing, and replay pathways.

The canonical event graph is the data contract that lets DFC promote promotions instead of merely listing them.

## Core Doctrine

- DFC does not compete with promotions. DFC promotes promotions.
- Big promotions are welcome, but small and regional promotions are a core growth lane.
- Official promoter metadata and official event artwork outrank generic placeholders.
- Social posts, partner pages, and broadcaster pages are acquisition lanes. The canonical DFC event page is the control plane.
- A real event should resolve to a real event identity, a real event date, and real promoter-facing commerce or viewing links.

## Graph Nodes

### Canonical Event

The canonical event is the master identity used by DFC surfaces.

Suggested fields:

- `eventId`
- `slug`
- `title`
- `normalizedTitle`
- `promotionId`
- `promotionName`
- `sportType`
- `eventDate`
- `venue`, `city`, `country`
- `status`
- `ticketUrl`
- `streamUrl`
- `posterUrl`, `bannerUrl`, `thumbnailUrl`
- `externalIds`

### PPV Offering

Commercial wrapper around the event.

- `ppvId`
- linked `eventId`
- `price`
- `currency`
- `regionalOverrides`
- `purchaseWindow`
- `replayWindow`
- `entitlementProductId`
- `streamPlatforms`

### Media Asset

Approved artwork and video references that can be promoted publicly.

- `assetId`
- `eventId`
- `promotionId`
- `type`
- `role` such as poster, banner, thumbnail, trailer
- `url`
- `sourceDomain`
- `approved`
- `approvedForPublicUse`
- `capturedAt`
- `checksum`

### Promotion

The partner being promoted.

- `promotionId`
- `name`
- `tier`
- `region`
- `officialSite`
- `ticketDomains`
- `streamDomains`

### Distribution Link

Official commerce or viewing destinations.

- `type`: ticket, buy_ppv, watch_live, watch_replay
- `url`
- `region`
- `source`
- `isOfficial`

## Resolution Order

Artwork and promotion links should resolve in this order:

1. Explicit event fields on the canonical event document.
2. Linked PPV event artwork when the PPV object has better commercial art.
3. Approved `media_assets` connected to the same event or promotion.
4. Deterministic artwork mapping from title, promoter, date, and official URLs.
5. DFC branded placeholder only as a final safety fallback.

This order prevents toy/demo behavior from outranking real event promotion.

## Matching Strategy

The graph should join records through a mix of strong and soft keys.

### Strong Keys

- explicit `eventId`
- linked `ppvEventId`
- stored `externalIds`
- promoter-owned asset references

### Soft Keys

- normalized title similarity
- event date proximity
- promoter name similarity
- official source domain matches from ticket or stream URLs
- venue and city similarity when available

## Current Implementation

The first production implementation is now wired through the shared Flutter services.

- `lib/shared/services/canonical_event_graph_service.dart`
- `lib/shared/services/event_service.dart`
- `lib/shared/services/ppv_service.dart`
- `lib/shared/widgets/dfc_network_image.dart`

### CanonicalEventGraphService

Current responsibilities:

- build a merged event graph from event, PPV, and approved media records
- resolve best poster URL for event surfaces
- resolve best poster URL for PPV surfaces
- prefer official or approved assets over generic art
- use metadata-aware fallback mapping when event records are incomplete

### EventService Integration

`EventService` now enriches fetched events through the canonical graph before returning them to screens. This means event cards, featured lists, and event detail pages can receive corrected poster, banner, and thumbnail fields even when the original event record is incomplete.

### PPVService Integration

`PPVService` now resolves poster art asynchronously through the canonical graph so a PPV card can inherit better artwork from the linked event or approved media asset set.

## Product Surfaces Powered By The Graph

- homepage featured events
- events index and event details
- PPV carousels and PPV cards
- social feed event embeds
- Earth and maps discovery surfaces
- ticketing handoff
- live watch entry points
- replay catalog and archive pages

## Business Impact

The canonical event graph is not just a data cleanup layer. It is the revenue and promotion spine for DFC.

- Better event identity means better SEO and less duplicate clutter.
- Better artwork resolution improves CTR on event cards and social embeds.
- Better promoter linkage means cleaner ticket and PPV handoff.
- Better metadata makes regional pricing, replay access, and sponsorship packaging possible.

## Next Steps

1. Add external source identity fields for promoter CMS feeds and partner broadcaster pages.
2. Persist ranked artwork candidates and link quality scores for auditability.
3. Add region-aware commercial link resolution for tickets, PPV, and replay.
4. Extend the graph to support trailer video, fighter lineup confidence, and sponsor inventory.
5. Promote the canonical event page as the stable DFC landing page for every event campaign.
