export interface RealtimeTransport {
  connect(token: string): Promise<void>;
  send(message: object): void;
  onMessage(cb: (msg: unknown) => void): void;
  onOpen(cb: () => void): void;
  onClose(cb: (code: number, reason: string) => void): void;
  close(): Promise<void>;
  isConnected(): boolean;
}
