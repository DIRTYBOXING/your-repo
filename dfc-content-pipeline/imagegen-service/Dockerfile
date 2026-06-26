FROM node:20-alpine
RUN apk add --no-cache build-base g++ cairo-dev pango-dev jpeg-dev giflib-dev librsvg-dev
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY src/ ./src/
COPY templates/ ./templates/
EXPOSE 4002
CMD ["node", "src/index.js"]
