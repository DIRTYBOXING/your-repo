import localforage from "localforage";
const QUEUE_KEY = "dfc_queue";

export async function enqueue(msg) {
  const q = (await localforage.getItem(QUEUE_KEY)) || [];
  q.push(msg);
  await localforage.setItem(QUEUE_KEY, q);
}

// Remove a single message from the queue by clientId (call after server ack)
export async function dequeue(clientId) {
  const q = (await localforage.getItem(QUEUE_KEY)) || [];
  const filtered = q.filter((m) => m.clientId !== clientId);
  if (filtered.length) {
    await localforage.setItem(QUEUE_KEY, filtered);
  } else {
    await localforage.removeItem(QUEUE_KEY);
  }
}

// Flush sends all queued messages but does NOT delete them.
// They get removed one-by-one via dequeue() when the server acks.
export async function flushQueue(sendFn) {
  const q = (await localforage.getItem(QUEUE_KEY)) || [];
  for (const m of q) {
    await sendFn(m);
  }
}

export async function getQueue() {
  return (await localforage.getItem(QUEUE_KEY)) || [];
}
