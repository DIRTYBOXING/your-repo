// src/routes/audit.ts
import { createHmac, randomUUID } from "node:crypto";
import { Router, type Request, type Response } from "express";

export const auditRouter = Router();

type AuditPayload = {
  actor_id: string;
  actor_email_masked: string;
  actor_role: string;
  action: string;
  metadata: Record<string, unknown>;
  ip_masked: string | null;
  request_id: string | null;
};

type AuditLogEntry = AuditPayload & {
  id: string;
  created_at: string;
  signature: string | null;
};

const auditLogs: AuditLogEntry[] = [];
const allowedRequestRoles = new Set(["admin", "system", "service"]);
const auditHmacSecret = process.env.AUDIT_HMAC_SECRET?.trim() || "";

function getHeaderValue(req: Request, headerName: string) {
  const value = req.header(headerName);
  return typeof value === "string" ? value.trim() : "";
}

function getRequestRole(req: Request) {
  return (
    getHeaderValue(req, "x-audit-role") ||
    getHeaderValue(req, "x-user-role") ||
    getHeaderValue(req, "x-role")
  ).toLowerCase();
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

function readRequiredString(
  source: Record<string, unknown>,
  fieldName: keyof AuditPayload,
  maxLength: number,
) {
  const value = source[fieldName];
  if (typeof value !== "string") {
    return { error: `${fieldName} must be a string` };
  }

  const normalized = value.trim();
  if (!normalized) {
    return { error: `${fieldName} is required` };
  }
  if (normalized.length > maxLength) {
    return { error: `${fieldName} exceeds ${maxLength} characters` };
  }

  return { value: normalized };
}

function readOptionalString(
  source: Record<string, unknown>,
  fieldName: "ip_masked" | "request_id",
  maxLength: number,
) {
  const value = source[fieldName];
  if (value === undefined || value === null || value === "") {
    return { value: null };
  }
  if (typeof value !== "string") {
    return { error: `${fieldName} must be a string when provided` };
  }

  const normalized = value.trim();
  if (!normalized) {
    return { value: null };
  }
  if (normalized.length > maxLength) {
    return { error: `${fieldName} exceeds ${maxLength} characters` };
  }

  return { value: normalized };
}

function stableStringify(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  }
  if (isPlainObject(value)) {
    const keys = Object.keys(value).sort((left, right) =>
      left.localeCompare(right),
    );
    return `{${keys
      .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function signAuditEntry(entry: Omit<AuditLogEntry, "signature">) {
  if (!auditHmacSecret) {
    return null;
  }

  return createHmac("sha256", auditHmacSecret)
    .update(stableStringify(entry))
    .digest("hex");
}

type ValidationResult = { error: string } | { value: AuditPayload };

function validatePayload(body: unknown): ValidationResult {
  if (!isPlainObject(body)) {
    return { error: "Request body must be a JSON object" };
  }

  const actorId = readRequiredString(body, "actor_id", 120);
  if (actorId.error) return { error: actorId.error };

  const actorEmailMasked = readRequiredString(body, "actor_email_masked", 160);
  if (actorEmailMasked.error) return { error: actorEmailMasked.error };

  const actorRole = readRequiredString(body, "actor_role", 64);
  if (actorRole.error) return { error: actorRole.error };

  const action = readRequiredString(body, "action", 160);
  if (action.error) return { error: action.error };

  const ipMasked = readOptionalString(body, "ip_masked", 64);
  if (ipMasked.error) return { error: ipMasked.error };

  const requestId = readOptionalString(body, "request_id", 160);
  if (requestId.error) return { error: requestId.error };

  const metadata = body.metadata;
  if (metadata !== undefined && !isPlainObject(metadata)) {
    return { error: "metadata must be an object when provided" };
  }

  const metadataRecord = isPlainObject(metadata) ? metadata : {};

  return {
    value: {
      actor_id: actorId.value,
      actor_email_masked: actorEmailMasked.value,
      actor_role: actorRole.value,
      action: action.value,
      metadata: metadataRecord,
      ip_masked: ipMasked.value,
      request_id: requestId.value,
    } satisfies AuditPayload,
  };
}

function ensureAuthorized(req: Request, res: Response) {
  const requestRole = getRequestRole(req);
  if (!allowedRequestRoles.has(requestRole)) {
    res.status(403).json({
      error: "forbidden",
      message: "audit route requires admin or service role",
    });
    return false;
  }

  return true;
}

// POST /audit - create audit log entry
// Example body: { actor_id, actor_email_masked, actor_role, action, metadata, ip_masked, request_id }
auditRouter.post("/", async (req, res) => {
  if (!ensureAuthorized(req, res)) {
    return;
  }

  const payload = validatePayload(req.body);
  if (payload.error) {
    res.status(400).json({ error: "invalid_request", message: payload.error });
    return;
  }

  const unsignedEntry = {
    id: randomUUID(),
    created_at: new Date().toISOString(),
    ...payload.value,
  };
  const entry: AuditLogEntry = {
    ...unsignedEntry,
    signature: signAuditEntry(unsignedEntry),
  };

  auditLogs.unshift(entry);
  res.status(201).json({ message: "Audit log entry created", log: entry });
});

// GET /audit - list audit logs (with pagination)
auditRouter.get("/", async (req, res) => {
  if (!ensureAuthorized(req, res)) {
    return;
  }

  const rawLimitValue =
    typeof req.query.limit === "string" ? req.query.limit : "50";
  const rawLimit = Number.parseInt(rawLimitValue, 10);
  const limit = Number.isFinite(rawLimit)
    ? Math.min(Math.max(rawLimit, 1), 100)
    : 50;
  const cursor = typeof req.query.cursor === "string" ? req.query.cursor : null;

  let startIndex = 0;
  if (cursor) {
    const cursorIndex = auditLogs.findIndex((log) => log.id === cursor);
    startIndex = cursorIndex >= 0 ? cursorIndex + 1 : 0;
  }

  const logs = auditLogs.slice(startIndex, startIndex + limit);
  const nextCursor = logs.length === limit ? (logs.at(-1)?.id ?? null) : null;

  res.json({
    logs,
    next_cursor: nextCursor,
    total: auditLogs.length,
    hmac_configured: Boolean(auditHmacSecret),
  });
});
