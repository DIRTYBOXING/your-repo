# message-ingest

Canonical owner for durable messaging ingest.

Recommended implementation:

- Validate message envelope
- Append to Kafka/Pulsar topic
- Persist offline-safe copy
- Emit ack and delivery events

Smoke check:

- Two-client send/receive roundtrip and persistence assertion.
