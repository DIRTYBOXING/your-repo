import os
import json
import logging
import google.generativeai as genai

logger = logging.getLogger(__name__)
genai.configure(api_key=os.getenv("GOOGLE_AI_KEY") or os.getenv("GEMINI_KEY"))
model = genai.GenerativeModel("gemini-2.0-flash")

def _clean_json(text: str) -> str:
    """Remove markdown fences and trim noise."""
    text = text.strip()

    if text.startswith("```json"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]

    return text.strip()

def call_gemini_json(prompt: str) -> dict:
    """Calls Gemini and strictly enforces a JSON dictionary response."""
    try:
        response = model.generate_content(f"{prompt}\n\nReturn ONLY valid JSON. No markdown. No commentary.")
        raw = response.text or ""
        cleaned = _clean_json(raw)
        return json.loads(cleaned)
    except Exception as e:
        logger.error(f"Gemini Inference Failed: {e}")
        return {"error": str(e)}