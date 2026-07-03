"use strict";

function tryParseJson(value) {
  if (typeof value !== "string") {
    return value;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return trimmed;
  }

  try {
    return JSON.parse(trimmed);
  } catch {
    return value;
  }
}

function normalizeCallableResponse(body) {
  const parsed = tryParseJson(body);

  if (parsed && typeof parsed === "object" && parsed.result !== undefined) {
    return parsed.result;
  }

  return parsed;
}

function normalizeCallableError(
  input,
  fallbackMessage = "Callable request failed",
) {
  const statusCode = input?.statusCode || input?.status || 500;
  const normalizedBody = normalizeCallableResponse(
    input?.body ?? input?.responseBody ?? input,
  );
  const errorPayload =
    normalizedBody &&
    typeof normalizedBody === "object" &&
    normalizedBody.error &&
    typeof normalizedBody.error === "object"
      ? normalizedBody.error
      : null;

  const message =
    errorPayload?.message ||
    (typeof normalizedBody === "string" && normalizedBody) ||
    input?.message ||
    fallbackMessage;

  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = errorPayload?.status || input?.code || "callable_error";
  error.details = errorPayload?.details || null;
  error.body = normalizedBody;
  return error;
}

module.exports = {
  normalizeCallableError,
  normalizeCallableResponse,
};
