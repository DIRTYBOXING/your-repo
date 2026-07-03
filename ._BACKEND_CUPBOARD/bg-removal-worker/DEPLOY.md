# DFC Background Removal Worker — Cloud Run deploy

# ================================================

#

# CPU deploy (cheaper, ~2-5s per image):

# gcloud run deploy dfc-bg-removal \

# --source . \

# --region australia-southeast1 \

# --memory 4Gi \

# --cpu 2 \

# --timeout 120 \

# --max-instances 5 \

# --allow-unauthenticated

#

# GPU deploy (fast, ~0.3s per image):

# gcloud run deploy dfc-bg-removal \

# --source . \

# --dockerfile Dockerfile.gpu \

# --region australia-southeast1 \

# --memory 8Gi \

# --cpu 4 \

# --gpu 1 \

# --gpu-type nvidia-l4 \

# --timeout 120 \

# --max-instances 3 \

# --allow-unauthenticated

#

# Set API key (optional):

# gcloud run services update dfc-bg-removal \

# --set-env-vars BG_REMOVAL_API_KEY=your-secret-key

#

# Mount model weights from GCS:

# Upload u2net.pth to gs://dfc-models/u2net.pth

# gcloud run services update dfc-bg-removal \

# --set-env-vars MODEL_PATH=/models/u2net.pth \

# --add-volume name=models,type=cloud-storage,bucket=dfc-models \

# --add-volume-mount volume=models,mount-path=/models
