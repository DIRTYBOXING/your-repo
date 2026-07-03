import firebase_admin
from firebase_admin import credentials, firestore
import logging

logger = logging.getLogger(__name__)
_db = None

def get_db():
    global _db
    if _db is None:
        if not firebase_admin._apps:
            firebase_admin.initialize_app()
        _db = firestore.client()
        logger.info("Firestore client initialized for DFC Intelligence")
    return _db
