"""
DFC Fight Predictor — Production ML Service
=============================================
FastAPI service exposing calibrated fight predictions with SHAP explanations,
real-time round scoring, and premium insight reports.

Endpoints:
  POST /predict         — Single fight probability + explanation
  POST /predict/batch   — Batch scoring for cards/events
  POST /predict/live    — Real-time round-by-round update
  GET  /model/info      — Model metadata and performance metrics
  GET  /health          — Liveness probe
"""

import os
import logging
import hashlib
import json
from urllib import error as urlerror
from urllib import request as urlrequest
from contextlib import asynccontextmanager
from typing import Optional

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from featurizer import Featurizer
from model_registry import ModelRegistry

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
MODEL_DIR = os.getenv("MODEL_DIR", "models")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
ALLOWED_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")
UFC_EVENT_SOURCE_BASE_URL = os.getenv("UFC_EVENT_SOURCE_BASE_URL", "").strip()

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("predictor")

# ---------------------------------------------------------------------------
# Global singletons (loaded at startup)
# ---------------------------------------------------------------------------
registry: Optional[ModelRegistry] = None
featurizer: Optional[Featurizer] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global registry, featurizer
    log.info("Loading model registry from %s …", MODEL_DIR)
    registry = ModelRegistry(MODEL_DIR)
    registry.load()
    featurizer = Featurizer()
    log.info("Predictor ready — models=%s", list(registry.models.keys()))
    yield
    log.info("Shutting down predictor")


