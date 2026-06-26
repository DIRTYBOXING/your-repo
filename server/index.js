const express = require("express");
const http = require("http");
const api = require("./apiStubs");
const internalRouter = require("./internalRoutes");
const { init } = require("./wsServer");
const { metricsApp } = require("./monitoring/server/metrics");
const { healthHandler, livenessHandler } = require("./health");

const app = express();
app.use("/api", api);
app.use("/internal", internalRouter);

// Platform heartbeat — the cockpit
app.get("/health", healthHandler);
app.get("/health/live", livenessHandler);

// mount metrics on same server under /metrics
app.use(metricsApp);

const server = http.createServer(app);
init(server);

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => console.log("control API listening", PORT));
