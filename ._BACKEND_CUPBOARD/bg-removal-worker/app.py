"""
DFC Background Removal Service
===============================
GPU-ready FastAPI microservice powered by U²-Net.
Endpoints:
  POST /remove-background/       — single image → transparent PNG
  POST /remove-background/batch/  — up to 10 images → ZIP of PNGs
  GET  /health                    — service health + device info

Designed for Cloud Run with optional GPU (nvidia-l4).
Falls back to CPU when no GPU is available.

Security:
  - Content-type validation (image/* only)
  - 10 MB max upload per image
  - Configurable API key via BG_REMOVAL_API_KEY env var
  - CORS restricted to DFC domains
"""

import io
import os
import zipfile
import logging
from contextlib import asynccontextmanager
from typing import Optional

import numpy as np
import torch
from PIL import Image
from torchvision import transforms
from fastapi import FastAPI, File, UploadFile, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from u2net import U2NET

# ── Config ──────────────────────────────────────────────────────────────

MODEL_PATH = os.getenv("MODEL_PATH", "u2net.pth")
API_KEY = os.getenv("BG_REMOVAL_API_KEY", "")  # Empty = no auth required
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
MAX_BATCH_SIZE = 10
INPUT_SIZE = 320
PORT = int(os.getenv("PORT", "8080"))

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/bmp", "image/tiff"}

logger = logging.getLogger("dfc-bg-removal")
logging.basicConfig(level=logging.INFO)

# ── Model singleton ────────────────────────────────────────────────────

device: torch.device = torch.device("cpu")
model: Optional[U2NET] = None

transform_pipeline = transforms.Compose([
    transforms.Resize((INPUT_SIZE, INPUT_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])


def load_model() -> None:
    global model, device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info("Loading U²-Net on %s", device)

    model = U2NET(3, 1)

    if os.path.exists(MODEL_PATH):
        state = torch.load(MODEL_PATH, map_location=device, weights_only=True)
        model.load_state_dict(state)
        logger.info("Loaded weights from %s", MODEL_PATH)
    else:
        logger.warning("No weights found at %s — model will produce random output", MODEL_PATH)

    model.to(device)
    model.eval()


# ── Core processing ────────────────────────────────────────────────────


def _preprocess(image_bytes: bytes) -> tuple[torch.Tensor, Image.Image]:
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    tensor = transform_pipeline(image).unsqueeze(0).to(device)
    return tensor, image


def _postprocess(mask_tensor: torch.Tensor, orig_size: tuple[int, int]) -> Image.Image:
    mask = mask_tensor.squeeze().cpu().numpy()
    # Normalize to 0-255
    mask_min, mask_max = mask.min(), mask.max()
    if mask_max - mask_min > 1e-6:
        mask = (mask - mask_min) / (mask_max - mask_min)
    mask = (mask * 255).astype(np.uint8)
    return Image.fromarray(mask).resize(orig_size, resample=Image.BILINEAR)


def remove_background(image_bytes: bytes) -> io.BytesIO:
    input_tensor, orig_image = _preprocess(image_bytes)

    with torch.no_grad():
        d0, *_ = model(input_tensor)  # type: ignore[misc]
        pred = d0[:, 0, :, :]

    mask_img = _postprocess(pred, orig_image.size)

    # Apply mask as alpha channel
    rgba = orig_image.convert("RGBA")
    rgba.putalpha(mask_img.convert("L"))

    buf = io.BytesIO()
    rgba.save(buf, format="PNG", optimize=True)
    buf.seek(0)
    return buf


# ── Auth dependency ─────────────────────────────────────────────────────


async def verify_api_key(x_api_key: Optional[str] = Header(None)):
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


async def validate_image(file: UploadFile) -> bytes:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type: {file.content_type}. Allowed: {', '.join(ALLOWED_TYPES)}",
        )

    data = await file.read()
    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail=f"File exceeds {MAX_FILE_SIZE // (1024*1024)} MB limit")
    return data


# ── App lifecycle ──────────────────────────────────────────────────────


@asynccontextmanager
async def lifespan(app: FastAPI):
    load_model()
    logger.info("DFC Background Removal Service ready on %s", device)
    yield
    logger.info("Shutting down")


app = FastAPI(
    title="DFC Background Removal",
    description="U²-Net powered background removal for fight posters, fighter cutouts & collectibles",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://datafightcentral.com",
        "https://*.datafightcentral.com",
        "http://localhost:*",
        "http://127.0.0.1:*",
    ],
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)

# Serve web UI
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.isdir(static_dir):
    app.mount("/ui", StaticFiles(directory=static_dir, html=True), name="ui")


# ── Endpoints ──────────────────────────────────────────────────────────


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "model_loaded": model is not None,
        "device": str(device),
        "cuda_available": torch.cuda.is_available(),
        "gpu_name": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
    }


@app.post("/remove-background/", dependencies=[Depends(verify_api_key)])
async def api_remove_background(file: UploadFile = File(...)):
    """Remove background from a single image. Returns transparent PNG."""
    image_bytes = await validate_image(file)
    try:
        output = remove_background(image_bytes)
    except Exception as e:
        logger.error("Background removal failed: %s", e)
        raise HTTPException(status_code=500, detail="Background removal failed")
    return StreamingResponse(output, media_type="image/png")


@app.post("/remove-background/batch/", dependencies=[Depends(verify_api_key)])
async def api_remove_background_batch(files: list[UploadFile] = File(...)):
    """Remove background from up to 10 images. Returns ZIP of transparent PNGs."""
    if len(files) > MAX_BATCH_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"Maximum {MAX_BATCH_SIZE} images per batch",
        )

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        for i, file in enumerate(files):
            image_bytes = await validate_image(file)
            try:
                output = remove_background(image_bytes)
                filename = file.filename or f"image_{i}.png"
                # Ensure .png extension
                if not filename.lower().endswith(".png"):
                    filename = filename.rsplit(".", 1)[0] + ".png"
                zf.writestr(filename, output.read())
            except Exception as e:
                logger.error("Batch item %d failed: %s", i, e)
                # Include error marker in zip
                zf.writestr(f"ERROR_{i}.txt", f"Failed: {file.filename}")

    zip_buffer.seek(0)
    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={"Content-Disposition": "attachment; filename=dfc_bg_removed.zip"},
    )


# ── Main ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app:app", host="0.0.0.0", port=PORT, reload=False)
