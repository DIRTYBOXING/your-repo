/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  DFC CHUCKYA — Drone Fleet & Detection Control Module       ║
 * ║  Launch pad ops, drone telemetry, phone/GPS/ping detection  ║
 * ║  Designed for real-time tracking & signal triangulation      ║
 * ╚══════════════════════════════════════════════════════════════╝
 *
 * Usage:  const { mountDroneRoutes } = require('./drone_control');
 *         mountDroneRoutes(app);
 */
"use strict";

const { v4: uuidv4 } = require("uuid");

// ─── In-memory stores ───
const drones = {};
const launchPads = {};
const detections = {};
const missions = {};
const droneCommands = {}; // command queue per drone

// ─── Allowed enums ───
const DRONE_STATUSES = [
  "grounded",
  "preflight",
  "launching",
  "airborne",
  "returning",
  "landing",
  "charging",
  "maintenance",
  "lost",
];
const DRONE_TYPES = ["recon", "tracker", "interceptor", "relay", "survey"];
const PAD_STATUSES = [
  "ready",
  "occupied",
  "launching",
  "recovering",
  "offline",
  "maintenance",
];
const DETECTION_TYPES = [
  "phone_ping",
  "gps_signal",
  "bluetooth",
  "wifi_probe",
  "rf_emission",
  "imsi_catch",
  "acoustic",
];
const MISSION_TYPES = [
  "search_grid",
  "track_target",
  "perimeter_patrol",
  "signal_hunt",
  "overwatch",
  "intercept",
  "relay_extend",
];
const COMMAND_TYPES = [
  "launch",
  "land",
  "rth",
  "hover",
  "waypoint",
  "orbit",
  "track_signal",
  "search_pattern",
  "altitude",
  "speed",
  "camera_on",
  "camera_off",
  "spotlight",
  "abort",
];

function clamp(v, min, max) {
  return Math.max(min, Math.min(max, Number(v) || min));
}
function validId(id) {
  return typeof id === "string" && /^[a-zA-Z0-9_-]{1,64}$/.test(id);
}

