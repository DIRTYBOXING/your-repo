// DFC automation pipeline
onEventChanged(event) {
if (env === 'prod' && event.isTest) throw new Error('Test events not allowed in production.');
publishToFeed('events', event);
if (['ANNOUNCED', 'ON_SALE'].includes(event.status)) queueJob('generateEventArticle', { eventId: event.id });
queueJob('generatePromoSnippets', { eventId: event.id });
if (event.status === 'RESULTS') queueJob('generateEventRecap', { eventId: event.id });
}// DFC automation pipeline
onEventChanged(event) {
if (env === 'prod' && event.isTest) throw new Error('Test events not allowed in production.');
publishToFeed('events', event);
if (['ANNOUNCED', 'ON_SALE'].includes(event.status)) queueJob('generateEventArticle', { eventId: event.id });
queueJob('generatePromoSnippets', { eventId: event.id });
if (event.status === 'RESULTS') queueJob('generateEventRecap', { eventId: event.id });
}# CONTRIBUTING TO DFC (DATA FIGHT CENTRAL)

## Core Principles

- **NO FAKE DATA** in production. All content must be real events, fighters, promotions, or clearly marked as TEST/STAGING only.
- **NO DEMO/PLACEHOLDER CONTENT** in live environments.
- **Respect image rights:** Only use images you own, are provided by promoters/fighters for promotion, or are official posters/logos/stock/CC with license.
- **Automation-first:** All new events, articles, and feeds should be wired to automation jobs (AI article drafts, social snippets, notifications).
- **Environment discipline:**
  - `dev`/`staging`: test data must be tagged as TEST.
  - `prod`: only real data. Any dummy content is a bug.

## Content Sources

- **Events:** Connected feeds, CSV imports, or admin console only.
- **Articles:** DFC AI agents/bots or approved editors.
- **Images:** DFC-owned, promoter/fighter-provided, official posters, or licensed stock/CC.

## Automation Requirements

- New event → auto article draft (AI), social snippets, email bullet.
- Event status change → feed updates, homepage, notifications.
- All automation jobs must be idempotent and environment-aware.

## Code & AI Agent Rules

- All scripts, code, and AI agents must respect this contract.
- Any code that introduces fake/demo data to production is a critical bug.
- All automation must be explicit, not implied—use config files for feeds, agents, and article engines.

## Example Automation Spec

```ts
// DFC automation pipeline
onEventChanged(event) {
  if (env === 'prod' && event.isTest) throw new Error('Test events not allowed in production.');
  publishToFeed('events', event);
  if (['ANNOUNCED', 'ON_SALE'].includes(event.status)) queueJob('generateEventArticle', { eventId: event.id });
  queueJob('generatePromoSnippets', { eventId: event.id });
  if (event.status === 'RESULTS') queueJob('generateEventRecap', { eventId: event.id });
}
```

## Contact

For questions, contact the DFC platform owner or lead developer.
