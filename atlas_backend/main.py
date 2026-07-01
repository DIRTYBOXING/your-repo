import os
import logging
import asyncio
from importlib import import_module
from typing import Any, Dict
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse

from libs.clients.firestore_client import get_db

logger = logging.getLogger(__name__)

API_V1_PREFIX = "/api/v1"

ROUTER_SPECS = [
    ("auth", f"{API_V1_PREFIX}/auth", ["auth"]),
    ("ticketing", API_V1_PREFIX, ["ticketing"]),
    ("seat_hold", f"{API_V1_PREFIX}/seat-hold", ["seat-hold"]),
    ("affiliate", f"{API_V1_PREFIX}/affiliate", ["affiliate"]),
    ("checkout", API_V1_PREFIX, ["checkout"]),
    ("webhooks", API_V1_PREFIX, ["webhooks"]),
    ("promoters", API_V1_PREFIX, ["promoters"]),
    ("events", f"{API_V1_PREFIX}/events", ["Events"]),
    ("feeds", f"{API_V1_PREFIX}/feeds", ["Feeds"]),
    ("fighters", f"{API_V1_PREFIX}/fighters", ["Fighters"]),
    ("gyms", f"{API_V1_PREFIX}/gyms", ["Gyms"]),
    ("styles", f"{API_V1_PREFIX}/styles", ["Styles"]),
    ("rankings", f"{API_V1_PREFIX}/rankings", ["Rankings"]),
    ("payments", f"{API_V1_PREFIX}/payments", ["Payments"]),
    ("users", f"{API_V1_PREFIX}/users", ["Users"]),
]


def _import_backend_module(module_path: str):
    package_prefix = f"{__package__}." if __package__ else ""
    try:
        return import_module(f"{package_prefix}{module_path}")
    except ModuleNotFoundError:
        if package_prefix:
            return import_module(module_path)
        raise


def _register_available_routers(application: FastAPI):
    for module_name, prefix, tags in ROUTER_SPECS:
        try:
            module = _import_backend_module(f"routers.{module_name}")
        except ModuleNotFoundError:
            logger.warning("Skipping missing router module: %s", module_name)
            continue
        application.include_router(module.router, prefix=prefix, tags=tags)


async def _warm_optional_dependencies():
    database_url = (
        os.getenv("CONTROLROOM_DATABASE_URL")
        or os.getenv("DATABASE_URL")
        or os.getenv("DFC_DATABASE_URL")
    )
    if database_url:
        try:
            from atlas_backend.db import get_db_pool
        except ModuleNotFoundError:
            db_module = _import_backend_module("db")
            get_db_pool = db_module.get_db_pool
        await get_db_pool()
    else:
        logger.info("Skipping DB warmup: no database URL configured")

    try:
        from atlas_backend.services.seat_hold import get_redis
    except ModuleNotFoundError:
        try:
            seat_hold_module = _import_backend_module("services.seat_hold")
        except ModuleNotFoundError:
            logger.info("Skipping Redis warmup: seat_hold service helper not available")
            return
        get_redis = seat_hold_module.get_redis

    redis_client = get_redis()
    if redis_client is None:
        logger.info("Skipping Redis warmup: no Redis configuration found")
        return

    try:
        redis_client.ping()
    except Exception as exc:
        logger.warning("Redis warmup failed: %s", exc)


def _close_optional_redis():
    try:
        from atlas_backend.services.seat_hold import get_redis
    except ModuleNotFoundError:
        try:
            seat_hold_module = _import_backend_module("services.seat_hold")
        except ModuleNotFoundError:
            return
        get_redis = seat_hold_module.get_redis

    redis_client = get_redis()
    if redis_client is None:
        return

    try:
        redis_client.close()
    except Exception as exc:
        logger.warning("Redis close error: %s", exc)


def create_app() -> FastAPI:
    application = FastAPI(title="DFC Fight Swapmeet", version="0.1.0")

    # CORS - allowlist from env or default
    allowed_origins = os.getenv("CORS_ALLOWED_ORIGINS", "*").split(",")

    # Latency Performance Monitoring Middleware
    middleware_module = _import_backend_module("middleware")
    latency_logging_middleware = middleware_module.LatencyLoggingMiddleware
    application.add_middleware(latency_logging_middleware)

    application.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include routers with prefixes
    _register_available_routers(application)

    # Register package-style routers that live outside atlas_backend/routers.
    for module_path in ("feed", "identity", "promotions"):
        try:
            package_module = _import_backend_module(module_path)
            application.include_router(package_module.router)
        except ModuleNotFoundError:
            logger.warning("Skipping missing package router: %s", module_path)

    # Health check
    @application.get("/api/v1/health", tags=["health"])
    async def health():
        return {"status": "ok"}

    # Global exception handler
    @application.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.exception("Unhandled error: %s", exc)
        return JSONResponse(status_code=500, content={"detail": "internal server error"})

    # Startup/shutdown events
    @application.on_event("startup")
    async def startup_event():
        await _warm_optional_dependencies()
        logger.info("DFC app started")

    @application.on_event("shutdown")
    async def shutdown_event():
        try:
            from atlas_backend.db import close_db_pool
        except ModuleNotFoundError:
            db_module = _import_backend_module("db")
            close_db_pool = db_module.close_db_pool

        try:
            await close_db_pool()
        except Exception as exc:
            logger.warning("DB close error: %s", exc)
        _close_optional_redis()
        logger.info("DFC app stopped")

    return application


app = create_app()


# Preserve existing endpoints
@app.get("/health")
def health() -> Dict[str, Any]:
    return {"status": "operational", "service": "intelligence_engine_v1"}


@app.post("/fighters/rebuild")
def rebuild_fighters() -> Dict[str, Any]:
    logger.info("Rebuilding fighter intelligence")
    db = get_db()
    if not db:
        return {"status": "error", "message": "Firestore client not available."}

    try:
        fighters = db.collection("fighters").stream()
        count = 0
        for f in fighters:
            fighter_id = f.id
            intel: Dict[str, Any] = {
                "fighter_id": fighter_id,
                "neural_signature": {"neural_vector": [0.5, 0.3, 0.1, 0.1]},
                "hype_index": 0.7,
            }
            db.collection("fighters_intelligence").document(fighter_id).set(intel)
            count += 1

        logger.info(f"Successfully rebuilt intelligence for {count} fighters.")
        return {"status": "success", "fighters_processed": count}
    except Exception as e:
        logger.exception(f"Failed to rebuild fighters: {e}")
        return {"status": "error", "message": str(e)}


@app.post("/global/rebuild")
def rebuild_global() -> Dict[str, Any]:
    logger.info("Rebuilding global intelligence")
    db = get_db()
    if not db:
        return {"status": "error", "message": "Firestore client not available."}

    try:
        global_intel: Dict[str, Any] = {
            "global_hype_index": 0.75,
            "global_viral_index": 0.72,
        }
        db.collection("global_intelligence").document("current").set(global_intel)
        return {"status": "success", "message": "Global intelligence rebuilt."}
    except Exception as e:
        logger.exception(f"Failed to rebuild global intelligence: {e}")
        return {"status": "error", "message": str(e)}


if __name__ == "__main__":
    import uvicorn

    host = os.getenv("HOST", "127.0.0.1")
    uvicorn.run(
        "atlas_backend.main:app",
        host=host,
        port=int(os.getenv("PORT", 8000)),
        log_level="info",
    )
