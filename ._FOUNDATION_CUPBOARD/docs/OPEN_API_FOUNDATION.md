# Open API Foundation for DFC

This document outlines the initial structure for the Data Fight Central Open API, enabling partners (charities, gyms, sponsors, apps) to connect, share resources, and track impact.

## API Endpoints (Sample)

### Authentication

- POST /api/auth/login
- POST /api/auth/register

### Gyms

- GET /api/gyms (list gyms)
- POST /api/gyms (register new gym)
- GET /api/gyms/{id} (get gym details)
- PUT /api/gyms/{id} (update gym info)

### Mentors

- GET /api/mentors
- POST /api/mentors
- GET /api/mentors/{id}
- PUT /api/mentors/{id}

### Charities

- GET /api/charities
- POST /api/charities
- GET /api/charities/{id}
- PUT /api/charities/{id}

### Sponsors

- GET /api/sponsors
- POST /api/sponsors
- GET /api/sponsors/{id}
- PUT /api/sponsors/{id}

### Events

- GET /api/events
- POST /api/events
- GET /api/events/{id}
- PUT /api/events/{id}

Canonical page-truth contract for PPV and event pages:

- `GET /api/events/{id}` returns one backend truth payload:
  - `posterUrl`
  - `price`
  - `currency`
  - `entitlementRequired`
  - `venue`
  - `playback.manifestUrl`

Machine-readable schema:

- `docs/api/dfc-events-api.contract.json`

### Donations

- GET /api/donations
- POST /api/donations

### Feedback & Reporting

- POST /api/feedback (anonymous reports)

## Security

- API Key or OAuth required for all partner endpoints.
- Admin review for new partners.

## Data Model (Sample)

- Gym: id, name, location, mentors, impactStats
- Mentor: id, name, skills, gymId, impactStats
- Charity: id, name, programs, impactStats
- Sponsor: id, name, donations, impactStats
- Event: id, name, date, location, description
- Donation: id, donor, recipient, amount, cause

## Next Steps

- Implement endpoints in backend (Node.js, Python, or Dart).
- Write API documentation for partners.
- Build admin dashboard for review/approval.

---

This foundation enables rapid integration and expansion. Focus next on DFC core features and partner onboarding.
