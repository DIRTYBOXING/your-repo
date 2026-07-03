Area Safety Control Pilot — One Page Summary

Objective
Deliver a consent-first admin control panel for monitoring engines, issuing commands, uploading assets, and promoting jobs with audit and police escalation.

Scope
Staging pilot: 1 promoter, 1 approver, 3 responders, 5 consenting users, 1 region.

KPIs

- Area alert delivery latency target: **≤ 10s**
- Job p95 latency target: **TBD** (measure)
- Promote success rate target: **> 95%**
- False positive rate target: **< 5%**

Pilot Steps

1. Start monitoring stack and import Grafana dashboard.
2. Onboard users to staging.
3. Upload asset, run dry run, create job, request promote, approver promotes.
4. Capture Prometheus queries: p95 latency, success/failure counts, consumer lag.
5. Produce retrospective and next steps.

Contacts

- Pilot lead: [Your name]
- SRE contact: [SRE]
- Police liaison: [QPS contact if available]
