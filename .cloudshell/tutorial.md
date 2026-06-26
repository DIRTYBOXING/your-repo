# Data Fight Central - Cloud Shell Tutorial

## Welcome! 🥊

This tutorial will help you get started with Data Fight Central in Google Cloud Shell.

---

## Step 1: Setup Environment

First, let's make sure everything is installed:

```bash
./cloudshell_open.sh
```

This will:

- Install Flutter (if needed)
- Install Firebase CLI (if needed)
- Get project dependencies

<walkthrough-spotlight-pointer spotlightId="devshell-web-preview-button">
Click the **Web Preview** button to preview your app later.
</walkthrough-spotlight-pointer>

---

## Step 2: Run the App Locally

Start the Flutter web server:

```bash
flutter run -d chrome --web-port=8080
```

Then click **Web Preview** → **Preview on port 8080** to see your app.

---

## Step 3: Build for Production

Build an optimized web release:

```bash
flutter build web --release
```

The build output will be in `build/web/`.

---

## Step 4: Deploy to Firebase

Deploy your app to Firebase Hosting:

```bash
firebase deploy --only hosting
```

Your app will be live at: `https://datafightcentral.web.app`

---

## Useful Commands

| Command                            | Description           |
| ---------------------------------- | --------------------- |
| `flutter pub get`                  | Install dependencies  |
| `flutter run -d chrome`            | Run in browser        |
| `flutter build web`                | Build web app         |
| `firebase deploy`                  | Deploy everything     |
| `firebase deploy --only hosting`   | Deploy web only       |
| `firebase deploy --only functions` | Deploy functions only |
| `firebase emulators:start`         | Run local emulators   |

---

## Troubleshooting

### Out of disk space?

```bash
rm -rf ~/.gradle ~/.npm/_cacache
flutter clean
```

### Firebase not logged in?

```bash
firebase login --no-localhost
```

### Flutter not found?

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

---

## Congratulations! 🎉

You're all set up to develop Data Fight Central in Cloud Shell.

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>
