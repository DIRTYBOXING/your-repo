// src/index.ts
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { json } from "body-parser";
import { Pool } from "pg";
import { auditRouter } from "./routes/audit";

const app = express();
const databaseUrl = process.env.DATABASE_URL?.trim() || "";
const dbPool = databaseUrl ? new Pool({ connectionString: databaseUrl }) : null;

app.use(helmet());
app.use(json());
app.use(morgan("combined"));

async function getDbStatus() {
  if (!dbPool) {
    return { status: "not_configured" };
  }

  const client = await dbPool.connect();
  try {
    await client.query("SELECT 1");
    return { status: "ok" };
  } finally {
    client.release();
  }
}

app.get("/health", async (_req, res) => {
  try {
    const db = await getDbStatus();
    res.status(200).json({ status: "ok", db: db.status });
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    res.status(503).json({ status: "degraded", db: "error", error: message });
  }
});

app.use("/audit", auditRouter);

const PORT = process.env.PORT || 8080;
const server = app.listen(PORT, () => {
  console.log(`Audit service running on port ${PORT}`);
});

async function shutdown(signal: string) {
  console.log(`Received ${signal}, shutting down audit service`);

  try {
    await dbPool?.end();
  } catch (error) {
    console.error("Failed to close DB pool cleanly:", error);
  }

  server.close(() => {
    process.exit(0);
  });
}

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    void shutdown(signal);
  });
}
