# DFCalive Social and SEO Launch Pack

## OG Image Template Spec

| Property   | Value                                                               |
| ---------- | ------------------------------------------------------------------- |
| Size       | 1200 x 630 px                                                       |
| Format     | JPEG (quality 90) or PNG                                            |
| Background | Dark gradient (#0D0D0D → #1a1a2e) matching DFC neon theme           |
| Elements   | Event title, date, venue/city, promoter logo, "LIVE PPV" badge, CTA |

### Text Layout

```
┌──────────────────────────────────────────────┐
│                                              │
│   [PROMOTER LOGO]          [DFC LOGO]        │
│                                              │
│   ██████████████████████████████████         │
│   █  {{event.title}}               █         │
│   █  LIVE PPV                      █         │
│   ██████████████████████████████████         │
│                                              │
│   {{event.venue}} • {{event.date}}           │
│                                              │
│   ┌──────────────┐                           │
│   │   BUY NOW    │                           │
│   └──────────────┘                           │
│                                              │
│   www.datafightcentral.com                   │
└──────────────────────────────────────────────┘
```

### 3 OG Variants for A/B Testing

- **Variant A**: Hero fighter image crop + event title overlay
- **Variant B**: Venue/city skyline background + fight card text
- **Variant C**: Face-off silhouette + "LIVE" countdown badge

---

## HTML Meta Tags (copy-paste per event page)

```html
<!-- Primary OG -->
<meta property="og:type" content="website" />
<meta
  property="og:title"
  content="{{event.title}} — Live on Data Fight Central"
/>
<meta property="og:description" content="{{event.short_description}}" />
<meta
  property="og:image"
  content="https://www.datafightcentral.com/assets/events/{{event.slug}}_og.jpg"
/>
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta
  property="og:url"
  content="https://www.datafightcentral.com/events/{{event.slug}}"
/>
<meta property="og:site_name" content="Data Fight Central" />

<!-- Twitter/X -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="{{event.title}} — Live PPV" />
<meta name="twitter:description" content="{{event.short_description}}" />
<meta
  name="twitter:image"
  content="https://www.datafightcentral.com/assets/events/{{event.slug}}_og.jpg"
/>

<!-- Canonical -->
<link
  rel="canonical"
  href="https://www.datafightcentral.com/events/{{event.slug}}"
/>
```

---

## JSON-LD Structured Data (schema.org Event)

```json
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "{{event.title}}",
  "startDate": "{{event.start_iso}}",
  "endDate": "{{event.end_iso}}",
  "eventAttendanceMode": "https://schema.org/OnlineEventAttendanceMode",
  "eventStatus": "https://schema.org/EventScheduled",
  "location": {
    "@type": "Place",
    "name": "{{event.venue}}",
    "address": "{{event.address}}"
  },
  "image": [
    "https://www.datafightcentral.com/assets/events/{{event.slug}}_og.jpg"
  ],
  "description": "{{event.short_description}}",
  "organizer": {
    "@type": "Organization",
    "name": "Data Fight Central",
    "url": "https://www.datafightcentral.com"
  },
  "offers": {
    "@type": "Offer",
    "url": "https://www.datafightcentral.com/events/{{event.slug}}",
    "price": "{{price}}",
    "priceCurrency": "AUD",
    "availability": "https://schema.org/InStock",
    "validFrom": "{{sale_start_iso}}"
  },
  "performer": [
    {
      "@type": "Person",
      "name": "{{fighter_1_name}}"
    },
    {
      "@type": "Person",
      "name": "{{fighter_2_name}}"
    }
  ]
}
```

### VideoObject (for highlights/clips after event)

```json
{
  "@context": "https://schema.org",
  "@type": "VideoObject",
  "name": "{{event.title}} — Official Highlights",
  "description": "Watch the official highlights from {{event.title}}.",
  "thumbnailUrl": "https://www.datafightcentral.com/assets/events/{{event.slug}}_thumb.jpg",
  "uploadDate": "{{upload_date_iso}}",
  "duration": "PT15S",
  "contentUrl": "https://www.datafightcentral.com/clips/{{event.slug}}_highlight.mp4",
  "embedUrl": "https://www.datafightcentral.com/embed/{{event.slug}}"
}
```

---

## UTM Scheme

| Parameter      | Values                                                  |
| -------------- | ------------------------------------------------------- |
| `utm_source`   | `facebook`, `x`, `youtube`, `instagram`, `email`, `sms` |
| `utm_medium`   | `organic`, `paid`, `email`, `sms`, `push`               |
| `utm_campaign` | `{event_slug}_{stage}` (e.g. `jones-vs-smith_announce`) |
| `utm_content`  | `variant_a`, `variant_b`, `variant_c` (for A/B tests)   |

### Example URLs

```
https://www.datafightcentral.com/events/jones-vs-smith?utm_source=facebook&utm_medium=organic&utm_campaign=jones-vs-smith_announce&utm_content=variant_a
https://www.datafightcentral.com/events/jones-vs-smith?utm_source=x&utm_medium=organic&utm_campaign=jones-vs-smith_countdown7&utm_content=variant_b
```

---

## Social Post Templates

### Announcement (T-21)

```
[LIVE PPV] {{event.title}} — {{event.date}}

Tickets and PPV now available. Watch worldwide on Data Fight Central.

Buy now: https://www.datafightcentral.com/events/{{event.slug}}?utm_source={{platform}}&utm_medium=organic&utm_campaign={{event.slug}}_announce

#CombatSports #PPV #LiveFighting #DataFightCentral #{{city}}
```

### Fighter Spotlight (T-14)

```
Meet {{fighter.name}} — {{fighter.record}} | {{fighter.style}}

Watch them compete LIVE at {{event.title}} on {{event.date}}.

PPV available now: https://...?utm_campaign={{event.slug}}_spotlight

#{{fighter.style}} #FighterSpotlight #DataFightCentral
```

### 7-Day Countdown (T-7)

```
7 DAYS until {{event.title}} 🔥

Secure your PPV pass now. Exclusive highlights and fighter breakdowns dropping this week.

https://...?utm_campaign={{event.slug}}_countdown7

#Countdown #LivePPV #CombatSports #DataFightCentral
```

### Last Chance (T-1)

```
TOMORROW: {{event.title}} goes LIVE.

Last chance to lock in your PPV pass. Don't miss it.

https://...?utm_campaign={{event.slug}}_lastchance

#FightNight #PPV #DataFightCentral
```

### Event Day Reminder

```
LIVE NOW: {{event.title}}

Tune in now on Data Fight Central. PPV still available.

https://...?utm_campaign={{event.slug}}_live

#LiveNow #PPV #CombatSports
```

### Post-Event Highlights (T+1)

```
Watch the official highlights from {{event.title}}.

Full VOD available now. Relive every round.

https://...?utm_campaign={{event.slug}}_highlights

#Highlights #VOD #DataFightCentral
```

---

## LLM Caption Generator Prompt

```
Generate 3 social captions for a combat sports event titled "{{event.title}}" on {{event.date}} at {{event.venue}}, {{event.city}}.

Requirements:
- Tone: punchy, urgent, local. No corny one-liners.
- Caption lengths: short (< 80 chars), medium (80-160 chars), long (160-280 chars).
- Include 5 hashtags relevant to combat sports and the city.
- Provide one 20-character headline for the OG image.

Output format (JSON):
{
  "captions": {
    "short": "...",
    "medium": "...",
    "long": "..."
  },
  "hashtags": ["#...", "#...", "#...", "#...", "#..."],
  "og_headline": "..."
}
```

---

## 30-Day Posting Calendar

| Day            | Activity                               | Platform               | UTM Campaign          |
| -------------- | -------------------------------------- | ---------------------- | --------------------- |
| T-21           | Announcement post + OG image           | Facebook, X, Instagram | `{slug}_announce`     |
| T-20           | Share announcement to fight groups     | Facebook Groups        | `{slug}_announce`     |
| T-18           | Fighter 1 spotlight (clip + bio)       | All                    | `{slug}_spotlight_f1` |
| T-16           | Fighter 2 spotlight (clip + bio)       | All                    | `{slug}_spotlight_f2` |
| T-14           | Full fight card reveal                 | All                    | `{slug}_fightcard`    |
| T-12           | Behind-the-scenes training clip        | Instagram, YouTube     | `{slug}_bts`          |
| T-10           | Venue/city hype post                   | Facebook, Instagram    | `{slug}_venue`        |
| T-7            | 7-day countdown                        | All                    | `{slug}_countdown7`   |
| T-5            | Paid ad launch (Variant A vs B)        | Facebook, Instagram    | `{slug}_paid`         |
| T-3            | 3-day countdown + early bird reminder  | All                    | `{slug}_countdown3`   |
| T-2            | Press/media post (quote from promoter) | X, Facebook            | `{slug}_press`        |
| T-1            | Last chance post + retarget audience   | All                    | `{slug}_lastchance`   |
| Event Day (AM) | Morning reminder                       | All                    | `{slug}_dayof`        |
| Event Day (PM) | LIVE NOW post                          | All                    | `{slug}_live`         |
| T+1            | Official highlights clip (15s)         | All                    | `{slug}_highlights`   |
| T+2            | Full VOD available post                | All                    | `{slug}_vod`          |
| T+3            | Fighter reaction/interview clip        | YouTube, Instagram     | `{slug}_reaction`     |
| T+5            | Best moments compilation               | All                    | `{slug}_bestof`       |
| T+7            | Next event teaser (if scheduled)       | All                    | `{slug}_next`         |

---

## SEO Checklist Per Event Page

- [ ] Server-render event page (or pre-render for crawlers).
- [ ] Include `schema.org/Event` JSON-LD in `<head>`.
- [ ] Include `VideoObject` JSON-LD for each highlight clip.
- [ ] Set canonical URL (`<link rel="canonical">`).
- [ ] OG image returns 200 on `curl -I`.
- [ ] Add event URL to `sitemap.xml` on publish.
- [ ] Ping Google: `https://www.google.com/ping?sitemap=https://www.datafightcentral.com/sitemap.xml`
- [ ] Ping Bing: `https://www.bing.com/ping?sitemap=https://www.datafightcentral.com/sitemap.xml`
- [ ] Core Web Vitals: LCP < 2.5s, FID < 100ms, CLS < 0.1.
- [ ] Pass Google Rich Results Test for the event page.

---

## Facebook Pixel Events

| Event              | Trigger               | Parameters                                                                           |
| ------------------ | --------------------- | ------------------------------------------------------------------------------------ |
| `PageView`         | Any page load         | —                                                                                    |
| `ViewContent`      | Event page view       | `content_type: "event"`, `content_ids: [eventId]`, `value: price`, `currency: "AUD"` |
| `AddToCart`        | Click "Buy PPV"       | `content_type: "event"`, `content_ids: [eventId]`, `value: price`                    |
| `InitiateCheckout` | Stripe checkout opens | `content_type: "event"`, `num_items: 1`, `value: price`                              |
| `Purchase`         | Payment confirmed     | `content_type: "event"`, `content_ids: [eventId]`, `value: price`, `currency: "AUD"` |

### Retargeting Funnel

1. **ViewContent but no AddToCart** → Retarget with countdown posts and urgency CTA.
2. **AddToCart but no Purchase** → Abandoned checkout → trigger email + SMS + Pixel retarget.
3. **Purchase** → Exclude from ads; add to lookalike seed audience for next event.
