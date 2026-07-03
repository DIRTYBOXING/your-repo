# moderation-worker

Responsibilities:

- Consume moderation jobs from queue.
- Run ML classifiers for text and media risk.
- Escalate uncertain/high-risk items to human review.
- Emit final verdict (`approved`, `rejected`, `pending_review`).

SLO recommendation:

- p95 moderation decision less than 5 seconds for low-risk text.
- bounded async handling for media review.
