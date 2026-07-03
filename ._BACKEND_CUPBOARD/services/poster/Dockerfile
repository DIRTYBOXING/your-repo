FROM node:20-bookworm-slim

WORKDIR /app

# Install Chromium required by Puppeteer.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends chromium \
	&& rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV NODE_ENV=production

COPY package.json .
RUN npm install --omit=dev

COPY index.js template.html ./

EXPOSE 8081
CMD ["node", "index.js"]
