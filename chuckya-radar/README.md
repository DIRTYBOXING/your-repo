# ╔══════════════════════════════════════════════════════════════╗

# ║ DFC CHUCKYA RADAR — TOP-SECRET TESTING ROOM ║

# ║ Anti-Piracy Signal Ingestion · Scoring · Evidence Export ║

# ║ DataFightCentral Internal Use Only ║

# ╚══════════════════════════════════════════════════════════════╝

> **Classification: DFC CHUCK TOP SECRET**
> For authorized DFC personnel only. Do not distribute externally.

---

## Quick Start (one command)

```bash
cd chuckya-radar
docker-compose up --build
```

| Service     | URL                           |
| ----------- | ----------------------------- |
| Radar API   | http://localhost:8081         |
| Dashboard   | http://localhost:8082         |
| Healthcheck | http://localhost:8081/healthz |

---

## API Endpoints

| Method | Path                          | Description                     |
| ------ | ----------------------------- | ------------------------------- |
| GET    | `/healthz`                    | Service health                  |
| POST   | `/v1/radar/event`             | Ingest a piracy/restream signal |
| GET    | `/v1/radar/alerts`            | List all alerts (newest first)  |
| GET    | `/v1/radar/alerts/:id`        | Get single alert detail         |
| POST   | `/v1/radar/alerts/:id/export` | Download Police Evidence Pack   |

---

## Test Commands

### Create a test alert

```bash
curl -s -X POST http://localhost:8081/v1/radar/event ^
  -H "Content-Type: application/json" ^
  -d "{\"source\":\"manual\",\"eventId\":\"evt_demo\",\"sessionId\":\"sess_demo_001\",\"userId\":\"uid_demo\",\"type\":\"piracy\",\"riskScore\":95,\"topSignals\":[\"watermark_match\",\"license_reuse\"]}"
```

### List all alerts

```bash
curl http://localhost:8081/v1/radar/alerts
```

### Export Police Evidence Pack

```bash
curl -X POST http://localhost:8081/v1/radar/alerts/R-<ALERT_ID>/export -o evidence.zip
```

### Batch test (5 signals, different risk levels)

```bash
curl -s -X POST http://localhost:8081/v1/radar/event -H "Content-Type: application/json" -d "{\"type\":\"piracy\",\"riskScore\":95,\"source\":\"drone\",\"topSignals\":[\"watermark_match\",\"geo_anomaly\"]}"
curl -s -X POST http://localhost:8081/v1/radar/event -H "Content-Type: application/json" -d "{\"type\":\"restream\",\"riskScore\":82,\"source\":\"player\",\"topSignals\":[\"license_reuse\",\"ip_cluster\"]}"
curl -s -X POST http://localhost:8081/v1/radar/event -H "Content-Type: application/json" -d "{\"type\":\"credential_sharing\",\"riskScore\":55,\"source\":\"auth\",\"topSignals\":[\"device_fingerprint_mismatch\"]}"
curl -s -X POST http://localhost:8081/v1/radar/event -H "Content-Type: application/json" -d "{\"type\":\"watermark_match\",\"riskScore\":40,\"source\":\"cdn\",\"topSignals\":[\"partial_match\"]}"
curl -s -X POST http://localhost:8081/v1/radar/event -H "Content-Type: application/json" -d "{\"type\":\"manual\",\"riskScore\":15,\"source\":\"manual\",\"topSignals\":[\"flagged_by_moderator\"]}"
```

---

## Mobile / Remote Device Testing

1. Run `docker-compose up` on a laptop/server connected to Wi-Fi.
2. Find your machine IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux).
3. Open `http://<YOUR_IP>:8082` on your phone — dashboard loads.
4. POST alerts from any device on the same network to `http://<YOUR_IP>:8081/v1/radar/event`.
5. Dashboard auto-refreshes every 10 seconds.

---

## Police Demo Script (5 minutes)

| Time | Step                 | Action                                                                                                         |
| ---- | -------------------- | -------------------------------------------------------------------------------------------------------------- |
| 0:00 | **Intro**            | "CHUCKYA Radar ingests signals, scores risk, and produces evidence packs with chain-of-custody."               |
| 0:30 | **Dashboard**        | Open dashboard, refresh, show live alerts with risk scores.                                                    |
| 1:30 | **Drilldown**        | Click an alert — show `topSignals`, `riskScore`, explain why it fired.                                         |
| 2:30 | **Export**           | Click **EXPORT** — download the evidence zip. Open it: show `alert.json`, `manifest.json` with SHA-256 hashes. |
| 3:30 | **Chain of custody** | Show `access.log` in ops-audit proving who accessed what and when.                                             |
| 4:00 | **Wrap**             | Explain retention (90d default), two-person approval for exports, legal contacts.                              |

---

## Evidence Pack Contents

Each exported zip contains:

| File            | Purpose                                          |
| --------------- | ------------------------------------------------ |
| `alert.json`    | Full alert payload with timestamps and signals   |
| `manifest.json` | SHA-256 hashes of every file + export metadata   |
| `*.mp4 / *`     | Any evidence files placed in the incident folder |

To add evidence files to an alert, place them in `ops-audit/R-<ALERT_ID>/` before exporting.

---

## Legal, Privacy & Chain-of-Custody Checklist

- [ ] **Two-person approval** for any police export
- [ ] **Retention policy**: 90 days default, extended for confirmed incidents
- [ ] **Access logs**: every ingest and export logged with IP, timestamp, alertId
- [ ] **SHA-256 hashes**: computed for every file in the evidence pack manifest
- [ ] **Secure delivery**: time-limited signed URLs or direct zip handover
- [ ] **Contacts**: legal@datafightcentral.com · ops@datafightcentral.com

### Compute SHA-256 manually

```bash
# Windows (PowerShell)
Get-FileHash .\ops-audit\R-...\clip.mp4 -Algorithm SHA256

# Linux/Mac
sha256sum ops-audit/R-.../clip.mp4
```

---

## Security Notes

- **Path traversal protection**: Evidence export only serves files within `ops-audit/` — cannot access parent directories.
- **Input validation**: Risk scores clamped 0–100, types restricted to allowlist, string fields length-capped.
- **CORS enabled**: Dashboard can reach the API across ports.
- **No authentication** in demo mode — add JWT middleware before any staging/production deployment.

---

## Allowed Alert Types

| Type                 | Description                        |
| -------------------- | ---------------------------------- |
| `piracy`             | Detected unauthorized distribution |
| `restream`           | Live restream detected             |
| `credential_sharing` | Account sharing / token reuse      |
| `watermark_match`    | Forensic watermark matched         |
| `manual`             | Manually flagged by moderator      |

---

## File Structure

```
chuckya-radar/
├── docker-compose.yml          # Orchestration
├── README.md                   # This file
├── radar-server/
│   ├── Dockerfile              # Node 20 container
│   ├── package.json            # Dependencies
│   └── index.js                # Express API
├── radar-dashboard/
│   └── index.html              # DFC-themed single-page dashboard
└── ops-audit/                  # Created at runtime — evidence storage
    ├── access.log              # Ingest + export audit trail
    └── R-<timestamp>/          # Per-incident evidence folders
        └── alert.json
```

---

**DataFightCentral · CHUCKYA Radar · DFC Chuck Top Secret Testing Room**
