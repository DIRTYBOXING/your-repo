import type { RealtimeTransport } from "./realtime_transport";

export class WebSocketAdapter implements RealtimeTransport {
  private ws: WebSocket | null = null;
  private readonly url: string;
  private messageHandler: (msg: unknown) => void = () => {};
  private openHandler: () => void = () => {};
  private closeHandler: (code: number, reason: string) => void = () => {};

  constructor(url: string) {
    this.url = url;
  }

  async connect(token: string): Promise<void> {
    const delimiter = this.url.includes("?") ? "&" : "?";
    const target = `${this.url}${delimiter}token=${encodeURIComponent(token)}`;

    await new Promise<void>((resolve, reject) => {
      const ws = new WebSocket(target);
      this.ws = ws;

      ws.onopen = () => {
        this.openHandler();
        resolve();
      };

      ws.onmessage = (event) => {
        try {
          const parsed = JSON.parse(String(event.data));
          this.messageHandler(parsed);
        } catch {
          this.messageHandler(event.data);
        }
      };

      ws.onerror = () => reject(new Error("websocket_connect_failed"));
      ws.onclose = (event) => {
        this.closeHandler(event.code, event.reason || "closed");
      };
    });
  }

  send(message: object): void {
    if (this.ws?.readyState !== WebSocket.OPEN) {
      throw new Error("websocket_not_connected");
    }

    this.ws.send(JSON.stringify(message));
  }

  onMessage(cb: (msg: unknown) => void): void {
    this.messageHandler = cb;
  }

  onOpen(cb: () => void): void {
    this.openHandler = cb;
  }

  onClose(cb: (code: number, reason: string) => void): void {
    this.closeHandler = cb;
  }

  async close(): Promise<void> {
    if (!this.ws) {
      return;
    }

    const ws = this.ws;
    await new Promise<void>((resolve) => {
      if (
        ws.readyState === WebSocket.CLOSED ||
        ws.readyState === WebSocket.CLOSING
      ) {
        resolve();
        return;
      }

      ws.onclose = (event) => {
        this.closeHandler(event.code, event.reason || "closed");
        resolve();
      };
      ws.close(1000, "client_close");
    });
  }

  isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }
}
