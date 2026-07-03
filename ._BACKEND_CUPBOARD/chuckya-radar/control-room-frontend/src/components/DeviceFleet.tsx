import React, { useEffect, useState } from "react";

interface Device {
  appInstanceId: string;
  registeredAt: string;
  registeredFromIp: string;
  publicKeySha256?: string;
  lastSeen?: string;
  status?: "online" | "stale" | "offline";
}

const DeviceFleet: React.FC = () => {
  const [devices, setDevices] = useState<Device[]>([]);

  useEffect(() => {
    const poll = async () => {
      try {
        // Try device-verifier endpoint first, fallback to empty
        const r = await fetch("/v1/devices");
        if (r.ok) {
          const data = await r.json();
          setDevices(Array.isArray(data) ? data : data.devices || []);
        }
      } catch {
        /* non-critical */
      }
    };
    poll();
    const iv = setInterval(poll, 5000);
    return () => clearInterval(iv);
  }, []);

  const getStatusColor = (status?: string) => {
    if (status === "online") return "#00FF88";
    if (status === "stale") return "#FFD700";
    return "#FF3366";
  };

  const getStatusLabel = (d: Device): string => {
    if (d.status) return d.status.toUpperCase();
    if (!d.lastSeen) return "REGISTERED";
    const age = Date.now() - new Date(d.lastSeen).getTime();
    if (age < 60_000) return "ONLINE";
    if (age < 300_000) return "STALE";
    return "OFFLINE";
  };

  return (
    <div className="cr-fleet">
      <div className="cr-fleet__count">{devices.length} devices registered</div>
      <table className="cr-fleet__table">
        <thead>
          <tr>
            <th>Status</th>
            <th>Device ID</th>
            <th>Registered</th>
            <th>Last Seen</th>
            <th>IP</th>
          </tr>
        </thead>
        <tbody>
          {devices.map((d) => (
            <tr key={d.appInstanceId}>
              <td>
                <span
                  className="cr-fleet__dot"
                  style={{ backgroundColor: getStatusColor(d.status) }}
                />
                {getStatusLabel(d)}
              </td>
              <td className="cr-fleet__id">{d.appInstanceId}</td>
              <td>{new Date(d.registeredAt).toLocaleDateString()}</td>
              <td>
                {d.lastSeen ? new Date(d.lastSeen).toLocaleTimeString() : "—"}
              </td>
              <td>{d.registeredFromIp}</td>
            </tr>
          ))}
          {devices.length === 0 && (
            <tr>
              <td colSpan={5} style={{ textAlign: "center", opacity: 0.5 }}>
                No devices registered yet
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};

export default DeviceFleet;
