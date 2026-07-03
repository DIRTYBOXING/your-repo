import time
import logging
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)

class LatencyLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()
        response = await call_next(request)
        process_time = time.perf_counter() - start_time
        logger.info(
            f"Request: {request.method} {request.url.path} | "
            f"Latency: {process_time:.4f}s | Status: {response.status_code}"
        )
        response.headers["X-Response-Time"] = f"{process_time:.4f}s"
        return response
