# Trust & Safety

## Tools

- **Block system** — User-to-user blocking, content creator blocking, immediate effect
- **Report system** — Categorised reports (harassment, spam, violence, IP theft), priority queue
- **Shadow ban system** — Invisible restriction for repeat offenders, content hidden from feeds
- **Rate limiting** — API: 100 req/min per user; Posts: 10/hour; Comments: 30/hour
- **Abuse detection** — Automated pattern detection (mass reporting, coordinated harassment)
- **Appeal system** — Users can appeal moderation decisions within 14 days

## AI Moderation

- **Toxicity detection** — Real-time NLP scoring on posts, comments, chat messages
- **Spam detection** — Duplicate content, link farming, bot pattern recognition
- **Harassment detection** — Targeted language, repeated unwanted contact, doxxing attempts
- **Image safety** — NSFW detection, violence classification (combat sport vs gratuitous)
- **Deepfake detection** — AI-generated content flagging for fighter likeness protection

## Content Policies

- Combat sport content allowed (training, competition, analysis)
- Gratuitous violence/real-world fight content prohibited
- Hate speech zero tolerance (permanent ban on first severe offence)
- Fighter impersonation prohibited (verified profiles only)
- Gambling promotion restrictions (jurisdiction-dependent)

## Escalation Matrix

| Severity | Response Time | Action                           |
| -------- | ------------- | -------------------------------- |
| Critical | < 1 hour      | Immediate removal + account lock |
| High     | < 4 hours     | Content removal + warning        |
| Medium   | < 24 hours    | Review + potential removal       |
| Low      | < 72 hours    | Flag for manual review           |

## Safety Metrics (Dashboard)

- Reports per day (target: < 0.1% of active users)
- Average resolution time
- False positive rate on AI moderation
- Appeal overturn rate
