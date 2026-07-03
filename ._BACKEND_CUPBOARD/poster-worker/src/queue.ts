import { PubSub } from "@google-cloud/pubsub";

const pubsub = new PubSub();

export async function publish(
  topicName: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await pubsub.topic(topicName).publishJSON(payload);
}
