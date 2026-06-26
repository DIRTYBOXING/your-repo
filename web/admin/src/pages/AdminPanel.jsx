import React from "react";
import EngineTile from "../components/EngineTile";
import GlobalKPIs from "../components/GlobalKPIs";
import LiveCharts from "../components/LiveCharts";
import PromoteQueue from "../components/PromoteQueue";
import UploadCenter from "../components/UploadCenter";
import wsClient from "../wsClient";

export default function AdminPanel() {
  React.useEffect(() => {
    wsClient.connect();
    return () => wsClient.disconnect();
  }, []);
  return (
    <div className="min-h-screen p-4 bg-gray-50">
      <header className="flex items-center justify-between mb-4">
        <h1 className="text-2xl font-bold">Control Panel</h1>
        <div className="flex gap-2">
          <button className="px-3 py-1 bg-gray-200 rounded">
            Environment: Staging
          </button>
          <button className="px-3 py-1 bg-red-600 text-white rounded">
            SOS
          </button>
        </div>
      </header>

      <GlobalKPIs />

      <div className="grid grid-cols-12 gap-4 mt-4">
        <aside className="col-span-3 space-y-3">
          <div className="bg-white p-3 rounded shadow">
            <h3 className="font-semibold mb-2">Engines</h3>
            <EngineTile id="engine-1" />
            <EngineTile id="engine-2" />
            <EngineTile id="engine-3" />
          </div>
          <UploadCenter />
        </aside>

        <main className="col-span-6 bg-white p-3 rounded shadow">
          <LiveCharts />
        </main>

        <section className="col-span-3 space-y-3">
          <PromoteQueue />
          <div className="bg-white p-3 rounded shadow">
            <h3 className="font-semibold">Audit Feed</h3>
            <div
              id="audit-feed"
              style={{ maxHeight: 300, overflow: "auto" }}
            ></div>
          </div>
        </section>
      </div>

      <footer className="mt-4">
        <div className="bg-white p-3 rounded shadow">
          <h4 className="font-semibold">Command Console</h4>
          <div id="command-console" />
        </div>
      </footer>
    </div>
  );
}
