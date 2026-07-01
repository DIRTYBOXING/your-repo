# Use NVIDIA CUDA Runtime as the base image for GPU acceleration
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

WORKDIR /app

# Install Python 3.11, pip, and hardware-accelerated FFmpeg
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install fastapi uvicorn pydantic httpx google-cloud-firestore google-cloud-storage

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]