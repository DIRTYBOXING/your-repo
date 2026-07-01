import os a complete checklist of jobs and commands i gave you its a check list for jobs completed 
import subprocess
import httpx
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from typing import List
from google.cloud import storage

app = FastAPI()
storage_client = storage.Client()

class RenderRequest(BaseModel):
    eventId: str
    theme: str
    imageUrls: List[str]

def process_octane_video(event_id: str, theme: str, image_urls: List[str]):
    work_dir = f"/tmp/{event_id}"
    os.makedirs(work_dir, exist_ok=True)
    
    try:
        # 1. Download the raw images from Firebase Storage
        for i, url in enumerate(image_urls):
            resp = httpx.get(url)
            with open(f"{work_dir}/img_{i:03d}.jpg", "wb") as f:
                f.write(resp.content)
                
        # 2. Run FFmpeg to stitch images into a cinematic video
        output_file = f"{work_dir}/output.mp4"
        ffmpeg_cmd = [
            "ffmpeg", "-y", 
            "-hwaccel", "cuda", # Force NVIDIA Hardware Acceleration
            "-framerate", "1/3", 
            "-i", f"{work_dir}/img_%03d.jpg",
            "-c:v", "h264_nvenc", # Use NVIDIA's ultra-fast hardware encoder
            "-preset", "p4",      # Balance of speed and quality for NVENC
            "-r", "30", 
            "-pix_fmt", "yuv420p", 
            output_file
        ]
        subprocess.run(ffmpeg_cmd, check=True)
        
        # 3. Upload the final MP4 back to Google Cloud Storage
        bucket = storage_client.bucket("datafightcentral.appspot.com")
        blob = bucket.blob(f"octane_final/{event_id}_promo.mp4")
        blob.upload_from_filename(output_file, content_type="video/mp4")
        
        print(f"✅ Octane Engine: Rendered and uploaded {event_id}_promo.mp4")
        
    except Exception as e:
        print(f"❌ Octane Engine Error: {e}")
        
    finally:
        # 4. Clean up the container's temporary storage
        for f in os.listdir(work_dir):
            os.remove(os.path.join(work_dir, f))
        os.rmdir(work_dir)

@app.post("/render-octane")
async def render_promo(req: RenderRequest, background_tasks: BackgroundTasks):
    # We pass this off to a background task so the Flutter UI gets an instant 200 OK
    background_tasks.add_task(process_octane_video, req.eventId, req.theme, req.imageUrls)
    return {
        "status": "processing",
        "message": "Render job queued. DFC Octane is building your promo."
    }