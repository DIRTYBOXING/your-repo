FROM node:20-slim

WORKDIR /app

# FFmpeg (required for audio analysis + clip extraction)
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

COPY package.json ./
RUN npm install --production

COPY . .

CMD ["node", "src/worker.js"]
