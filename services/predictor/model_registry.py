"""
DFC Model Registry — Loads, serves, and explains ensemble fight prediction models.

Supports:
  - LightGBM for win probability (core)
  - LightGBM for method prediction (KO/Sub/Decision)
  - LightGBM for round prediction
  - Live round-by-round model
  - SHAP TreeExplainer for interpretability
  - Calibration via isotonic regression
"""

import os
import logging
from typing import Optional

import numpy as np
import joblib

log = logging.getLogger("predictor.registry")


class ModelRegistry:
    """Manages versioned model artifacts and serves predictions."""

    def __init__(self, model_dir: str = "models"):
        self.model_dir = model_dir
        self.models: dict = {}
        self.explainers: dict = {}
        self.calibrators: dict = {}
        self.version: str = "0.0.0"
        self.calibration_error: float = 0.0

    def load(self):
        """Load all available model artifacts from disk."""
        os.makedirs(self.model_dir, exist_ok=True)

        # Win probability model (core)
        self._try_load("win_prob", "win_prob_lgbm.pkl")
        # Method model (multiclass: KO, Sub, Decision)
        self._try_load("method", "method_lgbm.pkl")
        # Round prediction model
        self._try_load("rounds", "rounds_lgbm.pkl")
        # Live round-by-round model
        self._try_load("live", "live_lgbm.pkl")
        # Calibrator for win_prob
        self._try_load_calibrator("win_prob_cal", "win_prob_calibrator.pkl")

        # Load metadata
        meta_path = os.path.join(self.model_dir, "metadata.json")
        if os.path.exists(meta_path):
            import json
            with open(meta_path) as f:
                meta = json.load(f)
            self.version = meta.get("version", "0.0.0")
            self.calibration_error = meta.get("calibration_error", 0.0)
        else:
            self.version = "0.1.0-baseline"

        if not self.models:
            log.warning("No trained models found in %s — predictions will use heuristic fallback", self.model_dir)

    def _try_load(self, name: str, filename: str):
        path = os.path.join(self.model_dir, filename)
        if os.path.exists(path):
            model = joblib.load(path)
            self.models[name] = model
            log.info("Loaded model: %s from %s", name, path)
            # Try to create SHAP explainer
            try:
                import shap
                self.explainers[name] = shap.TreeExplainer(model)
                log.info("SHAP explainer created for %s", name)
            except Exception as e:
                log.debug("SHAP explainer not available for %s: %s", name, e)
        else:
            log.info("Model not found: %s (path: %s) — will use heuristic", name, path)

    def _try_load_calibrator(self, name: str, filename: str):
        path = os.path.join(self.model_dir, filename)
        if os.path.exists(path):
            self.calibrators[name] = joblib.load(path)
            log.info("Loaded calibrator: %s", name)

    def metadata(self) -> dict:
        return {
            "version": self.version,
            "models": list(self.models.keys()),
            "has_calibrator": "win_prob_cal" in self.calibrators,
            "calibration_error": self.calibration_error,
        }

    # ------ Prediction methods ------

    def predict_win_prob(self, X: np.ndarray) -> float:
        """Return calibrated P(fighter_a wins)."""
        if "win_prob" in self.models:
            raw = self.models["win_prob"].predict(X, num_iteration=self.models["win_prob"].best_iteration)[0]
            # Apply calibrator if available
            if "win_prob_cal" in self.calibrators:
                raw = self.calibrators["win_prob_cal"].predict(np.array([[raw]]))[0]
            return float(np.clip(raw, 0.01, 0.99))
        # Heuristic fallback
        return self._heuristic_win_prob(X)

    def prediction_confidence(self, X: np.ndarray) -> float:
        """Return model confidence (distance from 0.5 → rescaled 0-1)."""
        prob = self.predict_win_prob(X)
        return abs(prob - 0.5) * 2.0

    def predict_method(self, X: np.ndarray, perspective: str = "a") -> dict:
        """Return P(KO), P(Sub), P(Decision) for the winner."""
        if "method" in self.models:
            probs = self.models["method"].predict(X)[0]
            if len(probs) >= 3:
                total = sum(probs)
                if total > 0:
                    probs = [p / total for p in probs]
                return {
                    "ko_tko": round(float(probs[0]), 4),
                    "submission": round(float(probs[1]), 4),
                    "decision": round(float(probs[2]), 4),
                }
        # Heuristic fallback (use feature stats)
        return {"ko_tko": 0.35, "submission": 0.20, "decision": 0.45}

    def predict_rounds(self, X: np.ndarray, scheduled: int) -> float:
        """Predict expected number of rounds the fight lasts."""
        if "rounds" in self.models:
            pred = self.models["rounds"].predict(X)[0]
            return float(np.clip(pred, 0.5, scheduled))
        return scheduled * 0.7  # heuristic: ~70% of scheduled

    def predict_live(self, X: np.ndarray) -> float:
        """Live round-by-round win probability for fighter A."""
        if "live" in self.models:
            raw = self.models["live"].predict(X)[0]
            return float(np.clip(raw, 0.01, 0.99))
        # Fallback: use feature dominance
        if X.shape[1] >= 10:
            a_dom = X[0, 9] if X.shape[1] > 9 else 0.5
            return float(np.clip(a_dom, 0.1, 0.9))
        return 0.5

    def predict_finish_probability(self, X: np.ndarray, current_round: int, total_rounds: int) -> float:
        """Probability the fight ends by finish in remaining rounds."""
        base_finish_rate = 0.45  # historical average
        remaining = max(total_rounds - current_round, 0)
        if remaining == 0:
            return 0.0
        # Exponential decay of finish probability per remaining round
        per_round = 1.0 - (1.0 - base_finish_rate) ** (1.0 / total_rounds)
        prob_no_finish = (1.0 - per_round) ** remaining
        return float(1.0 - prob_no_finish)

    def explain(self, X: np.ndarray, feature_names: list[str], top_k: int = 8) -> list[dict]:
        """Return top-K SHAP feature contributions for the prediction."""
        if "win_prob" in self.explainers:
            try:
                shap_values = self.explainers["win_prob"].shap_values(X)
                if isinstance(shap_values, list):
                    vals = shap_values[1][0] if len(shap_values) > 1 else shap_values[0][0]
                else:
                    vals = shap_values[0]
                # Pair with names and sort by absolute magnitude
                pairs = list(zip(feature_names, vals.tolist()))
                pairs.sort(key=lambda x: abs(x[1]), reverse=True)
                return [
                    {"feature": name, "impact": round(val, 4), "direction": "favors_a" if val > 0 else "favors_b"}
                    for name, val in pairs[:top_k]
                ]
            except Exception as e:
                log.warning("SHAP explanation failed: %s", e)
        return [{"feature": "model_unavailable", "impact": 0.0, "direction": "neutral"}]

    # ------ Heuristic fallback ------

    @staticmethod
    def _heuristic_win_prob(X: np.ndarray) -> float:
        """Simple rule-based fallback when no trained model is loaded."""
        if X.shape[1] < 50:
            return 0.5
        # Use win_pct, strike_diff, and odds if available
        a_win_pct = X[0, 0]
        b_win_pct = X[0, 23]
        strike_diff_delta = X[0, 49] if X.shape[1] > 49 else 0.0
        implied_a = X[0, 55] if X.shape[1] > 55 else 0.5

        # Weighted blend
        record_signal = (a_win_pct - b_win_pct) * 0.3
        strike_signal = np.tanh(strike_diff_delta / 5.0) * 0.2
        odds_signal = (implied_a - 0.5) * 0.5

        prob = 0.5 + record_signal + strike_signal + odds_signal
        return float(np.clip(prob, 0.05, 0.95))
