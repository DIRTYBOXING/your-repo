# ╔══════════════════════════════════════════════════════════════╗
# ║  DFC CHUCKYA Control Room — React Frontend                 ║
# ║  Multi-stage: build with Node, serve with lightweight HTTP ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Stage 1: Build ──
FROM node:18-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install --production=false
COPY . .
RUN npm run build

# ── Stage 2: Serve ──
FROM node:18-alpine
WORKDIR /app
RUN npm install -g serve@14
COPY --from=build /app/dist ./dist
EXPOSE 3000
USER node
CMD ["serve", "-s", "dist", "-l", "3000"]
