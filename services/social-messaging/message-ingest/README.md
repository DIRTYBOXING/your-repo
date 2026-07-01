# message-ingest

Responsibilities:

- Validate incoming message envelopes.
- Attach idempotency key and monotonic timestamp.
- Append message to Kafka or Pulsar topic.
- Persist delivery-safe copy to cold store.

Topic suggestion:

- `dfc.messaging.messages.v1`

Consumer outputs:

- delivery fanout
- unread counters
- moderation classifier
- audit sink
