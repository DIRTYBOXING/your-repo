# ── Stage 1: Build with full torch (CPU-only for smaller image) ────────
FROM python:3.12-slim AS base

WORKDIR /app

# System deps for Pillow/torch
RUN apt-get update && \
    apt-get install -y --no-install-recommends libgl1 libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cpu

COPY u2net.py app.py ./
COPY static/ ./static/

# Model weights — mount or bake in at build time
# To bake in: COPY u2net.pth .
# To mount at runtime: docker run -v /path/to/u2net.pth:/app/u2net.pth ...

EXPOSE 8080

# Cloud Run sends SIGTERM; uvicorn handles graceful shutdown
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