function mountDroneRoutes(app) {
  // ═══════════════════════════════════════════════════════════
  //  DRONE FLEET MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  /** Register a new drone */
  app.post("/v1/drones/register", (req, res) => {
    const b = req.body;
    const id = validId(b.droneId) ? b.droneId : `DRN-${Date.now()}`;
    if (drones[id])
      return res.status(409).json({ error: "drone already registered" });

    drones[id] = {
      droneId: id,
      callsign: String(b.callsign || id).slice(0, 32),
      type: DRONE_TYPES.includes(b.type) ? b.type : "recon",
      status: "grounded",
      battery: clamp(b.battery, 0, 100),
      position: {
        lat: clamp(b.lat, -90, 90),
        lng: clamp(b.lng, -180, 180),
        alt: clamp(b.alt, 0, 15000),
      },
      heading: clamp(b.heading, 0, 359),
      speed: 0,
      assignedPad: b.padId || null,
      assignedMission: null,
      camera: false,
      signalStrength: 100,
      lastTelemetry: new Date().toISOString(),
      registeredAt: new Date().toISOString(),
    };

    res.json({ status: "registered", drone: drones[id] });
  });

  /** List all drones */
  app.get("/v1/drones", (_req, res) => {
    res.json({ drones: Object.values(drones) });
  });

  /** Get single drone */
  app.get("/v1/drones/:id", (req, res) => {
    const d = drones[req.params.id];
    if (!d) return res.status(404).json({ error: "drone not found" });
    res.json(d);
  });

  /** Telemetry ingest (from drone or relay) */
  app.post("/v1/drones/:id/telemetry", (req, res) => {
    const d = drones[req.params.id];
    if (!d) return res.status(404).json({ error: "drone not found" });
    const b = req.body;

    if (b.lat !== undefined) d.position.lat = clamp(b.lat, -90, 90);
    if (b.lng !== undefined) d.position.lng = clamp(b.lng, -180, 180);
    if (b.alt !== undefined) d.position.alt = clamp(b.alt, 0, 15000);
    if (b.heading !== undefined) d.heading = clamp(b.heading, 0, 359);
    if (b.speed !== undefined) d.speed = clamp(b.speed, 0, 200);
    if (b.battery !== undefined) d.battery = clamp(b.battery, 0, 100);
    if (b.signalStrength !== undefined)
      d.signalStrength = clamp(b.signalStrength, 0, 100);
    if (DRONE_STATUSES.includes(b.status)) d.status = b.status;
    if (typeof b.camera === "boolean") d.camera = b.camera;
    d.lastTelemetry = new Date().toISOString();

    res.json({ status: "telemetry_updated", drone: d });
  });

  // ═══════════════════════════════════════════════════════════
  //  LAUNCH PAD CONTROLS
  // ═══════════════════════════════════════════════════════════

  /** Register a launch pad */
  app.post("/v1/launchpads/register", (req, res) => {
    const b = req.body;
    const id = validId(b.padId) ? b.padId : `PAD-${Date.now()}`;
    if (launchPads[id])
      return res.status(409).json({ error: "pad already registered" });

    launchPads[id] = {
      padId: id,
      name: String(b.name || `Pad ${id}`).slice(0, 64),
      status: "ready",
      position: {
        lat: clamp(b.lat, -90, 90),
        lng: clamp(b.lng, -180, 180),
        alt: clamp(b.alt, 0, 5000),
      },
      assignedDrone: null,
      lastActivity: new Date().toISOString(),
      launchCount: 0,
    };

    res.json({ status: "registered", pad: launchPads[id] });
  });

  /** List all launch pads */
  app.get("/v1/launchpads", (_req, res) => {
    res.json({ pads: Object.values(launchPads) });
  });

  /** Assign a drone to a pad */
  app.post("/v1/launchpads/:padId/assign", (req, res) => {
    const pad = launchPads[req.params.padId];
    if (!pad) return res.status(404).json({ error: "pad not found" });
    const drone = drones[req.body.droneId];
    if (!drone) return res.status(404).json({ error: "drone not found" });

    pad.assignedDrone = drone.droneId;
    pad.status = "occupied";
    drone.assignedPad = pad.padId;
    pad.lastActivity = new Date().toISOString();

    res.json({ status: "assigned", pad, drone });
  });

  // ═══════════════════════════════════════════════════════════
  //  DRONE COMMAND SYSTEM
  // ═══════════════════════════════════════════════════════════

  /** Send command to a drone */
  app.post("/v1/drones/:id/command", (req, res) => {
    const d = drones[req.params.id];
    if (!d) return res.status(404).json({ error: "drone not found" });
    const b = req.body;

    const cmdType = COMMAND_TYPES.includes(b.command) ? b.command : null;
    if (!cmdType)
      return res.status(400).json({
        error: `invalid command. allowed: ${COMMAND_TYPES.join(", ")}`,
      });

    const cmd = {
      commandId: uuidv4(),
      droneId: d.droneId,
      command: cmdType,
      params: {},
      issuedAt: new Date().toISOString(),
      issuedBy: String(b.issuedBy || req.ip || "operator").slice(0, 64),
      status: "pending",
    };

    // Command-specific params
    switch (cmdType) {
      case "launch":
        if (d.status !== "grounded" && d.status !== "preflight") {
          return res
            .status(400)
            .json({ error: "drone must be grounded to launch" });
        }
        d.status = "preflight";
        cmd.params.targetAlt = clamp(b.targetAlt || 50, 5, 500);
        // Update pad status
        if (d.assignedPad && launchPads[d.assignedPad]) {
          launchPads[d.assignedPad].status = "launching";
          launchPads[d.assignedPad].launchCount++;
        }
        break;
      case "land":
        d.status = "landing";
        cmd.params.padId = b.padId || d.assignedPad || null;
        if (cmd.params.padId && launchPads[cmd.params.padId]) {
          launchPads[cmd.params.padId].status = "recovering";
        }
        break;
      case "rth":
        d.status = "returning";
        cmd.params.returnPad = d.assignedPad || null;
        break;
      case "hover":
        cmd.params.duration = clamp(b.duration || 0, 0, 3600);
        break;
      case "waypoint":
        cmd.params.lat = clamp(b.lat, -90, 90);
        cmd.params.lng = clamp(b.lng, -180, 180);
        cmd.params.alt = clamp(b.alt || d.position.alt, 5, 500);
        cmd.params.speed = clamp(b.speed || 10, 1, 100);
        break;
      case "orbit":
        cmd.params.lat = clamp(b.lat, -90, 90);
        cmd.params.lng = clamp(b.lng, -180, 180);
        cmd.params.radius = clamp(b.radius || 50, 10, 500);
        cmd.params.alt = clamp(b.alt || d.position.alt, 5, 500);
        break;
      case "track_signal":
        cmd.params.detectionId = b.detectionId || null;
        cmd.params.signalType = DETECTION_TYPES.includes(b.signalType)
          ? b.signalType
          : "phone_ping";
        break;
      case "search_pattern":
        cmd.params.pattern = [
          "grid",
          "spiral",
          "expanding_square",
          "sector",
        ].includes(b.pattern)
          ? b.pattern
          : "grid";
        cmd.params.centerLat = clamp(b.centerLat || d.position.lat, -90, 90);
        cmd.params.centerLng = clamp(b.centerLng || d.position.lng, -180, 180);
        cmd.params.radius = clamp(b.radius || 200, 50, 2000);
        cmd.params.alt = clamp(b.alt || 30, 5, 200);
        break;
      case "altitude":
        cmd.params.alt = clamp(b.alt, 5, 500);
        break;
      case "speed":
        cmd.params.speed = clamp(b.speed, 0, 100);
        break;
      case "camera_on":
        d.camera = true;
        break;
      case "camera_off":
        d.camera = false;
        break;
      case "spotlight":
        cmd.params.on = b.on !== false;
        break;
      case "abort":
        d.status = "returning";
        break;
    }

    // Queue command
    if (!droneCommands[d.droneId]) droneCommands[d.droneId] = [];
    droneCommands[d.droneId].push(cmd);

    res.json({ status: "command_sent", command: cmd });
  });

  /** Get pending commands for a drone (polled by drone firmware) */
  app.get("/v1/drones/:id/commands", (req, res) => {
    const queue = droneCommands[req.params.id] || [];
    const pending = queue.filter((c) => c.status === "pending");
    res.json({ commands: pending });
  });

  /** Acknowledge command execution */
  app.post("/v1/drones/:id/commands/:cmdId/ack", (req, res) => {
    const queue = droneCommands[req.params.id] || [];
    const cmd = queue.find((c) => c.commandId === req.params.cmdId);
    if (!cmd) return res.status(404).json({ error: "command not found" });
    cmd.status = req.body.success === false ? "failed" : "executed";
    cmd.executedAt = new Date().toISOString();
    res.json({ status: "acknowledged", command: cmd });
  });

  // ═══════════════════════════════════════════════════════════
  //  DETECTION SYSTEM (phone pings, GPS, RF, Bluetooth, Wi-Fi)
  // ═══════════════════════════════════════════════════════════

  /** Ingest a detection event */
  app.post("/v1/detections", (req, res) => {
    const b = req.body;
    const type = DETECTION_TYPES.includes(b.type) ? b.type : "phone_ping";

    const id = `DET-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    const det = {
      detectionId: id,
      type,
      timestamp: new Date().toISOString(),
      source: {
        droneId: validId(b.droneId) ? b.droneId : null,
        sensorId:
          typeof b.sensorId === "string" ? b.sensorId.slice(0, 64) : null,
        type: b.sensorType || "onboard",
      },
      signal: {
        strength: clamp(b.strength || b.rssi, -150, 0), // dBm
        frequency: b.frequency ? clamp(b.frequency, 0, 60000) : null, // MHz
        channel: typeof b.channel === "string" ? b.channel.slice(0, 32) : null,
        ssid: typeof b.ssid === "string" ? b.ssid.slice(0, 64) : null,
        mac: typeof b.mac === "string" ? b.mac.slice(0, 17) : null,
        imsi: typeof b.imsi === "string" ? b.imsi.slice(0, 15) : null,
        phoneNumber: null, // never store raw — privacy
      },
      position: {
        lat: b.lat ? clamp(b.lat, -90, 90) : null,
        lng: b.lng ? clamp(b.lng, -180, 180) : null,
        alt: b.alt ? clamp(b.alt, 0, 15000) : null,
        accuracy: b.accuracy ? clamp(b.accuracy, 0, 1000) : null, // metres
        bearing: b.bearing ? clamp(b.bearing, 0, 359) : null,
      },
      // Triangulation data — multiple bearing lines converge
      bearings: Array.isArray(b.bearings)
        ? b.bearings.slice(0, 10).map((brg) => ({
            sensorLat: clamp(brg.lat, -90, 90),
            sensorLng: clamp(brg.lng, -180, 180),
            bearing: clamp(brg.bearing, 0, 359),
            strength: clamp(brg.strength, -150, 0),
          }))
        : [],
      confidence: clamp(b.confidence || 50, 0, 100),
      tracked: false,
      assignedDrone: null,
      status: "new", // new, tracking, lost, confirmed, dismissed
    };

    detections[id] = det;
    res.json({ status: "detection_logged", detection: det });
  });

  /** List detections */
  app.get("/v1/detections", (req, res) => {
    let list = Object.values(detections);
    // Filter by type
    if (req.query.type && DETECTION_TYPES.includes(req.query.type)) {
      list = list.filter((d) => d.type === req.query.type);
    }
    // Filter by status
    if (req.query.status) {
      list = list.filter((d) => d.status === req.query.status);
    }
    list.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    res.json({ detections: list.slice(0, 200) });
  });

  /** Get single detection */
  app.get("/v1/detections/:id", (req, res) => {
    const d = detections[req.params.id];
    if (!d) return res.status(404).json({ error: "detection not found" });
    res.json(d);
  });

  /** Assign a drone to track a detection */
  app.post("/v1/detections/:id/track", (req, res) => {
    const det = detections[req.params.id];
    if (!det) return res.status(404).json({ error: "detection not found" });
    const drone = drones[req.body.droneId];
    if (!drone) return res.status(404).json({ error: "drone not found" });

    det.tracked = true;
    det.assignedDrone = drone.droneId;
    det.status = "tracking";

    // Auto-send track command to drone
    const cmd = {
      commandId: uuidv4(),
      droneId: drone.droneId,
      command: "track_signal",
      params: {
        detectionId: det.detectionId,
        signalType: det.type,
        targetLat: det.position.lat,
        targetLng: det.position.lng,
      },
      issuedAt: new Date().toISOString(),
      issuedBy: "detection-system",
      status: "pending",
    };
    if (!droneCommands[drone.droneId]) droneCommands[drone.droneId] = [];
    droneCommands[drone.droneId].push(cmd);

    res.json({ status: "tracking_assigned", detection: det, command: cmd });
  });

  /** Update detection status */
  app.patch("/v1/detections/:id", (req, res) => {
    const det = detections[req.params.id];
    if (!det) return res.status(404).json({ error: "detection not found" });

    const allowed = ["new", "tracking", "lost", "confirmed", "dismissed"];
    if (req.body.status && allowed.includes(req.body.status))
      det.status = req.body.status;
    if (req.body.lat !== undefined)
      det.position.lat = clamp(req.body.lat, -90, 90);
    if (req.body.lng !== undefined)
      det.position.lng = clamp(req.body.lng, -180, 180);
    if (req.body.confidence !== undefined)
      det.confidence = clamp(req.body.confidence, 0, 100);

    res.json({ status: "updated", detection: det });
  });

  // ═══════════════════════════════════════════════════════════
  //  MISSION PLANNING
  // ═══════════════════════════════════════════════════════════

  /** Create a mission */
  app.post("/v1/missions", (req, res) => {
    const b = req.body;
    const id = `MSN-${Date.now()}`;
    const m = {
      missionId: id,
      type: MISSION_TYPES.includes(b.type) ? b.type : "search_grid",
      status: "planned", // planned, active, paused, completed, aborted
      assignedDrones: [],
      area: {
        centerLat: clamp(b.centerLat, -90, 90),
        centerLng: clamp(b.centerLng, -180, 180),
        radius: clamp(b.radius || 500, 50, 10000),
      },
      waypoints: Array.isArray(b.waypoints)
        ? b.waypoints.slice(0, 50).map((w) => ({
            lat: clamp(w.lat, -90, 90),
            lng: clamp(w.lng, -180, 180),
            alt: clamp(w.alt || 30, 5, 500),
            action: w.action || "flyover",
          }))
        : [],
      detectionTarget: b.detectionId || null,
      createdAt: new Date().toISOString(),
      createdBy: String(b.createdBy || req.ip || "operator").slice(0, 64),
      startedAt: null,
      completedAt: null,
      detectionsFound: 0,
    };

    missions[id] = m;
    res.json({ status: "mission_created", mission: m });
  });

  /** List missions */
  app.get("/v1/missions", (_req, res) => {
    res.json({ missions: Object.values(missions) });
  });

  /** Start a mission — assign drones and dispatch */
  app.post("/v1/missions/:id/start", (req, res) => {
    const m = missions[req.params.id];
    if (!m) return res.status(404).json({ error: "mission not found" });
    if (m.status === "active")
      return res.status(400).json({ error: "already active" });

    const droneIds = Array.isArray(req.body.droneIds) ? req.body.droneIds : [];
    const assigned = [];
    for (const did of droneIds) {
      if (
        drones[did] &&
        (drones[did].status === "grounded" || drones[did].status === "airborne")
      ) {
        drones[did].assignedMission = m.missionId;
        assigned.push(did);
      }
    }

    m.assignedDrones = assigned;
    m.status = "active";
    m.startedAt = new Date().toISOString();

    res.json({ status: "mission_started", mission: m });
  });

  /** Abort a mission */
  app.post("/v1/missions/:id/abort", (req, res) => {
    const m = missions[req.params.id];
    if (!m) return res.status(404).json({ error: "mission not found" });

    m.status = "aborted";
    m.completedAt = new Date().toISOString();

    // RTH all assigned drones
    for (const did of m.assignedDrones) {
      if (drones[did]) {
        drones[did].status = "returning";
        drones[did].assignedMission = null;
      }
    }

    res.json({ status: "mission_aborted", mission: m });
  });

  // ═══════════════════════════════════════════════════════════
  //  AGGREGATE STATS FOR DASHBOARD
  // ═══════════════════════════════════════════════════════════

  app.get("/v1/control/stats", (_req, res) => {
    const droneList = Object.values(drones);
    const detList = Object.values(detections);
    const msnList = Object.values(missions);

    res.json({
      drones: {
        total: droneList.length,
        airborne: droneList.filter((d) => d.status === "airborne").length,
        grounded: droneList.filter((d) => d.status === "grounded").length,
        returning: droneList.filter((d) => d.status === "returning").length,
        lowBattery: droneList.filter((d) => d.battery < 20).length,
        lostSignal: droneList.filter((d) => d.status === "lost").length,
      },
      detections: {
        total: detList.length,
        phonePings: detList.filter((d) => d.type === "phone_ping").length,
        gpsSignals: detList.filter((d) => d.type === "gps_signal").length,
        bluetooth: detList.filter((d) => d.type === "bluetooth").length,
        wifi: detList.filter((d) => d.type === "wifi_probe").length,
        rfEmissions: detList.filter((d) => d.type === "rf_emission").length,
        tracking: detList.filter((d) => d.status === "tracking").length,
        confirmed: detList.filter((d) => d.status === "confirmed").length,
      },
      missions: {
        total: msnList.length,
        active: msnList.filter((m) => m.status === "active").length,
        planned: msnList.filter((m) => m.status === "planned").length,
        completed: msnList.filter((m) => m.status === "completed").length,
      },
      pads: {
        total: Object.keys(launchPads).length,
        ready: Object.values(launchPads).filter((p) => p.status === "ready")
          .length,
        occupied: Object.values(launchPads).filter(
          (p) => p.status === "occupied",
        ).length,
      },
    });
  });
}

module.exports = { mountDroneRoutes };
