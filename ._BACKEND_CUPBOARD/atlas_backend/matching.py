# atlas_backend/matching.py
# DFC sensor-fusion matching pipeline (legacy Blackbird pilot): PostGIS-based matching, scoring, and alert creation.
# Wire into your FastAPI ingest endpoints via background_tasks.add_task(...)

import uuid
import json
import logging
from datetime import datetime, timezone
from typing import Optional

try:
    from .db import get_db_pool
except ImportError:
    from db import get_db_pool

logger = logging.getLogger(__name__)

# ─── Tunable constants ───────────────────────────────────────────────────────
TIME_WINDOW      = "10 seconds"
DIST_THRESHOLD   = 150.0      # metres
SCORE_RADAR      = 0.45
SCORE_GPS        = 0.15
SCORE_WATCHLIST  = 0.40
ALERT_VERIFY_THRESHOLD  = 0.45
ALERT_ACTION_THRESHOLD  = 0.75


# ─── DB helpers ──────────────────────────────────────────────────────────────

async def _get_pool():
    """Return the shared asyncpg pool for matching operations."""
    return await get_db_pool()


async def find_device_matches_for_track(track_id: str):
    pool = await _get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT * FROM find_device_matches($1, $2::interval, $3::float)",
            track_id, TIME_WINDOW, DIST_THRESHOLD
        )
    return rows


async def check_watchlist_match(phone: Optional[str]) -> bool:
    if not phone:
        return False
    pool = await _get_pool()
    async with pool.acquire() as conn:
        result = await conn.fetchval(
            "SELECT is_ping_watchlist_match($1)", phone
        )
    return bool(result)


async def get_track_confidence(track_id: str) -> float:
    pool = await _get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT confidence FROM tracks WHERE track_id=$1", track_id
        )
    return float(row["confidence"]) if row else 0.0


async def create_alert(level: str, reason: str, score: float, evidence: dict) -> str:
    alert_id = str(uuid.uuid4())
    pool = await _get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO alerts(alert_id, level, reason, score, ts, evidence)
            VALUES ($1, $2, $3, $4, now(), $5::jsonb)
            """,
            alert_id, level, reason, score, json.dumps(evidence)
        )
    logger.info("Alert created alert_id=%s level=%s score=%.2f", alert_id, level, score)
    return alert_id


async def write_audit(operator_id: str, action: str, target_id: str, detail: dict):
    pool = await _get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO audit_log(operator_id, action, target_id, detail, ts)
            VALUES ($1, $2, $3, $4::jsonb, now())
            """,
            operator_id, action, target_id, json.dumps(detail)
        )


# ─── Core matching pipeline ──────────────────────────────────────────────────

async def match_recent_devices_with_track(track_id: str, phone: Optional[str] = None):
    """
    Background task: run after inserting a new radar track.
    Scores spatial, temporal, and watchlist cues; creates alerts when thresholds met.
    """
    try:
        radar_conf    = await get_track_confidence(track_id)
        matches       = await find_device_matches_for_track(track_id)
        watchlist_hit = await check_watchlist_match(phone)

        watchlist_score = SCORE_WATCHLIST if watchlist_hit else 0.0

        if not matches and not watchlist_hit:
            return

        for m in matches:
            score = (
                SCORE_RADAR      * radar_conf
                + SCORE_GPS      * 1.0          # binary GPS proximity confirmed
                + watchlist_score
            )

            evidence = {
                "track_id":    track_id,
                "device_id":   str(m["device_id"]),
                "dist_m":      float(m["dist_m"]),
                "device_ts":   m["device_ts"].isoformat(),
                "track_ts":    m["track_ts"].isoformat(),
                "watchlist":   watchlist_hit,
                "radar_conf":  radar_conf,
                "score":       round(score, 4),
                "captured_at": datetime.now(timezone.utc).isoformat(),
            }

            if score >= ALERT_ACTION_THRESHOLD:
                await create_alert("Action", "Radar+GPS+Watchlist match", score, evidence)
            elif score >= ALERT_VERIFY_THRESHOLD:
                await create_alert("Verify", "Radar+GPS proximity", score, evidence)

    except Exception as exc:
        logger.exception("match_recent_devices_with_track failed track_id=%s: %s", track_id, exc)


# ─── FastAPI hook (wire into your ingest endpoint) ───────────────────────────
#
#  from atlas_backend.matching import match_recent_devices_with_track
#
#  @router.post("/ingest/track")
#  async def ingest_track(payload: TrackPayload, background_tasks: BackgroundTasks):
#      track_id = await db_insert_track(payload)
#      background_tasks.add_task(
#          match_recent_devices_with_track,
#          track_id=track_id,
#          phone=payload.phone
#      )
#      return {"track_id": track_id, "status": "ingested"}
