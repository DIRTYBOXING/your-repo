const fs = require('fs');
const path = require('path');

const openapiSpec = {
  openapi: "3.0.3",
  info: {
    title: "Data Fight Central (DFC) API - Protocol v1",
    description: "The canonical integration standard for the global combat sports ecosystem.",
    version: "1.0.0"
  },
  servers: [
    {
      url: "https://api.datafightcentral.com/v1",
      description: "Production Environment"
    },
    {
      url: "http://localhost:5001/datafightcentral/us-central1/api/v1",
      description: "Local Emulator"
    }
  ],
  paths: {
    "/fighters": {
      get: {
        summary: "List all fighters in the global registry",
        responses: {
          "200": { description: "Successful response" }
        }
      }
    },
    "/gyms": {
      get: {
        summary: "List registered training gyms and academies",
        responses: {
          "200": { description: "Successful response" }
        }
      }
    },
    "/events": {
      get: {
        summary: "List combat sports events",
        responses: {
          "200": { description: "Successful response" }
        }
      }
    },
    "/events/{eventId}/ppv": {
      get: {
        summary: "Retrieve PPV and streaming metadata for an event",
        parameters: [
          {
            name: "eventId",
            in: "path",
            required: true,
            schema: { type: "string" }
          }
        ],
        responses: {
          "200": { description: "Successful response" }
        }
      }
    }
  },
  components: {
    securitySchemes: {
      BearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT"
      }
    }
  },
  security: [
    { BearerAuth: [] }
  ]
};

// Ensure the docs folder exists
const docsDir = path.join(__dirname, '../docs');
if (!fs.existsSync(docsDir)) {
  fs.mkdirSync(docsDir, { recursive: true });
}

const targetFile = path.join(docsDir, 'openapi_v1.json');

fs.writeFileSync(
  targetFile,
  JSON.stringify(openapiSpec, null, 2),
  'utf8'
);

console.log(`✅ Successfully generated DFC Protocol v1 OpenAPI Spec at:`);
console.log(`   ${targetFile}`);
