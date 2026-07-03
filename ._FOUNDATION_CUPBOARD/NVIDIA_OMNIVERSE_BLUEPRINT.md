# 🚀 DFC × NVIDIA OMNIVERSE & DEEPSTREAM BLUEPRINT

**STATUS:** ARCHITECTURE LOCKED
**TARGET:** Google Cloud Run (GPU Allocated: NVIDIA L4 / T4)

## 1. THE DEEPSTREAM ANALYTICS PIPELINE (Fight Breakdown)
Instead of relying purely on human judges or wearables, we route raw Mux video streams through **NVIDIA DeepStream SDK**.

**How it integrates:**
1. A fight goes live via Mux. 
2. Mux Webhook fires a signal to `octane-engine` containing the live RTMP stream URL.
3. A DeepStream Python container (using TensorRT) ingests the stream in real-time.
4. **Pose Estimation Models** track fighter joints, identifying thrown strikes, landed strikes, and takedowns.
5. DeepStream outputs JSON telemetry directly into the `fightStats` Firestore collection at 30 FPS.

## 2. OMNIVERSE 3D PROMO GENERATION (Octane v2.0)
Currently, Octane uses FFmpeg to stitch 2D images. The next evolution uses **OpenUSD** and **NVIDIA Omniverse APIs** to generate dynamic 3D environments.

**How it integrates:**
1. Promoter uploads 2 photos of fighters into the Creative Hub.
2. DFC backend calls the **Omniverse Cloud API**.
3. Omniverse loads a pre-built `.usd` 3D Arena Template (e.g., "Neon Underground").
4. The API projects the 2D fighter images onto 3D character cards inside the arena.
5. Omniverse renders a 10-second fly-through camera sequence using RTX Path Tracing.
6. The final 3D rendered MP4 is pushed to Firebase Storage and delivered to the Promoter Dashboard.

## 3. REQUIRED INFRASTRUCTURE SHIFTS
- **GCP Cloud Run with GPUs:** Your `octane-engine` must be deployed with `--gpu=1` and `--gpu-type=nvidia-l4`.
- **CUDA-X Libraries:** Built into your Dockerfile (already implemented).
- **NGC (NVIDIA GPU Cloud):** We will pull pre-trained action-recognition models directly from NGC to avoid training from scratch.

## 4. EXECUTION PLAN
- [x] Phase 1: Shift FFmpeg from CPU to `h264_nvenc` (Completed).
- [ ] Phase 2: Deploy DeepStream container to ingest VOD fight replays for strike-counting.
- [ ] Phase 3: Connect Omniverse API to the `triggerOctaneRender` Cloud Function for 3D promo generation.