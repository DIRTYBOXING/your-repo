const nodeFetch = require("node-fetch");

const fetchFn =
  typeof globalThis.fetch === "function"
    ? globalThis.fetch.bind(globalThis)
    : nodeFetch.default || nodeFetch;

async function fetchModel(signals) {
  const endpoint =
    process.env.MODEL_ENDPOINT || "http://localhost:8090/predict";
  const res = await fetchFn(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ features: signals }),
  });

  if (!res.ok) {
    throw new Error(`model_http_${res.status}`);
  }

  return res.json();
}

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const signals = body.signals || {};
    const basePrice = Number(body.basePrice || 19.99);

    let modelJson = null;
    let fallbackReason = null;

    try {
      modelJson = await fetchModel(signals);
    } catch (modelErr) {
      fallbackReason = modelErr.message;
    }

    const probability =
      modelJson && typeof modelJson.probability === "number"
        ? modelJson.probability
        : 0.5;

    const demandFactor = 1 + (probability - 0.5) * 0.2;
    const price = Math.max(
      1.99,
      Math.round(basePrice * demandFactor * 100) / 100,
    );

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        price,
        model: modelJson,
        fallback: modelJson === null,
        fallbackReason,
      }),
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
