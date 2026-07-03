/**
 * DFC CHUCKYA Control Room — Mapbox Init Helper
 *
 * Sub-second alert layer updates via source.setData()
 * for real-time threat visualization on the Situational Overview panel.
 */

import type { Map as MapboxMap, GeoJSONSource } from "mapbox-gl";

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || "";
const ALERT_SOURCE_ID = "chuckya-alerts";
const ALERT_LAYER_ID = "chuckya-alerts-layer";

/* Mode → circle colour */
const MODE_COLORS: Record<string, string> = {
  code_red: "#FF3366",
  code_black: "#FF00FF",
  code_yellow: "#FFD700",
  code_green: "#00FF88",
};

export interface AlertFeature {
  id: string;
  lat: number;
  lng: number;
  mode: string;
  riskScore: number;
  signal: string;
  ts: string;
}

/** Create map instance, add empty alert source + layer */
export function initMap(container: string | HTMLElement): MapboxMap | null {
  if (!MAPBOX_TOKEN || MAPBOX_TOKEN === "pk.placeholder") {
    console.warn("[mapbox] No token — map disabled");
    return null;
  }

  // Dynamic import avoids bundling mapbox-gl when token absent
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const mapboxgl = (window as any).mapboxgl;
  if (!mapboxgl) {
    console.warn("[mapbox] mapbox-gl not loaded");
    return null;
  }

  mapboxgl.accessToken = MAPBOX_TOKEN;

  const map: MapboxMap = new mapboxgl.Map({
    container,
    style: "mapbox://styles/mapbox/dark-v11",
    center: [153.02, -27.47], // Brisbane default
    zoom: 12,
  });

  map.on("load", () => {
    map.addSource(ALERT_SOURCE_ID, {
      type: "geojson",
      data: { type: "FeatureCollection", features: [] },
    });

    map.addLayer({
      id: ALERT_LAYER_ID,
      type: "circle",
      source: ALERT_SOURCE_ID,
      paint: {
        "circle-radius": [
          "interpolate",
          ["linear"],
          ["get", "riskScore"],
          0,
          4,
          100,
          16,
        ],
        "circle-color": [
          "match",
          ["get", "mode"],
          "code_red",
          MODE_COLORS.code_red,
          "code_black",
          MODE_COLORS.code_black,
          "code_yellow",
          MODE_COLORS.code_yellow,
          "code_green",
          MODE_COLORS.code_green,
          "#00F5FF", // default neonCyan
        ],
        "circle-opacity": 0.85,
        "circle-stroke-width": 2,
        "circle-stroke-color": "#00F5FF",
      },
    });
  });

  return map;
}

/** Push alerts to the map — call on every WS message for sub-second updates */
export function updateAlerts(map: MapboxMap, alerts: AlertFeature[]): void {
  const source = map.getSource(ALERT_SOURCE_ID) as GeoJSONSource | undefined;
  if (!source) return;

  source.setData({
    type: "FeatureCollection",
    features: alerts.map((a) => ({
      type: "Feature" as const,
      geometry: { type: "Point" as const, coordinates: [a.lng, a.lat] },
      properties: {
        id: a.id,
        mode: a.mode,
        riskScore: a.riskScore,
        signal: a.signal,
        ts: a.ts,
      },
    })),
  });
}

/** Fly to a specific alert */
export function flyToAlert(map: MapboxMap, lat: number, lng: number): void {
  map.flyTo({ center: [lng, lat], zoom: 15, speed: 1.5 });
}
