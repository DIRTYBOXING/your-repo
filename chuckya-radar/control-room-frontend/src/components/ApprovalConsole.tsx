import React, { useEffect, useState, useCallback } from "react";

interface PendingExport {
  alertId: string;
  requestedAt: string;
  requestedBy: string;
  mode: string;
  riskScore: number;
  status: "pending" | "approved" | "rejected";
  approvedBy?: string;
}

const ApprovalConsole: React.FC = () => {
  const [items, setItems] = useState<PendingExport[]>([]);
  const [filter, setFilter] = useState<
    "all" | "pending" | "approved" | "rejected"
  >("pending");

  useEffect(() => {
    const poll = async () => {
      try {
        const r = await fetch("/v1/radar/exports/pending");
        if (r.ok) {
          const data = await r.json();
          setItems(Array.isArray(data) ? data : data.exports || []);
        }
      } catch {
        /* non-critical */
      }
    };
    poll();
    const iv = setInterval(poll, 3000);
    return () => clearInterval(iv);
  }, []);

  const handleAction = useCallback(
    async (alertId: string, action: "approve" | "reject") => {
      try {
        await fetch(`/v1/radar/exports/${alertId}/${action}`, {
          method: "POST",
        });
        setItems((prev) =>
          prev.map((i) =>
            i.alertId === alertId
              ? { ...i, status: action === "approve" ? "approved" : "rejected" }
              : i,
          ),
        );
      } catch {
        /* handle error */
      }
    },
    [],
  );

  const filtered = items.filter((i) => filter === "all" || i.status === filter);

  return (
    <div className="cr-approval">
      <div className="cr-approval__filters">
        {(["pending", "approved", "rejected", "all"] as const).map((f) => (
          <button
            key={f}
            className={`cr-btn cr-btn--sm ${filter === f ? "cr-btn--active" : ""}`}
            onClick={() => setFilter(f)}
          >
            {f.toUpperCase()}
            {f !== "all" && (
              <span className="cr-approval__count">
                {items.filter((i) => i.status === f).length}
              </span>
            )}
          </button>
        ))}
      </div>

      <ul className="cr-approval__list">
        {filtered.map((item) => (
          <li
            key={item.alertId}
            className={`cr-approval__item cr-approval__item--${item.status}`}
          >
            <div className="cr-approval__info">
              <span className="cr-approval__id">{item.alertId}</span>
              <span
                className={`cr-approval__mode cr-approval__mode--${item.mode}`}
              >
                {item.mode?.replace("_", " ").toUpperCase()}
              </span>
              <span className="cr-approval__risk">Risk {item.riskScore}</span>
              <span className="cr-approval__by">by {item.requestedBy}</span>
            </div>

            {item.status === "pending" && (
              <div className="cr-approval__actions">
                <button
                  className="cr-btn cr-btn--green"
                  onClick={() => handleAction(item.alertId, "approve")}
                >
                  APPROVE
                </button>
                <button
                  className="cr-btn cr-btn--red"
                  onClick={() => handleAction(item.alertId, "reject")}
                >
                  REJECT
                </button>
              </div>
            )}

            {item.status !== "pending" && (
              <span
                className={`cr-approval__status cr-approval__status--${item.status}`}
              >
                {item.status.toUpperCase()}
              </span>
            )}
          </li>
        ))}
        {filtered.length === 0 && (
          <li className="cr-approval__empty">No {filter} exports</li>
        )}
      </ul>
    </div>
  );
};

export default ApprovalConsole;
