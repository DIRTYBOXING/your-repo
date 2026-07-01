"""
DFC Featurizer — Transform fighter profiles and live data into ML feature vectors.
"""

import numpy as np
from typing import Optional


STANCE_MAP = {"orthodox": 0, "southpaw": 1, "switch": 2}
WEIGHT_CLASS_ORDER = [
    "strawweight", "flyweight", "bantamweight", "featherweight",
    "lightweight", "welterweight", "middleweight", "light_heavyweight",
    "heavyweight", "super_heavyweight",
]


class Featurizer:
    """Stateless feature builder — converts API payloads into numpy arrays."""

    @staticmethod
    def feature_names() -> list[str]:
        return [
            # Fighter A stats
            "a_win_pct", "a_ko_rate", "a_sub_rate", "a_dec_rate",
            "a_ko_loss_rate", "a_sub_loss_rate",
            "a_age", "a_height_cm", "a_reach_cm", "a_stance",
            "a_strikes_landed", "a_strikes_absorbed", "a_strike_diff",
            "a_td_landed", "a_td_absorbed", "a_td_diff",
            "a_control_time", "a_sub_attempts",
            "a_win_streak", "a_loss_streak",
            "a_days_since_fight", "a_camp_weeks", "a_short_notice",
            # Fighter B stats (mirrored)
            "b_win_pct", "b_ko_rate", "b_sub_rate", "b_dec_rate",
            "b_ko_loss_rate", "b_sub_loss_rate",
            "b_age", "b_height_cm", "b_reach_cm", "b_stance",
            "b_strikes_landed", "b_strikes_absorbed", "b_strike_diff",
            "b_td_landed", "b_td_absorbed", "b_td_diff",
            "b_control_time", "b_sub_attempts",
            "b_win_streak", "b_loss_streak",
            "b_days_since_fight", "b_camp_weeks", "b_short_notice",
            # Differential features
            "reach_diff", "height_diff", "age_diff", "experience_diff",
            "strike_diff_delta", "td_diff_delta", "control_diff",
            # Context
            "is_title_fight", "scheduled_rounds", "has_odds",
            "implied_prob_a", "implied_prob_b", "odds_edge",
        ]

    def build_fight_features(self, req) -> list[float]:
        a = req.fighter_a
        b = req.fighter_b

        def _fighter_vec(f):
            total = max(f.wins + f.losses + f.draws, 1)
            win_pct = f.wins / total
            ko_rate = f.ko_wins / max(f.wins, 1)
            sub_rate = f.sub_wins / max(f.wins, 1)
            dec_rate = f.dec_wins / max(f.wins, 1)
            ko_loss_rate = f.ko_losses / max(f.losses, 1)
            sub_loss_rate = f.sub_losses / max(f.losses, 1)
            strike_diff = f.avg_sig_strikes_landed - f.avg_sig_strikes_absorbed
            td_diff = f.avg_takedowns_landed - f.avg_takedowns_absorbed
            return [
                win_pct, ko_rate, sub_rate, dec_rate,
                ko_loss_rate, sub_loss_rate,
                f.age, f.height_cm, f.reach_cm,
                STANCE_MAP.get(f.stance.lower(), 0),
                f.avg_sig_strikes_landed, f.avg_sig_strikes_absorbed, strike_diff,
                f.avg_takedowns_landed, f.avg_takedowns_absorbed, td_diff,
                f.avg_control_time_sec, f.avg_sub_attempts,
                f.win_streak, f.loss_streak,
                f.days_since_last_fight, f.camp_weeks,
                1.0 if f.is_short_notice else 0.0,
            ]

        va = _fighter_vec(a)
        vb = _fighter_vec(b)

        # Differential features
        reach_diff = a.reach_cm - b.reach_cm
        height_diff = a.height_cm - b.height_cm
        age_diff = a.age - b.age
        exp_a = a.wins + a.losses + a.draws
        exp_b = b.wins + b.losses + b.draws
        experience_diff = exp_a - exp_b
        strike_diff_delta = (a.avg_sig_strikes_landed - a.avg_sig_strikes_absorbed) - \
                            (b.avg_sig_strikes_landed - b.avg_sig_strikes_absorbed)
        td_diff_delta = (a.avg_takedowns_landed - a.avg_takedowns_absorbed) - \
                        (b.avg_takedowns_landed - b.avg_takedowns_absorbed)
        control_diff = a.avg_control_time_sec - b.avg_control_time_sec

        # Context
        is_title = 1.0 if req.is_title_fight else 0.0
        sched_rounds = float(req.scheduled_rounds)

        # Odds-implied probabilities (if available)
        has_odds = 0.0
        implied_a = 0.5
        implied_b = 0.5
        odds_edge = 0.0
        if req.betting_odds_a and req.betting_odds_b:
            has_odds = 1.0
            implied_a = 1.0 / req.betting_odds_a
            implied_b = 1.0 / req.betting_odds_b
            total_impl = implied_a + implied_b
            if total_impl > 0:
                implied_a /= total_impl  # normalize overround
                implied_b /= total_impl
            odds_edge = implied_a - implied_b

        context = [
            reach_diff, height_diff, age_diff, experience_diff,
            strike_diff_delta, td_diff_delta, control_diff,
            is_title, sched_rounds, has_odds,
            implied_a, implied_b, odds_edge,
        ]

        return va + vb + context

    def build_live_features(self, update) -> list[float]:
        """Build feature vector from round-by-round live data."""
        round_num = update.round_num
        a_output = update.fighter_a_strikes + update.fighter_a_takedowns * 3 + update.fighter_a_knockdowns * 10
        b_output = update.fighter_b_strikes + update.fighter_b_takedowns * 3 + update.fighter_b_knockdowns * 10
        control_diff = update.fighter_a_control_sec - update.fighter_b_control_sec

        # Normalized per-round
        total_output = max(a_output + b_output, 1)
        a_dominance = a_output / total_output
        b_dominance = b_output / total_output

        return [
            float(round_num),
            float(update.fighter_a_strikes),
            float(update.fighter_b_strikes),
            float(update.fighter_a_takedowns),
            float(update.fighter_b_takedowns),
            float(update.fighter_a_control_sec),
            float(update.fighter_b_control_sec),
            float(update.fighter_a_knockdowns),
            float(update.fighter_b_knockdowns),
            a_dominance,
            b_dominance,
            float(control_diff),
            a_output - b_output,  # output differential
        ]

    @staticmethod
    def compute_momentum(update) -> float:
        """Positive = A gaining momentum, negative = B gaining."""
        a_score = (
            update.fighter_a_strikes * 1.0
            + update.fighter_a_takedowns * 3.0
            + update.fighter_a_knockdowns * 10.0
            + update.fighter_a_control_sec * 0.05
        )
        b_score = (
            update.fighter_b_strikes * 1.0
            + update.fighter_b_takedowns * 3.0
            + update.fighter_b_knockdowns * 10.0
            + update.fighter_b_control_sec * 0.05
        )
        total = max(a_score + b_score, 1.0)
        return (a_score - b_score) / total
