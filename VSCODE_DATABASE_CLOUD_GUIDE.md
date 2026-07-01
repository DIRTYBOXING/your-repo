# VSCode Guide: Database & Google Cloud Integration

## Quick Start

### 1. Open Workspace
```bash
code dfc.code-workspace
```

VSCode loads all 4 projects with shared settings, debugging configs, and extensions.

---

## Database Tools in VSCode

### PostgreSQL (Local & Cloud SQL)

**In VSCode:**
1. Open **Database Explorer** (left sidebar icon)
2. Click **+** → **PostgreSQL**
3. Select connection:
   - **DFC PostgreSQL (Local)** → `localhost:5432`
   - **DFC PostgreSQL (Cloud SQL)** → Cloud SQL proxy IP

**Available Actions:**
```
Right-click Database:
  - Execute Query (write SQL)
  - Run Current Query (Ctrl+Enter)
  - Show Data (view tables)
  - New Query Tab

Right-click Table:
  - Show Table (view records, 1000 limit)
  - Refresh
  - Export to CSV
  - Insert Row
  - Update Row
  - Delete Row
```

**Example Query:**
```sql
-- Find all events with predictions
SELECT 
  e.id,
  e.name,
  COUNT(p.id) as prediction_count,
  AVG(p.win_probability) as avg_confidence
FROM events e
LEFT JOIN predictions p ON e.id = p.event_id
WHERE e.status = 'scheduled'
GROUP BY e.id, e.name
ORDER BY e.start_at DESC;
```

**View Results:**
- Click table name → opens data viewer
- Sort: click column header
- Filter: type in search box
- Export: right-click → "Export to CSV"

---

### Redis (Cache/Session Store)

**In VSCode:**
1. **Redis Explorer** (left sidebar)
2. Add connection:
   - Host: `localhost`
   - Port: `6379`
   - DB: `0`

**Available Actions:**
```
Right-click DB:
  - Refresh Keys
  - Flush DB (⚠️ deletes all)
  - Info (memory, stats)

Right-click Key:
  - Get Value
  - Set Value
  - Delete Key
  - Rename Key
  - TTL (time to live)
```

**Common Commands:**
```
KEYS *                 # List all keys
GET session-123        # Get session data
SET cache-key value    # Store cache
DEL cache-key          # Delete
TTL session-123        # Time remaining
FLUSHDB                # Clear all (⚠️)
INFO                   # Server stats
```

---

### Firestore (NoSQL)

**In VSCode:**
1. **Firestore Explorer** (left sidebar)
2. Authenticate: `gcloud auth application-default login`
3. Select project: `datafightcentral`

**Available Actions:**
```
Collections:
  - View documents
  - Add document
  - Edit fields
  - Delete documents

Queries:
  - Filter by field
  - Order by
  - Limit results
  - Real-time sync
```

---

## Google Cloud Integration

### Authenticate
```bash
# In VSCode terminal (Ctrl+`)
gcloud auth login

# Set default project
gcloud config set project datafightcentral

# Get application default credentials
gcloud auth application-default login
```

### Cloud Explorer (Sidebar)

**In VSCode:**
1. Click **Google Cloud** icon (left sidebar)
2. Shows all GCP resources:
   - **Compute** → Cloud Run services, GKE clusters
   - **Storage** → Cloud Storage buckets
   - **Databases** → Cloud SQL instances
   - **Firestore** → Collections & documents
   - **Functions** → Cloud Functions
   - **Pub/Sub** → Topics & subscriptions

**Available Actions:**
```
Cloud Run Services:
  - View logs (Ctrl+click service)
  - Open in browser
  - Tail logs (real-time)
  - Redeploy

Cloud SQL:
  - Connect to database
  - View backups
  - Create backup
  - Restore backup

Cloud Storage:
  - Browse files
  - Download file
  - Upload file
  - Delete object
  - Share (generate signed URL)
```

### Useful Commands

**Deploy to Cloud Run:**
```bash
gcloud run deploy dfc-ingest \
  --source . \
  --region australia-southeast1 \
  --allow-unauthenticated
```

**View Cloud Run Logs:**
```bash
gcloud run logs read dfc-ingest --region australia-southeast1 --limit 50
```

**SSH into GKE Pod:**
```bash
kubectl exec -it -n dfc deployment/ingest -- /bin/bash
```

**Port-forward Cloud SQL:**
```bash
cloud_sql_proxy -instances=datafightcentral:australia-southeast1:dfc=tcp:5432
```

---

## REST Client (Requests.http)

**In VSCode:**
1. Open `requests.http` file
2. Hover over request → **Send Request** button
3. View response in sidebar

**Example:**
```http
GET http://localhost:8000/health

###

POST http://localhost:4010/checkout/session
Content-Type: application/json

