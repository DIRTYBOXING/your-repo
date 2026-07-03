# DFC Messenger — MVP

Minimal realtime messenger MVP using Socket.io (server) and React (client).
Includes offline queue (localforage), MongoDB persistence, and simple message dedupe.

## Quick start (local)

### Server

```bash
cd server
npm install
# set env vars
export MONGO_URI="your_mongo_uri"
export PORT=3001
node server.js
```

### Client

```bash
cd client
npm install
npm start
# or build for production
npm run build
```

## Notes

- Replace prompt-based IDs with Firebase Auth for production.
- Add HTTPS, rate limiting, and input validation before public launch.
- For deployment: host server on Render/Heroku/DigitalOcean; client on Vercel/Netlify.
