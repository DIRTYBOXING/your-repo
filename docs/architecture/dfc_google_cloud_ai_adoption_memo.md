# DFC Google Cloud AI Adoption Memo

## Objective

Map Google Cloud's production-ready AI guidance onto Data Fight Central's actual operating model.

This memo is intentionally practical.
It does not recommend a broad AI rebuild.
It identifies which Google Cloud capabilities DFC should use now, later, or ignore for the current stage of the product.

## DFC Starting Position

DFC already has the right control-plane doctrine:

- Firebase + GCP as the control plane
- Firestore as the durable workflow ledger
- Firebase Functions for app-triggered logic
- Cloud Run for heavier services and jobs
- Pub/Sub and Scheduler for background automation
- Gemini or Vertex AI only where AI adds leverage

That doctrine is already reflected in [docs/DFC_STACK_BLUEPRINT_V1.md](docs/DFC_STACK_BLUEPRINT_V1.md) and the canonical event model in [docs/DFC_CANONICAL_EVENT_GRAPH_V1.md](docs/DFC_CANONICAL_EVENT_GRAPH_V1.md).

The production-ready AI question for DFC is not how to host the most advanced model.
The question is how to use AI to improve truth, trust, safety, and operator speed.

## Use Now

### 1. Gemini or Vertex AI for bounded content operations

Use AI for:

- event normalization
- venue and promoter metadata extraction
- source summarization for operator review
- duplicate detection assist
- confidence scoring hints
- publish-review-suppress recommendations

Do not use AI as the final source of truth.
Use it as an assist layer on top of canonical records and source evidence.

### 2. Cloud Run for AI-backed workers and review services

Cloud Run is the best near-term execution surface for DFC AI jobs because it fits the existing stack and keeps the runtime simple.

Best uses:

- enrichment workers
- verification workers
- moderation helpers
- review queue APIs
- content ranking and scoring services

This matches the repo's broader guidance to prefer Cloud Run before GKE for heavier services.

### 3. Pub/Sub for ingestion and revalidation events

Use Pub/Sub to trigger:

- new source intake processing
- stale record revalidation
- map marker refresh decisions
- audit fan-out
- downstream feed and Earth surface updates

This keeps AI decisions event-driven and observable instead of buried in ad hoc cron logic.

### 4. BigQuery for evaluation, audits, and operator intelligence

BigQuery is the right place for:

- evaluation datasets
- false-positive and false-negative review
- source trust analytics
- publish decision audits
- freshness decay analysis
- operator throughput and backlog reporting

The current repo already assumes BigQuery for analytics and audit-adjacent work.

### 5. Security controls for AI workflows

The most relevant security pieces are:

- input hardening for untrusted external content
- prompt injection resistance for tool-using agents
- PII inspection before AI access
- secret isolation for service credentials
- observable logging for model-assisted publish decisions

Google's security learning path is useful here because DFC ingests third-party content and may eventually run tool-using agents.

### 6. Places and Geocoding for map-truth enrichment

These are not the same as AI, but they are critical to a production-ready Earth surface.

Use them for:

- venue existence checks
- canonical naming
- address cleanup
- coordinate validation
- place-based confidence scoring

They should feed the truth pipeline, not bypass it.

## Use Later

### 1. Agent Development Kit for tightly-scoped agent workflows

ADK becomes useful when DFC has clear, narrow agent jobs such as:

- source triage
- evidence gathering
- compliance pre-checks
- review packet generation
- operator handoff summaries

Do not introduce multi-agent orchestration until each step has measurable output quality and a clear failure policy.

### 2. Evaluation services for agent traces and retrieval quality

This becomes important when DFC has:

- tool-using agents
- retrieval-augmented operator consoles
- repeatable decision tasks that need benchmark datasets

Evaluation is high-value, but it should be tied to business metrics like reduced duplicate events, better venue accuracy, and fewer false map markers.

### 3. RAG on DFC internal knowledge

RAG is worth adding when DFC needs grounded operator assistance over:

- promoter records
- event history
- rights and licensing notes
- runbooks
- policy and legal docs

This is an operator-product capability, not the first requirement for Earth or feed integrity.

### 4. Fine-tuning for specialized internal workflows

Only consider fine-tuning after DFC proves that prompting and structured evaluation cannot meet a real business need.

Examples where it could later matter:

- highly repetitive metadata normalization
- domain-specific event naming patterns
- specialized moderation or rights classification with measured gaps

## Ignore For Now

### 1. Self-hosting open models on GKE

This adds operational weight before DFC has proven a need for it.
It does not solve the current truth and trust bottlenecks.

### 2. Large multi-agent swarms as a product dependency

DFC already has swarm language and agent-heavy concepts in legacy docs.
That should not become the default production posture.

The right bar is:

- small number of bounded agents
- clear tool permissions
- strong audits
- measurable output quality

### 3. AI-generated truth without provenance

No model output should create a canonical event, venue, or marker by itself.
Every published fact needs a source path and a review policy.

## Recommended DFC AI Topology

### Input lane

- external feeds
- partner submissions
- operator-entered records
- public pages and official promoter sources

### Processing lane

- Functions or ingest workers create candidate records
- Pub/Sub fans out verification and enrichment jobs
- Cloud Run services perform AI-assisted extraction, scoring, and normalization
- Places and Geocoding validate geographic claims

### Truth lane

- canonical event graph resolves event identity
- source trust rules assign trust posture
- safety and licensing checks gate risky content
- publish decisions are stored as durable workflow state

### Surface lane

- feed surfaces can show broader content with explicit trust labels
- Earth and map surfaces require stronger location truth and freshness
- operator surfaces show evidence, scores, and review actions

### Audit lane

- Firestore stores workflow state
- BigQuery stores analysis, evaluation, drift, and historical decision data

## Success Metrics

Judge the AI layer by product outcomes, not demo quality.

Primary metrics:

- reduction in duplicate event records
- reduction in false or stale map markers
- increase in verified venue coverage
- operator review time reduction
- publish accuracy for event and venue records
- trust-weighted click-through on event and venue surfaces

Secondary metrics:

- model latency
- worker cost
- review queue backlog
- percentage of suppressed low-confidence records

## Immediate Recommendation

DFC should not pursue a broad Google Cloud AI rollout.
DFC should implement a narrow production-ready AI lane focused on:

1. canonicalization
2. venue verification
3. trust scoring
4. moderation and rights checks
5. publish or suppress decisions
6. auditability and evaluation

That creates real leverage for both the feed and Earth surfaces without compromising the existing stack doctrine.