{
  "user_id": "user-123",
  "event_id": "event-456"
}
```

**Features:**
- Variables: `@baseUrl`, `@apiKey`
- Environment switching: dev/prod
- Response history
- Export responses
- Auth headers (JWT, API key)

---

## Debugging Services

### Python: Ingest API
1. **Open** `atlas_backend/main.py`
2. Set breakpoint (click line number)
3. **Debug** → **Python: Ingest API**
4. Debugger starts at breakpoint
5. Step through, watch variables, evaluate expressions

**Debug Controls (F5 panel):**
- ▶️ Continue (F5)
- ⏸️ Step Over (F10)
- → Step Into (F11)
- ← Step Out (Shift+F11)
- 🔴 Stop (Shift+F5)

### Node.js: Entitlements
1. **Open** `entitlements-service/server.js`
2. Set breakpoint
3. **Debug** → **Node.js: Entitlements Service**
4. Debugger opens Chrome DevTools UI
5. Inspect heap, profiles, network

**Variables Panel (left sidebar):**
- Local variables
- Closure variables
- Global scope
- Watch expressions

---

## Database Debugging

### Query Debugging in VSCode

**SQL Tools Plugin:**
1. Open `requests.http` or create `.sql` file
2. Highlight SQL query
3. Right-click → **Execute Query**
4. Results shown in panel below

**Example:**
```sql
-- Debug: Check for slow queries
SELECT 
  query,
  calls,
  mean_time,
  total_time
FROM pg_stat_statements
WHERE mean_time > 100
ORDER BY mean_time DESC
LIMIT 10;
```

### Connection Profiles

**In `.vscode/settings.json`:**
```json
"sql.connections": [
  {
    "name": "DFC Local",
    "driver": "PostgreSQL",
    "host": "localhost",
    "port": 5432,
    "database": "dfc",
    "username": "dfc_admin"
  }
]
```

**Switch Connections:**
- Click connection name (bottom status bar)
- Select profile from dropdown

---

## Monitoring from VSCode

### Prometheus Metrics
1. **REST Client** → `requests.http`
2. Query: `GET http://localhost:9090/api/v1/query?query=up`
3. View metrics in response panel

### Grafana Dashboards
1. **Open** http://localhost:3001 (click in REST Client response)
2. Login: `admin` / `dfc-grafana-local`
3. Dashboards → DFC Overview
4. Real-time metrics displayed

### Cloud Logging
1. **Google Cloud Explorer** → Logs
2. Filter by:
   - Resource (Cloud Run, GKE, Cloud SQL)
   - Time range
   - Severity level
3. View logs in VSCode

---

## Keyboard Shortcuts (Quick Reference)

| Action | Windows | Mac |
|--------|---------|-----|
| Start Debug | F5 | F5 |
| Step Over | F10 | F10 |
| Step Into | F11 | F11 |
| Toggle Breakpoint | Ctrl+K Ctrl+B | Cmd+K Cmd+B |
| Format Document | Shift+Alt+F | Shift+Opt+F |
| Run Tests | Ctrl+Shift+T | Cmd+Shift+T |
| Open Terminal | Ctrl+` | Ctrl+` |
| Open Command Palette | Ctrl+Shift+P | Cmd+Shift+P |
| REST Client | Ctrl+Alt+R | Cmd+Alt+R |
| Database Explorer | Ctrl+Shift+D | Cmd+Shift+D |
| Git: Pull | Ctrl+Shift+G | Cmd+Shift+G |

---

## Common Tasks

### Debug a Database Issue

1. **Open Database Explorer**
2. **Execute Query:**
```sql
SELECT * FROM pg_stat_activity WHERE state != 'idle';
```
3. **Identify slow query**
4. **Explain Plan:**
```sql
EXPLAIN ANALYZE SELECT ... FROM events WHERE ...;
```
5. **Check indexes:**
```sql
SELECT * FROM pg_indexes WHERE tablename = 'events';
```

### Monitor Cloud Run Service

1. **Google Cloud Explorer** → **Compute** → **Cloud Run**
2. Right-click service → **Tail Logs**
3. Logs stream in real-time to VSCode
4. Filter errors: search for "ERROR" or "Exception"

### Deploy and Test

1. **Terminal** → `bash deploy-gke.sh`
2. **Kubernetes Explorer** → View pods
3. Right-click pod → **Logs**
4. See deployment progress in real-time

### Debug REST API

1. **Open** `requests.http`
2. **Send Request** on endpoint
3. View response headers, body, status
4. Check timestamps → understand latency
5. Inspect response → set breakpoint in handler

---

## Extension Recommendations

| Extension | Purpose |
|-----------|---------|
| SQLTools | Database queries, connections |
| Firestore | NoSQL document browser |
| Google Cloud | Cloud resources explorer |
| REST Client | API testing (no Postman needed) |
| Redis | Cache key inspection |
| GitLens | Git blame, history, remotes |
| Copilot | AI code completion |
| Docker | Container management |
| Kubernetes | K8s cluster explorer |
| Remote Containers | Dev container debugging |

---

## Pro Tips

💡 **Sync Cloud SQL locally:**
```bash
# In VSCode terminal
cloud_sql_proxy -instances=PROJECT:REGION:INSTANCE=tcp:5432
# Then use localhost:5432 in DB Explorer
```

💡 **Export query results:**
- Right-click in SQL results
- "Save Results as CSV"

💡 **Set up watchers for auto-reload:**
```bash
# Python: nodemon or watchdog
watchmedo shell-command \
  --patterns="*.py" \
  --recursive \
  --command='killall python; python main.py' .
```

💡 **Use environment variables:**
```http
@apiKey = {{$dotenv API_KEY}}
```

💡 **Quick deployment:**
- Hit `Ctrl+Shift+T` → Run deployment task
- Logs stream to VSCode terminal

---

**Need Help?** Check individual extension documentation or run:
```bash
code --list-extensions
```

