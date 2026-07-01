# CHUCKYA Device App — Android Companion

Consent-based telemetry sender for CHUCKYA Safety Radar.

## Purpose

This companion app runs on a phone and sends signed telemetry pings to the CHUCKYA Radar backend. It collects **explicit consent** before gathering any device data (IMEI, location).

## Files

- `res/layout/activity_consent.xml` — Consent UI (DFC neon theme)
- `src/TelemetryConsentActivity.kt` — Activity: consent, keystore signing, telemetry POST

## How it works

1. On first launch, generates an RSA-2048 keypair in Android Keystore
2. Registers the public key with the backend (`/v1/device/registerPublicKey`)
3. Shows consent screen with checkboxes for App Instance ID (required), IMEI (optional), Location (optional)
4. On "Agree and Send Demo Ping":
   - Stores consent record on backend (`/v1/device/consent`)
   - Builds telemetry payload
   - Signs payload with device private key (SHA256withRSA)
   - POSTs to `/v1/radar/event`
5. Backend verifies signature against registered public key

## Setup

1. Replace `CHUCKYA_BACKEND_URL` in `BuildConfig` (or hardcode the staging URL)
2. Add OkHttp dependency: `implementation 'com.squareup.okhttp3:okhttp:4.12.0'`
3. If collecting IMEI: add `READ_PHONE_STATE` permission and runtime request
4. If collecting location: add `ACCESS_FINE_LOCATION` permission and runtime request

## Security

- Private key **never leaves the device** (Android Keystore hardware-backed)
- Payloads are signed to prevent spoofing
- Backend rejects unregistered device keys
- Consent records are stored immutably in `ops-audit/consents/`

## Legal

All data collection requires explicit opt-in consent. See the consent screen text for the exact wording presented to users.
