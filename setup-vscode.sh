#!/bin/bash
# VSCode setup script for DFC development

set -e

echo "🔧 Setting up VSCode for DFC Development..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Install VSCode extensions
echo -e "${BLUE}📦 Installing VSCode extensions...${NC}"
extensions=(
  "ms-python.python"
  "ms-python.pylance"
  "ms-python.debugpy"
  "dbaeumer.vscode-eslint"
  "esbenp.prettier-vscode"
  "ms-azuretools.vscode-docker"
  "ms-vscode-remote.remote-containers"
  "googlecloudtools.cloudcode"
  "ms-kubernetes-tools.vscode-kubernetes-tools"
  "mtxr.sqltools"
  "mtxr.sqltools-driver-pg"
  "redisclient.redis-explorer"
  "toba.vsfire"
  "humao.rest-client"
  "eamodio.gitlens"
  "GitHub.copilot"
  "GitHub.copilot-chat"
  "SonarSource.sonarlint-vscode"
)

for ext in "${extensions[@]}"; do
  echo "  Installing $ext..."
  code --install-extension "$ext" --force 2>/dev/null || echo "    ⚠️  Extension may already be installed"
done

echo -e "${GREEN}✅ Extensions installed${NC}"
echo ""

# Setup Python virtual environments
echo -e "${BLUE}🐍 Setting up Python virtual environments...${NC}"

for dir in atlas_backend services/predictor; do
  if [ -d "$dir" ]; then
    echo "  Setting up venv in $dir..."
    if [ ! -d "$dir/venv" ]; then
      python3 -m venv "$dir/venv"
      source "$dir/venv/bin/activate"
      pip install --upgrade pip
      if [ -f "$dir/requirements.txt" ]; then
        pip install -r "$dir/requirements.txt"
      fi
      echo "    ${GREEN}✅ venv ready${NC}"
    else
      echo "    venv already exists"
    fi
  fi
done

echo ""

# Setup Node.js
echo -e "${BLUE}📦 Setting up Node.js dependencies...${NC}"

if [ -d "entitlements-service" ] && [ -f "entitlements-service/package.json" ]; then
  cd entitlements-service
  npm install --legacy-peer-deps
  echo -e "  ${GREEN}✅ Dependencies installed${NC}"
  cd ..
fi

echo ""

# Create .env if not exists
if [ ! -f ".env" ]; then
  echo -e "${BLUE}🔐 Creating .env file...${NC}"
  cp .env.example .env
  echo -e "  ${YELLOW}⚠️  Fill in your credentials in .env${NC}"
fi

echo ""

# Setup Google Cloud
echo -e "${BLUE}☁️  Google Cloud Setup${NC}"
if command -v gcloud &> /dev/null; then
  echo "  ✅ Google Cloud SDK installed"
  
  # Check if authenticated
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
    echo "  ${YELLOW}⚠️  Not authenticated. Run: gcloud auth login${NC}"
  fi
else
  echo "  ${YELLOW}⚠️  Google Cloud SDK not installed${NC}"
  echo "  Install: https://cloud.google.com/sdk/docs/install"
fi

echo ""

# Database setup
echo -e "${BLUE}🗄️  Database Setup${NC}"
echo "  Starting PostgreSQL + Redis..."
docker compose -f docker-compose.minimal.yml up -d db redis prometheus grafana

echo "  Waiting for services to be ready..."
sleep 5

echo ""
echo -e "${GREEN}✅ VSCode setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Open VSCode: code dfc.code-workspace"
echo "  2. Install recommended extensions (Ctrl+Shift+X)"
echo "  3. F5 to start debugging a service"
echo "  4. Open Database Explorer (left sidebar)"
echo "  5. Connect to PostgreSQL & Redis"
echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo "  Debug Ingest API:         Ctrl+Shift+D → 'Python: Ingest API'"
echo "  Debug Entitlements:       Ctrl+Shift+D → 'Node.js: Entitlements'"
echo "  Start All Services:       Ctrl+Shift+D → 'Docker: Start All Services'"
echo "  Run Tests:                Ctrl+Shift+T → 'pytest-ingest'"
echo "  Format Code:              Shift+Alt+F"
echo "  Open Terminal:            Ctrl+\`"
echo "  Open REST Client:         Ctrl+Alt+R (requests.http)"
echo ""
echo -e "${BLUE}Database Tools:${NC}"
echo "  - PostgreSQL Explorer (left sidebar)"
echo "  - Redis Explorer (left sidebar)"
echo "  - Firestore Explorer (left sidebar)"
echo ""
echo -e "${BLUE}Cloud Tools:${NC}"
echo "  - Google Cloud Explorer (left sidebar)"
echo "  - Kubernetes Explorer (left sidebar)"
echo ""
