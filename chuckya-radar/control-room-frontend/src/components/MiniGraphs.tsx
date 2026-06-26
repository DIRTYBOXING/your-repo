import React, { useEffect, useRef, useState } from "react";

interface KPI {
  label: string;
  value: string;
  sparkline: number[];
  color: string;
}

const SPARKLINE_W = 120;
const SPARKLINE_H = 32;

function drawSparkline(
  canvas: HTMLCanvasElement,
  data: number[],
  color: string,
) {
  const ctx = canvas.getContext("2d");
  if (!ctx || data.length < 2) return;
  const max = Math.max(...data, 1);
  const step = SPARKLINE_W / (data.length - 1);
  ctx.clearRect(0, 0, SPARKLINE_W, SPARKLINE_H);
  ctx.beginPath();
  ctx.moveTo(0, SPARKLINE_H - (data[0] / max) * SPARKLINE_H);
  for (let i = 1; i < data.length; i++) {
    ctx.lineTo(i * step, SPARKLINE_H - (data[i] / max) * SPARKLINE_H);
  }
  ctx.strokeStyle = color;
  ctx.lineWidth = 1.5;
  ctx.stroke();
}

const MiniGraphs: React.FC = () => {
  const [kpis, setKpis] = useState<KPI[]>([
    { label: "Drones Airborne", value: "—", sparkline: [], color: "#00FF88" },
    { label: "Detections", value: "—", sparkline: [], color: "#FF00FF" },
    { label: "Phone Pings", value: "—", sparkline: [], color: "#FF6B35" },
    { label: "Active Tracking", value: "—", sparkline: [], color: "#00F5FF" },
    { label: "Missions Active", value: "—", sparkline: [], color: "#FFD700" },
    { label: "Low Battery", value: "—", sparkline: [], color: "#FF3366" },
  ]);
  const canvasRefs = useRef<(HTMLCanvasElement | null)[]>([]);

  useEffect(() => {
    const poll = async () => {
      try {
        const r = await fetch("/v1/control/stats");
        if (!r.ok) return;
        const data = await r.json();

        setKpis((prev) => {
          const next = [...prev];
          const airborne = data.drones?.airborne ?? 0;
          const totalDet = data.detections?.total ?? 0;
          const phonePings = data.detections?.phonePings ?? 0;
          const tracking = data.detections?.tracking ?? 0;
          const activeMissions = data.missions?.active ?? 0;
          const lowBat = data.drones?.lowBattery ?? 0;

          next[0] = {
            ...next[0],
            value: `${airborne}`,
            sparkline: [...prev[0].sparkline.slice(-9), airborne],
          };
          next[1] = {
            ...next[1],
            value: `${totalDet}`,
            sparkline: [...prev[1].sparkline.slice(-9), totalDet],
          };
          next[2] = {
            ...next[2],
            value: `${phonePings}`,
            sparkline: [...prev[2].sparkline.slice(-9), phonePings],
          };
          next[3] = {
            ...next[3],
            value: `${tracking}`,
            sparkline: [...prev[3].sparkline.slice(-9), tracking],
          };
          next[4] = {
            ...next[4],
            value: `${activeMissions}`,
            sparkline: [...prev[4].sparkline.slice(-9), activeMissions],
          };
          next[5] = {
            ...next[5],
            value: `${lowBat}`,
            sparkline: [...prev[5].sparkline.slice(-9), lowBat],
          };
          return next;
        });
      } catch {
        /* retry */
      }
    };
    poll();
    const iv = setInterval(poll, 5000);
    return () => clearInterval(iv);
  }, []);

  useEffect(() => {
    kpis.forEach((k, i) => {
      const canvas = canvasRefs.current[i];
      if (canvas && k.sparkline.length > 1) {
        drawSparkline(canvas, k.sparkline, k.color);
      }
    });
  }, [kpis]);

  return (
    <div className="cr-kpis">
      {kpis.map((k, i) => (
        <div key={k.label} className="cr-kpi">
          <div className="cr-kpi__label">{k.label}</div>
          <div className="cr-kpi__value" style={{ color: k.color }}>
            {k.value}
          </div>
          <canvas
            ref={(el) => {
              canvasRefs.current[i] = el;
            }}
            width={SPARKLINE_W}
            height={SPARKLINE_H}
            className="cr-kpi__spark"
          />
        </div>
      ))}
    </div>
  );
};

export default MiniGraphs;
