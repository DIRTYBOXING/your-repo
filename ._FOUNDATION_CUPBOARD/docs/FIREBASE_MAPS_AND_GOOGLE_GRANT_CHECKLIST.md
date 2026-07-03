# Firebase, Maps, and Google Grant Checklist

This is the operational checklist for Data Fight Central's current stack. It separates what the repo actually uses from what is optional, and it keeps the hybrid nonprofit plus revenue model compliant.

## What DFC Uses Now

### Required for the current app

- Firebase Authentication
- Cloud Firestore
- Cloud Functions
- Cloud Storage
- Firebase Hosting
- Firebase Cloud Messaging
- Firebase Analytics
- Firebase Crashlytics
- Firebase Performance Monitoring
- Firebase Remote Config
- Firebase App Check
- Google Maps JavaScript API for web
- Maps SDK for Android if Android maps are shipped
- Maps SDK for iOS if iOS maps are shipped
- Cloud Scheduler and Pub/Sub because functions in this repo use scheduled and message-driven workflows

### Optional or not required right now

- Realtime Database
- Places API
- Routes API
- Geocoding API
- Static Maps API
- Street View Static API
- 3D Tiles / Aerial View / Immersive Maps
- Vertex AI for the core app path

If a feature is not live, do not enable its Google API just because it might be useful later.

## Firebase Console Checklist

### 1. Billing plan

- Put the Firebase project on Blaze.
- Treat Blaze as required for this repo because it uses Cloud Functions, Scheduler, Pub/Sub, Hosting, Storage, and Maps-backed production traffic.
- Add monthly budget alerts in Google Cloud Billing before broad rollout.

### 2. Project settings

- In Firebase Console, confirm the registered web, Android, iOS, macOS, and Windows app IDs match the values in [lib/firebase_options.dart](lib/firebase_options.dart).
- Keep the project ID as `datafightcentral` unless you intentionally migrate everything.

### 3. Authentication

- Enable Email/Password.
- Enable Google sign-in if you want Google auth in production.
- Keep Anonymous auth enabled only if you want the current demo mode behavior.
- Add authorized domains for production web hosts.

### 4. Firestore

- Confirm Firestore is created and writable.
- Deploy [firestore.rules](firestore.rules) and [firestore.indexes.json](firestore.indexes.json).
- Monitor read-heavy screens because Firestore will become one of the first scaling costs.

### 5. Storage

- Confirm the default bucket exists and matches [lib/firebase_options.dart](lib/firebase_options.dart).
- Deploy [storage.rules](storage.rules).
- Watch bandwidth and media-heavy upload/download flows.

### 6. Hosting

- Confirm the Hosting sites in [firebase.json](firebase.json) are real and actively linked.
- Make sure the correct site is used for production deploys.
- Keep no-cache headers for the Flutter web shell as currently configured.

### 7. Cloud Functions

- Enable Cloud Functions, Cloud Build, Artifact Registry, Cloud Scheduler, and Pub/Sub in the linked Google Cloud project.
- Confirm the production region aligns with the app's configured functions region in [lib/main.dart](lib/main.dart).
- Add secrets only for features you actually run in production.

### 8. Cloud Messaging

- If you want web push, finish the FCM web setup and VAPID key path.
- If you are not launching web push yet, defer that setup instead of half-configuring it.

### 9. App Check

- Register the web app in Firebase App Check.
- For localhost, start the app, collect the generated debug token from the browser console, and safelist it in Firebase App Check.
- For production web, create a reCAPTCHA v3 site key and supply `FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY`.
- Optionally set `FIREBASE_APPCHECK_DEBUG_TOKEN` in `.env` for stable local runs.
- The web App Check bootstrap is already wired in [lib/main.dart](lib/main.dart).

### 9a. Exact App Check console order

Use this exact sequence:

1. Open Firebase Console for `datafightcentral`.
2. Go to Build -> App Check.
3. If the web app is not listed, register the web app that matches [lib/firebase_options.dart](lib/firebase_options.dart).
4. In App Check for the web app, choose `reCAPTCHA v3` as the production provider.
5. Create or paste the reCAPTCHA site key, then store that value in `.env` as `FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY`.
6. Run the web app locally through the normal VS Code task path so [scripts/run_with_env.ps1](scripts/run_with_env.ps1) passes the define into Flutter.
7. Open browser devtools and look for the App Check localhost debug token message emitted from [lib/main.dart](lib/main.dart).
8. Go back to Firebase Console -> App Check -> Manage debug tokens.
9. Add the localhost browser debug token.
10. Re-run the local web app and confirm the map lane no longer fails due to missing App Check trust.

