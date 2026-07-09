# Partner Pilot Brief (One-Pager)

**TO**: [Partner Name]
**FROM**: [Your Name], Data Fight Central
**DATE**: July 9, 2026
**RE**: 3-Week PPV Attribution Pilot Opportunity

---

## The Hook

**Real-time clip attribution drives measurable PPV lift.**

We just proved it: Creator Kai Reeves earned **$2,450.50** in 48 hours from 5 auto-generated clips, with **full per-clip attribution**. Her top clip converted at **3.2%** (15K views → 399 PPV purchases → $275 revenue).

We want to prove the same for your event. No long-term commitment. One event. 3 weeks of data. Exact ROI calculation.

---

## The Problem (Your Pain)

- ❌ Short moments go viral, but you can't measure which ones drive PPV lift
- ❌ Creators post clips blindly (no real-time feedback = poor optimization)
- ❌ You leave PPV revenue on the table (clips are underlevered or missing)
- ❌ Attribution is manual and delayed (weeks to analyze)

---

## The Solution (DFC)

**Orchestration** → **Auto-Clip** → **Viral Feed** → **Real-Time Attribution** → **Measurable PPV Lift**

- ✅ Event marker (knockout, submission) → auto-clip within 2–5s
- ✅ Clip in feed within 2–3s (fans discover, engage, click PPV)
- ✅ Conversion attributed to clip in real-time (full audit trail)
- ✅ Dashboard shows exact incremental revenue per clip per event

---

## The Proof (Kai Reeves Pilot)

| Metric                     | Result                             |
| -------------------------- | ---------------------------------- |
| Clips Generated            | 5                                  |
| Total Views                | 285K                               |
| Total Engagement           | 18.4K likes + 2.8K shares          |
| Total PPV Conversions      | 1,120+                             |
| **Total Creator Earnings** | **$2,450.50**                      |
| **Top Clip Performance**   | 15K views → 399 conversions → $275 |
| **Conversion Rate**        | 3.2% (vs. 0.5–2% industry avg)     |
| **Time to Feed**           | 2–3 seconds                        |
| **Time to Attribution**    | <100ms (server-validated)          |

**Your Expected PPV Lift**: +5–8% incremental per event (based on Kai's conversion rate)

---

## The Pilot (3 Weeks, No Strings)

### Week 1 — Integration

- You provide: event marker schema + 1 live event details
- We provide: sandbox credentials, webhook setup, API docs
- Deliverable: Integration tested, markers flowing, clips generating

### Week 2 — Execution

- Live event with DFC clipping active
- 3–5 auto-generated highlights from your event
- Co-promotion to DFC creators (10K+ reach)
- Real-time engagement + conversion tracking

### Week 3 — Analysis

- Full attribution breakdown by clip
- PPV lift calculation (baseline vs. clipped moments)
- ROI report: incremental revenue, creator engagement, platform lift
- Playbook for scaling to all future events

**Your Commitment**: Provide event data + 1 co-marketing mention (optional)
**Our Commitment**: End-to-end integration, monitoring, detailed analysis

---

## The Financials (Example)

**Scenario**: PPV event with 50K buy-ins at $15 each

```
Baseline PPV Revenue:           $750,000

Incremental from DFC Clips:     +5–8% ($37,500–$60,000)
├─ Creator Revenue Share (70%): -$26,250–$42,000
├─ DFC Platform Fee (30%):      +$11,250–$18,000
└─ Your Net Lift:               +$11,250–$18,000 per event

Annual Lift (12 events):        $135,000–$216,000
```

**ROI**: Pay DFC platform fee on incremental revenue; keep the rest.

---

## The Next Steps

**If you're interested:**

1. **Reply with "yes"** → We send sandbox credentials + webhook schema
2. **15-min call** → Map your event calendar, confirm marker format
3. **7-day integration** → Your team + our team sync markers to DFC
4. **Go live** → Next event runs with clipping active
5. **Measure** → Full report + decision to continue

**If you want a demo first:**

- We can show you Kai Reeves' live dashboard (earnings, clips, trending scores)
- 30-min technical walkthrough of the API + sandbox
- Zero pressure, zero cost

---

## Sandbox Access (Once You Say Yes)

We'll provide:

- **API Endpoint**: `https://sandbox.dfc.app/api/v1`
- **Auth Token**: Bearer `{token}` (valid for pilot duration)
- **Webhook URL**: `https://your-domain.com/webhooks/dfc-events` (you configure)
- **Rate Limit**: 1,000 requests/hour (ample for pilot)
- **Data**: Anonymized + non-production credentials

**Event Marker Schema** (sample):

```json
{
  "eventId": "your_event_001",
  "fighterId_a": "fighter_001",
  "fighterId_b": "fighter_002",
  "markers": [
    {
      "timestamp": "2026-07-09T14:32:15Z",
      "eventType": "knockout",
      "round": 2,
      "description": "Left hook KO"
    }
  ]
}
```

**Clip Read API** (we'll provide):

```
GET /api/v1/events/{eventId}/clips
→ Returns: clipId, title, videoUrl, views, conversions, revenue, createdAt
```

---

## Timeline (Can Start Immediately)

- **Today** → You confirm interest
- **Tomorrow** → Credentials + kickoff call
- **Day 3–7** → Integration build
- **Day 8–14** → Next live event (pilot runs)
- **Day 15–21** → Analysis + report

---

## Why Partner With Us Now

1. **First-mover advantage** — Be the first in your sport with real-time clip attribution
2. **Measurable ROI** — We prove +5–8% PPV lift with data, not projections
3. **Creator loyalty** — Happy creators = more content, better clips, repeat events
4. **Repeatable** — Playbook scales to all future events (low incremental cost)

---

## Questions to Discuss on the Call

1. How many events/year can you commit to the pilot?
2. What's your current event marker infrastructure (API, webhook, logs)?
3. Do you have a preferred creator roster to seed clips with?
4. What's your acceptable PPV lift threshold to continue after pilot?

---

## Contact

**Name**: {your_name}
**Title**: {your_title}
**Email**: partnerships@dfc.app
**Phone**: {your_phone}
**Timezone**: {your_tz}

**Ready to start?** Reply "yes" or schedule here: [calendly_link]

---

## Appendix: Quick FAQ

**Q: Is this a white-label solution?**
A: No. DFC branding is visible but non-intrusive. Co-branding available for partners.

**Q: What if the clips don't perform?**
A: That's the value of the data. If conversion rate is <2%, we iterate messaging/timing and improve.

**Q: Can we integrate with our existing PPV system?**
A: Yes. We measure incremental lift alongside your current system.

**Q: Is there a minimum commit after the pilot?**
A: No. Pilot is no-strings. If you love the results, we scale with volume-based SLAs.

**Q: How long does integration take?**
A: 3–7 days (assuming you have event marker data already).

**Q: What about creator data privacy?**
A: Creators own their data. We store audit trails for 90 days, then archive. Privacy-first.

---

**The closed loop is proven. Now let's measure it for your event.** 🚀
