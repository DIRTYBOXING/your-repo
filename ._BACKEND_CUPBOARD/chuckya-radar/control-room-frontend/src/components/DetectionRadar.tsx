import React, { useEffect, useRef, useState } from "react";

interface Detection {
  detectionId: string;
  type: string;
  timestamp: string;
  signal: {
    strength: number;
    frequency: number | null;
    ssid: string | null;
    mac: string | null;
  };
  position: {
    lat: number | null;
    lng: number | null;
    accuracy: number | null;
    bearing: number | null;
  };
  confidence: number;
  status: string;
  assignedDrone: string | null;
}

const TYPE_COLORS: Record<string, string> = {
  phone_ping: "#FF00FF",
  gps_signal: "#00FF88",
  bluetooth: "#00F5FF",
  wifi_probe: "#FFD700",
  rf_emission: "#FF6B35",
  imsi_catch: "#FF3366",
  acoustic: "#8899AA",
};

const TYPE_ICONS: Record<string, string> = {
  phone_ping: "📱",
  gps_signal: "🛰",
  bluetooth: "📶",
  wifi_probe: "📡",
  rf_emission: "⚡",
  imsi_catch: "🔐",
  acoustic: "🔊",
};

const DetectionRadar: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [detections, setDetections] = useState<Detection[]>([]);
  const sweepAngle = useRef(0);
  const animFrame = useRef(0);
  const [filter, setFilter] = useState<string>("all");

  useEffect(() => {
    const poll = async () => {
      try {
        const url =
          filter === "all" ? "/v1/detections" : `/v1/detections?type=${filter}`;
        const r = await fetch(url);
        if (r.ok) {
          const data = await r.json();
          setDetections(data.detections || []);
        }
      } catch {
        /* retry */
      }
    };
    poll();
    const iv = setInterval(poll, 2000);
    return () => clearInterval(iv);
  }, [filter]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const W = canvas.width;
    const H = canvas.height;
    const cx = W / 2;
    const cy = H / 2;
    const maxR = Math.min(cx, cy) - 10;

    const draw = () => {
      ctx.fillStyle = "#050A14";
      ctx.fillRect(0, 0, W, H);

      // Range rings
      for (let i = 1; i <= 5; i++) {
        const r = (maxR / 5) * i;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(255,0,255,${0.08 + i * 0.02})`;
        ctx.lineWidth = 1;
        ctx.stroke();
        // Range labels
        ctx.fillStyle = "rgba(255,0,255,0.3)";
        ctx.font = "9px JetBrains Mono, monospace";
        ctx.fillText(`${i * 20}m`, cx + r - 20, cy - 3);
      }

      // Cross hairs + diagonal lines
      ctx.strokeStyle = "rgba(255,0,255,0.08)";
      ctx.beginPath();
      ctx.moveTo(cx, 0);
      ctx.lineTo(cx, H);
      ctx.moveTo(0, cy);
      ctx.lineTo(W, cy);
      ctx.moveTo(0, 0);
      ctx.lineTo(W, H);
      ctx.moveTo(W, 0);
      ctx.lineTo(0, H);
      ctx.stroke();

      // Sweep line
      sweepAngle.current = (sweepAngle.current + 0.015) % (Math.PI * 2);
      const sx = cx + Math.cos(sweepAngle.current) * maxR;
      const sy = cy + Math.sin(sweepAngle.current) * maxR;

      // Sweep trail (fading arc)
      for (let t = 0; t < 30; t++) {
        const a = sweepAngle.current - t * 0.02;
        const ex = cx + Math.cos(a) * maxR;
        const ey = cy + Math.sin(a) * maxR;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(ex, ey);
        ctx.strokeStyle = `rgba(255,0,255,${0.3 - t * 0.01})`;
        ctx.lineWidth = 1;
        ctx.stroke();
      }

      // Main sweep line
      const grad = ctx.createLinearGradient(cx, cy, sx, sy);
      grad.addColorStop(0, "rgba(255,0,255,0)");
      grad.addColorStop(1, "rgba(255,0,255,0.8)");
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(sx, sy);
      ctx.strokeStyle = grad;
      ctx.lineWidth = 2;
      ctx.stroke();

      // Detection blips
      for (const det of detections) {
        // Position in radar by signal strength (stronger = closer to center)
        const strength = Math.abs(det.signal.strength); // dBm (negative), 0=strongest
        const dist = Math.min(strength / 100, 1); // normalize: 0dBm=center, -100dBm=edge
        // Angle from bearing or hash
        const angle =
          det.position.bearing !== null
            ? (det.position.bearing / 180) * Math.PI
            : ((det.detectionId.charCodeAt(det.detectionId.length - 1) || 0) /
                128) *
              Math.PI *
              2;

        const bx = cx + Math.cos(angle) * dist * maxR;
        const by = cy + Math.sin(angle) * dist * maxR;
        const color = TYPE_COLORS[det.type] || "#00F5FF";

        // Pulsing glow for active tracking
        const pulseSize =
          det.status === "tracking" ? 12 + Math.sin(Date.now() / 200) * 4 : 8;

        // Outer glow
        ctx.beginPath();
        ctx.arc(bx, by, pulseSize, 0, Math.PI * 2);
        const glowGrad = ctx.createRadialGradient(bx, by, 0, bx, by, pulseSize);
        glowGrad.addColorStop(0, color + "88");
        glowGrad.addColorStop(1, color + "00");
        ctx.fillStyle = glowGrad;
        ctx.fill();

        // Blip core
        ctx.beginPath();
        ctx.arc(bx, by, 3, 0, Math.PI * 2);
        ctx.fillStyle = color;
        ctx.fill();

        // Signal strength indicator (small text)
        ctx.fillStyle = color;
        ctx.font = "8px JetBrains Mono, monospace";
        ctx.fillText(`${det.signal.strength}dBm`, bx + 6, by - 2);
      }

      // Center dot
      ctx.beginPath();
      ctx.arc(cx, cy, 4, 0, Math.PI * 2);
      ctx.fillStyle = "#FF00FF";
      ctx.fill();
      ctx.beginPath();
      ctx.arc(cx, cy, 2, 0, Math.PI * 2);
      ctx.fillStyle = "#fff";
      ctx.fill();

      animFrame.current = requestAnimationFrame(draw);
    };

    draw();
    return () => cancelAnimationFrame(animFrame.current);
  }, [detections]);

  // Stats
  const byType = Object.entries(TYPE_COLORS).map(([type, color]) => ({
    type,
    color,
    icon: TYPE_ICONS[type] || "•",
    count: detections.filter((d) => d.type === type).length,
  }));

  return (
    <div className="cr-detection">
      <div className="cr-detection__filters">
        <button
          className={`cr-btn cr-btn--sm ${filter === "all" ? "cr-btn--active" : ""}`}
          onClick={() => setFilter("all")}
        >
          ALL ({detections.length})
        </button>
        {byType
          .filter((t) => t.count > 0)
          .map((t) => (
            <button
              key={t.type}
              className={`cr-btn cr-btn--sm ${filter === t.type ? "cr-btn--active" : ""}`}
              style={{
                color: filter === t.type ? t.color : undefined,
                borderColor: filter === t.type ? t.color : undefined,
              }}
              onClick={() => setFilter(t.type)}
            >
              {t.icon} {t.count}
            </button>
          ))}
      </div>

      <canvas
        ref={canvasRef}
        width={400}
        height={400}
        className="cr-detection__canvas"
      />

      <div className="cr-detection__legend">
        {Object.entries(TYPE_COLORS).map(([type, color]) => (
          <span
            key={type}
            className="cr-detection__legend-item"
            style={{ color }}
          >
            {TYPE_ICONS[type]} {type.replace("_", " ")}
          </span>
        ))}
      </div>
    </div>
  );
};

export default DetectionRadar;
