# VSCode + Database + Google Cloud Quick Start

## 1-Minute Setup

```bash
# Clone repo
git clone https://github.com/yourusername/Data-Fight-Central.git
cd Data-Fight-Central

# Run setup
bash setup-vscode.sh

# Open workspace
code dfc.code-workspace
```

✅ **Done!** VSCode is ready with all tools.

---

## 5-Minute Debugging Session

### Debug Python (Ingest API)

```
1. Press F5 (Start Debugging)
2. Select "Python: Ingest API (FastAPI)"
3. Open atlas_backend/main.py
4. Click line 42 (set breakpoint - red dot appears)
5. Go to http://localhost:8000/health in browser
6. Debugger pauses at breakpoint
7. Hover variables, step through code
8. Press F5 to continue
```

### Debug Node.js (Entitlements)

```
1. Press F5
2. Select "Node.js: Entitlements Service"
3. Open entitlements-service/server.js
4. Set breakpoint on line 50
5. Trigger request via REST Client (Ctrl+Alt+R)
6. Chrome DevTools opens with live debugging
7. Inspect variables, call stack, network
```

---

## Database Access (No External Tools)

### Query PostgreSQL in VSCode

```
1. Left sidebar → Database Explorer
2. Right-click "DFC PostgreSQL (Local)"
3. New Query
4. Write SQL:
   SELECT * FROM events WHERE status = 'scheduled';
5. Ctrl+Enter to execute
6. Results shown in panel
```

### Inspect Redis Cache

```
1. Left sidebar → Redis Explorer
2. Click "Local Redis" (localhost:6379)
3. View all keys
4. Click key to see value
5. Right-click to TTL, delete, set
```

### Browse Firestore Collections

```
1. Left sidebar → Firestore Explorer
2. Select project: datafightcentral
3. Browse collections
4. View documents (auto-formatted JSON)
5. Add/edit/delete documents
```

---

## Google Cloud from VSCode

### View Cloud Run Logs

```
1. Left sidebar → Google Cloud
2. Expand "Compute" → "Cloud Run"
3. Click service (e.g., dfc-ingest)
4. Logs open in editor
5. Real-time streaming
6. Filter by severity
```

### Deploy to Cloud Run

```
1. Terminal (Ctrl+`)
2. Run: gcloud run deploy dfc-ingest --source . --region australia-southeast1
3. Logs stream in terminal
4. View in sidebar when done
```

### SSH into GKE Pod

```
1. Left sidebar → Kubernetes
2. Select cluster, namespace (dfc)
3. Right-click pod
4. "Exec into Pod"
5. Terminal opens inside container
```

### Connect to Cloud SQL

```
1. Terminal: bash setup-cloud-sql.sh
2. Run task: Cloud SQL Proxy (Ctrl+Shift+B)
3. Database Explorer → Add Connection
4. Use localhost:5432
5. Query cloud database directly
```

---

## API Testing (REST Client)

### Test Ingest API

Open `requests.http` and click **Send Request** on any endpoint:

```http
GET http://localhost:8000/health
→ View response in sidebar

POST http://localhost:8000/events
Content-Type: application/json

