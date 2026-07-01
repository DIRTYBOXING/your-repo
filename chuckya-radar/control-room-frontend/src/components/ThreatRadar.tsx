import React, { useEffect, useRef, useState } from "react";

interface Alert {
  id?: string;
  alertId?: string;
  mode: string;
  riskScore: number;
  ts?: string;
  createdAt?: string;
  proximity?: number;
}

const MODE_COLORS: Record<string, string> = {
  code_black: "#FF3366",
  code_red: "#FF6B35",
  code_amber: "#FFB347",
  code_yellow: "#FFD700",
};

const ThreatRadar: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const sweepAngle = useRef(0);
  const animFrame = useRef(0);

  useEffect(() => {
    const poll = async () => {
      try {
        const r = await fetch("/v1/radar/alerts");
        const data = await r.json();
        const list = Array.isArray(data) ? data : data.alerts || [];
        setAlerts(list.slice(0, 50));
      } catch {
        /* retry next tick */
      }
    };
    poll();
    const iv = setInterval(poll, 3000);
    return () => clearInterval(iv);
  }, []);

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

      // Rings
      for (let i = 1; i <= 4; i++) {
        const r = (maxR / 4) * i;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.strokeStyle = "rgba(0,245,255,0.15)";
        ctx.lineWidth = 1;
        ctx.stroke();
      }

      // Cross hairs
      ctx.strokeStyle = "rgba(0,245,255,0.1)";
      ctx.beginPath();
      ctx.moveTo(cx, 0);
      ctx.lineTo(cx, H);
      ctx.moveTo(0, cy);
      ctx.lineTo(W, cy);
      ctx.stroke();

      // Sweep line
      sweepAngle.current = (sweepAngle.current + 0.02) % (Math.PI * 2);
      const sx = cx + Math.cos(sweepAngle.current) * maxR;
      const sy = cy + Math.sin(sweepAngle.current) * maxR;
      const grad = ctx.createLinearGradient(cx, cy, sx, sy);
      grad.addColorStop(0, "rgba(0,245,255,0)");
      grad.addColorStop(1, "rgba(0,245,255,0.6)");
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(sx, sy);
      ctx.strokeStyle = grad;
      ctx.lineWidth = 2;
      ctx.stroke();

      // Blips — position by proximity (distance) and hash-based angle
      for (const a of alerts) {
        const id = a.alertId || a.id || "";
        const hashAngle =
          ((id.charCodeAt(id.length - 1) || 0) / 128) * Math.PI * 2;
        const dist = a.proximity ? Math.min(a.proximity / 100, 1) : 0.5;
        const bx = cx + Math.cos(hashAngle) * dist * maxR;
        const by = cy + Math.sin(hashAngle) * dist * maxR;
        const color = MODE_COLORS[a.mode] || "#00F5FF";

        ctx.beginPath();
        ctx.arc(bx, by, 4, 0, Math.PI * 2);
        ctx.fillStyle = color;
        ctx.fill();

        // Glow
        ctx.beginPath();
        ctx.arc(bx, by, 8, 0, Math.PI * 2);
        ctx.fillStyle = color.replace(")", ",0.25)").replace("rgb", "rgba");
        ctx.fill();
      }

      // Center dot
      ctx.beginPath();
      ctx.arc(cx, cy, 3, 0, Math.PI * 2);
      ctx.fillStyle = "#00F5FF";
      ctx.fill();

      animFrame.current = requestAnimationFrame(draw);
    };

    draw();
    return () => cancelAnimationFrame(animFrame.current);
  }, [alerts]);

  // SVG sparkline for alert timeline
  const timelinePts = alerts
    .slice(0, 30)
    .map((a, i) => {
      const x = 10 + i * 9;
      const y = 50 - (a.riskScore / 100) * 40;
      return `${x},${y}`;
    })
    .join(" ");

  return (
    <div className="cr-radar">
      <canvas
        ref={canvasRef}
        width={360}
        height={360}
        className="cr-radar__canvas"
      />
      <div className="cr-radar__legend">
        {Object.entries(MODE_COLORS).map(([k, v]) => (
          <span key={k} style={{ color: v, marginRight: 12 }}>
            ● {k.replace("_", " ").toUpperCase()}
          </span>
        ))}
      </div>
      <svg
        className="cr-radar__sparkline"
        viewBox="0 0 300 60"
        preserveAspectRatio="none"
      >
        <polyline
          points={timelinePts}
          fill="none"
          stroke="#00F5FF"
          strokeWidth="1.5"
        />
      </svg>
    </div>
  );
};

export default ThreatRadar;
