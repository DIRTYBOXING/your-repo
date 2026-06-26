import React from "react";

export default function EngineTile({ id }) {
  const [state, setState] = React.useState({
    name: id,
    status: "unknown",
    cpu: 0,
    lastSeen: 0,
  });

  React.useEffect(() => {
    const handler = (e) => {
      const m = e.detail;
      if (m && m.type === "telemetry" && m.id === id)
        setState((s) => ({ ...s, ...m.payload }));
    };
    window.addEventListener("ws-msg", handler);
    return () => window.removeEventListener("ws-msg", handler);
  }, [id]);

  const sendCmd = async (cmd) => {
    await fetch("/api/commands", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ targetId: id, command: cmd, params: {} }),
    });
  };

  return (
    <div className="p-2 border rounded flex items-center justify-between mb-2">
      <div>
        <div className="font-medium">{state.name}</div>
        <div className="text-xs text-gray-500">
          {state.status} • CPU {Math.round(state.cpu * 100)}%
        </div>
      </div>
      <div className="flex flex-col gap-1">
        <button
          className="px-2 py-1 text-xs border rounded"
          onClick={() => sendCmd("start")}
        >
          Start
        </button>
        <button
          className="px-2 py-1 text-xs border rounded"
          onClick={() => sendCmd("stop")}
        >
          Stop
        </button>
        <button
          className="px-2 py-1 text-xs border rounded"
          onClick={() => sendCmd("fetch")}
        >
          Fetch
        </button>
      </div>
    </div>
  );
}
