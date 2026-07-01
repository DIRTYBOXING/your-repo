# DFC Social Impact & Mentoring Campaigns

**Last Updated:** March 9, 2026

## Overview

Data Fight Central operates five core social impact and mentoring campaigns designed to support vulnerable populations through education, awareness, and community support. These campaigns represent the heart of DFC's mission beyond combat sports.

---

## Campaign Portfolio

### 1. **Men's Mental Health Mentoring** 🔵

**ID:** `mens_mental_health_2025`  
**Category:** Mental Health  
**Target Audience:** Men  
**Status:** Active  
**Tagline:** _"Teach Men to Be Men Again"_

#### Vision

A mentoring program designed to help men rebuild courage, confidence, and mental resilience. Program specifically targets victims and survivors of trauma, abuse, and mental health challenges, providing safe pathways to rediscover their strength.

#### Key Messaging

- Rebuild courage and confidence
- Safe mentoring spaces for men
- Teach men to support each other
- Recovery is possible

#### Asset

- **File:** `assets/campaigns/dfc_mens_mental_health.png`
- **Type:** Nike-style shoe with DFC mental health shield
- **Design:** Blue theme with mental health ribbon motif

#### Integration Points

- Mentoring feature module
- Dashboard wellness section
- Social feed campaigns
- Email marketing

---

### 2. **Women's Health & Breast Cancer Awareness** 🩷

**ID:** `womens_health_awareness_2025`  
**Category:** Health Awareness  
**Target Audience:** Women  
**Status:** Active  
**Tagline:** _"Rebuilding Courage, Reclaiming Strength"_

#### Vision

Empowering women survivors to rebuild courage and reclaim their strength. Dedicated to creating safe spaces for women who can't walk into traditional gyms—building confidence one step at a time. Campaign honors those lost to breast cancer.

#### Key Messaging

- Safe spaces for recovery
- Reclaim body confidence
- Community support network
- Dedicated to survivors

#### Asset

- **File:** `assets/campaigns/dfc_womens_health_shield.png`
- **Type:** Ornamental shield with pink ribbon, roses, butterflies
- **Design:** Pink/purple theme with elegance and strength

#### Integration Points

- Women's health community
- Dashboard wellness cards
- Onboarding flow for women
- Social awareness posts

#### Personal Connection

This campaign honors those lost to breast cancer, including the user's sister.

---

### 3. **Breast Cancer Awareness Month Badge** 🎀

**ID:** `breast_cancer_awareness_month_2025`  
**Category:** Health Awareness  
**Target Audience:** General  
**Status:** Active (October focus)  
**Tagline:** _"Wear Pink, Spread Hope"_

#### Vision

A simple, powerful badge campaign for Breast Cancer Awareness Month (October). Allows all users to show solidarity and spread hope to everyone fighting breast cancer.

#### Key Messaging

- Show solidarity
- Spread hope
- October awareness focus
- Community engagement

#### Asset

- **File:** `assets/campaigns/dfc_breast_cancer_badge.png`
- **Type:** Circular badge with pink ribbon
- **Design:** Clean, professional, badge-ready

#### Integration Points

- User profile badges
- Social media sharing
- Dashboard awareness section
- October campaign push

---

### 4. **DFC Charity - Change a Child's Future** 💛

**ID:** `dfc_charity_2025`  
**Category:** Charity  
**Target Audience:** General  
**Status:** Active  
**Tagline:** _"\$1 CAN CHANGE A CHILD'S FUTURE"_

#### Vision

\$1 can change a child's future. DFC Charity provides struggling Australian and New Zealand children with safe homes, food, and education. Every dollar matters.

#### Key Messaging

- \$1 creates impact
- Safe homes
- Food security
- Education access
- Community care

#### Asset

- **File:** `assets/campaigns/dfc_gold_coin_charity.png`
- **Type:** Golden coin/seal with children imagery
- **Design:** Gold with city skyline, American flag elements

#### Integration Points

- Donation module
- Dashboard charity cards
- Marketplace charity partnerships
- Social giving features

#### Impact Model

- \$1 contributions
- Transparent tracking
- Direct child support
- Australian/NZ focus

---

### 5. **Buy a Coffee, Not a Coffin** ☕

