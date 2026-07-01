# DFC PPV Template Pack

Purpose: convert the DFC PPV master package into reusable working materials that can be issued to promoters, fighters, gyms, creators, sponsors, and internal operators.

Use this document when an event is approved for launch-pack production.

---

## 1. Pack Assembly Standard

Every PPV event should produce these named folders or equivalent storage groupings:

```text
/{event_slug}/
  /launch-pack/
  /fighter-pack/
  /gym-pack/
  /creator-pack/
  /promoter-pack/
  /sponsor-pack/
  /countdown/
  /replay-pack/
```

Recommended file-name convention:

```text
{event_slug}_{asset_type}_{variant}_{size}.{ext}
```

Examples:

- `ibc4_poster_main_1080x1350.jpg`
- `ibc4_fightcard_full_1920x1080.jpg`
- `ibc4_countdown_t24_1080x1920.jpg`
- `ibc4_caption_fighter_main.txt`

---

## 2. Launch-Pack Deliverable Matrix

| Item                | Required          | Audience                            |
| ------------------- | ----------------- | ----------------------------------- |
| Main hero poster    | yes               | all                                 |
| Full fight card     | yes               | all                                 |
| Main-event card     | yes               | fighters, promoters, creators       |
| Countdown set       | yes               | all                                 |
| Buy-now caption set | yes               | all                                 |
| Referral links      | yes               | fighters, gyms, creators, promoters |
| Payout explainer    | yes               | fighters, gyms, creators            |
| Sponsor lockup pack | if sponsors exist | sponsors, promoters                 |
| Replay pack         | after event       | all                                 |

---

## 3. Poster And Card Template Specs

### 3.1 Poster blueprint

Required fields:

- event title
- promoter name
- main event
- date and local time
- venue and city
- DFC or partner watch CTA
- live PPV badge

Safe layout zones:

- top 15 percent: logos and badges
- center 50 percent: main headline and fighters
- bottom 20 percent: date, venue, CTA

### 3.2 Fight-card blueprint

Required fields:

- main event
- co-main
- full bout order
- bout class or ruleset if relevant
- DFC branding line
- PPV CTA

### 3.3 Story asset blueprint

Required fields:

- short headline
- single CTA
- buy link or QR placement zone
- countdown or live marker

---

## 4. Caption Templates

Replace bracketed placeholders before use.

### 4.1 Master launch caption

```text
[LIVE PPV] [EVENT_TITLE] goes live on [EVENT_DATE].

Main event: [MAIN_EVENT]
Venue: [VENUE], [CITY]

Watch on Data Fight Central:
[BUY_LINK]

#[EVENT_TAG] #[CITY_TAG] #PPV #CombatSports #DataFightCentral
```

### 4.2 Fighter caption

```text
Fight night is coming.

I’m on the card for [EVENT_TITLE] on [EVENT_DATE] and you can watch it live on DFC.

Use my link to get your PPV pass:
[FIGHTER_REFERRAL_LINK]

Main event: [MAIN_EVENT]
Venue: [VENUE], [CITY]

#[FIGHTER_TAG] #[EVENT_TAG] #PPV #FightNight #DataFightCentral
```

### 4.3 Gym caption

```text
Our team is on the card for [EVENT_TITLE].

Support the gym and watch live through our event link:
[GYM_REFERRAL_LINK]

[EVENT_DATE] at [VENUE], [CITY]

#[GYM_TAG] #[EVENT_TAG] #PPV #GymLife #DataFightCentral
```

### 4.4 Creator caption

```text
[EVENT_TITLE] is nearly here.

Main event: [MAIN_EVENT]
Live on [EVENT_DATE]

Use my link for the PPV:
[CREATOR_REFERRAL_LINK]

#[EVENT_TAG] #PPV #CombatSports #CreatorPartner #DataFightCentral
```

### 4.5 Promoter caption

```text
[PROMOTER_NAME] presents [EVENT_TITLE].

Live from [VENUE], [CITY] on [EVENT_DATE].
Main event: [MAIN_EVENT]

Official PPV link:
[MASTER_BUY_LINK]

#[PROMOTER_TAG] #[EVENT_TAG] #PPV #FightNight #DataFightCentral
```

