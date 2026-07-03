# Open Source Release Plan

## Candidate artifacts to publish
- [.github/workflows/dfc-backend-deploy.yml](c:/Data-Fight-Central-safe-bridge/.github/workflows/dfc-backend-deploy.yml)
- [atlas_backend/Dockerfile](c:/Data-Fight-Central-safe-bridge/atlas_backend/Dockerfile)
- [docs/DEPLOYMENT.md](c:/Data-Fight-Central-safe-bridge/docs/DEPLOYMENT.md)
- [atlas_backend/services/seat_hold.py](c:/Data-Fight-Central-safe-bridge/atlas_backend/services/seat_hold.py) if the interface remains domain-agnostic
- `examples/minimal-demo/` as a mocked public sample

## Boundaries
- Keep partner-specific code, data contracts, and private business logic out of the public subset.
- Publish only the deploy, runtime, and demo patterns that are reusable without exposing internal operations.
- Treat Secret Manager names and production identifiers as examples unless they are already public.

## Release steps
1. Remove private keys, internal URLs, and partner-only code.
2. Add or confirm `LICENSE`, `CONTRIBUTING.md`, and `SECURITY.md`.
3. Create a minimal demo that runs with mocked secrets.
4. Add a five-command quickstart.
5. Publish the subset and announce it alongside a sponsor roadmap.

## Minimal README quickstart
1. Clone the repo.
2. Build the demo image.
3. Run the container on port 8080.
4. Hit `/health`.
5. Review the deploy workflow and Secret Manager setup.

## Suggested GitHub features to use
- GitHub Actions environments for promotion approval
- Dependabot or equivalent dependency updates
- Code owners for public review boundaries
- GitHub Sponsors profile and funding metadata
- Security advisories and private vulnerability reporting