**ID:** `coffee_not_coffin_2025`  
**Category:** Mentoring  
**Target Audience:** General  
**Status:** Active  
**Tagline:** _"BUY A COFFEE, NOT A COFFIN"_

#### Vision

A powerful mentoring message: invest in life, not death. Support DFC mentoring programs that help people choose hope, connection, and recovery over despair. Every coffee donation fuels mentoring initiatives.

#### Key Messaging

- Choose life over death
- Invest in recovery
- Mentoring saves lives
- Hope is possible
- Connection matters

#### Asset

- **File:** `assets/campaigns/dfc_coffee_not_coffin.png`
- **Type:** Nike-style shoe with coffin and coffee contrast
- **Design:** Dark theme with stark contrast messaging

#### Integration Points

- Mental health awareness
- Mentoring feature
- Social awareness posts
- Charity/donation drives

#### Impact Model

- Coffee donations → mentoring support
- Suicide prevention focus
- Mental health outreach
- Recovery pathways

---

## Campaign Categories

### Mental Health (2 campaigns)

1. Men's Mental Health Mentoring 🔵
2. Buy a Coffee, Not a Coffin ☕

### Health Awareness (2 campaigns)

1. Women's Health & Breast Cancer Awareness 🩷
2. Breast Cancer Awareness Month Badge 🎀

### Charity (1 campaign)

1. DFC Charity - Change a Child's Future 💛

---

## Asset Management

### Location

All campaign assets are stored in: `assets/campaigns/`

### File Format

Currently using SVG format for scalability:

- `dfc_mens_mental_health.png`
- `dfc_womens_health_shield.png`
- `dfc_breast_cancer_badge.png`
- `dfc_gold_coin_charity.png`
- `dfc_coffee_not_coffin.png`

### Usage Guidelines

- High-resolution for web/app display
- Responsive scaling recommended
- Brand consistency across all platforms
- Credit DFC when sharing

---

## Feature Integration Roadmap

### Phase 1: Dashboard Integration

- [ ] Campaign cards on main dashboard
- [ ] Category filtering
- [ ] Impact statistics display

### Phase 2: Social Features

- [ ] Campaign-specific posts
- [ ] User testimonials
- [ ] Progress tracking

### Phase 3: Engagement

- [ ] Campaign badges/achievements
- [ ] Sharing workflows
- [ ] Community challenges

### Phase 4: Monetization

- [ ] Donation workflows
- [ ] Sponsorship opportunities
- [ ] Partnership integrations

---

## Data Model Reference

Campaigns are implemented via `SocialCampaign` model in:

```
lib/shared/models/social_campaign_model.dart
```

Each campaign includes:

- Campaign metadata (id, name, description)
- Categorization (category, targetAudience, tags)
- Visual assets (assetPath)
- Call-to-action (callToAction, ctaLink)
- Lifecycle management (launchDate, status)

---

## Accessibility & Inclusivity

### Mental Health Campaigns

- Designed for trauma survivors
- Safe, non-judgmental messaging
- Accessible language
- Privacy-first approach

### Health Awareness Campaigns

- Survivor-focused
- Inclusive imagery
- Respectful language
- Support resources included

### Charity Campaign

- Child-safe messaging
- Transparent impact reporting
- Culturally sensitive (AU/NZ)
- Multiple donation options

---

## Success Metrics

### Engagement KPIs

- Views/impressions per campaign
- Click-through rates to CTAs
- Social shares and comments
- User badge adoption rate

### Impact KPIs

- Funds raised per campaign
- Mentoring program enrollments
- Community member growth
- Support contacts/referrals

### Health KPIs

- Mental health resource usage
- Awareness month participation
- Support network growth
- Recovery pathway engagement

---

## Next Steps

1. **Move image files** from Downloads → `assets/campaigns/`
2. **Add campaign routes** to GoRouter/navigation
3. **Create campaign screens** in marketing/discovery features
4. **Integrate with dashboard** cards
5. **Add social sharing** capabilities
6. **Create admin dashboard** for campaign analytics

---

## Contact & Questions

For campaign integration, asset updates, or strategic questions, refer to the DFC team leads or review the copilot-instructions.md file for architecture guidance.
