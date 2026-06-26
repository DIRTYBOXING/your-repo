FROM python:3.11-slim

WORKDIR /app

COPY ../../pyproject.toml ./
RUN pip install fastapi uvicorn google-cloud-firestore pydantic httpx firebase-admin google-generativeai

COPY ../../libs ./libs
COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]