import React, { useEffect, useState } from "react";

interface DroneDetail {
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

interface Props {
  selectedDrone: string | null;
}

const DroneTracker: React.FC<Props> = ({ selectedDrone }) => {
  const [drone, setDrone] = useState<DroneDetail | null>(null);
  const [history, setHistory] = useState<
    { lat: number; lng: number; alt: number; ts: string }[]
  >([]);

  useEffect(() => {
    if (!selectedDrone) {
      setDrone(null);
      setHistory([]);
      return;
    }

    const poll = async () => {
      try {
        const r = await fetch(`/v1/drones/${selectedDrone}`);
        if (r.ok) {
          const d = await r.json();
          setDrone(d);
          setHistory((prev) => {
            const next = [
              ...prev,
              {
                lat: d.position.lat,
                lng: d.position.lng,
                alt: d.position.alt,
                ts: d.lastTelemetry,
              },
            ];
            return next.slice(-60); // Keep last 60 positions
          });
        }
      } catch {
        /* retry */
      }
    };
    poll();
    const iv = setInterval(poll, 1500);
    return () => clearInterval(iv);
  }, [selectedDrone]);

  if (!drone) {
    return (
      <div className="cr-tracker cr-tracker--empty">
        <div className="cr-tracker__placeholder">
          <span className="cr-tracker__placeholder-icon">🎯</span>
          <span>Select a drone to track</span>
        </div>
      </div>
    );
  }

  const headingArrow = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"][
    Math.round(drone.heading / 45) % 8
  ];

  return (
    <div className="cr-tracker">
      <div className="cr-tracker__header">
        <span className="cr-tracker__callsign">{drone.callsign}</span>
        <span className="cr-tracker__type">{drone.type.toUpperCase()}</span>
        <span
          className="cr-tracker__status"
          style={{
            color:
              drone.status === "airborne"
                ? "#00FF88"
                : drone.status === "returning"
                  ? "#FFD700"
                  : "#8899AA",
          }}
        >
          {drone.status.toUpperCase()}
        </span>
      </div>

      <div className="cr-tracker__telemetry">
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">LAT</span>
          <span className="cr-tracker__value cr-tracker__value--coord">
            {drone.position.lat.toFixed(6)}
          </span>
        </div>
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">LNG</span>
          <span className="cr-tracker__value cr-tracker__value--coord">
            {drone.position.lng.toFixed(6)}
          </span>
        </div>
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">ALT</span>
          <span className="cr-tracker__value">
            {drone.position.alt}
            <span className="cr-tracker__unit">m</span>
          </span>
        </div>
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">SPD</span>
          <span className="cr-tracker__value">
            {drone.speed}
            <span className="cr-tracker__unit">m/s</span>
          </span>
        </div>
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">HDG</span>
          <span className="cr-tracker__value">
            {headingArrow} {drone.heading}°
          </span>
        </div>
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">BAT</span>
          <span
            className="cr-tracker__value"
            style={{
              color:
                drone.battery < 20
                  ? "#FF3366"
                  : drone.battery < 40
                    ? "#FFD700"
                    : "#00FF88",
            }}
          >
            {drone.battery}%
          </span>
        </div>
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">SIG</span>
          <span
            className="cr-tracker__value"
            style={{ color: drone.signalStrength > 60 ? "#00FF88" : "#FF3366" }}
          >
            {drone.signalStrength}%
          </span>
        </div>
        <div className="cr-tracker__row">
          <span className="cr-tracker__label">CAM</span>
          <span
            className="cr-tracker__value"
            style={{ color: drone.camera ? "#00FF88" : "#FF3366" }}
          >
            {drone.camera ? "ACTIVE" : "OFF"}
          </span>
        </div>
      </div>

      {/* Compass indicator */}
      <div className="cr-tracker__compass">
        <svg viewBox="0 0 80 80" width={80} height={80}>
          <circle
            cx={40}
            cy={40}
            r={36}
            fill="none"
            stroke="rgba(0,245,255,0.15)"
            strokeWidth={1}
          />
          <circle
            cx={40}
            cy={40}
            r={24}
            fill="none"
            stroke="rgba(0,245,255,0.1)"
            strokeWidth={1}
          />
          {/* N/S/E/W labels */}
          <text
            x={40}
            y={10}
            textAnchor="middle"
            fill="#00F5FF"
            fontSize={8}
            fontFamily="JetBrains Mono"
          >
            N
          </text>
          <text
            x={40}
            y={76}
            textAnchor="middle"
            fill="#8899AA"
            fontSize={8}
            fontFamily="JetBrains Mono"
          >
            S
          </text>
          <text
            x={74}
            y={43}
            textAnchor="middle"
            fill="#8899AA"
            fontSize={8}
            fontFamily="JetBrains Mono"
          >
            E
          </text>
          <text
            x={6}
            y={43}
            textAnchor="middle"
            fill="#8899AA"
            fontSize={8}
            fontFamily="JetBrains Mono"
          >
            W
          </text>
          {/* Heading needle */}
          <line
            x1={40}
            y1={40}
            x2={40 + Math.sin((drone.heading * Math.PI) / 180) * 28}
            y2={40 - Math.cos((drone.heading * Math.PI) / 180) * 28}
            stroke="#FF00FF"
            strokeWidth={2}
            strokeLinecap="round"
          />
          <circle cx={40} cy={40} r={3} fill="#FF00FF" />
        </svg>
      </div>

      {/* Position trail */}
      {history.length > 2 && (
        <div className="cr-tracker__trail">
          <span className="cr-tracker__trail-label">
            Trail ({history.length} pts)
          </span>
          <svg viewBox="0 0 200 40" className="cr-tracker__trail-svg">
            <polyline
              points={history
                .map((h, i) => {
                  const x = (i / (history.length - 1)) * 200;
                  const minAlt = Math.min(...history.map((p) => p.alt));
                  const maxAlt = Math.max(...history.map((p) => p.alt)) || 1;
                  const range = maxAlt - minAlt || 1;
                  const y = 38 - ((h.alt - minAlt) / range) * 36;
                  return `${x},${y}`;
                })
                .join(" ")}
              fill="none"
              stroke="#00F5FF"
              strokeWidth={1.5}
            />
          </svg>
        </div>
      )}

      <div className="cr-tracker__updated">
        Last: {new Date(drone.lastTelemetry).toLocaleTimeString()}
      </div>
    </div>
  );
};

export default DroneTracker;
