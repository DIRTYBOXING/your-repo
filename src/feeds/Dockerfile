# Dockerfile for DFC Auto-Feed Intake Service
FROM node:20-slim

WORKDIR /app

# Copy only package files first for caching
COPY ../../package.json ../../package-lock.json* ./
RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev

# Copy only the intake service and config
COPY . .
COPY ../../config/auto_feed_sources.json ./config/auto_feed_sources.json

# Install required dependencies for intake
RUN npm install rss-parser node-fetch pg

ENV NODE_ENV=production

CMD ["npx", "ts-node", "src/feeds/intake.ts"]
