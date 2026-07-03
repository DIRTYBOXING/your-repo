# Promoter Social Kit — One-Click Buy

Use this kit to help promoters add the Buy Now widget or deep link to their profile and social posts.

---

## 1. Quick embed (link-in-bio / website)

**Embed snippet (copy/paste)**

```html
<!-- DFC One-Click Buy Widget -->
<script async src="https://cdn.datafightcentral.com/widget/widget.js"></script>
<div
  class="dfc-widget"
  data-event-id="evt_123"
  data-sku-id="sku_vip"
  data-ref="promoter_abc"
  data-experiment="widget_ab_2026_06"
></div>
```

**Notes:**
- Replace `data-event-id`, `data-sku-id`, and `data-ref` with your values.
- The widget auto-loads and renders a single "Buy Now" button.
- For deep link use: `https://dfc.link/buy?event=evt_123&sku=sku_vip&ref=promoter_abc`

---

## 2. Deep link examples (for bio)

**Short deep link:**
```
https://dfc.link/buy?event=evt_123&sku=sku_vip&ref=promoter_abc
```

**Universal link (iOS/Android):** Use the deep link above. The deeplink handler redirects to widget or native app.

---

## 3. QR code for print / offline

Generate a QR code from any deep link using this URL pattern:

```
https://chart.googleapis.com/chart?cht=qr&chs=400x400&chl=https://dfc.link/buy?event=evt_123&sku=sku_vip&ref=promoter_abc
```

Promoters can print this on posters, business cards, or flyers. Fans scan → buy instantly.

---

## 4. Social post copy (ready to paste)

**Instagram story / post**

Headline: Tickets live — 1-click buy!
Body: Tap my profile pic to buy your ticket instantly. Limited seats — grab yours now! 🎟️ #FightNight
CTA: Buy Now → (link to deep link)

**Twitter / X**

Tickets for [Event Name] are live. Click my profile link to buy instantly — no waiting. #FightNight

**Facebook**

I'm selling tickets for [Event Name]. Click my profile link to buy instantly. Limited seats — get yours now!

---

## 5. Image suggestions (for story / post)

| Asset | Specs |
|---|---|
| Hero image | Promoter action shot (portrait), 1080×1080 or 1080×1920 for stories |
| Overlay text | "Buy Now — 1-Click" and event date/time |
| Thumbnail | 400×400 with promoter face and event logo |
| QR code | 400×400 with deep link embedded (use QR URL above) |

---

## 6. Test checklist for promoters

- [ ] Paste embed snippet or deep link in bio.
- [ ] Run a test sale using demo mode (instructions in promoter dashboard).
- [ ] Confirm ticket email / wallet pass received.
- [ ] Complete KYC to enable payouts.

---

## 7. Example email to promoters

**Subject:** Get set — Add one-click buy to your profile

**Body:**

```
Hey [Promoter Name],

We've enabled one-click ticket sales for your profile. Paste this snippet
into your bio or website to let fans buy instantly:

[embed snippet]

QR code for print materials:
https://chart.googleapis.com/chart?cht=qr&chs=400x400&chl=https://dfc.link/buy?event=evt_123&sku=sku_vip&ref=promoter_abc

Run a test sale in demo mode and confirm you receive the ticket.
If you need help, reply and we'll walk you through it.

Cheers,
DFC Team
