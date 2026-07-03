# AI Benchmark Plan — DFC CPU Baseline to GPU Validation

## Purpose
Create a reproducible benchmark harness that proves the operational value of GPU support for DFC AI-assisted ranking, moderation, media, and sales-support workflows.

## Primary objective
Measure the difference between current CPU baseline behavior and a future GPU-backed inference path in terms of:

- latency
- throughput
- cost per inference
- deployment complexity
- operator usefulness under real DFC workflows

## Candidate benchmark lanes

### Lane 1: Ranking assistance
- Input: canonical event or feed objects with metadata
- Task: generate ranking or prioritization signals
- Output: scored or annotated items usable in feed or storefront prioritization

### Lane 2: Promo and sales drafting
- Input: canonical event, venue, rights, and campaign metadata
- Task: generate campaign copy variants or operator suggestions
- Output: promo drafts and structured sales-support suggestions

### Lane 3: Media or evidence analysis
- Input: selected media metadata or derived assets
- Task: moderation or event-intelligence assistance
- Output: operator-facing annotations, flags, or summaries

## Benchmark environment

### CPU baseline
- Current Cloud Run-compatible path
- Same prompt and payload set used for GPU comparisons
- Fixed batch sizes and concurrency settings for reproducibility

### GPU validation target
- Containerized inference path prepared for NVIDIA or GCP GPU-backed infrastructure
- Same prompts, same payload shapes, same evaluation dataset

## Metrics to capture
- p50 latency
- p95 latency
- sustained throughput
- error rate
- cost per 1,000 requests or per inference batch
- infrastructure assumptions used during the run
- qualitative output usefulness for the operator workflow

## Output quality guardrails
- Measure performance only on tasks that are actually part of DFC product or operator workflows
- Keep a fixed evaluation dataset and prompt template set
- Record whether faster output still meets operator usefulness requirements

## Runbook

### Step 1
Pick one benchmark lane and freeze the dataset.

### Step 2
Run the CPU baseline for 24 to 48 hours or enough samples to capture stable percentiles.

### Step 3
Record latency, throughput, error rate, and estimated cost.

### Step 4
Repeat the same run on a GPU-backed path when credits or hardware become available.

### Step 5
Write a delta report showing:
- baseline metrics
- GPU metrics
- operational meaning of the change
- whether the gain is enough to justify production rollout

## Suggested report structure
- workload description
- input dataset summary
- environment and model assumptions
- CPU baseline table
- GPU comparison table
- cost interpretation
- product and operator implication
- next-step recommendation

## Immediate next steps
1. Select the first benchmark lane.
2. Build a reproducible script or notebook around that lane.
3. Capture the first CPU baseline before partner credits arrive.
4. Re-run the same harness under NVIDIA or GCP GPU support.
