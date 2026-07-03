import React, { useEffect, useState } from "react";

interface Drone {
  droneId: string;
  callsign: string;
  type: string;
  status: string;
  battery: number;
  position: { lat: number; lng: number; alt: number };
  heading: number;
  speed: number;
  assignedMission: string | null;
  camera: boolean;
  signalStrength: number;
  lastTelemetry: string;
}

const STATUS_COLORS: Record<string, string> = {
  airborne: "#00FF88",
  returning: "#FFD700",
  grounded: "#8899AA",
  preflight: "#00F5FF",
  launching: "#FF00FF",
  landing: "#FFB347",
  charging: "#FF6B35",
  maintenance: "#8899AA",
  lost: "#FF3366",
};

const TYPE_ICONS: Record<string, string> = {
  recon: "🔍",
  tracker: "📡",
  interceptor: "⚡",
  relay: "🔗",
  survey: "🗺️",
};

interface Props {
  onSelectDrone?: (droneId: string) => void;
  selectedDrone?: string | null;
}

const DroneFleet: React.FC<Props> = ({ onSelectDrone, selectedDrone }) => {
  const [drones, setDrones] = useState<Drone[]>([]);

  useEffect(() => {
    const poll = async () => {
      try {
        const r = await fetch("/v1/drones");
        if (r.ok) {
          const data = await r.json();
          setDrones(data.drones || []);
        }
      } catch {
        /* retry next tick */
      }
    };
    poll();
    const iv = setInterval(poll, 2000);
    return () => clearInterval(iv);
  }, []);

  const getBatteryColor = (pct: number) => {
    if (pct > 60) return "#00FF88";
    if (pct > 30) return "#FFD700";
    if (pct > 15) return "#FF6B35";
    return "#FF3366";
  };

  const airborne = drones.filter((d) => d.status === "airborne").length;
  const grounded = drones.filter((d) => d.status === "grounded").length;
  const lowBat = drones.filter((d) => d.battery < 20).length;

  return (
    <div className="cr-drones">
      <div className="cr-drones__summary">
        <span className="cr-drones__stat" style={{ color: "#00FF88" }}>
          ▲ {airborne} airborne
        </span>
        <span className="cr-drones__stat" style={{ color: "#8899AA" }}>
          ▼ {grounded} grnd
        </span>
        {lowBat > 0 && (
          <span className="cr-drones__stat" style={{ color: "#FF3366" }}>
            ⚠ {lowBat} low bat
          </span>
        )}
        <span className="cr-drones__count">{drones.length} total</span>
      </div>
      <table className="cr-drones__table">
        <thead>
          <tr>
            <th>Status</th>
            <th>Callsign</th>
            <th>Type</th>
            <th>Battery</th>
            <th>Alt</th>
            <th>Speed</th>
            <th>Signal</th>
            <th>Mission</th>
          </tr>
        </thead>
        <tbody>
          {drones.map((d) => (
            <tr
              key={d.droneId}
              className={`cr-drones__row ${selectedDrone === d.droneId ? "cr-drones__row--sel" : ""}`}
              onClick={() => onSelectDrone?.(d.droneId)}
            >
              <td>
                <span
                  className="cr-fleet__dot"
                  style={{
                    backgroundColor: STATUS_COLORS[d.status] || "#8899AA",
                  }}
                />
                {d.status.toUpperCase()}
              </td>
              <td className="cr-drones__callsign">{d.callsign}</td>
              <td>
                {TYPE_ICONS[d.type] || "•"} {d.type}
              </td>
              <td>
                <div className="cr-drones__battery">
                  <div
                    className="cr-drones__battery-fill"
                    style={{
                      width: `${d.battery}%`,
                      backgroundColor: getBatteryColor(d.battery),
                    }}
                  />
                  <span className="cr-drones__battery-text">{d.battery}%</span>
                </div>
              </td>
              <td>{d.position.alt}m</td>
              <td>{d.speed} m/s</td>
              <td
                style={{
                  color:
                    d.signalStrength > 60
                      ? "#00FF88"
                      : d.signalStrength > 30
                        ? "#FFD700"
                        : "#FF3366",
                }}
              >
                {d.signalStrength}%
              </td>
              <td className="cr-drones__mission">
                {d.assignedMission || "—"}
                {d.camera && <span className="cr-drones__cam">📷</span>}
              </td>
            </tr>
          ))}
          {drones.length === 0 && (
            <tr>
              <td colSpan={8} style={{ textAlign: "center", opacity: 0.5 }}>
                No drones registered — POST /v1/drones/register to add
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};

export default DroneFleet;
