from typing import Any, Dict
import logging
from fastapi import FastAPI

from libs.clients.firestore_client import get_db

logger = logging.getLogger(__name__)
app = FastAPI(title="DFC Intelligence Service", version="0.1.0")

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
            # TODO: Wire Gemini to generate dynamic neural signatures and hype indexes based on actual fight history
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