### 10. Monitoring and budgets

- Turn on billing budgets and alerts.
- Review Firebase usage dashboards weekly during launch.
- Set alert thresholds before public campaigns.

## Google Maps and Billing Checklist

### 1. Billing and APIs

- Attach a valid Google Cloud billing account to the same project.
- Enable only these APIs first:
- Maps JavaScript API
- Maps SDK for Android
- Maps SDK for iOS

Do not enable Places, Routes, Geocoding, Static Maps, or advanced 3D products until the app actually uses them.

### 2. API keys

- Create separate keys for web, Android, and iOS.
- Restrict the web key by HTTP referrer.
- Restrict the Android key by package name plus SHA certificate.
- Restrict the iOS key by bundle ID.
- Restrict each key to only the API it needs.

### 3. Immediate security cleanup

- Rotate the current web Maps key because a hardcoded web key exists in [web/index.html](web/index.html).
- Replace it with a production key that is tightly referrer-restricted.
- Keep localhost referrers only on a dev key, not your main production web key.
- The repo no longer needs a hardcoded source-controlled Maps key. The web loader now expects `GOOGLE_MAPS_API_KEY_WEB` or `GOOGLE_MAPS_API_KEY` from `.env` through [scripts/run_with_env.ps1](scripts/run_with_env.ps1).

### 3a. Exact Maps key rotation order

Use this exact sequence:

1. Open Google Cloud Console for the project linked to Firebase `datafightcentral`.
2. Go to APIs & Services -> Credentials.
3. Find the currently exposed browser key and create a replacement key before deleting or disabling the old one.
4. Rename the new key clearly, for example `dfc-web-maps-prod`.
5. Set Application restrictions to `HTTP referrers`.
6. Add only the production hosts you actually use:
   - `https://www.datafightcentral.com/*`
   - `https://datafightcentral.com/*`
   - `https://datafightcentral.web.app/*`
   - `https://datafightcentral.firebaseapp.com/*`
7. Create a separate dev key for localhost access, and keep localhost off the production key.
8. Set API restrictions to `Restrict key` and allow only `Maps JavaScript API`.
9. Put the production value in `.env` as `GOOGLE_MAPS_API_KEY_WEB_PROD`.
10. Put the localhost value in `.env` as `GOOGLE_MAPS_API_KEY_WEB_DEV`.
11. Sync the replacement values into local `.env` and GitHub Actions secrets with [scripts/sync_google_maps_web_secrets.ps1](scripts/sync_google_maps_web_secrets.ps1).
12. Run the web app or web build using the existing VS Code tasks so the wrapper injects the correct key temporarily into [web/index.html](web/index.html): local `run` uses the dev key, CI and hosted web `build` use the prod key.
13. After the new key works in both local and deployed lanes, disable or delete the previously exposed key.

### 3b. Secret sync command

Use this after creating the replacement keys in Google Cloud:

```powershell
$prodMapsWeb = 'paste-new-prod-key-here' # pragma: allowlist secret
$devMapsWeb = 'paste-new-localhost-key-here' # pragma: allowlist secret
pwsh -ExecutionPolicy Bypass -File .\scripts\sync_google_maps_web_secrets.ps1 -GoogleMapsApiKeyWebProd $prodMapsWeb -GoogleMapsApiKeyWebDev $devMapsWeb
```

The helper updates local `.env` and the GitHub repository secrets `GOOGLE_MAPS_API_KEY_WEB_PROD` and `GOOGLE_MAPS_API_KEY_WEB_DEV`. The production deploy workflow now materializes `.env` in CI and builds through [scripts/run_with_env.ps1](scripts/run_with_env.ps1) so the Maps placeholder in [web/index.html](web/index.html) is resolved from the rotated secret instead of a source-controlled literal.

### 4. Suggested web referrer list

Production key:

