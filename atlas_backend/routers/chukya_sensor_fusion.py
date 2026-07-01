import hashlib
import json
import logging
import os
import time
from datetime import datetime, timezone
from typing import Any, Optional

from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from pydantic import BaseModel
import psycopg2

try:
    from ..db import get_db_pool
    from ..event_bus import publish_event
    from ..metrics import (
        evidence_exports_total,
        export_errors_total,
        ingest_errors_total,
        tracks_ingest_latency_seconds,
        tracks_ingested_total,
    )
except ImportError:
    from db import get_db_pool
    from event_bus import publish_event
    from metrics import (
        evidence_exports_total,
        export_errors_total,
        ingest_errors_total,
        tracks_ingest_latency_seconds,
        tracks_ingested_total,
    )


logger = logging.getLogger(__name__)

router = APIRouter(tags=['chukya-sensor-fusion'])

DEFAULT_DFC_DATABASE_URL = 'postgresql://localhost:5432/dfc'

_RESPONSE_DESCRIPTIONS = {
    400: 'Bad request',
    500: 'Internal server error',
}


def documented_responses(*codes: int) -> dict[int | str, dict[str, Any]]:
    responses: dict[int | str, dict[str, Any]] = {}
    for code in codes:
        responses[code] = {'description': _RESPONSE_DESCRIPTIONS[code]}
    return responses


def get_matching_pipeline_handler():
    try:
        from ..matching import match_recent_devices_with_track
    except ImportError:
        from matching import match_recent_devices_with_track
    return match_recent_devices_with_track


def get_dfc_database_url() -> str:
    return os.getenv('DFC_DATABASE_URL') or os.getenv('DATABASE_URL') or DEFAULT_DFC_DATABASE_URL


class RadarPing(BaseModel):
    timestamp: float
    fighter_id: str
    strike_velocity: float
    stamina: int
    heart_rate: int


class TrackPayload(BaseModel):
    node_id: str
    bearing_deg: float
    range_m: float
    lat: float
    lon: float
    confidence: float = 0.0
    phone: Optional[str] = None


@router.post('/api/radar/ping', status_code=status.HTTP_201_CREATED, responses=documented_responses(500), deprecated=True)
@router.post('/sensor-fusion/radar/ping', status_code=status.HTTP_201_CREATED, responses=documented_responses(500))
async def ingest_radar_ping(ping: RadarPing):
    db_url = get_dfc_database_url()
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO radar_telemetry (timestamp, fighter_id, strike_velocity, stamina, heart_rate)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (ping.timestamp, ping.fighter_id, ping.strike_velocity, ping.stamina, ping.heart_rate),
        )
        conn.commit()
        cur.close()
        conn.close()
        await publish_event(
            'sensor.radar_ping_received',
            source='chukya_sensor_fusion',
            subject=ping.fighter_id,
            stream='sensor',
            payload={
                'fighter_id': ping.fighter_id,
                'timestamp': ping.timestamp,
                'strike_velocity': ping.strike_velocity,
                'stamina': ping.stamina,
                'heart_rate': ping.heart_rate,
            },
        )
        return {'status': 'ok'}
    except Exception as exc:
        logger.error('Sensor fusion radar ingest error: %s', exc)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.post('/blackbird/ingest/track', status_code=status.HTTP_201_CREATED, responses=documented_responses(500), deprecated=True)
@router.post('/sensor-fusion/ingest/track', status_code=status.HTTP_201_CREATED, responses=documented_responses(500))
async def ingest_sensor_track(payload: TrackPayload, background_tasks: BackgroundTasks):
    """Ingest a sensor track, persist it, then queue the matching pipeline."""
    started_at = time.perf_counter()
    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            track_id = await conn.fetchval(
                """
                INSERT INTO tracks(node_id, bearing_deg, range_m, origin, confidence)
                VALUES ($1, $2, $3, ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography, $6)
                RETURNING track_id
                """,
                payload.node_id,
                payload.bearing_deg,
                payload.range_m,
                payload.lon,
                payload.lat,
                payload.confidence,
            )
        tracks_ingest_latency_seconds.observe(time.perf_counter() - started_at)
        tracks_ingested_total.labels(node_id=payload.node_id).inc()

        match_recent_devices_with_track = get_matching_pipeline_handler()
        background_tasks.add_task(
            match_recent_devices_with_track,
            track_id=str(track_id),
            phone=payload.phone,
        )
        await publish_event(
            'sensor.track_ingested',
            source='chukya_sensor_fusion',
            subject=str(track_id),
            stream='sensor',
            payload={
                'track_id': str(track_id),
                'node_id': payload.node_id,
                'lat': payload.lat,
                'lon': payload.lon,
                'confidence': payload.confidence,
            },
        )
        return {'track_id': str(track_id), 'status': 'ingested'}
    except Exception as exc:
        ingest_errors_total.labels(error_type=type(exc).__name__).inc()
        logger.exception('sensor fusion ingest error: %s', exc)
        raise HTTPException(status_code=500, detail='Track ingest failed') from exc