app = FastAPI(
    title="DFC Fight Predictor",
    version="1.0.0",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Request / Response schemas
# ---------------------------------------------------------------------------
class FighterProfile(BaseModel):
    fighter_id: str
    name: str
    wins: int = 0
    losses: int = 0
    draws: int = 0
    ko_wins: int = 0
    sub_wins: int = 0
    dec_wins: int = 0
    ko_losses: int = 0
    sub_losses: int = 0
    dec_losses: int = 0
    age: float = 30.0
    height_cm: float = 178.0
    reach_cm: float = 180.0
    stance: str = "orthodox"  # orthodox | southpaw | switch
    weight_class: str = "welterweight"
    avg_sig_strikes_landed: float = 0.0
    avg_sig_strikes_absorbed: float = 0.0
    avg_takedowns_landed: float = 0.0
    avg_takedowns_absorbed: float = 0.0
    avg_control_time_sec: float = 0.0
    avg_sub_attempts: float = 0.0
    win_streak: int = 0
    loss_streak: int = 0
    days_since_last_fight: int = 180
    camp_weeks: int = 8
    is_short_notice: bool = False


class PredictRequest(BaseModel):
    fighter_a: FighterProfile
    fighter_b: FighterProfile
    event_name: Optional[str] = None
    is_title_fight: bool = False
    scheduled_rounds: int = 3
    betting_odds_a: Optional[float] = None  # decimal odds
    betting_odds_b: Optional[float] = None


class MethodProbabilities(BaseModel):
    ko_tko: float
    submission: float
    decision: float


class PredictResponse(BaseModel):
    fighter_a_win_prob: float
    fighter_b_win_prob: float
    confidence: float  # 0-1 model certainty
    method_probs_a: MethodProbabilities
    method_probs_b: MethodProbabilities
    expected_rounds: float
    explanation: list  # top SHAP features
    model_version: str
    calibration_score: float


class BatchPredictRequest(BaseModel):
    fights: list[PredictRequest]


class NamedMatchup(BaseModel):
    fighter_a_name: str = Field(min_length=1)
    fighter_b_name: str = Field(min_length=1)
    weight_class: str = "welterweight"


class EventAutoPredictRequest(BaseModel):
    event_name: Optional[str] = None
    fighters: list[str] = Field(default_factory=list)
    matchups: list[NamedMatchup] = Field(default_factory=list)
    weight_class: str = "welterweight"
    scheduled_rounds: int = 3
    is_title_fight: bool = False


class EventAutoPredictEntry(BaseModel):
    fighter_a_name: str
    fighter_b_name: str
    prediction: PredictResponse


class EventAutoPredictResponse(BaseModel):
    event_name: Optional[str] = None
    matchup_count: int
    predictions: list[EventAutoPredictEntry]


class UfcEventPredictRequest(BaseModel):
    ufc_event_id: str = Field(min_length=1)
    scheduled_rounds: Optional[int] = None
    is_title_fight: Optional[bool] = None
    weight_class: Optional[str] = None


class LiveRoundUpdate(BaseModel):
    fight_id: str
    round_num: int
    fighter_a_strikes: int = 0
    fighter_b_strikes: int = 0
    fighter_a_takedowns: int = 0
    fighter_b_takedowns: int = 0
    fighter_a_control_sec: int = 0
    fighter_b_control_sec: int = 0
    fighter_a_knockdowns: int = 0
    fighter_b_knockdowns: int = 0
    # Base prediction from pre-fight
    base_prediction: Optional[PredictRequest] = None


class LivePredictResponse(BaseModel):
    fighter_a_win_prob: float
    fighter_b_win_prob: float
    momentum_shift: float  # negative = B gaining, positive = A gaining
    finish_prob_remaining: float
    round_num: int


def _sanitize_fighter_id(name: str) -> str:
    slug = "-".join(name.strip().lower().split())
    if not slug:
        slug = "fighter"
    digest = hashlib.sha1(name.encode("utf-8")).hexdigest()[:8]
    return f"{slug}-{digest}"


def _synthetic_profile_from_name(name: str, weight_class: str) -> FighterProfile:
    digest = hashlib.sha256(name.encode("utf-8")).digest()
    wins = 6 + (digest[0] % 25)
    losses = digest[1] % 10
    ko_wins = min(wins, digest[2] % 12)
    sub_wins = min(wins - ko_wins, digest[3] % 8)
    dec_wins = max(0, wins - ko_wins - sub_wins)

    return FighterProfile(
        fighter_id=_sanitize_fighter_id(name),
        name=name,
        wins=wins,
        losses=losses,
        draws=digest[4] % 3,
        ko_wins=ko_wins,
        sub_wins=sub_wins,
        dec_wins=dec_wins,
        ko_losses=digest[5] % 5,
        sub_losses=digest[6] % 4,
        dec_losses=digest[7] % 6,
        age=22 + (digest[8] % 17),
        height_cm=165 + (digest[9] % 36),
        reach_cm=168 + (digest[10] % 35),
        stance=["orthodox", "southpaw", "switch"][digest[11] % 3],
        weight_class=weight_class,
        avg_sig_strikes_landed=1.5 + ((digest[12] % 60) / 10),
        avg_sig_strikes_absorbed=1.0 + ((digest[13] % 60) / 10),
        avg_takedowns_landed=(digest[14] % 40) / 10,
        avg_takedowns_absorbed=(digest[15] % 40) / 10,
        avg_control_time_sec=30 + (digest[16] % 240),
        avg_sub_attempts=(digest[17] % 30) / 10,
        win_streak=digest[18] % 6,
        loss_streak=digest[19] % 4,
        days_since_last_fight=30 + (digest[20] % 330),
        camp_weeks=6 + (digest[21] % 8),
        is_short_notice=(digest[22] % 10) == 0,
    )


def _auto_pair_matchups(fighters: list[str], default_weight_class: str) -> list[NamedMatchup]:
    cleaned = [name.strip() for name in fighters if name and name.strip()]
    if len(cleaned) % 2 != 0:
        raise HTTPException(400, "fighters list must contain an even number of names")

    pairs: list[NamedMatchup] = []
    for idx in range(0, len(cleaned), 2):
        pairs.append(
            NamedMatchup(
                fighter_a_name=cleaned[idx],
                fighter_b_name=cleaned[idx + 1],
                weight_class=default_weight_class,
            )
        )
    return pairs


def _default_ufc_catalog() -> dict[str, dict]:
    return {
        "UFC999": {
            "event_name": "UFC 999",
            "matchups": [
                {
                    "fighter_a_name": "Alex Pereira",
                    "fighter_b_name": "Jiri Prochazka",
                    "weight_class": "light heavyweight",
                },
                {
                    "fighter_a_name": "Leon Edwards",
                    "fighter_b_name": "Belal Muhammad",
                    "weight_class": "welterweight",
                },
            ],
            "scheduled_rounds": 5,
            "is_title_fight": True,
        },
        "UFC300": {
            "event_name": "UFC 300",
            "matchups": [
                {
                    "fighter_a_name": "Alex Pereira",
                    "fighter_b_name": "Jamahal Hill",
                    "weight_class": "light heavyweight",
                },
                {
                    "fighter_a_name": "Zhang Weili",
                    "fighter_b_name": "Yan Xiaonan",
                    "weight_class": "strawweight",
                },
            ],
            "scheduled_rounds": 5,
            "is_title_fight": True,
        },
    }


def _fetch_ufc_event_from_source(ufc_event_id: str) -> Optional[dict]:
    if not UFC_EVENT_SOURCE_BASE_URL:
        return None

    endpoint = f"{UFC_EVENT_SOURCE_BASE_URL.rstrip('/')}/events/{ufc_event_id}"
    try:
        with urlrequest.urlopen(endpoint, timeout=5) as response:
            if response.status >= 400:
                return None
            return json.loads(response.read().decode("utf-8"))
    except (urlerror.URLError, TimeoutError, ValueError) as exc:
        log.warning("UFC source fetch failed for %s: %s", ufc_event_id, exc)
        return None


def _load_ufc_event(ufc_event_id: str) -> tuple[Optional[dict], str]:
    source_event = _fetch_ufc_event_from_source(ufc_event_id)
    if source_event:
        return source_event, "upstream"

    catalog = _default_ufc_catalog()
    fallback = catalog.get(ufc_event_id.upper())
    if fallback:
        return fallback, "catalog"

    return None, "missing"


def _build_synthetic_map_points(zoom: int, tile_x: int, tile_y: int) -> list[dict]:
    base_points = [
        {
            "id": "gym_ufc_pi",
            "label": "UFC Performance Institute",
            "category": "gym",
            "lat": 36.0857,
            "lng": -115.1531,
        },
        {
            "id": "gym_xtreme_couture",
            "label": "Xtreme Couture MMA",
            "category": "gym",
            "lat": 36.1389,
            "lng": -115.1725,
        },
        {
            "id": "event_tmobile",
            "label": "T-Mobile Arena",
            "category": "event",
            "lat": 36.1028,
            "lng": -115.1781,
        },
    ]

    return [
        {
            **point,
            "zoom": zoom,
            "tile": {"x": tile_x, "y": tile_y},
        }
        for point in base_points
    ]


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "models_loaded": list(registry.models.keys()) if registry else [],
    }


