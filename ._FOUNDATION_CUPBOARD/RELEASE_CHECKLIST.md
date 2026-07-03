# DFC Public Release Checklist

**Goal:** Prepare the repository for a clean, sponsor-ready public release.

---

## 1) Safety and Secrets

- [ ] Add or verify `.gitignore` is present and comprehensive.
- [ ] Remove or untrack any local editor configurations (e.g., `.vscode/settings.json`).
- [ ] Remove or untrack build output directories (e.g., `build/`, `bin/`, `obj/`).
- [ ] Remove or untrack any `*.env`, `*.key`, `*.pem`, `*.pfx`, or similar secret files from Git tracking.
- [ ] Search the entire repository history for accidentally committed API keys, tokens, connection strings, and private credentials.
- [ ] Replace any sensitive configuration files (like `appsettings.json`) with sanitized examples (e.g., `appsettings.example.json`).
- [ ] Confirm no real secrets remain in any committed files.

## 2) Legal and Policy Files

- [ ] Add `LICENSE` file with the full Apache License 2.0 text.
- [ ] Add `NOTICE` file for Apache attribution.
- [ ] Add `SECURITY.md` with instructions for reporting vulnerabilities.
- [ ] Add `CONTRIBUTING.md` detailing how to contribute to the project.
- [ ] Consider adding a `CODE_OF_CONDUCT.md` if you expect community contributions.

## 3) Documentation and Onboarding

- [ ] Verify `README.md` is complete and public-ready.
- [ ] Ensure the `README.md` clearly explains:
  - [ ] What DFC is and its mission.
  - [ ] How to set up and run the project locally (especially with the Firebase Emulator Suite).
  - [ ] A summary of the contribution process.
  - [ ] How to report security issues (linking to `SECURITY.md`).
  - [ ] Context for potential sponsors.
- [ ] Ensure `appsettings.example.json` and any other example config files are present and clear.
- [ ] Add a simple architecture diagram (e.g., the Mermaid diagram) to the `README.md` or `docs/`.

## 4) Repo Hygiene and Build Checks

- [ ] Run `flutter analyze` and fix all critical or blocking analyzer errors.
- [ ] Run all available automated tests and ensure they pass.
- [ ] Confirm the application builds successfully for target platforms (Web, Android, iOS).
- [ ] Confirm that core user flows can be tested locally using the Firebase Emulator Suite.
- [ ] Ensure generated artifacts are not tracked by Git unless it is intentional (e.g., for a specific deployment process).
- [ ] Confirm the lockfile policy is decided and documented:
  - [ ] Keep `pubspec.lock` for this application to ensure consistent builds.

## 5) Public vs. Private Split Verification

### Keep Public
- [ ] Flutter application source code (`lib/`).
- [ ] Public-facing UI components and services.
- [ ] All public documentation (`README.md`, `CONTRIBUTING.md`, etc.).
- [ ] Sanitized configuration examples (`appsettings.example.json`).
- [ ] Demo flows and test files that do not contain secrets.
- [ ] Public-facing architecture diagrams.

### Keep Private (in a separate repository)
- [ ] All production secrets and credentials.
- [ ] Deployment scripts that contain private values.
- [ ] Internal strategy documents and private runbooks.
- [ ] Monitoring configurations with private endpoints or keys.
- [ ] Any sponsor-only materials or contracts not intended for public view.

## 6) Release Packaging and Final Review

- [ ] Create a dedicated release branch (e.g., `release/public-v1`).
- [ ] Carefully review the diff between the release branch and the main branch.
- [ ] Open a clean Pull Request for the public release to get a final review from the team.
- [ ] Once merged, tag the release in Git (e.g., `v1.0.0`).
- [ ] Update the GitHub repository description and add relevant topics (e.g., `flutter`, `combat-sports`, `firebase`, `ppv`).
- [ ] Consider adding README badges for build status, license, etc.

## 7) Final Verification Commands

- [ ] Search for secrets one last time: `git grep -n "API_KEY\|SECRET\|PRIVATE_KEY\|TOKEN"`
- [ ] Confirm no local user-specific paths remain in any configuration files.
- [ ] Run one final local smoke test of the application.

---

### Ready to Publish When:
- [ ] No secrets are present in the public repository's history.
- [ ] All public-facing files are polished and professional.
- [ ] All private and sensitive files are securely excluded.
- [ ] The build is stable, and analysis passes cleanly.
- [ ] The `README.md` and policy documents are complete and clear.
- [ ] The repository is structured to be understandable to a new contributor.
