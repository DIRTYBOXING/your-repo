#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Chukya 3.0 — VM bootstrap: create user, dirs, install configs
# ═══════════════════════════════════════════════════════════════════════════
# Run as root:  sudo bash infrastructure/systemd/setup-vm.sh
set -euo pipefail

echo "==> Creating chukya system user and group"
if ! id -u chukya &>/dev/null; then
  useradd --system --no-create-home --shell /usr/sbin/nologin chukya
fi

echo "==> Creating /etc/chukya"
mkdir -p /etc/chukya
cat > /etc/chukya/config.yaml <<'YAML'
chukya:
  scan:
    travel_radar_interval_seconds: 30
    ambush_burst_seconds: 5
    guardian_continuous_seconds: 2
    stealth_sentinel_interval_seconds: 120
  thresholds:
    police_notify_confidence: 0.8
    consecutive_detections_required: 2
    high_threat_confidence: 0.7
    clear_threshold: 0.3
  safe_zone:
    default_radius_meters: 200
    default_restraining_distance_meters: 200
  evidence:
    max_attachment_bytes: 10485760
    retention_days: 2555
  battery:
    budget_percent_24h: 5.0
YAML
chown root:chukya /etc/chukya/config.yaml
chmod 640 /etc/chukya/config.yaml

echo "==> Creating /etc/chukya/chukya.env (edit with real secrets)"
cat > /etc/chukya/chukya.env <<'ENV'
# HMAC secret for phone hashing — generate with: openssl rand -hex 32
CHUKYA_HMAC_SECRET=REPLACE_WITH_HMAC_SECRET
# Firebase project
FIREBASE_PROJECT_ID=datafightcentral
# Region
REGION=australia-southeast1
ENV
chown root:chukya /etc/chukya/chukya.env
chmod 640 /etc/chukya/chukya.env

echo "==> Creating log directory"
mkdir -p /var/log/chukya
chown chukya:chukya /var/log/chukya
chmod 750 /var/log/chukya

echo "==> Installing systemd service"
cp "$(dirname "$0")/chukya-safety.service" /etc/systemd/system/
systemctl daemon-reload

echo "==> Installing logrotate config"
cp "$(dirname "$0")/chukya-logrotate.conf" /etc/logrotate.d/chukya

echo "==> Done. Next steps:"
echo "    1. Edit /etc/chukya/chukya.env with real secrets"
echo "    2. Place chukya-safety binary at /usr/local/bin/chukya-safety"
echo "    3. sudo systemctl enable --now chukya-safety"
echo "    4. journalctl -u chukya-safety -f"
