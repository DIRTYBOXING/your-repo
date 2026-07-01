# DFC South Asia Pipeline And Diagrams

Status: implementation-facing pipeline for India and Pakistan commerce, marketing, research, and distribution.

## Pipeline

### Pipeline A: Research -> Offer -> Distribution

1. Research city, gym, creator, and platform demand.
2. Select commercial offer for the market.
3. Localize pricing and copy.
4. Generate market-specific launch packs.
5. Route through DFC, partner, creator, gym, and WhatsApp channels.
6. Measure clicks, buys, replay, and referrals.
7. Reprice and repackage based on conversion.

### Pipeline B: Event Commerce Flow

1. Source event identity and main card story.
2. Create India and Pakistan variants.
3. Attach INR and PKR pricing intent.
4. Build event page, replay promise, and direct CTA.
5. Push into creator and gym activation packs.
6. Drive to DFC PPV or partner route by market.
7. Capture replay retention and referral-driven sales.

## Diagram 1: South Asia Growth System

```mermaid
flowchart LR
    A[Event Source] --> B[DFC Commerce Surface]
    B --> C[India Variant]
    B --> D[Pakistan Variant]
    C --> E[Creator Packs]
    C --> F[Gym Packs]
    C --> G[Regional Platform Routing]
    D --> H[Creator Packs]
    D --> I[Gym Packs]
    D --> J[Regional Platform Routing]
    E --> K[Traffic]
    F --> K
    G --> K
    H --> L[Traffic]
    I --> L
    J --> L
    K --> M[PPV Buys and Replay]
    L --> M
    M --> N[Analytics and Repricing]
    N --> B
```

## Diagram 2: Market Research To Revenue Loop

```mermaid
flowchart TD
    A[City Research] --> B[Audience Demand Map]
    B --> C[Price Ladder]
    B --> D[Creative Angle]
    B --> E[Distribution Route]
    C --> F[Localized Event Page]
    D --> F
    E --> F
    F --> G[Clicks]
    G --> H[Buys]
    G --> I[Replay Interest]
    H --> J[Referral ROI]
    I --> J
    J --> K[Next Market Iteration]
```

## Diagram 3: India And Pakistan Operating Split

```mermaid
flowchart LR
    A[DFC Core Event] --> B[India Lane]
    A --> C[Pakistan Lane]
    B --> D[Hindi and English Creative]
    B --> E[INR Pricing]
    B --> F[Sony LIV JioCinema FanCode Adjacency]
    B --> G[Punjab Delhi Mumbai Bangalore]
    C --> H[Urdu and English Creative]
    C --> I[PKR Pricing]
    C --> J[PTV Sports Tapmad Geo Super Adjacency]
    C --> K[Lahore Karachi Islamabad]
    D --> L[Short-form and WhatsApp Distribution]
    H --> L
    E --> M[Local Commerce Conversion]
    I --> M
    F --> N[Partner Route]
    J --> N
    G --> O[Gym and Creator Activation]
    K --> O
```

## What Must Be True In Product

1. India and Pakistan must exist as explicit markets in export and distribution logic.
2. Event pages must communicate local market relevance, not just global availability.
3. Replay and live offers must be priced and packaged for mobile-first users.
4. Creator and gym packs must be market-specific.
5. Analytics must report India and Pakistan separately, not as generic international traffic.

## Immediate Build Targets

1. India and Pakistan market routing in export engine.
2. South Asia quick preset in shipping center.
3. Region-aware watch surfaces that show South Asia as a growth lane.
4. India and Pakistan pricing and campaign reporting surfaces in promoter operations.
