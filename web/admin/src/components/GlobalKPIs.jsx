import React from "react";

export default function GlobalKPIs() {
  const [kpis, setKpis] = React.useState({
    alertLatency: "-",
    p95Latency: "-",
    successRate: "-",
    activeEngines: "-",
  });

  React.useEffect(() => {
    async function load() {
      try {
        const res = await fetch("/api/kpis");
        const json = await res.json();
        setKpis(json);
      } catch (e) {
        console.error(e);
      }
    }
    load();
    const t = setInterval(load, 5000);
    return () => clearInterval(t);
  }, []);

  return (
    <div className="grid grid-cols-4 gap-4">
      <div className="bg-white p-3 rounded shadow">
        <div className="text-sm text-gray-500">Alert Latency</div>
        <div className="text-xl font-bold">{kpis.alertLatency} ms</div>
      </div>
      <div className="bg-white p-3 rounded shadow">
        <div className="text-sm text-gray-500">Job p95 Latency</div>
        <div className="text-xl font-bold">{kpis.p95Latency} ms</div>
      </div>
      <div className="bg-white p-3 rounded shadow">
        <div className="text-sm text-gray-500">Promote Success</div>
        <div className="text-xl font-bold">{kpis.successRate}%</div>
      </div>
      <div className="bg-white p-3 rounded shadow">
        <div className="text-sm text-gray-500">Active Engines</div>
        <div className="text-xl font-bold">{kpis.activeEngines}</div>
      </div>
    </div>
  );
}
