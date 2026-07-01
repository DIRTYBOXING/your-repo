#!/usr/bin/env bash
set -euo pipefail

ORIGIN_DOMAIN="your.origin.domain"
OUTPUT_DIR="/var/www/llhls/stream1"
SERVICE_FILE="/etc/systemd/system/llhls-ffmpeg.service"

echo "Updating packages"
apt-get update -y

echo "Installing dependencies"
apt-get install -y nginx git curl wget build-essential pkg-config libssl-dev

echo "Installing FFmpeg (apt may be old). Attempting apt first."
if ! command -v ffmpeg >/dev/null 2>&1; then
  apt-get install -y ffmpeg || true
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "FFmpeg not found or apt package insufficient. Installing static build."
  mkdir -p /opt/ffmpeg && cd /opt/ffmpeg
  wget -q https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
  tar -xf ffmpeg-release-amd64-static.tar.xz --strip-components=1
  cp ffmpeg /usr/local/bin/ffmpeg
  cp ffprobe /usr/local/bin/ffprobe
fi

echo "Creating output directory"
mkdir -p "${OUTPUT_DIR}"
chown -R www-data:www-data /var/www/llhls
chmod -R 755 /var/www/llhls

echo "Writing systemd service"
cat > "${SERVICE_FILE}" <<'EOF'
[Unit]
Description=LL-HLS FFmpeg Origin Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/llhls/stream1
ExecStart=/usr/bin/ffmpeg -hide_banner -loglevel info -i "srt://0.0.0.0:9999?mode=listener" -map 0:v -map 0:a -c:v libx264 -preset veryfast -tune zerolatency -g 48 -keyint_min 48 -sc_threshold 0 -bf 0 -b:v 3500k -maxrate 4000k -bufsize 8000k -c:a aac -b:a 128k -ac 2 -f hls -hls_time 1 -hls_list_size 6 -hls_flags delete_segments+append_list+omit_endlist+independent_segments -hls_segment_type fmp4 -hls_segment_filename "/var/www/llhls/stream1/seg_%05d.m4s" -master_pl_name "/var/www/llhls/stream1/master.m3u8" -hls_playlist_type event "/var/www/llhls/stream1/stream.m3u8"
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting service"
systemctl daemon-reload
systemctl enable llhls-ffmpeg.service
systemctl start llhls-ffmpeg.service

echo "Writing minimal NGINX site"
cat > /etc/nginx/sites-available/llhls <<EOF
server {
  listen 80;
  server_name ${ORIGIN_DOMAIN};

  root /var/www;
  access_log /var/log/nginx/llhls.access.log;
  error_log /var/log/nginx/llhls.error.log;

  location /llhls/ {
    add_header Cache-Control no-cache;
    add_header Access-Control-Allow-Origin *;
    types {
      application/vnd.apple.mpegurl m3u8;
      video/mp4 m4s;
    }
    expires -1;
    tcp_nopush on;
  }
}
EOF

ln -sf /etc/nginx/sites-available/llhls /etc/nginx/sites-enabled/llhls
nginx -t
systemctl reload nginx

echo "Bootstrap complete. Check journalctl -u llhls-ffmpeg.service -f and /var/log/nginx/llhls.access.log"
