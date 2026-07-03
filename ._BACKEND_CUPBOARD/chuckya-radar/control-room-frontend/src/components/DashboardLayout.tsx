import React, { useState } from "react";
import SituationalOverview from "./SituationalOverview";
import DetectionRadar from "./DetectionRadar";
import DroneFleet from "./DroneFleet";
import LaunchPadControls from "./LaunchPadControls";
import DroneTracker from "./DroneTracker";
import EvidenceLocker from "./EvidenceLocker";
import ApprovalConsole from "./ApprovalConsole";
import MiniGraphs from "./MiniGraphs";

const DashboardLayout: React.FC = () => {
  const [selectedDrone, setSelectedDrone] = useState<string | null>(null);

  return (
    <div className="cr-root">
      <header className="cr-header">
        <span className="cr-logo">CHUCKYA</span>
        <span className="cr-title">DRONE OPS — CONTROL ROOM</span>
        <span className="cr-badge cr-badge--live">LIVE</span>
        <span className="cr-header__mode">DETECTION & TRACKING</span>
      </header>

      <div className="cr-grid cr-grid--drone">
        {/* Row 1: Situational Overview (wide) + Detection Radar + Drone Tracker */}
        <section className="cr-panel cr-panel--overview">
          <h2 className="cr-panel__title">Situational Overview</h2>
          <SituationalOverview />
        </section>

        <section className="cr-panel cr-panel--radar">
          <h2 className="cr-panel__title">Detection Radar</h2>
          <DetectionRadar />
        </section>

        <section className="cr-panel cr-panel--tracker">
          <h2 className="cr-panel__title">Drone Tracker</h2>
          <DroneTracker selectedDrone={selectedDrone} />
        </section>

        {/* Row 2: Drone Fleet (wide) + Launch Pad Controls */}
        <section className="cr-panel cr-panel--fleet">
          <h2 className="cr-panel__title">Drone Fleet</h2>
          <DroneFleet
            onSelectDrone={setSelectedDrone}
            selectedDrone={selectedDrone}
          />
        </section>

        <section className="cr-panel cr-panel--launchpad">
          <h2 className="cr-panel__title">Launch Pad Controls</h2>
          <LaunchPadControls selectedDrone={selectedDrone} />
        </section>

        {/* Row 3: Evidence + Approvals + Analytics */}
        <section className="cr-panel cr-panel--evidence">
          <h2 className="cr-panel__title">Evidence Locker</h2>
          <EvidenceLocker />
        </section>

        <section className="cr-panel cr-panel--approval">
          <h2 className="cr-panel__title">Approval Console</h2>
          <ApprovalConsole />
        </section>

        <section className="cr-panel cr-panel--analytics">
          <h2 className="cr-panel__title">Analytics</h2>
          <MiniGraphs />
        </section>
      </div>
    </div>
  );
};

export default DashboardLayout;
