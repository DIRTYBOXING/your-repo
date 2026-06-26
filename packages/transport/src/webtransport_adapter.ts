import type { RealtimeTransport } from "./realtime_transport";

export class WebTransportAdapter implements RealtimeTransport {
  private readonly url: string;

  constructor(url: string) {
    this.url = url;
  }

  async connect(_token: string): Promise<void> {
    throw new Error(`webtransport_not_implemented:${this.url}`);
  }

  send(_message: object): void {
    throw new Error("webtransport_not_implemented");
  }

  onMessage(_cb: (msg: unknown) => void): void {}

  onOpen(_cb: () => void): void {}

  onClose(_cb: (code: number, reason: string) => void): void {}

  close(): Promise<void> {
    return Promise.resolve();
  }

  isConnected(): boolean {
    return false;
  }
}
