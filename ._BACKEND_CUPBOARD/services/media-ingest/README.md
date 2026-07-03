# media-ingest

Canonical owner for clip upload and transcode handoff.

Flow:

- signed upload URL
- validation and scan
- transcode and thumbnail generation
- moderation enqueue
- feed publish eligibility

Smoke check:

- upload intent -> clip object -> CDN 200.
