import os
import logging
import asyncio
from typing import Any, Dict
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse

from libs.clients.firestore_client import get_db
from routers import ticketing, seat_hold, affiliate, checkout, webhooks, promoters, events, fighters, gyms, styles, rankings, payments, users

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    application = FastAPI(title="DFC Fight Swapmeet", version="0.1.0")

    # CORS - allowlist from env or default
    allowed_origins = os.getenv("CORS_ALLOWED_ORIGINS", "*").split(",")
    application.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Latency Performance Monitoring Middleware
    from middleware import LatencyLoggingMiddleware
    application.add_middleware(LatencyLoggingMiddleware)

    # Include routers with prefixes
    application.include_router(ticketing.router, prefix="/api/v1", tags=["ticketing"])
    application.include_router(seat_hold.router, prefix="/api/v1/seat-hold", tags=["seat-hold"])
    application.include_router(affiliate.router, prefix="/api/v1/affiliate", tags=["affiliate"])
    application.include_router(checkout.router, prefix="/api/v1", tags=["checkout"])
    application.include_router(webhooks.router, prefix="/api/v1", tags=["webhooks"])
    application.include_router(promoters.router, prefix="/api/v1", tags=["promoters"])
    application.include_router(events.router, prefix="/api/v1/events", tags=["Events"])
    application.include_router(fighters.router, prefix="/api/v1/fighters", tags=["Fighters"])
    application.include_router(gyms.router, prefix="/api/v1/gyms", tags=["Gyms"])
    application.include_router(styles.router, prefix="/api/v1/styles", tags=["Styles"])
    application.include_router(rankings.router, prefix="/api/v1/rankings", tags=["Rankings"])
    application.include_router(payments.router, prefix="/api/v1/payments", tags=["Payments"])
    application.include_router(users.router, prefix="/api/v1/users", tags=["Users"])

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
        from atlas_backend.db import get_db_pool
        from atlas_backend.services.seat_hold import get_redis

        # Warm up DB pool
        await get_db_pool()
        # Warm up Redis connection
        get_redis().ping()
        logger.info("DFC app started")

    @application.on_event("shutdown")
    async def shutdown_event():
        from atlas_backend.db import close_db_pool
        from atlas_backend.services.seat_hold import get_redis

        try:
            await close_db_pool()
        except Exception as exc:
            logger.warning("DB close error: %s", exc)
        try:
            get_redis().close()
        except Exception as exc:
            logger.warning("Redis close error: %s", exc)
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

    uvicorn.run(
        "atlas_backend.main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        log_level="info",
    )
