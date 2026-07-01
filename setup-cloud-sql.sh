#!/bin/bash
# Setup Cloud SQL proxy for local VSCode database debugging

set -e

PROJECT_ID="${GCP_PROJECT_ID:-datafightcentral}"
INSTANCE_NAME="dfc"
REGION="australia-southeast1"

echo "☁️  Setting up Cloud SQL Proxy for VSCode..."
echo ""

# Check if cloud_sql_proxy is installed
if ! command -v cloud_sql_proxy &> /dev/null; then
  echo "📦 Installing Cloud SQL Proxy..."
  
  # Detect OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
    chmod +x cloud_sql_proxy
    sudo mv cloud_sql_proxy /usr/local/bin/
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
    chmod +x cloud_sql_proxy
    sudo mv cloud_sql_proxy /usr/local/bin/
  else
    echo "❌ Unsupported OS. Download manually: https://cloud.google.com/sql/docs/postgres/sql-proxy"
    exit 1
  fi
fi

echo "✅ Cloud SQL Proxy installed"
echo ""

# Get Cloud SQL instance connection string
echo "🔍 Fetching Cloud SQL instance details..."
INSTANCE_PATH=$(gcloud sql instances describe $INSTANCE_NAME --format="value(name)" 2>/dev/null)

if [ -z "$INSTANCE_PATH" ]; then
  echo "❌ Cloud SQL instance '$INSTANCE_NAME' not found"
  echo "Create one: gcloud sql instances create $INSTANCE_NAME ..."
  exit 1
fi

INSTANCE_CONNECTION_NAME="$PROJECT_ID:$REGION:$INSTANCE_NAME"
echo "✅ Found: $INSTANCE_CONNECTION_NAME"
echo ""

# Create VS Code launch config for cloud proxy
echo "📝 Creating VS Code task for Cloud SQL Proxy..."
cat > .vscode/tasks-cloud-sql.json << EOF
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Cloud SQL Proxy (Port 5432)",
      "type": "shell",
      "command": "cloud_sql_proxy",
      "args": ["-instances=$INSTANCE_CONNECTION_NAME=tcp:5432"],
      "isBackground": true,
      "problemMatcher": {
        "pattern": {
          "regexp": "^.*$",
          "file": 1,
          "location": 2,
          "message": 3
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": "^.*Listening on.*",
          "endsPattern": "^.*Ready to accept connections.*"
        }
      },
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
EOF

echo "✅ Task created: .vscode/tasks-cloud-sql.json"
echo ""

# Create environment file for VSCode
echo "📝 Creating .env for Cloud SQL connection..."
cat > .env.cloud-sql << EOF
# Cloud SQL Connection (VSCode Database Explorer)
CLOUD_SQL_IP=127.0.0.1
CLOUD_SQL_PORT=5432
CLOUD_SQL_USER=dfc_admin
CLOUD_SQL_PASSWORD=\${{ secrets.CLOUD_SQL_PASSWORD }}
CLOUD_SQL_INSTANCE=$INSTANCE_CONNECTION_NAME

# Copy CLOUD_SQL_PASSWORD from: gcloud sql users describe dfc_admin --instance=$INSTANCE_NAME
EOF

echo "✅ Environment file created: .env.cloud-sql"
echo ""

# Instructions
echo "🚀 Setup complete! Follow these steps:"
echo ""
echo "1️⃣  Set Cloud SQL user password:"
echo "    gcloud sql users set-password dfc_admin --instance=$INSTANCE_NAME --password=YOUR_PASSWORD"
echo ""
echo "2️⃣  In VSCode, run task (Ctrl+Shift+B):"
echo "    \"Cloud SQL Proxy (Port 5432)\""
echo ""
echo "3️⃣  In Database Explorer, add connection:"
echo "    Host: localhost"
echo "    Port: 5432"
echo "    Database: dfc"
echo "    Username: dfc_admin"
echo "    Password: <from step 1>"
echo ""
echo "4️⃣  Execute queries directly in VSCode! 🎉"
echo ""

# Optional: Auto-start proxy on VSCode startup
echo "❓ Auto-start proxy on VSCode launch? (y/n)"
read -r response

if [[ "$response" == "y" ]]; then
  mkdir -p .vscode
  cat > .vscode/launch.json << EOF
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Cloud SQL Proxy",
      "type": "shell",
      "request": "launch",
      "preLaunchTask": "Cloud SQL Proxy (Port 5432)"
    }
  ]
}
EOF
  echo "✅ Auto-start configured"
fi

echo ""
echo "📚 For more info, see VSCODE_DATABASE_CLOUD_GUIDE.md"
