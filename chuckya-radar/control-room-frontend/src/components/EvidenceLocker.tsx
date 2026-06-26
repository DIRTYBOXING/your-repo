import React, { useEffect, useState } from "react";

interface Alert {
  alertId: string;
  mode: string;
  riskScore: number;
  createdAt: string;
  type?: string;
  signatureVerified?: boolean;
  appInstanceId?: string;
  topSignals?: string[];
}

interface EvidenceFile {
  name: string;
  sha256: string;
  bytes?: number;
}

const EvidenceLocker: React.FC = () => {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [selected, setSelected] = useState<Alert | null>(null);
  const [manifest, setManifest] = useState<EvidenceFile[]>([]);

  useEffect(() => {
    const poll = async () => {
      try {
        const r = await fetch("/v1/radar/alerts");
        const data = await r.json();
        setAlerts(Array.isArray(data) ? data : data.alerts || []);
      } catch {
        /* retry */
      }
    };
    poll();
    const iv = setInterval(poll, 5000);
    return () => clearInterval(iv);
  }, []);

  const selectAlert = async (a: Alert) => {
    setSelected(a);
    setManifest([]);
    try {
      const r = await fetch(`/v1/radar/alerts/${a.alertId}`);
      const detail = await r.json();
      if (detail.evidence) setManifest(detail.evidence);
    } catch {
      /* non-critical */
    }
  };

  const downloadEvidence = (alertId: string) => {
    const a = document.createElement("a");
    a.href = `/v1/radar/alerts/${alertId}/export`;
    a.download = `${alertId}_evidence.zip`;
    a.click();
  };

  return (
    <div className="cr-evidence">
      <ul className="cr-evidence__list">
        {alerts.slice(0, 40).map((a) => (
          <li
            key={a.alertId}
            className={`cr-evidence__item ${selected?.alertId === a.alertId ? "cr-evidence__item--sel" : ""}`}
            onClick={() => selectAlert(a)}
          >
            <span className={`cr-evidence__mode cr-evidence__mode--${a.mode}`}>
              {a.mode?.replace("_", " ")}
            </span>
            <span className="cr-evidence__id">{a.alertId}</span>
            <span className="cr-evidence__ts">
              {new Date(a.createdAt).toLocaleTimeString()}
            </span>
            {a.signatureVerified && (
              <span className="cr-evidence__verified">✓ SIG</span>
            )}
          </li>
        ))}
      </ul>

      {selected && (
        <div className="cr-evidence__detail">
          <h3>{selected.alertId}</h3>
          <table className="cr-evidence__table">
            <tbody>
              <tr>
                <td>Mode</td>
                <td>{selected.mode}</td>
              </tr>
              <tr>
                <td>Risk</td>
                <td>{selected.riskScore}</td>
              </tr>
              <tr>
                <td>Type</td>
                <td>{selected.type || "safety_ping"}</td>
              </tr>
              <tr>
                <td>Device</td>
                <td>{selected.appInstanceId || "—"}</td>
              </tr>
              <tr>
                <td>Signature</td>
                <td>
                  {selected.signatureVerified ? "✓ VERIFIED" : "✗ UNSIGNED"}
                </td>
              </tr>
              <tr>
                <td>Signals</td>
                <td>{selected.topSignals?.join(", ") || "—"}</td>
              </tr>
            </tbody>
          </table>

          {manifest.length > 0 && (
            <div className="cr-evidence__files">
              <h4>Evidence Files</h4>
              {manifest.map((f) => (
                <div key={f.name} className="cr-evidence__file">
                  <span>{f.name}</span>
                  <code>{f.sha256?.slice(0, 16)}…</code>
                </div>
              ))}
            </div>
          )}

          <div className="cr-evidence__actions">
            <button
              className="cr-btn cr-btn--cyan"
              onClick={() => downloadEvidence(selected.alertId)}
            >
              Download Evidence ZIP
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default EvidenceLocker;
