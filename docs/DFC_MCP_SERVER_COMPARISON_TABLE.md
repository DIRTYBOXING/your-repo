# DFC MCP Server Comparison Table

This table defines which MCP servers matter for DFC, what they do, and whether they are required.

## At a glance

| MCP Server | Primary Role | DFC Use Cases | Required? | Production Dependency? | Notes |
|---|---|---|---|---|---|
| Firebase Admin MCP | Local AI access to Firebase Admin capabilities | Firestore reads/writes for diagnostics, entitlement checks, storage inspection, rules-aware investigations | **Recommended (High Value)** | **No** | Most valuable MCP for DFC workflows; treat with least-privilege credentials |
| Filesystem MCP | Local AI file access/editing | Refactors, route-constant migrations, docs updates, module sweep edits | **Yes** | **No** | Core for codebase operations |
| Git MCP | Local AI Git operations | Diffs, branch prep, commit generation, patch hygiene | **Yes** | **No** | Core for safe change management |
| Terminal MCP | Local AI command execution | `flutter analyze`, tests, grep checks, script-driven validation | Optional | **No** | Useful for validation loops; keep command scope controlled |
| Custom DFC MCP | Team-specific automation primitives | Routing-spine checks, module sweep automation, trust/safety checks | Optional | **No** | Add only when custom automation has clear ROI |

## Servers you do NOT need to host DFC

| Server Type | Needed for DFC backend? | Why |
|---|---|---|
| HTTP MCP server as production backend | **No** | MCP is tooling protocol, not app hosting/runtime |
| Express/Node REST server (for MCP parity) | **No** | DFC backend is Firebase-native |
| Python API server (for MCP parity) | **No** | Not required unless separate product need exists |

## Required vs optional baseline for DFC

### Baseline set (recommended default)

- Filesystem MCP
- Git MCP
- Firebase Admin MCP

### Optional add-ons

- Terminal MCP
- Custom DFC MCP

## Architecture fit

- **Production path:** Flutter clients -> Firebase Auth/Firestore/Storage/Functions
- **Local tooling path:** Cline/AI assistant -> MCP servers -> repo + Firebase admin operations

These paths are intentionally separate.

## Governance alignment

Regardless of MCP usage, merge authority remains with repository-native controls:

- `.github/workflows/ci.yml`
- `.github/workflows/quality-gate.yml`
- `.github/workflows/routing-check.yml`
- `.github/workflows/firebase-security-check.yml`
- `.github/workflows/dfc-rulepack-check.yml`
- Branch protection required checks

## Decision rule

If a tool/server is unavailable locally, DFC must still pass by:

1. Local analyze/tests (or teammate execution)
2. Pull request checks in GitHub
3. Required branch protection gates

MCP accelerates development; it does not define platform correctness.
