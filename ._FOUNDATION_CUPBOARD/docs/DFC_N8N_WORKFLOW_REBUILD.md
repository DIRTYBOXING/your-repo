# DFC n8n Workflow Rebuild

## Objective

Replace the current one-workflow social poster with two DFC-compatible workflows:

1. `DFC Content Brain`
2. `DFC Publisher`

This split keeps generation separate from distribution and matches the Firebase contract already used by the app.

## Why The Current Draft Does Not Fit

The current draft rewrites a description, posts directly to Facebook, sends an email, and returns a publishing receipt. The DFC app expects a structured content pack first, not an already-published social artifact.

The synchronous n8n response for the brain workflow must match what `functions/content/content_brain.js` expects:

```json
{
  "posts": [
    {
      "platform": "facebook",
      "caption": "...",
      "postType": "text",
      "mediaUrl": "https://...",
      "mediaUrls": ["https://...", "https://..."],
      "thumbnailUrl": "https://...",
      "best_time_to_post": "7:30 PM"
    }
  ],
  "headline": "...",
  "summary": "...",
  "viralScore": 8,
  "toneSummary": "...",
  "suggestedMedia": "...",
  "suggestedMediaAssets": ["https://...", "https://..."],
  "mediaPlan": {
    "posterUrl": "https://...",
    "primaryPreviewAssetUrl": "https://...",
    "primaryPublishableAssetUrl": "https://...",
    "thumbnailUrl": "https://...",
    "assetUrls": ["https://...", "https://..."],
    "assets": [
      { "url": "https://...", "role": "poster", "type": "svg", "order": 1 }
    ]
  },
  "pipeline": {
    "engine": "n8n",
    "model": "gemini-2.0-flash-exp"
  }
}
```

## Workflow 1: DFC Content Brain

### Minimum Node Layout

1. `Webhook Brain Request`
2. `Normalize Request`
3. `Build Generation Prompt`
4. `Generate Structured Content`
5. `Parse Structured Output`
6. `Respond Brain Output`

### Node Field Mapping

#### 1. Webhook Brain Request

Input fields expected from Firebase:

- `webInput`
- `platform`
- `postType`
- `brandTone`
- `audienceType`
- `niche`
- `objective`
- `eventData`
- `mediaPlan`
- `requestId`
- `callbackUrl`

#### 2. Normalize Request

Normalize into:

- `webInput`
- `platform`
- `postType`
- `brandTone`
- `audienceType`
- `niche`
- `objective`
- `requestId`
- `callbackUrl`
- `eventData`
- `eventTitle`
- `posterUrl`
- `promoterName`
- `mediaPlan`
- `assetUrls`

#### 3. Build Generation Prompt

Create:

- `generationPrompt`
- JSON schema hint for `posts`, `headline`, `summary`, `viralScore`, `toneSummary`, `suggestedMedia`, `suggestedMediaAssets`, `mediaPlan`, `pipeline`

#### 4. Generate Structured Content

Use Gemini or another model, but require JSON-only output.

#### 5. Parse Structured Output

Guarantee the response body includes:

- `posts[]`
- `headline`
- `summary`
- `viralScore`
- `toneSummary`
- `suggestedMedia`
- `suggestedMediaAssets`
- `mediaPlan`
- `pipeline`

#### 6. Respond Brain Output

Return the structured JSON directly. Do not publish to Facebook here. Do not send email here.

SVG note:
If the request only supplies SVG or source-art URLs, keep them in `mediaPlan.assetUrls` and `suggestedMediaAssets`, but do not pretend they are directly publishable raster assets. Leave `mediaPlan.primaryPublishableAssetUrl` empty until a renderable image or video exists.

## Workflow 2: DFC Publisher

### Minimum Node Layout

1. `Webhook Publish Request`
2. `Normalize Publish Request`
3. `Post to Platform`
4. `Send Operator Email`
5. `Format Publish Result`
6. `Respond Publish Result`

### Node Field Mapping

#### 1. Webhook Publish Request

Input fields:

- `requestId`
- `contentDocId`
- `platform`
- `headline`
- `caption`
- `postType`
- `mediaUrl`
- `linkUrl`
- `operatorEmail`
- `callbackUrl`

#### 2. Normalize Publish Request

Normalize into:

- `requestId`
- `contentDocId`
- `platform`
- `caption`
- `headline`
- `mediaUrl`
- `linkUrl`
- `operatorEmail`
- `callbackUrl`

#### 3. Post to Platform

For the minimal publisher flow in this repo, use Facebook as the first branch.

#### 4. Send Operator Email

Send a simple notification through SendGrid after the publish attempt.

#### 5. Format Publish Result

Return:

- `success`
- `requestId`
- `contentDocId`
- `platform`
- `postId`
- `emailMessageId`

#### 6. Respond Publish Result

Respond with the publishing receipt. This workflow is where platform-side actions live.

## What Moves Out Of The Old Workflow

- `Post to Facebook Page` moves to `DFC Publisher`.
- `Send Email via SendGrid` moves to `DFC Publisher`.
- Merge logic belongs to `DFC Publisher`, not `DFC Content Brain`.

## Repo Templates

Import these repo-hosted starter workflows into n8n:

- `n8n/flows/dfc_content_brain_minimal.json`
- `n8n/flows/dfc_publisher_minimal.json`

## Six-Step Go-Live Checklist

1. Bring up the repo-hosted n8n stack in queue mode: `docker compose up -d db redis n8n n8n-worker`.
2. Import `n8n/flows/dfc_content_brain_minimal.json` and `n8n/flows/dfc_publisher_minimal.json` into your DFC n8n instance.
3. Activate the `DFC Content Brain Minimal` workflow and confirm the production webhook path is `/webhook/dfc-content-brain`.
4. Set `functions/.env` so `N8N_CONTENT_BRAIN_URL` points to that exact live webhook URL. Leave `N8N_API_KEY` empty unless the webhook is protected.
5. Run the VS Code task `DFC Brain: Smoke n8n Content Brain`. It must return a valid DFC content pack, not just any HTTP 200.
6. After the smoke passes, run the content-brain lane from the app or Firebase callable path and confirm the generated payload lands in the expected Firestore workflow state.
