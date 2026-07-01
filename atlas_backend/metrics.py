# atlas_backend/metrics.py
# Prometheus metrics instrumentation for the DFC sensor-fusion ingest + matching pipeline.
# Metric names retain blackbird_* prefixes for dashboard compatibility.
# Usage: mount via Starlette middleware or FastAPI lifespan.

from prometheus_client import Counter, Histogram, Gauge, REGISTRY
import time

# ─── Ingest metrics ──────────────────────────────────────────────────────────
tracks_ingested_total = Counter(
    "blackbird_tracks_ingested_total",
    "Total radar tracks received by the ingest API",
    ["node_id"]
)

tracks_ingest_latency_seconds = Histogram(
    "blackbird_tracks_ingest_latency_seconds",
    "Time from track received to DB write complete",
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5]
)

ingest_errors_total = Counter(
    "blackbird_ingest_errors_total",
    "Total ingest errors",
    ["error_type"]
)

# ─── Matching pipeline metrics ───────────────────────────────────────────────
matches_evaluated_total = Counter(
    "blackbird_matches_evaluated_total",
    "Total track-device pairs evaluated by matching pipeline"
)

alerts_created_total = Counter(
    "blackbird_alerts_created_total",
    "Total alerts created",
    ["level"]   # Verify, Action, Resolved
)

matching_duration_seconds = Histogram(
    "blackbird_matching_duration_seconds",
    "Time taken to run full matching pipeline for one track",
    buckets=[0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
)

# ─── Edge node health ────────────────────────────────────────────────────────
edge_nodes_active = Gauge(
    "blackbird_edge_nodes_active",
    "Number of edge nodes currently reporting heartbeats"
)

edge_node_last_seen_seconds = Gauge(
    "blackbird_edge_node_last_seen_seconds",
    "Unix timestamp of last heartbeat per node",
    ["node_id"]
)

# ─── Export metrics ──────────────────────────────────────────────────────────
evidence_exports_total = Counter(
    "blackbird_evidence_exports_total",
    "Total encrypted evidence packages exported"
)

export_errors_total = Counter(
    "blackbird_export_errors_total",
    "Total evidence export errors"
)


# ─── Helper: timed context manager ───────────────────────────────────────────
class timed:
    """Context manager that records duration into a Histogram."""
    def __init__(self, histogram: Histogram):
        self._histogram = histogram
        self._start = None

    def __enter__(self):
        self._start = time.perf_counter()
        return self

    def __exit__(self, *args):
        elapsed = time.perf_counter() - self._start
        self._histogram.observe(elapsed)


# ─── FastAPI /metrics endpoint (mount in main.py) ────────────────────────────
#
#  from prometheus_client import make_asgi_app
#  from fastapi import FastAPI
#
#  app = FastAPI()
#  metrics_app = make_asgi_app()
#  app.mount("/metrics", metrics_app)
#
# Scrape at: http://your-service/metrics
