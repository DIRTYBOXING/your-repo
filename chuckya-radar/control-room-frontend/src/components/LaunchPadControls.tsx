import React, { useEffect, useState } from "react";

interface Drone {
  droneId: string;
  callsign: string;
  status: string;
  battery: number;
  assignedPad: string | null;
}

interface LaunchPad {
  padId: string;
  name: string;
  status: string;
  position: { lat: number; lng: number; alt: number };
  assignedDrone: string | null;
  launchCount: number;
}

const PAD_STATUS_COLORS: Record<string, string> = {
  ready: "#00FF88",
  occupied: "#00F5FF",
  launching: "#FF00FF",
  recovering: "#FFD700",
  offline: "#FF3366",
  maintenance: "#8899AA",
};

const COMMANDS = [
  {
    id: "launch",
    label: "LAUNCH",
    icon: "🚀",
    color: "#00FF88",
    requiresGrounded: true,
  },
  {
    id: "land",
    label: "LAND",
    icon: "⬇",
    color: "#FFD700",
    requiresAirborne: true,
  },
  {
    id: "rth",
    label: "RTH",
    icon: "🏠",
    color: "#FF6B35",
    requiresAirborne: true,
  },
  {
    id: "hover",
    label: "HOVER",
    icon: "⏸",
    color: "#00F5FF",
    requiresAirborne: true,
  },
  {
    id: "search_pattern",
    label: "SEARCH",
    icon: "🔍",
    color: "#FF00FF",
    requiresAirborne: true,
  },
  {
    id: "orbit",
    label: "ORBIT",
    icon: "⭕",
    color: "#FFD700",
    requiresAirborne: true,
  },
  { id: "camera_on", label: "CAM ON", icon: "📷", color: "#00FF88" },
  { id: "camera_off", label: "CAM OFF", icon: "📷", color: "#8899AA" },
  { id: "spotlight", label: "LIGHT", icon: "💡", color: "#FFD700" },
  { id: "abort", label: "ABORT", icon: "🛑", color: "#FF3366" },
] as const;

interface Props {
  selectedDrone?: string | null;
}

const LaunchPadControls: React.FC<Props> = ({ selectedDrone }) => {
  const [pads, setPads] = useState<LaunchPad[]>([]);
  const [drones, setDrones] = useState<Drone[]>([]);
  const [lastCmd, setLastCmd] = useState<string | null>(null);
  const [cmdStatus, setCmdStatus] = useState<
    "idle" | "sending" | "ok" | "error"
  >("idle");

  useEffect(() => {
    const poll = async () => {
      try {
        const [pRes, dRes] = await Promise.all([
          fetch("/v1/launchpads"),
          fetch("/v1/drones"),
        ]);
        if (pRes.ok) setPads((await pRes.json()).pads || []);
        if (dRes.ok) setDrones((await dRes.json()).drones || []);
      } catch {
        /* retry */
      }
    };
    poll();
    const iv = setInterval(poll, 3000);
    return () => clearInterval(iv);
  }, []);

  const activeDrone = drones.find((d) => d.droneId === selectedDrone) || null;

  const sendCommand = async (cmd: string) => {
    if (!activeDrone) return;
    setCmdStatus("sending");
    setLastCmd(cmd);
    try {
      const body: Record<string, unknown> = {
        command: cmd,
        issuedBy: "control-room",
      };
      if (cmd === "launch") body.targetAlt = 50;
      if (cmd === "search_pattern") body.pattern = "expanding_square";
      if (cmd === "orbit") body.radius = 100;

      const r = await fetch(`/v1/drones/${activeDrone.droneId}/command`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      setCmdStatus(r.ok ? "ok" : "error");
    } catch {
      setCmdStatus("error");
    }
    setTimeout(() => setCmdStatus("idle"), 2000);
  };

  return (
    <div className="cr-launchpad">
      {/* Launch Pads Grid */}
      <div className="cr-launchpad__pads">
        <div className="cr-launchpad__pads-title">Launch Pads</div>
        <div className="cr-launchpad__pad-grid">
          {pads.map((p) => (
            <div
              key={p.padId}
              className="cr-launchpad__pad"
              style={{ borderColor: PAD_STATUS_COLORS[p.status] || "#8899AA" }}
            >
              <div className="cr-launchpad__pad-name">{p.name}</div>
              <div
                className="cr-launchpad__pad-status"
                style={{ color: PAD_STATUS_COLORS[p.status] }}
              >
                {p.status.toUpperCase()}
              </div>
              <div className="cr-launchpad__pad-drone">
                {p.assignedDrone || "EMPTY"}
              </div>
              <div className="cr-launchpad__pad-launches">×{p.launchCount}</div>
            </div>
          ))}
          {pads.length === 0 && (
            <div className="cr-launchpad__no-pads">No pads registered</div>
          )}
        </div>
      </div>

      {/* Command Section */}
      <div className="cr-launchpad__commands">
        <div className="cr-launchpad__target">
          {activeDrone ? (
            <>
              <span className="cr-launchpad__target-label">TARGET:</span>
              <span className="cr-launchpad__target-name">
                {activeDrone.callsign}
              </span>
              <span
                className="cr-launchpad__target-status"
                style={{
                  color:
                    activeDrone.status === "airborne" ? "#00FF88" : "#8899AA",
                }}
              >
                [{activeDrone.status.toUpperCase()}]
              </span>
              <span
                className="cr-launchpad__target-bat"
                style={{
                  color: activeDrone.battery < 20 ? "#FF3366" : "#00FF88",
                }}
              >
                🔋{activeDrone.battery}%
              </span>
            </>
          ) : (
            <span className="cr-launchpad__target-none">
              Select a drone from fleet
            </span>
          )}
        </div>

        <div className="cr-launchpad__cmd-grid">
          {COMMANDS.map((cmd) => {
            const disabled =
              !activeDrone ||
              (cmd.requiresGrounded &&
                activeDrone.status !== "grounded" &&
                activeDrone.status !== "preflight") ||
              (cmd.requiresAirborne && activeDrone.status !== "airborne");

            return (
              <button
                key={cmd.id}
                className={`cr-launchpad__cmd ${disabled ? "cr-launchpad__cmd--disabled" : ""}`}
                style={{
                  borderColor: disabled ? "#333" : cmd.color,
                  color: disabled ? "#555" : cmd.color,
                }}
                onClick={() => !disabled && sendCommand(cmd.id)}
                disabled={disabled}
              >
                <span className="cr-launchpad__cmd-icon">{cmd.icon}</span>
                <span className="cr-launchpad__cmd-label">{cmd.label}</span>
              </button>
            );
          })}
        </div>

        {lastCmd && (
          <div
            className={`cr-launchpad__feedback cr-launchpad__feedback--${cmdStatus}`}
          >
            {cmdStatus === "sending" && `Sending ${lastCmd.toUpperCase()}...`}
            {cmdStatus === "ok" && `✓ ${lastCmd.toUpperCase()} sent`}
            {cmdStatus === "error" && `✗ ${lastCmd.toUpperCase()} failed`}
          </div>
        )}
      </div>
    </div>
  );
};

export default LaunchPadControls;