{
  "name": "UFC 300",
  "status": "scheduled"
}
→ Creates event, see response
```

### Switch Environments

Change `@baseUrl` at top of file:
```http
@baseUrl = http://localhost        # Local
// @baseUrl = https://api.dfc.com   # Production
```

All requests use the variable automatically.

---

## Common Tasks

### Run Tests
```
Ctrl+Shift+T → Select "pytest-ingest"
Results show in terminal
```

### Format Code
```
Shift+Alt+F → Auto-formats file
(Python uses Black, JS uses Prettier)
```

### Git Operations
```
Ctrl+Shift+G → Git Explorer
View changes, stage, commit, push
```

### Deploy
```
Ctrl+Shift+B → Select "deploy-gke"
Deployment runs, logs stream to terminal
```

---

## Sidebar Panels (Left Side)

| Icon | Name | What It Does |
|------|------|-------------|
| 🔍 | Explorer | Browse files, create new files |
| 🔎 | Search | Find text across project |
| 🌿 | Source Control | Git history, branches, commits |
| ▶️ | Run & Debug | Start debuggers, run tests |
| 📦 | Extensions | Install/manage extensions |
| 💾 | Database Explorer | Query PostgreSQL, view tables |
| 🔴 | Redis | Browse cache keys |
| 🌐 | Google Cloud | Cloud resources, logs |
| ☸️ | Kubernetes | K8s clusters, pods, services |
| 🔥 | Firestore | NoSQL collections, documents |

Click icon to open panel. Click again to close.

---

## Keyboard Shortcuts (Essential)

```
Ctrl+K Ctrl+W  → Close current tab
Ctrl+Shift+P   → Command palette (search all commands)
Ctrl+/         → Toggle comment
Ctrl+Z         → Undo
Ctrl+S         → Save file
Ctrl+Shift+S   → Save as
F2             → Rename (variable/function across file)
Ctrl+D         → Select next occurrence (multi-edit)
Ctrl+H         → Find & Replace
Ctrl+J         → Toggle panel height
Ctrl+B         → Toggle sidebar
```

---

## Troubleshooting

### Port Already in Use
```bash
# Find process using port
lsof -i :8000

# Kill it
kill -9 <PID>
```

### Docker Services Won't Start
```bash
# Check status
docker compose -f docker-compose.minimal.yml ps

# View logs
docker compose logs ingest

# Restart
docker compose -f docker-compose.minimal.yml restart
```

### Database Connection Failed
```bash
# Check PostgreSQL is running
docker compose -f docker-compose.minimal.yml exec db pg_isready

# Check credentials in .env
cat .env | grep DATABASE_URL

# Test connection
psql postgresql://dfc_admin:password@localhost:5432/dfc
```

### Debugging Not Working
```bash
# Ensure port is free (F5 uses ports 5678, 9229)
lsof -i :5678

# Check Python version (3.8+)
python --version

# Check Node.js version (14+)
node --version

# Reinstall dependencies
rm -rf venv && python -m venv venv
source venv/bin/activate
pip install -r atlas_backend/requirements.txt
```

### Cloud SQL Connection Timeout
```bash
# Check proxy is running
ps aux | grep cloud_sql_proxy

# Check firewall allows 0.0.0.0/0
gcloud sql instances patch dfc \
  --require-ssl=false \
  --backup-start-time 03:00

# Test connection
psql -h 127.0.0.1 -U dfc_admin -d dfc
```

---

## Performance Tips

💡 **Faster debugging:**
- Use breakpoints instead of print statements
- Conditional breakpoints: right-click breakpoint

💡 **Faster database queries:**
- Use LIMIT during development
- Check query plans: EXPLAIN ANALYZE

💡 **Faster deployments:**
- Use docker compose for local testing first
- Build images only when needed (--no-cache)

💡 **Smoother debugging:**
- Disable extensions temporarily (they slow VSCode)
- Use lightweight themes (Light+, Dark+)

---

## Next Steps

1. **Master debugging:** Familiarize yourself with F5, F10, F11
2. **Learn shortcuts:** Pin 5 most-used shortcuts above monitor
3. **Database skills:** Write 3-4 SQL queries daily
4. **Cloud familiarity:** Deploy manually, read cloud logs
5. **Automate workflows:** Create custom tasks in tasks.json

---

## Links & Resources

| Resource | Link |
|----------|------|
| VSCode Docs | https://code.visualstudio.com/docs |
| Database Explorer | https://github.com/mtxr/vscode-sqltools |
| Google Cloud Tools | https://cloud.google.com/docs/cloud-code/quickstart |
| Kubernetes Extension | https://github.com/Azure/vscode-kubernetes-tools |
| REST Client | https://github.com/Huachao/vscode-restclient |
| Cloud SQL Proxy | https://cloud.google.com/sql/docs/postgres/sql-proxy |

---

**Questions?** Check:
- VSCode Command Palette (Ctrl+Shift+P) → "Developer: Toggle Developer Tools"
- Extension README in VSCode sidebar
- GitHub issues for the project

**Happy coding! 🚀**
