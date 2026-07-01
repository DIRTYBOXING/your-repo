module.exports = {
  apps: [
    {
      name: "entitlement",
      script: "entitlements-service/server.js",
      autorestart: true,
      watch: false,
      max_restarts: 10,
      env: {
        NODE_ENV: "development",
      },
    },
    {
      name: "auto-clip",
      script: "dfc-content-pipeline/auto-clip-worker/src/worker.js",
      autorestart: true,
      watch: false,
      max_restarts: 10,
      env: {
        NODE_ENV: "development",
      },
    },
  ],
};
