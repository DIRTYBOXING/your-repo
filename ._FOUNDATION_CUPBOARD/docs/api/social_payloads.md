# DFC Social Orchestrator — Platform Payloads

> Reference payloads the Social Orchestrator transforms a `SocialPost` into
> before handing off to each platform connector. The orchestrator reads a
> `SocialPost`, picks the winning (or A/B test) variant, and fans out the
> platform-specific payloads below.

---

## 1. Meta (Facebook Page + Instagram)

### Facebook Page Post (Graph API v19.0)

```
POST https://graph.facebook.com/v19.0/{page-id}/feed
Authorization: Bearer {PAGE_ACCESS_TOKEN}
```

```json
{
  "message": "🥊 UFC 313: Santos vs Aliyev — LIVE Saturday from T-Mobile Arena, Las Vegas.\n\nMain card starts 10pm ET on ESPN+ PPV.\nGet your tickets before they're gone.\n\n#UFC313 #MMA #DataFightCentral #LiveCombat #FightNight",
  "link": "https://datafightcentral.com/event/demo-ufc-313?utm_source=dfc&utm_medium=social&utm_campaign=ufc313_fight_week&utm_content=v_short",
  "published": false,
  "scheduled_publish_time": 1743379200,
  "targeting": {
    "geo_locations": {
      "countries": ["US", "AU", "GB"]
    }
  }
}
```

### Instagram Media (Graph API — carousel or single image)

```
POST https://graph.facebook.com/v19.0/{ig-user-id}/media
Authorization: Bearer {PAGE_ACCESS_TOKEN}
```

```json
{
  "image_url": "https://storage.googleapis.com/datafightcentral.appspot.com/og/ufc313_v_cinematic_full.png",
  "caption": "UFC 313 is LIVE Saturday 🔥 Santos vs Aliyev from Las Vegas.\n\nWho takes it? Drop your prediction 👇\n\n#UFC313 #MMA #DataFightCentral #FightWeek #SantosVsAliyev",
  "location_id": "261163007283996"
}
```

Then publish:

```
POST https://graph.facebook.com/v19.0/{ig-user-id}/media_publish
```

```json
{
  "creation_id": "{creation-id-from-above}"
}
```

---

## 2. X (Twitter) API v2

### Create Tweet

```
POST https://api.twitter.com/2/tweets
Authorization: Bearer {OAUTH2_USER_TOKEN}
```

```json
{
  "text": "🥊 UFC 313: Santos vs Aliyev — LIVE Saturday from T-Mobile Arena 🏟️\n\nMain card 10pm ET · ESPN+ PPV\n\n#UFC313 #MMA #FightNight\n\nhttps://datafightcentral.com/event/demo-ufc-313?utm_source=dfc&utm_medium=social&utm_campaign=ufc313_fight_week&utm_content=v_short_x",
  "media": {
    "media_ids": ["1849000000000000001"]
  },
  "poll": {
    "options": ["Santos by KO", "Aliyev by Decision", "Going the Distance"],
    "duration_minutes": 1440
  }
}
```

### Upload Media (v1.1 — still required for media)

```
POST https://upload.twitter.com/1.1/media/upload.json
Content-Type: multipart/form-data
```

Fields:

- `media_data`: base64 OG image
- `media_category`: `tweet_image`

---

## 3. YouTube (Data API v3)

### Upload Video (auto-clip highlight)

```
POST https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status
Authorization: Bearer {OAUTH2_TOKEN}
Content-Type: multipart/related
```

**Metadata part:**

```json
{
  "snippet": {
    "title": "UFC 313 Highlights: Santos vs Aliyev — Best Moments",
    "description": "The best moments from UFC 313: Santos vs Aliyev at T-Mobile Arena, Las Vegas.\n\n📺 Full event on ESPN+ PPV\n🎟️ https://datafightcentral.com/event/demo-ufc-313\n\n#UFC313 #MMA #DataFightCentral #Highlights #Santos #Aliyev",
    "tags": [
      "UFC 313",
      "MMA",
      "Santos",
      "Aliyev",
      "DataFightCentral",
      "highlights",
      "fight"
    ],
    "categoryId": "17",
    "defaultLanguage": "en"
  },
  "status": {
    "privacyStatus": "public",
    "publishAt": "2026-03-28T22:00:00Z",
    "selfDeclaredMadeForKids": false,
    "license": "youtube"
  }
}
```

**Binary part:** MP4 clip (10-30s auto-generated highlight).

### YouTube Community Post (text + image)

```
POST https://www.googleapis.com/youtube/v3/activities?part=snippet
```

> Note: Community posts require YouTube Studio API (not public REST).
> The orchestrator generates the payload and queues it for the
> YouTube Studio headless publisher or manual copy-paste pack.

---

## 4. TikTok (Content Posting API v2)

### Direct Post

```
POST https://open.tiktokapis.com/v2/post/publish/content/init/
Authorization: Bearer {TIKTOK_ACCESS_TOKEN}
Content-Type: application/json
```

```json
{
  "post_info": {
    "title": "UFC 313: Santos vs Aliyev 🔥 Who wins? #UFC313 #MMA #DataFightCentral",
    "privacy_level": "PUBLIC_TO_EVERYONE",
    "disable_duet": false,
    "disable_comment": false,
    "disable_stitch": false,
    "video_cover_timestamp_ms": 3000
  },
  "source_info": {
    "source": "PULL_FROM_URL",
    "video_url": "https://storage.googleapis.com/datafightcentral.appspot.com/clips/ufc313_highlight_30s.mp4"
  }
}
```

---

## 5. Threads (Meta Threads API)

```
POST https://graph.threads.net/v1.0/{threads-user-id}/threads
Authorization: Bearer {THREADS_ACCESS_TOKEN}
```

```json
{
  "media_type": "IMAGE",
  "image_url": "https://storage.googleapis.com/datafightcentral.appspot.com/og/ufc313_v_cinematic_full.png",
  "text": "UFC 313 is Saturday night 🥊 Santos vs Aliyev from T-Mobile Arena.\n\nPredictions? 👇\n\n#UFC313 #MMA #DataFightCentral"
}
```

Then publish:

```
POST https://graph.threads.net/v1.0/{threads-user-id}/threads_publish
```

```json
{
  "creation_id": "{creation-id-from-above}"
}
```

---

## 6. UTM Tagging Rules

All links include DFC UTM parameters:

| Parameter      | Value                                          |
| -------------- | ---------------------------------------------- |
| `utm_source`   | `dfc`                                          |
| `utm_medium`   | `social`                                       |
| `utm_campaign` | `{eventSlug}_{phase}` e.g. `ufc313_fight_week` |
| `utm_content`  | `{variantId}_{platform}` e.g. `v_short_meta`   |

---

## 7. Webhook Callback (Engagement Signal Ingest)

Platforms POST engagement data back to DFC:

```
POST https://us-central1-datafightcentral.cloudfunctions.net/api/social/signals
X-DFC-Webhook-Secret: {HMAC_SHA256_SIGNATURE}
Content-Type: application/json
```

```json
{
  "postId": "sp_ufc313_01",
  "platform": "meta_fb",
  "variantId": "v_short",
  "impressions": 12400,
  "clicks": 890,
  "reactions": 2340,
  "shares": 180,
  "watchTimeSeconds": 0,
  "ctr": 0.0718,
  "collectedAt": "2026-03-28T14:00:00Z"
}
```

The A/B selector reads these signals and auto-promotes the winning variant
when the configured `promoteAfterMinutes` threshold is reached.
