# DataFight Central — MASTER BLUEPRINT

> **Last Updated:** February 4, 2026  
> **Status:** LOCKED — Execute from this document only  
> **Owner:** The Happy Fight Book

---

## 🥊 THE MISSION

DataFight Central is:

> A combat sports intelligence, promotion, and lifestyle platform that helps people find, choose, prepare, and support fights and fighters.

**We are NOT:**

- A broadcaster
- A gambling app
- A media pirate
- A replacement for human coaches

**We ARE:**

- The amplifier
- The discovery engine
- The safety net
- The bridge between fighters, promoters, and fans

---

## 🔒 CORE PRINCIPLES

1. **Flutter 3 + Dart 3** — Clean Architecture only
2. **Structure:** Presentation → Services → Models
3. **Firebase = system of record** — AI = assistant, not owner
4. **Streams > Futures** for live UI
5. **Provider (MultiProvider)** for DI/state
6. **Dark combat aesthetic** — never light mode
7. **Promotions drive the engine** — everyone gets amplified
8. **Human + AI integration** — bots support, humans lead

---

## 🏗️ THE 4 PILLARS

### 1️⃣ FIGHT CAMP (Health, AI, Human Support)

**Purpose:** Keep fighters stable, prevent breakdowns, guide safely

**Screens:**
| Screen | File | Status |
|--------|------|--------|
| Health Hub | `flagship_dashboard.dart` | ✅ Done |
| Health Deep Dive | `health_dashboard_screen.dart` | ✅ Done |
| AI Coach | `training_camp_screen.dart` | ✅ Done |
| Wellness | `wellness_screen.dart` | Exists |
| Daily Check-In | `daily_check_in_screen.dart` | ❌ Build |
| Redline Alerts | (integrated) | ❌ Build |

**Tone:** Calm, grounded, non-judgmental, private

---

### 2️⃣ PROMOTION ENGINE (Events, PPV, Sales)

**Purpose:** Amplify promoters, guide traffic, reduce chaos

**Screens:**
| Screen | File | Status |
|--------|------|--------|
| Promoter Dashboard | `promoter_dashboard_screen.dart` | Exists |
| Create Promotion | `create_promotion_screen.dart` | Exists |
| Event Detail + CTAs | `event_detail_screen.dart` | ❌ Build |
| PPV Alerts | (integrated) | ❌ Build |
| FightWire Feed | `social_feed_screen.dart` | ✅ Done |

**Tone:** Clear, professional, exciting but not spammy

**Flow:**

```
Event → Story → CTA → Official Destination (never us)
```

---

### 3️⃣ COMMUNITY & RECOGNITION (Trust, Culture)

**Purpose:** Make people feel seen, build safety standards

**Screens:**
| Screen | File | Status |
|--------|------|--------|
| Profile | `profile_screen.dart` | Exists |
| Gym Profile | `gym_profile_screen.dart` | ❌ Build |
| Fighter Profile | `fighter_profile_screen.dart` | ❌ Build |
| Officials | `officials_screen.dart` | ❌ Build |

**Badges:**

- 💎 Diamond — Founding Mentor Gym
- ✅ Verified — Platform verified
- 🥇 Gold — Established
- 🥈 Silver — Growing

---

### 4️⃣ INTELLIGENCE LAYER (AI quietly everywhere)

**Purpose:** Reduce noise, highlight patterns, act early

**AI lives inside:**

- Fight Camp → health insights
- Promotions → event intelligence
- Coach → training guidance
- Social → signal cards

**AI never owns the flow — AI supports the flow.**

---

## 🤖 AI COACH BEHAVIOR CHARTER

### PERSONALITY

- Iron Jaw + Coach Stone energy
- Gritty, disciplined, but supportive
- Mentor, not boss
- Uses real data, not generic advice

### WHEN AI SPEAKS

