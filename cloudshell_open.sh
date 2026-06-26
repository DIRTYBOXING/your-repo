#!/bin/bash
# Cloud Shell setup script for Data Fight Central
# This runs when the project is opened via "Open in Cloud Shell" button

set -e

echo "🥊 Setting up Data Fight Central..."

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    cd ~
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$HOME/flutter/bin"
    flutter precache --web
fi

# Navigate to project
cd ~/Data-Fight-Central 2>/dev/null || cd ~/cloudshell_open 2>/dev/null || true

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Install Firebase CLI if not present
if ! command -v firebase &> /dev/null; then
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
fi

# Login to Firebase (will prompt if not logged in)
firebase login --no-localhost 2>/dev/null || true

# Set project
firebase use datafightcentral 2>/dev/null || echo "Run: firebase use datafightcentral"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Quick commands:"
echo "  flutter run -d chrome   # Run web app"
echo "  flutter build web       # Build for production"
echo "  firebase deploy         # Deploy to Firebase"
echo ""
