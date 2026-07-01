# Automated Dependency & Extension Updates

To keep your Dart/Flutter dependencies and VS Code extensions up to date, run:

```powershell
./scripts/update_dependencies.ps1
```

This script will:

- Upgrade all Dart/Flutter packages (`flutter pub upgrade`)
- Show outdated packages (`flutter pub outdated`)
- Force-update all installed VS Code extensions

Run this script regularly, or add it to your CI/CD pipeline for automated updates.

# Developer Setup

This project uses Google OAuth (Application Default Credentials) for server-side AI calls. API keys are not accepted by the Generative Language API v1/v1beta.

## Prerequisites

- Enable "Generative Language API" in the GCP project.
- Install the Google Cloud SDK (`gcloud`).

## Authenticate Locally (Choose One)

### Option A: Service Account JSON

1. Create a service account with access to Generative Language API.
2. Download the JSON key file.
3. Point your shell to the credentials:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
```

### Option B: Application Default Credentials via gcloud

```powershell
gcloud auth application-default login
```

## Run Genkit Locally

```powershell
Set-Location "c:\Users\User\dev\Data Fight Central\genkit"
node hello.mjs
```

If authentication is correct, the script prints a Gemini response.

## Firebase Functions (Local Emulator)

```powershell
Set-Location "c:\Users\User\dev\Data Fight Central\functions"
firebase emulators:start --only functions
```

Cloud Functions use the default service account via ADC. No Gemini API key secret is required.

## Production Deploy

- Ensure the default Functions service account has access to Generative Language API.
- Deploy as usual; Functions authenticate via OAuth.

## Google Sign-In (Client)

- Use OAuth client IDs (Web, Android, iOS).
- Confirm authorized domains and redirect URIs in Firebase Console.

## Notes

- `.env` can retain `GOOGLE_GENAI_API_KEY` for legacy scripts, but it is not used for v1/v1beta.
- Do not include secrets in the Flutter app under `lib/`.

## Event AI Card Producer (Nano Banna)

The promoter Event Manager now supports AI card packaging and optional image generation via Nano Banna.

- If no Nano Banna endpoint is provided, the app still generates style/hype/prompt metadata.
- To enable image output, run Flutter with compile-time defines:

```powershell
flutter run --dart-define=NANO_BANNA_ENDPOINT="https://your-nano-banna-endpoint" --dart-define=NANO_BANNA_API_KEY="your_api_key"
```

Expected response JSON can include either:

- `{"imageUrl": "https://..."}`
- `{"url": "https://..."}`
- `{"data": [{"url": "https://..."}]}`
