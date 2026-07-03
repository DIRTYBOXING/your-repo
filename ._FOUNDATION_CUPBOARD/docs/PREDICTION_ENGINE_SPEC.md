# Prediction Engine Spec

## Objective

Generate event-level win probabilities and confidence scores using historical fight performance, ranking strength, style matchup context, and current readiness signals.

## Inputs

- Past performance metrics: win streak, finish rate, strike differential.
- Ranking strength: division rank and quality of opposition.
- Style matchup vectors: stance, range profile, takedown and defense matchups.
- Health and camp readiness: recent recovery and injury-risk signals.
- Fight context: rounds, weight class, short-notice status.

## Baseline Formula

For each fighter score S:

S = 0.28 * rankScore + 0.24 * pastPerformanceScore + 0.18 * styleMatchupScore + 0.18 * healthScore + 0.12 * trainingCampScore

Context multiplier C:

C = 0.5 + 0.2 * pace + 0.15 * defense + 0.15 * consistency

Adjusted score A = S * C

Probability:

P(A) = adjustedA / (adjustedA + adjustedB)
P(B) = adjustedB / (adjustedA + adjustedB)

Confidence:

confidence = abs(P(A) - P(B))

## Output Contract

- eventId
- fighterAId
- fighterBId
- probabilityA
- probabilityB
- confidence
- modelVersion

## Required Validation

- Backtest by event cohort and division.
- Calibrate confidence with reliability curves.
- Compare against market implied odds for sanity checks.
- Store modelVersion with each prediction for auditability.