@app.get("/model/info")
async def model_info():
    if not registry:
        raise HTTPException(503, "Models not loaded")
    return registry.metadata()


@app.get("/maps/generate")
async def generate_maps(
    type: str = Query(default="synthetic"),
    zoom: int = Query(default=10, ge=0, le=22),
    x: int = Query(default=0),
    y: int = Query(default=0),
):
    if type != "synthetic":
        raise HTTPException(400, "Only synthetic maps are supported")

    return {
        "status": "ok",
        "type": type,
        "tile": {"x": x, "y": y, "zoom": zoom},
        "generated": _build_synthetic_map_points(zoom=zoom, tile_x=x, tile_y=y),
    }


@app.post("/predict", response_model=PredictResponse)
async def predict(req: PredictRequest):
    if not registry or not featurizer:
        raise HTTPException(503, "Models not loaded")

    features = featurizer.build_fight_features(req)
    feature_names = featurizer.feature_names()
    X = np.array([features])

    # --- Core win probability (ensemble) ---
    win_prob_a = registry.predict_win_prob(X)
    win_prob_b = 1.0 - win_prob_a
    confidence = registry.prediction_confidence(X)

    # --- Method probabilities ---
    method_a = registry.predict_method(X, perspective="a")
    method_b = registry.predict_method(X, perspective="b")

    # --- Expected rounds ---
    expected_rounds = registry.predict_rounds(X, req.scheduled_rounds)

    # --- SHAP explanation ---
    explanation = registry.explain(X, feature_names, top_k=8)

    return PredictResponse(
        fighter_a_win_prob=round(win_prob_a, 4),
        fighter_b_win_prob=round(win_prob_b, 4),
        confidence=round(confidence, 4),
        method_probs_a=MethodProbabilities(**method_a),
        method_probs_b=MethodProbabilities(**method_b),
        expected_rounds=round(expected_rounds, 2),
        explanation=explanation,
        model_version=registry.version,
        calibration_score=registry.calibration_error,
    )


