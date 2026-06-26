---
mode: ask
description: Return the DFC Brain interface contract for a streaming or PPV decision
---

# DFC Brain Interface

For any streaming, PPV, playback, replay, or content-distribution decision in Data Fight Central, answer using the `streaming_doctrine_v1` interface.

## Response Contract

Return these fields clearly:

- `objective`: `streaming_doctrine_v1`
- `primaryPlatform`
- `secondaryPlatforms`
- `messagingKey`
- `operatorNotes`
- `riskFlags`
- `recommendedNextAction`

## Evaluation Rules

- Assume Mux ingest plus signed HLS playback is the default unless the request proves a different lane is required.
- Only elevate WebRTC when the experience is truly latency-sensitive and the low-latency feature flag is enabled.
- Treat social and partner platforms as distribution surfaces, not the primary premium watch path.
- Treat Firebase + GCP as the canonical control plane unless a human maintainer explicitly changes that rule.
- Treat n8n as optional automation glue, not the durable source of truth.
- Include explicit risk flags whenever doctrine and request intent do not align.
