import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      "/v1/device": {
        target: "http://localhost:8083",
        changeOrigin: true,
      },
      "/v1": {
        target: "http://localhost:8081",
        changeOrigin: true,
      },
      "/ws": {
        target: "ws://localhost:8084",
        ws: true,
      },
    },
  },
});
