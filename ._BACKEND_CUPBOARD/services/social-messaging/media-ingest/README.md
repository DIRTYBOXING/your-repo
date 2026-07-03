# media-ingest

Responsibilities:

- Receive upload intents and signed upload URLs.
- Validate file type, size, and malware posture.
- Trigger transcode and thumbnail jobs.
- Emit moderation job for every clip.

Canonical flow:

upload -> scan -> transcode -> object store -> CDN URL -> moderation queue -> feed eligibility
