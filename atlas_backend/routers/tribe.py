import hashlib as _hashlib
import logging
import os
import random as _random
import time
from datetime import datetime
from typing import Any, Optional

import firebase_admin
import httpx
from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore
from pydantic import BaseModel

try:
    from ..event_bus import publish_event
except ImportError:
    from event_bus import publish_event

try:
    from ..identity.auth import get_current_user
except ImportError:
    from identity.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(tags=['tribe'])

CLOUD_URL = os.environ.get("TRIBE_CLOUD_URL", "")

async def cloud_inference(req: 'TribeV2Request') -> dict[str, Any]:
    """Attempts to call the real Gemini Cloud Function."""
    if not CLOUD_URL:
        raise ValueError("CLOUD_URL not set")
    async with httpx.AsyncClient(timeout=5.0) as client:
        resp = await client.post(CLOUD_URL, json=req.model_dump())
        resp.raise_for_status()
        return resp.json()

def merge_scores(cloud: dict | None, local: dict, fighter_affinity: float = 0.5) -> float:
    """Merges AI semantic scoring with local deterministic fallback logic."""
    if not cloud:
        final_score = local.get('feed_priority', 0.0) + (0.2 * fighter_affinity)
        return round(final_score, 4)
    final_score = (
        0.5 * cloud.get('feed_priority', 0.0) +
        0.3 * local.get('feed_priority', 0.0) +
            0.2 * fighter_affinity
    )
    return round(final_score, 4)

def store_inference(req: 'TribeV2Request', cloud: dict | None, local: dict, final_score: float, user_id: str | None = None):
    """Logs the hybrid scoring metrics to DFC Intelligence memory in Firestore."""
    client = get_firestore_client()
    if not client:
        return
    try:
        deltas = {}
        regions = {"local": local.get("regions", {}), "dominant_local": local.get("dominant_region")}
        if cloud:
            deltas = {
                "feed_priority": cloud.get("feed_priority", 0) - local.get("feed_priority", 0),
                "viral_potential": cloud.get("viral_potential", 0) - local.get("viral_potential", 0),
                "overall_engagement": cloud.get("overall_engagement", 0) - local.get("overall_engagement", 0),
            }
            regions["cloud"] = cloud.get("regions", {})
            regions["dominant_cloud"] = cloud.get("dominant_region")

        doc = {
            "request": req.model_dump(),
            "cloud": cloud,
            "local": local,
            "final_score": final_score,
            "deltas": deltas,
            "regions": regions,
            "fighter_id": req.fighter_id,
            "content_type": req.content_type,
            "model_version_cloud": cloud.get("model_version") if cloud else None,
            "model_version_local": local.get("model_version"),
            "user_id": user_id,
            "created_at": datetime.utcnow().isoformat(),
        }
        client.collection("tribe_v2_inference").add(doc)
    except Exception as exc:
        logger.warning('TRIBE v2 inference store failed (non-fatal): %s', exc)

_RESPONSE_DESCRIPTIONS = {
    400: 'Bad request',
}


def documented_responses(*codes: int) -> dict[int | str, dict[str, str]]:
    responses: dict[int | str, dict[str, str]] = {}
    for code in codes:
        responses[code] = {'description': _RESPONSE_DESCRIPTIONS[code]}
    return responses


def firestore_timestamp_value() -> Any:
    return getattr(firestore, 'SERVER_TIMESTAMP', int(time.time())) if firebase_admin._apps else int(time.time())


def get_firestore_client():
    if not firebase_admin._apps:
        return None
    try:
        return firestore.client()
    except Exception as exc:
        logger.warning('TRIBE Firestore client unavailable: %s', exc)
        return None


class TribeV2Request(BaseModel):
    content_type: str = 'fight_clip'
    modality: str = 'trimodal'
    text: Optional[str] = None
    visual_url: Optional[str] = None
    audio_url: Optional[str] = None
    fighter_id: Optional[str] = None
    metadata: Optional[dict[str, Any]] = None


class TribeV2BatchRequest(BaseModel):
    items: list[TribeV2Request]


class TribeV2CompareRequest(BaseModel):
    item_a: TribeV2Request
    item_b: TribeV2Request


