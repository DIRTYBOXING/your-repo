# Operational Readiness

## Pre-Launch Checklist

- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All deployment scripts validated (deploy.sh, backup_firestore.sh)
- [ ] All documentation complete and reviewed
- [ ] All monitoring alerts configured and tested
- [ ] All dashboards live (Cloud Run, Firestore, Stripe, custom)
- [ ] Firestore security rules deployed and tested
- [ ] Storage rules deployed and tested
- [ ] Firestore indexes deployed
- [ ] Stripe webhook endpoints verified
- [ ] DNS/CDN configuration verified
- [ ] SSL certificates valid and auto-renewing
- [ ] Seed data loaded for demo/staging
- [ ] Load test completed (1,000 concurrent users)
- [ ] Penetration test completed (OWASP Top 10)
- [ ] Legal documents published (ToS, Privacy Policy, Refund Policy)
- [ ] App Store/Play Store listings prepared
- [ ] Firebase Remote Config flags set

## Launch Day

- [ ] War room active (Slack channel + monitoring screens)
- [ ] All team members on standby
- [ ] Monitoring dashboards on screen
- [ ] Fallback scripts ready (fallback_repair.js, replay_webhook.sh)
- [ ] Stripe live mode activated
- [ ] CDN cache warmed
- [ ] DNS propagation confirmed
- [ ] First user signup verified
- [ ] First purchase flow verified end-to-end
- [ ] Real-time feed verified
- [ ] Push notifications verified

## Post-Launch (24h)

- [ ] Analytics export reviewed
- [ ] Error rate < 1% confirmed
- [ ] Response time p95 < 500ms confirmed
- [ ] No critical incidents
- [ ] User feedback collection active
- [ ] First daily report generated

## Post-Launch (7 days)

- [ ] Full event report generated
- [ ] System audit completed
- [ ] Performance baseline established
- [ ] User retention metrics captured
- [ ] Revenue reconciliation completed
- [ ] Incident retrospective (if any)
- [ ] Backlog prioritized based on launch learnings
- [ ] Firestore backup verified (3 successful automated backups)

## Rollback Plan

- Cloud Run: instant rollback to previous revision
- Firestore rules: previous version stored in repo, redeploy in < 2 min
- DNS: failover to maintenance page in < 5 min
- Stripe: disable webhooks → queue events → replay after fix
- Data: Firestore point-in-time recovery (last 7 days)

## Incident Response

| Severity | Definition             | Response    | Escalation       |
| -------- | ---------------------- | ----------- | ---------------- |
| SEV-1    | Platform down          | Immediate   | All hands        |
| SEV-2    | Major feature broken   | < 30 min    | Engineering lead |
| SEV-3    | Minor feature degraded | < 2 hours   | On-call engineer |
| SEV-4    | Cosmetic / low-impact  | Next sprint | Backlog          |