### 4.6 Replay caption

```text
Replay now available for [EVENT_TITLE].

Watch the full event or relive the headline fights on DFC:
[REPLAY_LINK]

#[EVENT_TAG] #Replay #PPV #Highlights #DataFightCentral
```

---

## 5. Countdown Templates

### 5.1 T-24h

```text
24 hours until [EVENT_TITLE].

Main event: [MAIN_EVENT]
Get your PPV pass now:
[BUY_LINK]
```

### 5.2 T-6h

```text
6 hours to go.

[EVENT_TITLE] is live today from [CITY].
Watch here:
[BUY_LINK]
```

### 5.3 T-1h

```text
1 hour until live.

If you’re watching [EVENT_TITLE], lock in your PPV now:
[BUY_LINK]
```

### 5.4 T-10m

```text
We are almost live.

[EVENT_TITLE] starts in 10 minutes.
Direct PPV link:
[BUY_LINK]
```

### 5.5 Live now

```text
LIVE NOW: [EVENT_TITLE]

Watch on DFC:
[WATCH_OR_BUY_LINK]
```

---

## 6. Activation Messages

### 6.1 Fighter activation DM

```text
Hey [FIGHTER_NAME],

Your DFC launch pack for [EVENT_TITLE] is ready.

Included:
- fighter poster
- countdown assets
- caption copy
- your referral link

Your posting windows:
- T-10 days
- T-3 days
- T-24h
- live now

Your link:
[FIGHTER_REFERRAL_LINK]

Pack location:
[PACK_LINK]
```

### 6.2 Gym activation DM

```text
Hey [GYM_NAME],

Your gym activation pack for [EVENT_TITLE] is ready.

Included:
- gym-branded poster
- story asset
- caption set
- referral link

Recommended posting days:
- T-7 days
- T-3 days
- T-24h

Pack location:
[PACK_LINK]
```

### 6.3 Creator activation DM

```text
Hey [CREATOR_NAME],

Your creator pack for [EVENT_TITLE] is ready.

Included:
- approved clips
- caption variants
- your referral link
- payout summary

Only use assets from this pack for this event.

Pack location:
[PACK_LINK]
Referral link:
[CREATOR_REFERRAL_LINK]
```

### 6.4 Sponsor delivery email

```text
Subject: [EVENT_TITLE] sponsor activation materials

Attached is the sponsor delivery pack for [EVENT_TITLE].

Included:
- sponsor lockup creative
- social and story sizes
- approved CTA copy
- tracking links
- placement schedule

Please use only the supplied assets and links for campaign reporting consistency.
```

---

## 7. Payout Explainer Template

Use this in fighter, gym, and creator packs.

```text
This event uses tracked referral attribution.

Your pack includes a unique DFC referral link. Purchases attributed through that link are used for campaign and payout reporting.

Event: [EVENT_TITLE]
Referral owner: [NAME]
Referral type: [fighter/gym/creator]
Payout model: [fixed percentage / fixed amount / campaign bonus]
Settlement timing: [for example, within 30 days of event close]

Questions or disputes:
[OWNER_NAME] — [OWNER_EMAIL]
```

---

## 8. Platform Posting Matrix

| Platform          | Best asset              | Best CTA                 |
| ----------------- | ----------------------- | ------------------------ |
| Instagram feed    | 1080x1350               | link in bio, comment CTA |
| Instagram story   | 1080x1920               | swipe or sticker link    |
| Facebook          | 1200x628 or 1080x1350   | direct PPV link          |
| X                 | 1920x1080               | direct PPV link          |
| TikTok            | 1080x1920               | story-style live CTA     |
| YouTube community | 1920x1080               | direct PPV link          |
| Email             | 1200x628                | buy-now button           |
| SMS               | text only or short link | direct PPV link          |

---

## 9. Internal Packaging Checklist

- all links tested
- all assets rights-approved
- all sizes exported
- all captions proofread
- all owner names and contacts populated
- all schedule dates match the event timezone
- replay copy withheld until replay is actually ready

This document is the reusable template layer under the DFC PPV master package.
