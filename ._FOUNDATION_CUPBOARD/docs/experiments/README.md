# Experimentation Platform

Deterministic experiment assignment and exposure logging.

## Assignment Algorithm

- Deterministic hash-based assignment: `hash(userId + experimentId + configVersion) % variants.length`.
- Stable across restarts for the same user+experiment when configVersion is unchanged.
- Idempotent: `/experiments/assign` returns the same variant on repeat calls.

## Exposure Contract

Exposure records include:
- `userId`
- `experimentId`
- `variant`
- `timestamp`
- `context` (`page`, `feature`)

Exposures are append-only to support analytics pipelines.

## Auditability

All experiment configuration changes create a new `configVersion` and write an entry to `experiment_audit`.

## Usage Examples

```dart
final experimentService = ExperimentService(db);
final assignmentService = AssignmentService(db);
final exposureLogger = ExposureLogger(db);

// Create experiment
final experimentId = await experimentService.createExperiment(
  experimentId: 'exp-001',
  config: {'hypothesis': 'variant_a wins'},
  variants: ['control', 'variant_a', 'variant_b'],
);

// Assign user
final assignment = await assignmentService.assign(
  userId: 'user-123',
  experimentId: experimentId,
);

// Log exposure
await exposureLogger.logExposure(
  userId: 'user-123',
  experimentId: experimentId,
  variant: assignment.variant,
  context: {'page': 'home', 'feature': 'cta'},
);
