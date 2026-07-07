# Welcome to Data Fight Central 🥊

Welcome to the Cloud Shell environment for **Data Fight Central**!

This interactive walkthrough will guide you through setting up and running the project in seconds.

---

## 🛠️ Step 1: Run Setup Script

We have prepared a script that automates the entire environment setup:
- Clones and configures **Flutter** (stable)
- Adds Flutter to your persistent shell `PATH`
- Installs Dart & Flutter dependencies
- Configures the **Firebase CLI** and connects to the `datafightcentral` project

Click the command block below or copy-paste it into the Cloud Shell terminal to execute:

```bash
chmod +x cloudshell_open.sh && ./cloudshell_open.sh
```

---

## 🚀 Step 2: Run the Web App

Once the setup finishes successfully, launch the Flutter development server:

```bash
flutter run -d chrome --web-port=8080 --web-hostname=0.0.0.0
```

When the dev server is active:
1. Click the **Web Preview** button (looks like a prompt with a web icon) in the top-right corner of the Cloud Shell terminal.
2. Select **Preview on port 8080**.

---

## 📦 Step 3: Deploy to Firebase

To build and deploy the production bundle to Firebase hosting, run:

```bash
flutter build web && firebase deploy
```