_TRIBE_REGION_PROFILES: dict[str, dict[str, float]] = {
    'fight_clip': {
        'visual_cortex': 0.92, 'motor_cortex': 0.88, 'amygdala': 0.85,
        'basal_ganglia': 0.80, 'insula': 0.72, 'anterior_cingulate': 0.70,
        'prefrontal_cortex': 0.65, 'auditory_cortex': 0.55,
        'cerebellum': 0.50, 'hippocampus': 0.40,
        'broca_area': 0.30, 'wernicke_area': 0.28,
    },
    'highlight': {
        'visual_cortex': 0.90, 'amygdala': 0.82, 'motor_cortex': 0.78,
        'basal_ganglia': 0.75, 'insula': 0.68, 'anterior_cingulate': 0.65,
        'prefrontal_cortex': 0.60, 'auditory_cortex': 0.50,
        'cerebellum': 0.45, 'hippocampus': 0.42,
        'broca_area': 0.35, 'wernicke_area': 0.30,
    },
    'training': {
        'motor_cortex': 0.90, 'cerebellum': 0.88, 'prefrontal_cortex': 0.82,
        'visual_cortex': 0.78, 'basal_ganglia': 0.72, 'hippocampus': 0.70,
        'anterior_cingulate': 0.65, 'insula': 0.55,
        'amygdala': 0.45, 'auditory_cortex': 0.40,
        'broca_area': 0.35, 'wernicke_area': 0.30,
    },
    'promo': {
        'visual_cortex': 0.85, 'prefrontal_cortex': 0.80, 'amygdala': 0.78,
        'broca_area': 0.72, 'wernicke_area': 0.70, 'anterior_cingulate': 0.65,
        'insula': 0.60, 'hippocampus': 0.55,
        'motor_cortex': 0.45, 'auditory_cortex': 0.42,
        'basal_ganglia': 0.35, 'cerebellum': 0.30,
    },
    'corner_audio': {
        'auditory_cortex': 0.92, 'wernicke_area': 0.88, 'broca_area': 0.85,
        'prefrontal_cortex': 0.80, 'amygdala': 0.72, 'anterior_cingulate': 0.68,
        'insula': 0.62, 'hippocampus': 0.55,
        'motor_cortex': 0.45, 'visual_cortex': 0.38,
        'basal_ganglia': 0.30, 'cerebellum': 0.28,
    },
}


def _tribe_local_inference(req: TribeV2Request) -> dict[str, Any]:
    """Deterministic-ish local inference using content-type profiles + text hash jitter."""
    profile = _TRIBE_REGION_PROFILES.get(req.content_type, _TRIBE_REGION_PROFILES['fight_clip'])
    seed_text = (req.text or req.content_type) + (req.fighter_id or '')
    seed_val = int(_hashlib.md5(seed_text.encode()).hexdigest()[:8], 16)
    rng = _random.Random(seed_val)

    regions = {}
    for region, base in profile.items():
        jitter = rng.uniform(-0.08, 0.08)
        regions[region] = round(max(0.0, min(1.0, base + jitter)), 4)

    values = list(regions.values())
    overall = round(sum(values) / len(values), 4) if values else 0.0
    dominant = max(regions, key=lambda region: regions[region]) if regions else 'unknown'

    viral = round(min(1.0, (
        regions.get('amygdala', 0) * 0.4 +
        regions.get('visual_cortex', 0) * 0.3 +
        regions.get('motor_cortex', 0) * 0.3
    )), 4)
    feed_priority = round(overall * 0.6 + viral * 0.4, 4)

    return {
        'regions': regions,
        'overall_engagement': overall,
        'dominant_region': dominant,
        'viral_potential': viral,
        'feed_priority': feed_priority,
        'modality': req.modality,
        'content_type': req.content_type,
        'model_version': 'tribe_v2_local_0.1',
    }


@router.get('/tribe/v2/health')
async def tribe_v2_health():
    return {
        'service': 'tribe_v2_brain_encoder',
        'status': 'operational',
        'model_version': 'tribe_v2_local_0.1',
        'regions_count': 12,
        'content_types': list(_TRIBE_REGION_PROFILES.keys()),
        'modalities': ['visual', 'auditory', 'language', 'trimodal'],
    }


