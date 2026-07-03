import os
from typing import Optional

import redis


_redis_client: Optional[redis.Redis] = None


def _redis_url() -> str | None:
    if os.getenv("REDIS_URL"):
        return os.getenv("REDIS_URL")

    host = os.getenv("REDIS_HOST")
    if not host:
        return None

    port = os.getenv("REDIS_PORT", "6379")
    database = os.getenv("REDIS_DB", "0")
    password = os.getenv("REDIS_PASSWORD")

    if password:
        return f"redis://:{password}@{host}:{port}/{database}"
    return f"redis://{host}:{port}/{database}"


def get_redis() -> Optional[redis.Redis]:
    global _redis_client

    if _redis_client is not None:
        return _redis_client

    redis_url = _redis_url()
    if not redis_url:
        return None

    _redis_client = redis.Redis.from_url(redis_url, decode_responses=True)
    return _redis_client
