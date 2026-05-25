import type { WebSocket } from 'ws';

type Client = {
  userId: string;
  socket: WebSocket;
};

const clients = new Set<Client>();

export function addClient(
  userId: string,
  socket: WebSocket,
  onMessage?: (userId: string, data: string) => void,
  onClose?: (userId: string) => void
) {
  const client = { userId, socket };
  clients.add(client);
  socket.on('close', () => {
    clients.delete(client);
    onClose?.(userId);
  });
  if (onMessage) {
    socket.on('message', (data) => onMessage(userId, data.toString()));
  }
}

export function onlineUserIds() {
  return new Set([...clients].filter((client) => client.socket.readyState === 1).map((client) => client.userId));
}

export function closeSocket(socket: WebSocket, code: number, reason: string) {
  const anySocket = socket as any;
  if (typeof anySocket.close === 'function') {
    anySocket.close(code, reason);
    return;
  }
  if (typeof anySocket.terminate === 'function') {
    anySocket.terminate();
  }
}

export function broadcastToUsers(userIds: string[], event: unknown) {
  const payload = JSON.stringify(event);
  const allowed = new Set(userIds);
  for (const client of clients) {
    if (allowed.has(client.userId) && client.socket.readyState === 1) {
      try {
        client.socket.send(payload);
      } catch {
        clients.delete(client);
        try {
          client.socket.close();
        } catch {
          // Ignore cleanup failures; a stale realtime client must not fail the API request.
        }
      }
    }
  }
}

export function sendToUsers(userIds: string[], event: unknown) {
  broadcastToUsers(userIds, event);
}