@router.post('/tribe/v2/predict')
async def tribe_v2_predict(req: TribeV2Request, user: dict = Depends(get_current_user)):
    cloud = None
    try:
        if CLOUD_URL:
            cloud = await cloud_inference(req)
    except Exception as exc:
        logger.warning('Cloud inference failed: %s', exc)

    local = _tribe_local_inference(req)
    final_score = merge_scores(cloud, local, fighter_affinity=0.5)

    store_inference(req, cloud, local, final_score, user_id=user.get('user_id', 'anon'))
    active_model = cloud if cloud else local

    await publish_event(
        'tribe.prediction_generated',
        source='tribe_v2',
        subject=user.get('user_id', 'anon'),
        stream='ai',
        payload={
            'user_id': user.get('user_id', 'anon'),
            'fighter_id': req.fighter_id,
            'content_type': req.content_type,
            'modality': req.modality,
            'feed_priority': active_model.get('feed_priority', 0),
            'viral_potential': active_model.get('viral_potential', 0),
        },
    )

    return active_model


@router.post('/tribe/v2/compare')
async def tribe_v2_compare(req: TribeV2CompareRequest, user: dict = Depends(get_current_user)):
    cloud_a, cloud_b = None, None
    if CLOUD_URL:
        try: cloud_a = await cloud_inference(req.item_a)
        except Exception: pass
        try: cloud_b = await cloud_inference(req.item_b)
        except Exception: pass

    local_a = _tribe_local_inference(req.item_a)
    local_b = _tribe_local_inference(req.item_b)

    score_a = merge_scores(cloud_a, local_a, fighter_affinity=0.5)
    score_b = merge_scores(cloud_b, local_b, fighter_affinity=0.5)

    if score_a > score_b:
        winner, margin = 'item_a', round(score_a - score_b, 4)
    elif score_b > score_a:
        winner, margin = 'item_b', round(score_b - score_a, 4)
    else:
        winner, margin = 'tie', 0.0

    return {
        'winner': winner,
        'margin': margin,
        'item_a': {'final_score': score_a, 'cloud': cloud_a, 'local': local_a},
        'item_b': {'final_score': score_b, 'cloud': cloud_b, 'local': local_b},
    }


@router.post('/tribe/v2/rank', responses=documented_responses(400))
async def tribe_v2_rank(req: TribeV2BatchRequest, user: dict = Depends(get_current_user)):
    if not req.items:
        raise HTTPException(status_code=400, detail='List of items cannot be empty')
    if len(req.items) > 100:
        raise HTTPException(status_code=400, detail='Ranking limited to 100 items')

    results = []
    for idx, item in enumerate(req.items):
        cloud = None
        try:
            if CLOUD_URL:
                cloud = await cloud_inference(item)
        except Exception:
            pass

        local = _tribe_local_inference(item)
        final_score = merge_scores(cloud, local, fighter_affinity=0.5)

        results.append({
            "original_index": idx,
            "score": final_score,
            "cloud": cloud,
            "local": local,
            "input_text_preview": (item.text or '')[:120],
        })

    results.sort(key=lambda x: x["score"], reverse=True)

    for rank, entry in enumerate(results, start=1):
        entry["rank"] = rank

    client = get_firestore_client()
    if client is not None:
        try:
            client.collection('tribe_rank_reports').add({
                'item_count': len(results),
                'top_priority': results[0]['score'] if results else 0,
                'user_id': user.get('user_id', 'anon'),
                'created_at': firestore_timestamp_value(),
            })
        except Exception as exc:
            logger.warning('TRIBE v2 rank Firestore persist failed: %s', exc)

    return {
        'count': len(results),
        'ranked_items': results,
    }


@router.post('/tribe/v2/batch', responses=documented_responses(400))
async def tribe_v2_batch(req: TribeV2BatchRequest, user: dict = Depends(get_current_user)):
    if len(req.items) > 100:
        raise HTTPException(status_code=400, detail='Batch limited to 100 items')

    batch_results = []
    for item in req.items:
        cloud = None
        try:
            if CLOUD_URL:
                cloud = await cloud_inference(item)
        except Exception:
            pass

        local = _tribe_local_inference(item)
        final_score = merge_scores(cloud, local, fighter_affinity=0.5)

        batch_results.append({
            "final_score": final_score,
            "cloud": cloud,
            "local": local,
        })

    batch_results.sort(key=lambda x: x["final_score"], reverse=True)

    client = get_firestore_client()
    if client is not None:
        try:
            client.collection('tribe_batch_reports').add({
                'item_count': len(batch_results),
                'top_engagement': batch_results[0]["final_score"] if batch_results else 0,
                'user_id': user.get('user_id', 'anon'),
                'created_at': firestore_timestamp_value(),
            })
        except Exception as exc:
            logger.warning('TRIBE v2 batch Firestore persist failed (non-fatal): %s', exc)

    return {
        'count': len(batch_results),
        'items': batch_results,
    }