@router.get('/blackbird/alerts', deprecated=True)
@router.get('/sensor-fusion/alerts')
async def list_sensor_alerts(level: Optional[str] = None, limit: int = 50):
    """Return recent alerts, optionally filtered by level."""
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        if level:
            rows = await conn.fetch(
                'SELECT * FROM alerts WHERE level=$1 ORDER BY ts DESC LIMIT $2',
                level,
                limit,
            )
        else:
            rows = await conn.fetch('SELECT * FROM alerts ORDER BY ts DESC LIMIT $1', limit)
    return [dict(row) for row in rows]


@router.post('/blackbird/alerts/{alert_id}/{action}', responses=documented_responses(400, 500), deprecated=True)
@router.post('/sensor-fusion/alerts/{alert_id}/{action}', responses=documented_responses(400, 500))
async def patch_sensor_alert(alert_id: str, action: str):
    """Operator triage: acknowledged | escalated | resolved."""
    valid = {'acknowledged', 'escalated', 'resolved'}
    if action not in valid:
        raise HTTPException(status_code=400, detail=f'Action must be one of {valid}')

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            'UPDATE alerts SET status=$1, updated_at=NOW() WHERE id=$2',
            action.capitalize(),
            alert_id,
        )
        await conn.execute(
            """INSERT INTO audit_log (alert_id, action, actor, ts)
               VALUES ($1, $2, 'operator', NOW())""",
            alert_id,
            action,
        )

    await publish_event(
        'sensor.alert_status_updated',
        source='chukya_sensor_fusion',
        subject=alert_id,
        stream='sensor',
        payload={
            'alert_id': alert_id,
            'status': action.capitalize(),
        },
    )

    return {'alert_id': alert_id, 'status': action.capitalize()}


@router.post('/blackbird/export/{alert_id}', responses=documented_responses(500), deprecated=True)
@router.post('/sensor-fusion/export/{alert_id}', responses=documented_responses(500))
async def export_sensor_evidence(alert_id: str):
    """Build an evidence package and optionally upload it to GCS."""
    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            alert = await conn.fetchrow('SELECT * FROM alerts WHERE id=$1', alert_id)
            audit_rows = await conn.fetch(
                'SELECT * FROM audit_log WHERE alert_id=$1 ORDER BY ts DESC LIMIT 20',
                alert_id,
            )
            await conn.execute(
                """INSERT INTO audit_log (alert_id, action, actor, ts)
                   VALUES ($1, 'evidence_export', 'operator', NOW())""",
                alert_id,
            )
    except Exception as exc:
        export_errors_total.inc()
        logger.exception('sensor fusion evidence export DB error: %s', exc)
        raise HTTPException(status_code=500, detail='DB error during export') from exc

    export_id = f'EXP-{alert_id}-{int(time.time())}'
    manifest = {
        'export_id': export_id,
        'alert_id': alert_id,
        'exported_at': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
        'alert': dict(alert) if alert is not None else {},
        'audit_trail': [dict(row) for row in audit_rows],
        'files': [
            'alert_record.json',
            'track_snapshot.json',
            'device_match.json',
            'audit_trail.json',
            'export_signature.txt',
        ],
        'encryption': 'AES-256 (key in Secret Manager)',
        'retention_days': 30,
    }

    manifest_bytes = json.dumps(manifest, default=str).encode()
    manifest['sha256'] = hashlib.sha256(manifest_bytes).hexdigest()

    gcs_bucket = os.getenv('EVIDENCE_BUCKET')
    signed_url: Optional[str] = None
    if gcs_bucket:
        try:
            from google.cloud import storage as _gcs

            client = _gcs.Client()
            blob = client.bucket(gcs_bucket).blob(f'exports/{export_id}.json')
            blob.upload_from_string(
                json.dumps(manifest, default=str),
                content_type='application/json',
            )
            signed_url = blob.generate_signed_url(expiration=3600)
        except Exception as exc:
            export_errors_total.inc()
            logger.warning('GCS export failed, returning manifest inline: %s', exc)

    evidence_exports_total.inc()
    await publish_event(
        'sensor.evidence_exported',
        source='chukya_sensor_fusion',
        subject=alert_id,
        stream='sensor',
        payload={
            'alert_id': alert_id,
            'export_id': export_id,
            'has_signed_url': signed_url is not None,
            'sha256': manifest['sha256'],
        },
    )
    return {
        'export_id': export_id,
        'signed_url': signed_url,
        'manifest': manifest if not signed_url else None,
        'sha256': manifest['sha256'],
    }
