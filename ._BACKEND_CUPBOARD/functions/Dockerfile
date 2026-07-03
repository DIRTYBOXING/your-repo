FROM node:20-slim

WORKDIR /app

# Copy function code and dependencies
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev

COPY . .

# Expose port for Cloud Run
ENV PORT=8080
EXPOSE 8080

# Simple Express wrapper that routes to both serverless handlers
CMD ["node", "server.js"]
