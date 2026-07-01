#!/bin/bash
# .devcontainer/post-create.sh
# Runs after dev container is created

set -e

echo "🔧 Setting up DFC dev container..."

# Install Node.js tools
echo "📦 Installing Node.js global tools..."
npm install -g yarn pnpm @firebase/cli

# Install Python tools
echo "🐍 Installing Python tools..."
pip install --upgrade pip
pip install black flake8 pytest pytest-cov pytest-asyncio

# Install Google Cloud SDK (if not present)
if ! command -v gcloud &> /dev/null; then
  echo "☁️  Installing Google Cloud SDK..."
  curl https://sdk.cloud.google.com | bash
fi

# Install Stripe CLI (if not present)
if ! command -v stripe &> /dev/null; then
  echo "💳 Installing Stripe CLI..."
  curl https://raw.githubusercontent.com/stripe/stripe-cli/master/install.sh -s | bash
fi

# Install Docker Compose (already installed in base image)
echo "✅ Docker Compose installed"

# Create directories
mkdir -p ~/.ssh
mkdir -p ~/.config/gcloud

echo "✅ DFC dev container ready!"
echo ""
echo "📚 Next steps:"
echo "   1. Copy .env.example to .env"
echo "   2. Fill in your API keys and credentials"
echo "   3. Run: docker compose -f docker-compose.minimal.yml up -d"
echo "   4. Access services on localhost"
echo ""
echo "🚀 Start developing!"