@app.post("/predict/batch")
async def predict_batch(req: BatchPredictRequest):
    results = []
    for fight in req.fights:
        r = await predict(fight)
        results.append(r)
    return {"predictions": results}


@app.post("/predict/event", response_model=EventAutoPredictResponse)
async def predict_event(req: EventAutoPredictRequest):
    if not req.fighters and not req.matchups:
        raise HTTPException(400, "Provide fighters or matchups")

    matchups = req.matchups if req.matchups else _auto_pair_matchups(req.fighters, req.weight_class)

    predictions: list[EventAutoPredictEntry] = []
    for matchup in matchups:
        fight = PredictRequest(
            fighter_a=_synthetic_profile_from_name(matchup.fighter_a_name, matchup.weight_class),
            fighter_b=_synthetic_profile_from_name(matchup.fighter_b_name, matchup.weight_class),
            event_name=req.event_name,
            scheduled_rounds=req.scheduled_rounds,
            is_title_fight=req.is_title_fight,
        )
        fight_prediction = await predict(fight)
        predictions.append(
            EventAutoPredictEntry(
                fighter_a_name=matchup.fighter_a_name,
                fighter_b_name=matchup.fighter_b_name,
                prediction=fight_prediction,
            )
        )

    return EventAutoPredictResponse(
        event_name=req.event_name,
        matchup_count=len(predictions),
        predictions=predictions,
    )


@app.post("/predict/event/ufc")
async def predict_event_ufc(req: UfcEventPredictRequest):
    event_id = req.ufc_event_id.strip().upper()
    if not event_id:
        raise HTTPException(400, "ufc_event_id required")

    source_event, source = _load_ufc_event(event_id)
    if not source_event:
        raise HTTPException(404, f"UFC event {event_id} not found")

    event_payload = EventAutoPredictRequest(
        event_name=source_event.get("event_name", event_id),
        fighters=source_event.get("fighters", []),
        matchups=source_event.get("matchups", []),
        weight_class=req.weight_class or source_event.get("weight_class", "welterweight"),
        scheduled_rounds=req.scheduled_rounds or source_event.get("scheduled_rounds", 3),
        is_title_fight=req.is_title_fight
        if req.is_title_fight is not None
        else bool(source_event.get("is_title_fight", False)),
    )

    predictions = await predict_event(event_payload)
    return {
        "ufc_event_id": event_id,
        "source": source,
        "predictions": predictions.model_dump(),
    }


@app.post("/predict/live", response_model=LivePredictResponse)
async def predict_live(update: LiveRoundUpdate):
    """Real-time round-by-round probability update during a live fight."""
    if not registry or not featurizer:
        raise HTTPException(503, "Models not loaded")

    live_features = featurizer.build_live_features(update)
    X = np.array([live_features])

    # Use the live model (trained on round-by-round data)
    win_prob_a = registry.predict_live(X)
    momentum = featurizer.compute_momentum(update)
    finish_prob = registry.predict_finish_probability(X, update.round_num, 5)

    return LivePredictResponse(
        fighter_a_win_prob=round(win_prob_a, 4),
        fighter_b_win_prob=round(1.0 - win_prob_a, 4),
        momentum_shift=round(momentum, 4),
        finish_prob_remaining=round(finish_prob, 4),
        round_num=update.round_num,
    )
