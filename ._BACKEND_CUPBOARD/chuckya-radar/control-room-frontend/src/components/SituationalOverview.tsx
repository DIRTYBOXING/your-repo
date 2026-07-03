import React, { useEffect, useRef, useState } from "react";
import { useWebSocket } from "../hooks/useWebSocket";

interface Alert {
  id: string;
  mode: string;
  riskScore: number;
  lat?: number;
  lng?: number;
  ts: string;
  deviceId?: string;
  description?: string;
}

const MODE_COLORS: Record<string, string> = {
  code_black: "#FF3366",
  code_red: "#FF6B35",
  code_amber: "#FFB347",
  code_yellow: "#FFD700",
};

const WS_URL =
  import.meta.env.VITE_WS_URL || `ws://${window.location.hostname}:8081/ws`;

const SituationalOverview: React.FC = () => {
  const { messages, connected } = useWebSocket(WS_URL);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const mapRef = useRef<HTMLDivElement>(null);

  // Fetch initial alerts
  useEffect(() => {
    fetch("/v1/radar/alerts")
      .then((r) => r.json())
      .then((data) => {
        if (Array.isArray(data.alerts)) setAlerts(data.alerts);
        else if (Array.isArray(data)) setAlerts(data);
      })
      .catch(() => {});
  }, []);

  // Merge WebSocket alerts
  useEffect(() => {
    for (const msg of messages) {
      if (msg.type === "alert" && msg.payload) {
        const a = msg.payload as Alert;
        setAlerts((prev) => {
          if (prev.some((p) => p.id === a.id)) return prev;
          return [a, ...prev].slice(0, 200);
        });
      }
    }
  }, [messages]);

  return (
    <div className="cr-overview">
      <div className="cr-overview__status">
        <span
          className={`cr-dot ${connected ? "cr-dot--on" : "cr-dot--off"}`}
        />
        {connected ? "CONNECTED" : "RECONNECTING"}
        <span className="cr-overview__count">{alerts.length} alerts</span>
      </div>

      <div ref={mapRef} className="cr-overview__map">
        {/* Mapbox GL or Leaflet can be mounted here */}
        <div className="cr-overview__map-placeholder">
          MAP FEED — {alerts.filter((a) => a.lat).length} geo-tagged
        </div>
      </div>

      <ul className="cr-overview__list">
        {alerts.slice(0, 30).map((a) => (
          <li
            key={a.id}
            className="cr-overview__item"
            style={{ borderLeftColor: MODE_COLORS[a.mode] || "#00F5FF" }}
          >
            <span className="cr-overview__mode">
              {a.mode?.replace("_", " ").toUpperCase()}
            </span>
            <span className="cr-overview__risk">Risk {a.riskScore}</span>
            <span className="cr-overview__ts">
              {new Date(a.ts).toLocaleTimeString()}
            </span>
            {a.description && (
              <span className="cr-overview__desc">{a.description}</span>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default SituationalOverview;
