FROM node:18-alpine

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --production --ignore-scripts

COPY . .

ENV NODE_ENV=production
EXPOSE 8080

USER node
CMD ["node", "ws-server.js"]
