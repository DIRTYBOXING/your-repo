# DFC Capability Manifest

This document defines what the unified DFC Combat OS can do, how modules connect, and what must stay synchronized.

## Mission

DFC is a combat operations system that combines creator commerce, event operations, prediction intelligence, health telemetry, and fan distribution into one controlled platform.

## Core Capability Areas

- Commerce: PPV, ticketing, subscriptions, direct creator sales.
- Distribution: DFC-owned commerce with external funnel traffic from social channels.
- Prediction: event-level probability modeling from historical and live performance signals.
- Rankings: dynamic division and pound-for-pound ladders with shift tracking.
- Maps and directories: event map overlays and gym discovery.
- Health and devices: camp readiness and wearable-derived checks.
- AI interaction: fan, fighter, and coach guidance workflows.

## Synchronization Model

1. Entry: users enter via feed, creator pages, maps, or event links.
2. Transaction: checkout writes order intent and payment status.
3. Fulfillment: webhook confirms payment and grants access artifacts.
4. Visibility: feed and profile state update with access status.
5. Intelligence: predictions and rankings refresh from latest outcomes.
6. Telemetry: health and device updates contribute to readiness models.

## Non-Negotiable Engineering Rules

- UI in screens and widgets only.
- State mutation in controllers only.
- External systems in core and feature services.
- Business rules in domain usecases.
- Repository interfaces in domain repositories.
- No direct API logic inside widgets.

## Go/No-Go Signals

Go when all critical flows are green:

- Checkout success to webhook confirmation.
- Order and access token persisted to data stores.
- Profile reflects ticket or PPV entitlement.
- Prediction card and ranking updates render correctly.
- Domain mapping and TLS are healthy for public endpoints.

No-Go when any of the above fail.
