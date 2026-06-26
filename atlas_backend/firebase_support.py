import json
import logging
import os
import time
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import storage as gcs_storage


logger = logging.getLogger(__name__)


def _firebase_options() -> dict[str, str]:
    bucket_name = get_storage_bucket_name()
    return {'storageBucket': bucket_name} if bucket_name else {}


def ensure_firebase_app():
    if firebase_admin._apps:
        return firebase_admin.get_app()

    cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    options = _firebase_options()
    try:
        if cred_path and os.path.exists(cred_path):
            return firebase_admin.initialize_app(credentials.Certificate(cred_path), options=options or None)
        if os.getenv('FIREBASE_CONFIG') or os.getenv('K_SERVICE'):
            return firebase_admin.initialize_app(options=options or None)
    except Exception as exc:
        logger.warning('Firebase app unavailable: %s', exc)
    return None


def get_firestore_client():
    app = ensure_firebase_app()
    if app is None:
        return None
    try:
        return firestore.client(app=app)
    except Exception as exc:
        logger.warning('Firestore client unavailable: %s', exc)
        return None


def firestore_timestamp_value() -> Any:
    if ensure_firebase_app() is not None:
        return getattr(firestore, 'SERVER_TIMESTAMP', int(time.time()))
    return int(time.time())


def get_storage_bucket_name() -> str | None:
    return os.getenv('EVIDENCE_BUCKET') or os.getenv('FIREBASE_STORAGE_BUCKET')


def upload_json_blob(object_path: str, payload: dict[str, Any], bucket_name: str | None = None) -> dict[str, str] | None:
    bucket_name = bucket_name or get_storage_bucket_name()
    if not bucket_name:
        return None

    if ensure_firebase_app() is None:
        return None

    try:
        client = gcs_storage.Client()
        blob = client.bucket(bucket_name).blob(object_path)
        blob.upload_from_string(json.dumps(payload, default=str), content_type='application/json')
        return {'storage_bucket': bucket_name, 'storage_object_path': object_path}
    except Exception as exc:
        logger.warning('GCS JSON upload failed for %s: %s', object_path, exc)
        return None
