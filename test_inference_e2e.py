import requests
import json
import time

API_URL = "http://localhost:8080/ingest/clip"

payload = {
    "clip_id": f"clip_test_{int(time.time())}",
    "video_url": "https://storage.googleapis.com/dfc-clips/sample_hook_ko.mp4",
    "fighter_id": "fighter_alpha_001",
    "event_id": "event_omega_99",
    "promoter_id": "promoter_x"
}

print(f"🔥 Firing E2E Test Payload to DFC Inference Engine...")
print(f"📦 Target: {API_URL}")
print(f"📄 Payload: {json.dumps(payload, indent=2)}\n")

try:
    response = requests.post(API_URL, json=payload)
    
    print(f"📡 Status Code: {response.status_code}")
    if response.status_code == 200:
        print("✅ SUCCESS! AI Engine Processed the Clip.")
        print("🧠 Neural Output:")
        print(json.dumps(response.json(), indent=2))
        print("\n👉 Next: Check your Firebase Console to verify the document was written to the 'clips' collection.")
    else:
        print(f"❌ FAILED. Response: {response.text}")
except Exception as e:
    print(f"🚨 CRITICAL ERROR: Is the server running? Details: {e}")