- `https://www.datafightcentral.com/*`
- `https://datafightcentral.com/*`
- `https://datafightcentral.web.app/*`
- `https://datafightcentral.firebaseapp.com/*`

Local dev key:

- `http://127.0.0.1/*`
- `http://localhost/*`

If your local browser keeps using fixed ports, add the exact localhost ports as well.

Only include hosts you actually use.

### 5. Maps pricing reality

- Your current map usage is mostly Dynamic Maps style loading.
- Google Maps pricing is usage-based, and Dynamic Maps charges after the monthly free cap.
- Google Maps Platform public programs for nonprofits can add credits if your nonprofit is verified.
- Watch page loads, not just API call counts.

## Hybrid Nonprofit Plus Revenue Model

### What Google Ad Grants can support

- Crisis support pages
- Resource directories
- Donation pages
- Volunteer recruitment pages
- Mentor or safe-gym nonprofit onboarding pages
- Awareness and education campaigns

### What Google Ad Grants should not support

- Paid app subscriptions
- PPV sales
- Promoter SaaS sales
- Sponsor acquisition funnels
- Commercial event ticket sales unless they are structured as a clearly eligible nonprofit fundraising flow

### Recommended structure for DFC

- Keep a nonprofit lane and a commercial lane.
- Use the nonprofit lane for mission, safety, crisis, education, and donation activity.
- Use the commercial lane for paid growth, subscriptions, PPV, sponsor packages, and promoter tools.
- Keep landing pages separate even if the umbrella brand stays connected.

### Clean domain approach

- Nonprofit lane: `foundation.datafightcentral.org` or `nightchill.datafightcentral.org`
- Commercial lane: `app.datafightcentral.com` or the current commercial product domain

If you keep everything on one domain, use clearly separated paths and keep Ad Grants traffic away from commercial checkout flows.

### Conversion tracking split

- Nonprofit conversions: donations, volunteer signups, mentor applications, resource clicks, hotline clicks
- Commercial conversions: subscriptions, PPV purchases, sponsor leads, promoter upgrades

Do not mix these inside the same Google Ad Grants campaign structure.

## Google for Nonprofits and Grant Fit

### Australia-specific eligibility signals

- ACNC registration
- DGR status
- ATO income tax exemption
- Goodstack verification for Google for Nonprofits

If you apply through an Australian entity, keep the application Australian all the way through. Do not mix Australian charity language with US 501(c)(3) language.

### Program fit for DFC

- Google for Nonprofits: yes, if the nonprofit entity is properly registered and verified
- Google Ad Grants: yes, for the nonprofit lane only
- Google Maps nonprofit credits: yes, after Google for Nonprofits verification, with additional Maps credits starting around $250 per month
- Standard paid Google Ads: yes, for the commercial lane

## Immediate Next Actions

### This week

- Finalize the real filing entity and jurisdiction.
- Clean the grant application so it uses one jurisdiction only.
- Move the Firebase project to Blaze if it is not already there.
- Rotate and restrict the current web Maps key.
- Finish App Check debug token registration for localhost.
- Create a nonprofit-only landing structure before launching Ad Grants.

## Poverty-proof priority order

If money and energy are both tight, do the work in this order and stop there until each item is done:

1. Keep the app launch path stable.
   This means: do not break the normal web demo and real-auth tasks.
2. Lock down the Google Maps web key.
   This prevents avoidable cost leakage and key abuse.
3. Finish Firebase App Check for web.
   This is the minimum trust layer for maps and future abuse reduction.
4. Keep only the APIs you already need.
   Do not enable Places, Routes, Geocoding, or extra Google products yet.
5. Keep Blaze budgets and alerts on.
   Cheap surprises still hurt when the budget is tight.
6. Separate nonprofit traffic from commercial traffic before grants.
   This protects the grant lane from being contaminated by PPV or SaaS flows.
7. Delay premium extras.
   Do not spend time or money on advanced Maps products, fancy location APIs, or cosmetic Google features before the above six are done.

### Before any grant submission

- Make sure the public site has mission, programs, privacy policy, terms, and contact pages.
- Make sure nonprofit and commercial user journeys are clearly separated.
- Make sure donation pages do not look like disguised commercial product pages.
- Make sure grant ads never land on subscription, PPV, or promoter checkout pages.
