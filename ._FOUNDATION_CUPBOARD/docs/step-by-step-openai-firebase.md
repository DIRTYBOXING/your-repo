# Step-by-Step: Wiring OpenAI ↔ Firebase — DFC Pipeline

> **Purpose:** Connect the gaps between existing services. Everything below is already built — this guide wires them together.

---

## Pipeline Overview

```
Flutter App → Firestore → Firebase Functions → Atlas Backend (OpenAI/Claude/Gemini)
                                             → Poster Worker (AI captions + Sharp compositing)
                                             → Genkit (Gemini reasoning flows)
                                             ↓
                                         Firestore ← results written back
```

---

## Step 1 — Set Environment Variables

All services read from env vars. Create a `.env` in the project root (gitignored) with these **required** keys:

```env
# ─── OpenAI (Atlas Backend) ──────────────────────────────────
OPENAI_API_KEY=sk-...

# ─── Anthropic (Atlas + Genkit Samurai) ──────────────────────
ANTHROPIC_API_KEY=sk-ant-...

# ─── Google AI / Gemini (Genkit + Atlas PSYCHE/SCALES bots) ──
GOOGLE_GENAI_API_KEY=AIza...
# Alias used by some services:
GOOGLE_AI_KEY=AIza...

# ─── Perplexity (Atlas fallback chain) ───────────────────────
PERPLEXITY_API_KEY=pplx-...

# ─── Pinecone (vector memory for Atlas /chat) ────────────────
PINECONE_API_KEY=...
PINECONE_ENV=us-east-1
PINECONE_INDEX=dfc-fighter-memory

# ─── Firebase ────────────────────────────────────────────────
GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
FIREBASE_PROJECT_ID=datafightcentral
FIREBASE_STORAGE_BUCKET=datafightcentral.appspot.com

# ─── PostgreSQL (Radar/Blackbird geospatial) ─────────────────
DATABASE_URL=postgresql://dfc_admin:supersecret@localhost:5432/dfc

# ─── Poster Worker ──────────────────────────────────────────
ASSETS_BUCKET=datafightcentral.appspot.com
AI_ENDPOINT=http://localhost:8000          # ← CRITICAL: was placeholder

# ─── Outreach / Auth ────────────────────────────────────────
SENDGRID_API_KEY=SG...
TWILIO_SID=AC...
TWILIO_AUTH_TOKEN=...
JWT_SECRET=...
REFRESH_TOKEN_SECRET=...

# ─── Stripe ──────────────────────────────────────────────────
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## Step 2 — Fix the Poster Worker Placeholder (Critical Gap)

**Problem:** `poster-worker/src/aiOrchestrator.ts` points to `https://api.example.ai/generate` — a dead URL.

**Fix:** Point it at the real Atlas Backend.

### Local Development

```env
# In poster-worker .env or docker-compose environment:
AI_ENDPOINT=http://atlas-backend:8000
```

### Production (Cloud Run)

```bash
gcloud run services update poster-worker \
  --region australia-southeast1 \
  --set-env-vars "AI_ENDPOINT=https://atlas-backend-XXXX-ts.a.run.app"
```

### Code Change Required

In `poster-worker/src/aiOrchestrator.ts`, the caption endpoint calls `${AI_ENDPOINT}/caption`. Atlas Backend doesn't have a `/caption` route yet. **Two options:**

**Option A — Add `/caption` to Atlas Backend:**

```python
# atlas_backend/main.py — add this endpoint

class CaptionRequest(BaseModel):
    prompt: str

@app.post('/caption')
def caption(req: CaptionRequest):
    """Generate poster caption variants via multi-model AI."""
    if not ai_service:
        raise HTTPException(status_code=503, detail='AI service unavailable')
    try:
        result = ai_service.generate(
            prompt=f"Generate 3 short, punchy fight poster captions for: {req.prompt}. "
                   "Return JSON: {{\"variants\": [\"caption1\", \"caption2\", \"caption3\"]}}",
            preferred_model='gpt_5_nano',
        )
        import json
        parsed = json.loads(result.get('text', '{}'))
        return parsed
    except Exception as e:
        logger.error('Caption generation failed: %s', e)
        raise HTTPException(status_code=500, detail='Caption generation failed')
```

**Option B — Rewire poster-worker to use `/v1/generate`:**

