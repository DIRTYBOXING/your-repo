const IORedis = require("ioredis");

function makeRedisConnectionFromEnv() {
  const host = process.env.REDIS_HOST || "redis";
  const port = Number(process.env.REDIS_PORT || 6379);
  const connectTimeout = Number(process.env.REDIS_CONNECT_TIMEOUT || 10000);

  const maxRetriesEnv = process.env.REDIS_MAX_RETRIES_PER_REQUEST;
  const maxRetriesPerRequest =
    maxRetriesEnv === undefined ||
    maxRetriesEnv === "" ||
    maxRetriesEnv === "null"
      ? null
      : Number(maxRetriesEnv);

  return new IORedis({
    host,
    port,
    connectTimeout,
    maxRetriesPerRequest,
  });
}

module.exports = { makeRedisConnectionFromEnv };
