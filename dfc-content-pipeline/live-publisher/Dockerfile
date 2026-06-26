FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY src/ ./src/
EXPOSE 4003
CMD ["node", "src/index.js"]
