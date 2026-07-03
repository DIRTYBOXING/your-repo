FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONPATH=/app

COPY atlas_backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY libs ./libs
COPY atlas_backend ./atlas_backend

CMD ["uvicorn", "atlas_backend.main:app", "--host", "0.0.0.0", "--port", "8080"]
