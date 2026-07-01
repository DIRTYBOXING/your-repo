#!/bin/bash
# Cloud Shell setup script for Data Fight Central
# This runs when the project is opened via "Open in Cloud Shell" button

set -e

echo "🥊 Setting up Data Fight Central..."

# 1. Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    cd ~
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$HOME/flutter/bin"
    
    # Persist Flutter path for subsequent interactive shells
    if ! grep -q "flutter/bin" ~/.bashrc; then
        echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    fi
    flutter precache --web
fi

# 2. Navigate to project directory dynamically
PROJECT_DIR=$(find ~ -name "pubspec.yaml" -not -path "*/.dart_tool/*" -not -path "*/.pub-cache/*" -print -quit | xargs dirname 2>/dev/null)
if [ -n "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
else
    cd ~/Data-Fight-Central 2>/dev/null || cd ~/datafightcentral 2>/dev/null || cd ~/cloudshell_open 2>/dev/null || true
fi

# 3. Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# 4. Install Firebase CLI if not present
if ! command -v firebase &> /dev/null; then
    echo "📦 Installing Firebase CLI..."
    # Fallback to npm global with sudo if available, or normal npm install
    if command -v sudo &> /dev/null; then
        sudo npm install -g firebase-tools
    else
        npm install -g firebase-tools
    fi
fi

# 5. Login to Firebase (will prompt if not logged in)
firebase login --no-localhost 2>/dev/null || true

# 6. Set project
firebase use datafightcentral 2>/dev/null || echo "Run: firebase use datafightcentral"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Quick commands:"
echo "  flutter run -d chrome   # Run web app"
echo "  flutter build web       # Build for production"
echo "  firebase deploy         # Deploy to Firebase"
echo ""