```typescript
// poster-worker/src/aiOrchestrator.ts — update callCaptionModel
async function callCaptionModel(
  prompt: string,
): Promise<{ variants?: string[] } | null> {
  try {
    const res = await globalThis.fetch(`${AI_ENDPOINT}/v1/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        prompt: `Generate 3 short punchy fight poster captions for: ${prompt}. Return JSON array of 3 strings.`,
        preferred_model: "gpt_5_nano",
      }),
    });
    if (!res.ok) return null;
    const data = await res.json();
    // Parse the text response into variants
    const text = data.text ?? data.reply ?? "";
    const parsed = JSON.parse(text);
    return { variants: Array.isArray(parsed) ? parsed : [text] };
  } catch {
    return null;
  }
}
```

---

## Step 3 — Fix Poster Template URLs

**Problem:** `composePoster()` fetches templates from `https://templates.example.com/*.png` — another placeholder.

**Fix:** Upload templates to GCS and update the reference.

```bash
# Upload templates to Firebase Storage
gsutil cp assets/ppv/*.png gs://datafightcentral.appspot.com/templates/posters/

# Then in poster-worker config or code, set:
TEMPLATE_BASE_URL=https://storage.googleapis.com/datafightcentral.appspot.com/templates/posters
```

---

## Step 4 — Deploy Atlas Backend to Cloud Run

Atlas is the hub for all AI calls. It must be live for poster-worker, Genkit, and the Flutter app.

```bash
# From project root:
cd atlas_backend

# Build and push
gcloud builds submit --tag gcr.io/datafightcentral/atlas-backend

# Deploy
gcloud run deploy atlas-backend \
  --image gcr.io/datafightcentral/atlas-backend \
  --region australia-southeast1 \
  --platform managed \
  --allow-unauthenticated \
  --port 8000 \
  --max-instances 5 \
  --set-env-vars "OPENAI_API_KEY=sk-...,ANTHROPIC_API_KEY=sk-ant-...,GOOGLE_AI_KEY=AIza...,PERPLEXITY_API_KEY=pplx-..."
```

> **Better:** Use Cloud Run secrets instead of env vars:
>
> ```bash
> gcloud run deploy atlas-backend \
>   --set-secrets "OPENAI_API_KEY=OPENAI_API_KEY:latest,ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest"
> ```

After deploy, note the URL (e.g. `https://atlas-backend-abc123-ts.a.run.app`) and update poster-worker's `AI_ENDPOINT`.

---

## Step 5 — Deploy Genkit (AI Flows → Firebase Functions)

Genkit powers the health intelligence flows (`generateDailyInsight`, PSYCHE/SCALES/SHIELD/FUEL).

```bash
cd genkit

# Install deps
npm install

# Build TypeScript
npm run build

# Local dev (hot reload)
npm run dev

# Deploy to Firebase Functions
npm run deploy
# (runs: firebase deploy --only functions)
```

**Required secrets in Firebase:**

```bash
firebase functions:secrets:set GOOGLE_GENAI_API_KEY
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set ANTHROPIC_API_KEY
```

---

## Step 6 — Wire Flutter App → Atlas Backend

The Flutter app talks to Atlas through Firebase Functions (proxy) or directly.

### Option A — Direct (simpler, for dev)

```dart
// lib/shared/services/atlas_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AtlasService {
  static const _baseUrl = String.fromEnvironment(
    'ATLAS_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Send a chat message to Atlas AI coach
  Future<String> chat(String message, {String? userId}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': userId ?? 'anon',
        'message': message,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reply'] as String;
    }
    throw Exception('Atlas chat failed: ${response.statusCode}');
  }

  /// Multi-model generate (Claude/GPT/Gemini with fallback)
  Future<Map<String, dynamic>> generate(String prompt, {String? model}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/v1/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        if (model != null) 'preferred_model': model,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Atlas generate failed: ${response.statusCode}');
  }
}
```

Run with:

```bash
flutter run -d chrome --dart-define=ATLAS_URL=https://atlas-backend-abc123-ts.a.run.app
```

### Option B — Through Firebase Functions (production)

```javascript
// functions/atlas-proxy.js
const functions = require("firebase-functions");
const fetch = require("node-fetch");

const ATLAS_URL =
  process.env.ATLAS_URL || "https://atlas-backend-abc123-ts.a.run.app";

exports.atlasChat = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Sign in required");

  const response = await fetch(`${ATLAS_URL}/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      session_id: data.sessionId,
      user_id: context.auth.uid,
      message: data.message,
    }),
  });
  return response.json();
});
```

---

## Step 7 — Wire Content Pipeline (Auto-Feed → AI → Firestore)

The content pipeline ingestion flow:

```
RSS/API Sources → Firebase Functions (seedPipelineContent)
                      ↓
               content_pipeline collection (status: INTAKE)
                      ↓
               Firebase Functions (onWrite trigger)
                      ↓
               Atlas /v1/generate (AI scoring + caption)
                      ↓
               content_pipeline (status: RANKED)
                      ↓
               Poster Worker (poster generation via Pub/Sub)
                      ↓
               posts collection (status: PUBLISHED)
