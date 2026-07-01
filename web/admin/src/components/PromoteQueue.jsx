import React from "react";

export default function PromoteQueue() {
  const [queue, setQueue] = React.useState([]);

  React.useEffect(() => {
    async function load() {
      const res = await fetch("/api/jobs/pending");
      const json = await res.json();
      setQueue(json.jobs || []);
    }
    load();
    const t = setInterval(load, 5000);
    return () => clearInterval(t);
  }, []);

  const promote = async (id) => {
    await fetch(`/api/jobs/${id}/promote`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ approverId: "admin" }),
    });
  };

  return (
    <div className="bg-white p-3 rounded shadow">
      <h3 className="font-semibold mb-2">Promote Queue</h3>
      {queue.map((j) => (
        <div
          key={j.id}
          className="p-2 border rounded mb-2 flex justify-between items-center"
        >
          <div>
            <div className="font-medium">{j.name}</div>
            <div className="text-xs text-gray-500">
              Waiting {j.waitMinutes}m
            </div>
          </div>
          <div>
            <button
              className="px-2 py-1 bg-green-600 text-white rounded"
              onClick={() => promote(j.id)}
            >
              Promote
            </button>
          </div>
        </div>
      ))}
      {queue.length === 0 && (
        <div className="text-sm text-gray-500">No pending jobs</div>
      )}
    </div>
  );
}
