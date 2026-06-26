import type { RealtimeTransport } from "./realtime_transport";
import { WebSocketAdapter } from "./websocket_adapter";
import { WebTransportAdapter } from "./webtransport_adapter";

export type TransportKind = "websocket" | "webtransport";

export interface TransportFactoryOptions {
  websocketUrl: string;
  webtransportUrl?: string;
  enableWebTransport?: boolean;
}

function supportsWebTransport(): boolean {
  return typeof globalThis !== "undefined" && "WebTransport" in globalThis;
}

export function createTransport(
  options: TransportFactoryOptions,
): RealtimeTransport {
  const useWebTransport =
    Boolean(options.enableWebTransport) &&
    Boolean(options.webtransportUrl) &&
    supportsWebTransport();

  if (useWebTransport && options.webtransportUrl) {
    return new WebTransportAdapter(options.webtransportUrl);
  }

  return new WebSocketAdapter(options.websocketUrl);
}
