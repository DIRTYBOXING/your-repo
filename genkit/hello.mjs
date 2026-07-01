import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { enableFirebaseTelemetry } from "@genkit-ai/firebase";
import { genkit } from "genkit";
import { googleAI, gemini } from "@genkit-ai/googleai";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.resolve(__dirname, "..", ".env");

if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, "utf8");
  for (const line of envContent.split(/\r?\n/)) {
    if (!line || line.startsWith("#") || !line.includes("=")) continue;
    const [key, ...rest] = line.split("=");
    if (!process.env[key]) {
      process.env[key] = rest.join("=");
    }
  }
}

process.env.GOOGLE_CLOUD_PROJECT ??= "datafightcentral";

enableFirebaseTelemetry();

const ai = genkit({
  plugins: [
    googleAI({
      apiVersion: "v1beta",
      models: ["gemini-2.5-flash"],
    }),
  ],
});

const helloFlow = ai.defineFlow("helloFlow", async (name) => {
  const { text } = await ai.generate({
    model: gemini("gemini-2.5-flash"),
    prompt: `Hello Gemini, my name is ${name}`,
  });
  console.log(text);
});

helloFlow("Chris");
