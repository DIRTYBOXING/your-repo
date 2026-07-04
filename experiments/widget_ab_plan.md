# Widget A/B Experiment Plan — One-Click Social Buy

**Goal**
- Increase click→paid conversion for social traffic (profile bio, link-in-bio, promoter posts).
- Primary metric: **Conversion Rate (click → paid)** within 10 minutes of click.

**Hypothesis**
- A single-button **"Buy Now"** widget (Variant A) will convert better than a two-step modal (Variant B) because it reduces friction and cognitive load.

**Variants**
- **Control (B0)**: Current widget (if any).
- **Variant A (one-tap)**: Single button that opens Stripe modal prefilled with SKU/ref; minimal copy.
- **Variant B (two-step)**: Button opens a confirmation modal with event details and CTA to proceed to Stripe.

**Target audience**
- Social traffic from promoter profiles and link-in-bio clicks.
- Randomize at widget load per user (client-side experiment flag) or server-side via `experiment_id` param.

**Experiment design**
- Randomization: 50% Variant A, 50% Variant B (or 33/33/33 if including control).
- Unit of randomization: **browser session** (cookie + localStorage) or `user_id` if logged in.
- Duration: minimum 14 days or until **statistical significance** reached.
- Minimum detectable effect (MDE): target +10% relative lift.

**Primary & Secondary metrics**
- **Primary**: `conversion_click_to_paid_10m` = paid orders / widget clicks within 10 minutes.
- **Secondary**:
  - `time_to_payment` median
  - `dropoff_rate` (click → open modal → start payment)
  - `avg_order_value`
  - `refund_rate` and `chargeback_rate`

**Instrumentation events**

All events include these common fields:
| Field | Type | Example |
|---|---|---|
| `experiment_id` | string | `"widget_ab_2026_06"` |
| `variant` | string | `"A"` |
| `promoter_id` | string | `"promoter_abc"` |
| `event_id` | string | `"evt_123"` |
| `sku_id` | string | `"sku_vip"` |
| `ref_code` | string | `"joe_demo"` |
| `session_id` | string | `"sess_456"` |
| `build_info` | string | `"commit_sha:abcdef123"` |
| `env` | string | `"staging"` or `"prod"` |
| `timestamp` | string (ISO 8601) | `"2026-06-27T05:00:00Z"` |

Events emitted:
1. `widget_impression`
2. `widget_click`
3. `checkout_initiated`
4. `payment_intent_created`
5. `payment_succeeded`
6. `ticket_issued`
7. `widget_experiment_assignment`

**Tracking & storage**
- Send events to analytics pipeline (Segment/Amplitude) and raw event store (Kafka/warehouse).
- Persist `experiment_id` and `variant` on `orders` table:

```sql
ALTER TABLE orders ADD COLUMN experiment_id TEXT;
ALTER TABLE orders ADD COLUMN experiment_variant TEXT;
```

**Analysis plan**
- Compare `conversion_click_to_paid_10m` between variants using proportion test (chi-square) and compute lift and 95% CI.
- Secondary: median `time_to_payment` (Mann-Whitney), AOV differences (t-test or bootstrap).
- Safety checks: compare refund/chargeback rates across variants.

**Rollout rules**
- If Variant A shows statistically significant uplift and no adverse signal (refund/chargeback increase), roll out to 100% in 48 hours.
- If adverse signals appear, pause experiment and revert.

**Implementation notes**
- Add `experiment_id` and `variant` to widget embed snippet as `data-experiment`.
- Use deterministic assignment (hash of `user_id` or `session_id`) to avoid cross-variant contamination.
- Add `experiment_id` and `variant` to Stripe PaymentIntent metadata for downstream reconciliation.
