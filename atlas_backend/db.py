import logging
import os
from typing import Optional

import asyncpg

logger = logging.getLogger(__name__)

DEFAULT_CONTROLROOM_DATABASE_URL = 'postgresql://localhost:5432/controlroom'

_pool: Optional[asyncpg.Pool] = None


def get_controlroom_database_url() -> str:
    return os.getenv('CONTROLROOM_DATABASE_URL') or os.getenv('DATABASE_URL') or DEFAULT_CONTROLROOM_DATABASE_URL


async def get_db_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(get_controlroom_database_url(), min_size=1, max_size=5)
        logger.info('Control room DB pool initialized')
    return _pool


async def close_db_pool():
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None
        logger.info('Control room DB pool closed')
