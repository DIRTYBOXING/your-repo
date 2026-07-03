"""
DFC Fight Predictor — Training Pipeline
=========================================
Trains LightGBM ensemble models for:
  1. Win probability (binary classification)
  2. Method of victory (multiclass: KO/TKO, Submission, Decision)
  3. Expected rounds (regression)
Plus isotonic calibration and SHAP analysis.

Usage:
  python train.py                     # Train on data/fights.parquet
  python train.py --data path.csv     # Custom data path
  python train.py --synthetic 5000    # Generate synthetic data for testing
"""

import os
import json
import argparse
import logging
from datetime import datetime

import numpy as np
import pandas as pd
import lightgbm as lgb
import joblib
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.isotonic import IsotonicRegression
from sklearn.metrics import (
    roc_auc_score, brier_score_loss, log_loss,
    accuracy_score, classification_report,
    mean_absolute_error,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s")
log = logging.getLogger("train")

MODEL_DIR = os.environ.get("MODEL_DIR", "models")


# ---------------------------------------------------------------------------
# Synthetic data generator (for bootstrapping training)
# ---------------------------------------------------------------------------
def generate_synthetic_fights(n: int = 5000, seed: int = 42) -> pd.DataFrame:
    """Generate synthetic fight data with realistic distributions."""
    rng = np.random.default_rng(seed)
    rows = []
    for _ in range(n):
        # Fighter A
        a_total = rng.integers(5, 45)
        a_win_pct = rng.beta(3, 2)
        a_wins = int(a_total * a_win_pct)
        a_losses = a_total - a_wins
        a_ko_rate = rng.beta(2, 3)
        a_sub_rate = rng.beta(1.5, 4)
        a_dec_rate = max(0, 1.0 - a_ko_rate - a_sub_rate)
        a_age = rng.normal(30, 4)
        a_height = rng.normal(180, 8)
        a_reach = a_height + rng.normal(2, 4)
        a_stance = rng.choice([0, 1, 2], p=[0.65, 0.3, 0.05])
        a_strikes = rng.normal(4.5, 1.5)
        a_strikes_abs = rng.normal(3.5, 1.5)
        a_td = rng.normal(1.5, 1.0)
        a_td_abs = rng.normal(1.0, 0.8)
        a_control = rng.normal(60, 40)
        a_sub_att = rng.exponential(0.5)
        a_win_streak = rng.integers(0, 8)
        a_loss_streak = rng.integers(0, 4)
        a_days = rng.integers(60, 400)
        a_camp = rng.integers(4, 14)
        a_short = rng.random() < 0.12

        # Fighter B (similar but independent)
        b_total = rng.integers(5, 45)
        b_win_pct = rng.beta(3, 2)
        b_wins = int(b_total * b_win_pct)
        b_losses = b_total - b_wins
        b_ko_rate = rng.beta(2, 3)
        b_sub_rate = rng.beta(1.5, 4)
        b_dec_rate = max(0, 1.0 - b_ko_rate - b_sub_rate)
        b_age = rng.normal(30, 4)
        b_height = rng.normal(180, 8)
        b_reach = b_height + rng.normal(2, 4)
        b_stance = rng.choice([0, 1, 2], p=[0.65, 0.3, 0.05])
        b_strikes = rng.normal(4.5, 1.5)
        b_strikes_abs = rng.normal(3.5, 1.5)
        b_td = rng.normal(1.5, 1.0)
        b_td_abs = rng.normal(1.0, 0.8)
        b_control = rng.normal(60, 40)
        b_sub_att = rng.exponential(0.5)
        b_win_streak = rng.integers(0, 8)
        b_loss_streak = rng.integers(0, 4)
        b_days = rng.integers(60, 400)
        b_camp = rng.integers(4, 14)
        b_short = rng.random() < 0.12

        # Differentials
        reach_diff = a_reach - b_reach
        height_diff = a_height - b_height
        age_diff = a_age - b_age
        exp_diff = a_total - b_total
        strike_diff_delta = (a_strikes - a_strikes_abs) - (b_strikes - b_strikes_abs)
        td_diff_delta = (a_td - a_td_abs) - (b_td - b_td_abs)
        control_diff = a_control - b_control

        # Context
        is_title = 1.0 if rng.random() < 0.15 else 0.0
        sched_rounds = 5.0 if is_title else 3.0
        has_odds = 1.0 if rng.random() < 0.7 else 0.0
        implied_a = rng.beta(5, 5) if has_odds else 0.5
        implied_b = 1.0 - implied_a if has_odds else 0.5
        odds_edge = implied_a - implied_b

        # --- Generate realistic label ---
        # Win probability driven by skill differential + randomness
        skill_signal = (
            (a_win_pct - b_win_pct) * 0.25
            + np.tanh(strike_diff_delta / 3) * 0.15
            + np.tanh(td_diff_delta / 2) * 0.10
            + np.tanh(control_diff / 50) * 0.05
            + (odds_edge * 0.3 if has_odds else 0.0)
        )
        noise = rng.normal(0, 0.15)
        win_prob = 1.0 / (1.0 + np.exp(-(skill_signal + noise) * 4))
        label = 1 if rng.random() < win_prob else 0

        # Method of victory
        if label == 1:
            method_probs = [a_ko_rate * 0.8, a_sub_rate * 0.6, a_dec_rate * 1.2]
        else:
            method_probs = [b_ko_rate * 0.8, b_sub_rate * 0.6, b_dec_rate * 1.2]
        total_m = sum(method_probs) or 1
        method_probs = [p / total_m for p in method_probs]
        method = rng.choice([0, 1, 2], p=method_probs)  # 0=KO, 1=Sub, 2=Dec

        # Rounds
        if method == 2:  # Decision
            rounds_lasted = sched_rounds
        else:
            rounds_lasted = rng.integers(1, int(sched_rounds) + 1)

        row = [
            a_win_pct, a_ko_rate, a_sub_rate, a_dec_rate,
            a_losses / max(a_total, 1) * a_ko_rate,  # ko_loss_rate proxy
            a_losses / max(a_total, 1) * a_sub_rate,
            a_age, a_height, a_reach, a_stance,
            a_strikes, a_strikes_abs, a_strikes - a_strikes_abs,
            a_td, a_td_abs, a_td - a_td_abs,
            a_control, a_sub_att, a_win_streak, a_loss_streak,
            a_days, a_camp, 1.0 if a_short else 0.0,

            b_win_pct, b_ko_rate, b_sub_rate, b_dec_rate,
            b_losses / max(b_total, 1) * b_ko_rate,
            b_losses / max(b_total, 1) * b_sub_rate,
            b_age, b_height, b_reach, b_stance,
            b_strikes, b_strikes_abs, b_strikes - b_strikes_abs,
            b_td, b_td_abs, b_td - b_td_abs,
            b_control, b_sub_att, b_win_streak, b_loss_streak,
            b_days, b_camp, 1.0 if b_short else 0.0,

            reach_diff, height_diff, age_diff, exp_diff,
            strike_diff_delta, td_diff_delta, control_diff,

            is_title, sched_rounds, has_odds,
            implied_a, implied_b, odds_edge,

            label, method, rounds_lasted,
        ]
        rows.append(row)

    from featurizer import Featurizer
    feature_names = Featurizer.feature_names()
    cols = feature_names + ["label", "method", "rounds_lasted"]
    return pd.DataFrame(rows, columns=cols)


# ---------------------------------------------------------------------------
# Training
# ---------------------------------------------------------------------------
def train_win_prob(X: np.ndarray, y: np.ndarray):
    """Train LightGBM binary classifier for win probability."""
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    dtrain = lgb.Dataset(X_train, label=y_train)
    dval = lgb.Dataset(X_val, label=y_val, reference=dtrain)

    params = {
        "objective": "binary",
        "metric": ["binary_logloss", "auc"],
        "learning_rate": 0.03,
        "num_leaves": 63,
        "min_child_samples": 20,
        "feature_fraction": 0.8,
        "bagging_fraction": 0.8,
        "bagging_freq": 5,
        "lambda_l1": 0.1,
        "lambda_l2": 1.0,
        "verbose": -1,
    }

    callbacks = [lgb.early_stopping(50), lgb.log_evaluation(100)]
    model = lgb.train(params, dtrain, num_boost_round=2000, valid_sets=[dval], callbacks=callbacks)

    # Evaluate
    val_pred = model.predict(X_val, num_iteration=model.best_iteration)
    auc = roc_auc_score(y_val, val_pred)
    brier = brier_score_loss(y_val, val_pred)
    ll = log_loss(y_val, val_pred)
    acc = accuracy_score(y_val, (val_pred > 0.5).astype(int))

    log.info("Win Prob — AUC: %.4f | Brier: %.4f | LogLoss: %.4f | Acc: %.4f", auc, brier, ll, acc)

    # Isotonic calibration
    calibrator = IsotonicRegression(out_of_bounds="clip")
    calibrator.fit(val_pred, y_val)
    cal_pred = calibrator.predict(val_pred)
    cal_brier = brier_score_loss(y_val, cal_pred)
    log.info("Calibrated Brier: %.4f (was %.4f)", cal_brier, brier)

    return model, calibrator, {"auc": auc, "brier": brier, "calibrated_brier": cal_brier, "log_loss": ll, "accuracy": acc}


def train_method(X: np.ndarray, y_method: np.ndarray):
    """Train multiclass model for method of victory."""
    X_train, X_val, y_train, y_val = train_test_split(X, y_method, test_size=0.2, random_state=42, stratify=y_method)
    dtrain = lgb.Dataset(X_train, label=y_train)
    dval = lgb.Dataset(X_val, label=y_val, reference=dtrain)

    params = {
        "objective": "multiclass",
        "num_class": 3,
        "metric": "multi_logloss",
        "learning_rate": 0.05,
        "num_leaves": 31,
        "verbose": -1,
    }

    callbacks = [lgb.early_stopping(50), lgb.log_evaluation(100)]
    model = lgb.train(params, dtrain, num_boost_round=1000, valid_sets=[dval], callbacks=callbacks)

    val_pred = model.predict(X_val, num_iteration=model.best_iteration)
    pred_labels = np.argmax(val_pred, axis=1)
    acc = accuracy_score(y_val, pred_labels)
    log.info("Method — Accuracy: %.4f", acc)
    log.info("\n%s", classification_report(y_val, pred_labels, target_names=["KO/TKO", "Submission", "Decision"]))

    return model, {"accuracy": acc}


def train_rounds(X: np.ndarray, y_rounds: np.ndarray):
    """Train regression model for expected rounds."""
    X_train, X_val, y_train, y_val = train_test_split(X, y_rounds, test_size=0.2, random_state=42)
    dtrain = lgb.Dataset(X_train, label=y_train)
    dval = lgb.Dataset(X_val, label=y_val, reference=dtrain)

    params = {
        "objective": "regression",
        "metric": "mae",
        "learning_rate": 0.05,
        "num_leaves": 31,
        "verbose": -1,
    }

    callbacks = [lgb.early_stopping(50), lgb.log_evaluation(100)]
    model = lgb.train(params, dtrain, num_boost_round=1000, valid_sets=[dval], callbacks=callbacks)

    val_pred = model.predict(X_val, num_iteration=model.best_iteration)
    mae = mean_absolute_error(y_val, val_pred)
    log.info("Rounds — MAE: %.4f", mae)

    return model, {"mae": mae}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="DFC Fight Predictor Training")
    parser.add_argument("--data", type=str, default=None, help="Path to training data (CSV or Parquet)")
    parser.add_argument("--synthetic", type=int, default=0, help="Generate N synthetic fights for testing")
    args = parser.parse_args()

    os.makedirs(MODEL_DIR, exist_ok=True)

    # Load or generate data
    if args.synthetic > 0:
        log.info("Generating %d synthetic fights …", args.synthetic)
        df = generate_synthetic_fights(args.synthetic)
    elif args.data:
        ext = os.path.splitext(args.data)[1].lower()
        df = pd.read_parquet(args.data) if ext == ".parquet" else pd.read_csv(args.data)
    else:
        log.error("Provide --data <path> or --synthetic <N>")
        return

    log.info("Training data: %d fights, %d features", len(df), df.shape[1] - 3)

    from featurizer import Featurizer
    feature_cols = Featurizer.feature_names()
    X = df[feature_cols].values
    y_win = df["label"].values
    y_method = df["method"].values
    y_rounds = df["rounds_lasted"].values

    # Train models
    log.info("=" * 60)
    log.info("Training win probability model …")
    win_model, calibrator, win_metrics = train_win_prob(X, y_win)

    log.info("=" * 60)
    log.info("Training method model …")
    method_model, method_metrics = train_method(X, y_method)

    log.info("=" * 60)
    log.info("Training rounds model …")
    rounds_model, rounds_metrics = train_rounds(X, y_rounds)

    # Save
    joblib.dump(win_model, os.path.join(MODEL_DIR, "win_prob_lgbm.pkl"))
    joblib.dump(calibrator, os.path.join(MODEL_DIR, "win_prob_calibrator.pkl"))
    joblib.dump(method_model, os.path.join(MODEL_DIR, "method_lgbm.pkl"))
    joblib.dump(rounds_model, os.path.join(MODEL_DIR, "rounds_lgbm.pkl"))

    # Save metadata
    metadata = {
        "version": f"1.0.0-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}",
        "trained_at": datetime.utcnow().isoformat(),
        "num_fights": len(df),
        "win_metrics": win_metrics,
        "method_metrics": method_metrics,
        "rounds_metrics": rounds_metrics,
        "calibration_error": win_metrics["calibrated_brier"],
    }
    with open(os.path.join(MODEL_DIR, "metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2, default=str)

    log.info("=" * 60)
    log.info("All models saved to %s/", MODEL_DIR)
    log.info("Metadata: %s", json.dumps(metadata, indent=2, default=str))


if __name__ == "__main__":
    main()