```

**Trigger the pipeline:**

```bash
# Seed a single item
curl -X POST https://us-central1-datafightcentral.cloudfunctions.net/seedPipelineContent \
  -H "Content-Type: application/json" \
  -d '{
    "title": "UFC 310: Pantoja vs Asakura",
    "source": "ufc.com",
    "sourceUrl": "https://ufc.com/event/ufc-310",
    "mediaType": "event",
    "sport": "MMA"
  }'
```

---

## Step 8 — Local Development (docker-compose)

Spin up the full stack locally:

```bash
# Start PostgreSQL + Atlas + Vault
docker-compose up -d

# Start Firebase emulators (separate terminal)
pwsh -ExecutionPolicy Bypass -File scripts/start_emulators.ps1 -KillExisting

# Start Flutter
flutter run -d chrome --dart-define=ATLAS_URL=http://localhost:8000
```

**docker-compose.yml services:**
| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL + PostGIS | 5432 | Radar/Blackbird geospatial data |
| Atlas Backend | 8000 | AI inference hub |
| Vault | 8200 | Secret management |
| Firebase Emulators | 4000 (UI), 8080 (Firestore), 5001 (Functions) | Local Firebase |

---

## Step 9 — Production Deploy (Cloud Build)

The full pipeline deploys via `cloudbuild.yaml`:

```bash
# Trigger from CLI:
gcloud builds submit --config cloudbuild.yaml

# Or push to master (if Cloud Build trigger is set):
git push origin master
```

**Build order:**

1. Docker build → push 6 service images to GCR
2. Cloud Run deploy (poster-worker → promotion-worker → entitlements → genkit → atlas → outreach)
3. Firebase Functions deploy
4. Region: `australia-southeast1`

---

## Step 10 — Verify the Full Chain

Run these health checks after deployment:

```bash
# 1. Atlas Backend
curl https://atlas-backend-XXXX-ts.a.run.app/health
# Expected: {"status":"ok","time":...}

# 2. Atlas AI models available
curl https://atlas-backend-XXXX-ts.a.run.app/v1/models
# Expected: list of available models

# 3. Test chat
curl -X POST https://atlas-backend-XXXX-ts.a.run.app/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test","message":"How should I prepare for a fight in 8 weeks?"}'

# 4. Firebase Functions health
curl https://us-central1-datafightcentral.cloudfunctions.net/healthCheck

# 5. Poster worker (trigger via Pub/Sub or content_pipeline write)
# Check Cloud Run logs:
gcloud run services logs read poster-worker --region australia-southeast1 --limit 20
```

---

## Remaining Gaps Checklist

| Gap                                        | Status          | Action                                                                                      |
| ------------------------------------------ | --------------- | ------------------------------------------------------------------------------------------- |
| `AI_ENDPOINT` placeholder in poster-worker | ⚠️ Blocking     | Point to Atlas Cloud Run URL                                                                |
| Template URLs in poster-worker             | ⚠️ Blocking     | Upload to GCS, update `TEMPLATE_BASE_URL`                                                   |
| `/caption` endpoint on Atlas               | ⚠️ Missing      | Add endpoint (Step 2, Option A) or rewire poster-worker                                     |
| Social platform tokens                     | ⚠️ Not set      | Add Instagram/Twitter/Facebook tokens to Cloud Run secrets                                  |
| Genkit deploy to Functions                 | ⚠️ Not deployed | Run `cd genkit && npm run deploy`                                                           |
| Atlas → Firestore write-back               | ⚠️ Optional     | Atlas has `USE_FIREBASE` flag but only writes `health_metrics` — extend for content scoring |
| Pinecone index creation                    | ⚠️ One-time     | Create `dfc-fighter-memory` index in Pinecone dashboard (1536 dims, cosine)                 |
| Flutter `AtlasService`                     | ⚠️ Not built    | Create `lib/shared/services/atlas_service.dart` (Step 6)                                    |

---

## Model Fallback Chain (Atlas)

```
Request → gpt_5_nano (GPT-4o-mini)
            ↓ fail
         claude_sonnet_4_6 (Anthropic)
            ↓ fail
         gemini_3_pro (Google)
            ↓ fail
         gpt_5_2 (GPT-4o)
            ↓ fail
         perplexity (Sonar)
            ↓ fail
         AiModelError raised
```

All models are **real API calls** — no stubs. Set the API keys and they activate automatically.