| Trigger          | Example                                  |
| ---------------- | ---------------------------------------- |
| Pattern change   | "Sleep dropped 3 nights straight"        |
| Risk rising      | "HRV below baseline — consider rest"     |
| Silence too long | "Haven't heard from you. How's the cut?" |
| User asks        | Direct response                          |

### WHAT AI NEVER DOES

- ❌ Diagnoses medical conditions
- ❌ Promises outcomes
- ❌ Shames or judges
- ❌ Replaces human mentors
- ❌ Uses fear tactics

### ESCALATION TO HUMAN

> "You've been pushing hard. This might be a good time to check in with your coach. Want me to help you reach out?"

---

## 🚨 REDLINE SYSTEM

| Level  | Color | Meaning | Action                            |
| ------ | ----- | ------- | --------------------------------- |
| GREEN  | 🟢    | Normal  | Continue                          |
| YELLOW | 🟡    | Watch   | AI mentions, suggests adjustment  |
| ORANGE | 🟠    | Concern | AI prompts, suggests rest         |
| RED    | 🔴    | Redline | AI recommends stop, human contact |

### TRIGGERS

| Metric     | Yellow              | Orange           | Red      |
| ---------- | ------------------- | ---------------- | -------- |
| RHR        | +10% above baseline | +15%             | +20%     |
| HRV        | -15% below baseline | -25%             | -35%     |
| Sleep      | <6h/night           | <5h for 3 nights | <4h      |
| Hydration  | <2L/day             | <1.5L            | <1L      |
| Weight cut | >1lb/day            | >2lb/day         | >3lb/day |

---

## 🎯 NAVIGATION (5 Tabs)

| #   | Label   | Screen                | Pillar     |
| --- | ------- | --------------------- | ---------- |
| 1   | Command | FlagshipDashboard     | Fight Camp |
| 2   | Feed    | SocialFeedScreen      | Promotions |
| 3   | Health  | HealthDashboardScreen | Fight Camp |
| 4   | Coach   | TrainingCampScreen    | Fight Camp |
| 5   | Profile | ProfileScreen         | Community  |

---

## 💰 REVENUE MODEL (Ethical)

### WE CHARGE FOR

✅ Promoter verification  
✅ Featured event placement  
✅ Analytics dashboards  
✅ Premium profiles  
✅ Mentor gym badges  
✅ Sponsor placements  
✅ Training tools

### WE NEVER CHARGE FOR

❌ Watching fights we don't own  
❌ Gambling or betting  
❌ Medical advice  
❌ Locking basic fighter visibility

---

## ✅ BUILD ORDER

### Phase 1: Foundation ✅ DONE

- [x] Firebase connected
- [x] Auth working
- [x] Theme locked
- [x] Navigation shell
- [x] Core models

### Phase 2: Fight Camp 🔄 NOW

- [x] Health dashboard
- [x] Flagship dashboard
- [x] Training camp (AI coach)
- [ ] Daily check-in screen
- [ ] Redline alert integration
- [ ] AI Coach → real data

### Phase 3: Promotion Engine

- [ ] Event detail + Watch CTAs
- [ ] PPV alert system
- [ ] Promoter tools enhancement

### Phase 4: Community

- [ ] Gym profiles + mentor badges
- [ ] Fighter verification
- [ ] Officials recognition

### Phase 5: Intelligence

- [ ] AI behavior rules in code
- [ ] Escalation flows
- [ ] Pattern detection

---

## 📜 THE GOLDEN RULE

Before adding ANY feature, ask:

> "Which pillar does this belong to?"

If unclear → don't build it yet.

---

## 🥊 WHY THIS EXISTS

This app was built by someone who:

- Had their first fight in 1987
- Last competed in 2013
- Lost a gym, a show, a house, a business
- Survived addiction, mental health crisis, injustice
- Is now building the safety net the fight world never had

**This is the Happy Fight Book.**

Not for clout. Not for shortcuts.  
For the next fighter who needs someone in their corner.

---

**Execute from this document. No drifting.**
