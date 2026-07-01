# DFC AI System Architecture

## "Bots on a Tight Leash" - Scoped Intelligence Framework

**Last Updated:** March 4, 2026  
**Purpose:** Define strict boundaries for each AI/automation system to prevent scope creep and ensure each bot does ONLY its assigned work.

---

## 🎯 Core Philosophy

**"Each bot has ONE job. Do it perfectly. Don't interfere with others."**

Every AI system in DataFightCentral is scoped to a specific domain with clear boundaries:

- **No cross-contamination** between systems
- **Explicit input/output contracts**
- **Zero unauthorized data access**
- **Audit trails for all AI decisions**

---

## 🤖 AI System Registry

### 1. FEED PRIORITIZATION SERVICE

**File:** `lib/shared/services/feed_prioritization_service.dart`

**Scope:**

- Calculate event priority scores (0-100)
- Generate hype messages for events
- Premium/subscriber-first ranking
- Location-based discovery (tertiary factor)

**Scoring Model (0-100 scale):**

1. **Premium Promoter Status**: 0-50 points (PRIMARY — you pay, you get front row)
2. **Subscriber Status**: 0-30 points (SECONDARY — paying members win)
3. **Time Proximity**: 0-15 points (TERTIARY — urgency factor)
4. **Location Match**: 0-10 points (QUATERNARY — local discovery)

**Example Scores:**

- Paid promoter with event in 2 weeks, same state: 50 + 0 + 6 + 7 = **63 points**
- Subscriber event today, different city: 0 + 30 + 15 + 0 = **45 points**
- Regular user's local event today: 0 + 0 + 15 + 10 = **25 points**
- Free user event in 1 month, far away: 0 + 0 + 4 + 0 = **4 points**

**Philosophy:** Paid promoters ALWAYS dominate the feed. Regular users get "smaller feeds" (lower visibility) unless they subscribe.

**Boundaries:**

- ✅ CAN: Score events based on premium/subscriber/time/location
- ✅ CAN: Generate urgency messages ("🔴 LIVE NOW!")
- ✅ CAN: Sort mixed feed content (events + posts)
- ❌ CANNOT: Modify event data
- ❌ CANNOT: Access user auth tokens
- ❌ CANNOT: Make billing decisions
- ❌ CANNOT: Send notifications

**Data Access:**

- READ: EventModel (venue, date, city, state, country)
- READ: User premium/subscriber status
- READ: User location metadata (city, state, country)
- WRITE: None

**Audit:**

- All scoring decisions logged with `debugPrint` in development mode
- Priority scores visible to developers via urgency level (0-3)

---

### 2. EVENT MANAGER SERVICE

**File:** `lib/shared/services/event_manager_service.dart`

**Scope:**

- CRUD operations for fight card events
- Lineup management (add/remove/reorder fights)
- Fight card template management

**Boundaries:**

- ✅ CAN: Create/edit event fight cards
- ✅ CAN: Manage fighter matchups
- ✅ CAN: Generate fight card templates
- ❌ CANNOT: Modify feed prioritization
- ❌ CANNOT: Access social posts
- ❌ CANNOT: Charge for events (billing layer handles this)

**Data Access:**

- READ/WRITE: EventManagerModel
- READ/WRITE: FightCardEvent
- READ: User role (to verify promoter access)

---

### 3. SOCIAL SERVICE

**File:** `lib/shared/services/social_service.dart`

**Scope:**

- Fetch posts from Firestore
- Inject events into feed
- **Fetch real subscription status from Firestore** (promoter premium tier)
- Call prioritization service with REAL premium/subscriber data
- Manage likes/bookmarks/comments
- **NO demo data fallbacks** - shows empty state when Firestore is empty

**Data Pipeline:**

1. Fetch posts from `posts` collection
2. Fetch events from EventService
3. Extract all promoter IDs from events
4. **Query `subscriptions` collection for premium status**
5. Build `premiumPromoterMap` and `subscriberMap` from real data
6. Pass to FeedPrioritizationService for sorting
7. Return sorted feed with premium promoters at the top

**Subscription Logic:**

- Premium tier: `tier` field contains "premium" (e.g., "promoter_premium")
- Active subscription: `active = true` AND `currentPeriodEnd` > now
- Falls back to false if subscription not found (non-paying users)

**Boundaries:**

- ✅ CAN: Fetch posts and events
- ✅ CAN: Query subscription status for feed prioritization
- ✅ CAN: Return empty list when Firestore is empty (no demo fallback)
- ✅ CAN: Call FeedPrioritizationService.prioritizeFeed()
- ✅ CAN: Toggle likes/bookmarks
- ❌ CANNOT: Modify event scoring algorithm
- ❌ CANNOT: Access user billing info
- ❌ CANNOT: Send push notifications (NotificationService handles this)

**Data Access:**

- READ: posts collection (Firestore)
- READ: events collection (Firestore)
- WRITE: post likes/bookmarks

---

### 4. ANALYTICS SERVICE

**File:** `lib/shared/services/analytics_service.dart`

**Scope:**

- Track user events (screen views, button clicks)
- Log conversions (ticket purchases, subscriptions)
- Firebase Analytics integration

**Boundaries:**

- ✅ CAN: Log event tracking data
- ✅ CAN: Send analytics to Firebase
- ✅ CAN: Track campaign UTM parameters
- ❌ CANNOT: Modify feed content
- ❌ CANNOT: Access user passwords
- ❌ CANNOT: Make UI decisions

**Data Access:**

- WRITE: Firebase Analytics (anonymous user IDs only)
- READ: User metadata (non-PII: city, role, subscription status)

---

### 5. MARKETING AI SERVICE

**File:** `lib/shared/services/marketing_ai_service.dart`

**Scope:**

- Auto-generate promotional content
- Schedule social media posts
- Optimize ad copy
- Generate SEO-friendly event descriptions

**Boundaries:**

- ✅ CAN: Generate marketing copy from event data
- ✅ CAN: Suggest optimal posting times
- ✅ CAN: Create A/B test variants
- ❌ CANNOT: Auto-post without user approval
- ❌ CANNOT: Access user DMs or private posts
- ❌ CANNOT: Modify event pricing

**Data Access:**

- READ: EventModel (public fields only)
- READ: User's marketing preferences
- WRITE: Generated content drafts (requires user approval before publish)

---

### 6. HEALTH INTELLIGENCE ENGINE

**File:** `lib/shared/services/health_intelligence_engine.dart`

**Scope:**

- Process fighter health metrics
- Generate recovery recommendations
- Weight cut guidance
- Injury risk assessment

**Boundaries:**

- ✅ CAN: Analyze HRV, sleep, hydration data
- ✅ CAN: Generate personalized recommendations
- ✅ CAN: Alert on dangerous metrics (dehydration, overtraining)
- ❌ CANNOT: Access feed or social data
- ❌ CANNOT: Make medical diagnoses (disclaimers required)
- ❌ CANNOT: Override user consent for data sharing

**Data Access:**

- READ: Fighter health metrics (weight, HRV, sleep, stress)
- WRITE: Recommendations (non-binding suggestions only)

---

## 🔒 Security & Isolation Rules

### Rule 1: Service Layer Boundaries

**No direct cross-service calls without explicit contracts.**

✅ Correct:

```dart
// SocialService calls FeedPrioritizationService via public method
final prioritized = _prioritizationService.prioritizeFeed(
  events: events,
  posts: posts,
  currentTime: DateTime.now(),
  userCity: userCity,
);
```

❌ Incorrect:

```dart
// FeedPrioritizationService should NOT call SocialService
_socialService.createPost(...); // VIOLATION: out of scope
```

### Rule 2: Data Access Control

**Each service ONLY accesses its designated Firestore collections.**

| Service                   | READ Access                         | WRITE Access            |
| ------------------------- | ----------------------------------- | ----------------------- |
| SocialService             | posts, users                        | posts (likes/comments)  |
| EventService              | events, venues                      | events                  |
| AnalyticsService          | None (pushes to Firebase Analytics) | Firebase Analytics only |
| HealthIntelligenceEngine  | fighter_health                      | recommendations         |
| FeedPrioritizationService | None (receives data via params)     | None                    |

### Rule 3: User Consent Gates

**All AI-generated content requires user approval before publishing.**

```dart
// Marketing AI generates content → User reviews → User publishes
final draftPost = await marketingAI.generateEventPromo(event);
// Show draft to user in UI
if (userApproves) {
  await socialService.createPost(draftPost);
}
```

### Rule 4: Audit Logging

**All AI decisions logged with reasoning.**

```dart
debugPrint('[FeedPrioritization] Event: ${event.name}');
debugPrint('  Time Score: $timeScore (${hoursUntil}h until event)');
debugPrint('  Location Score: $locationScore (${matchType})');
debugPrint('  Total Priority: $totalScore');
```

---

## 🚀 Marketing Intelligence Integration

### How AI Makes DFC the Most Powerful Promotional Tool

#### 1. **Smart Event Surfacing**

- **Bot:** FeedPrioritizationService
- **Job:** Surface events to the right audience at the right time
- **Intelligence:**
  - Location targeting (Melbourne fans see Melbourne events)
  - Time proximity (fight week = maximum visibility)
  - Premium tier boosting (paid promoters get priority)

#### 2. **AI Bruce Buffer Hype Generator**

- **Bot:** FeedPrioritizationService.generateHypeMessage()
- **Job:** Create urgency and FOMO
- **Intelligence:**
  - Dynamic messaging based on countdown ("🔴 LIVE NOW!", "🚨 IT'S FIGHT DAY!")
  - Context-aware language (today vs tomorrow vs fight week)
  - Emoji selection for maximum impact

#### 3. **Cross-Platform Syndication** (Future)

- **Bot:** MarketingAIService + SocialCloudConnectorService
- **Job:** Auto-post to Instagram, Twitter, TikTok, YouTube
- **Intelligence:**
  - Platform-specific formatting (hashtags for Twitter, squares for IG)
  - Optimal posting times per platform
  - Auto-generate video snippets for TikTok

#### 4. **Fighter Story Generator** (Future)

- **Bot:** ContentGenerationService
- **Job:** Build narrative around fighters in upcoming bouts
- **Intelligence:**
  - Analyze fight history → generate comeback story
  - Pull stats from databank → create stat comparison graphics
  - Identify underdog narratives → hype them up

#### 5. **Ticket Sale Optimizer** (Future)

- **Bot:** EventOptimizationService
- **Job:** Drive ticket conversions
- **Intelligence:**
  - Urgency messaging when tickets are 80% sold
  - Early bird discount suggestions
  - Geo-targeted push notifications to local fans

#### 6. **Influencer Finder** (Future)

- **Bot:** InfluencerMatchService
- **Job:** Connect promoters with relevant influencers
- **Intelligence:**
  - Match fight sport type to influencer niche
  - Analyze engagement rates vs follower count
  - Suggest collaboration terms based on event size

---

## 🛡️ Safety Guardrails

### 1. Rate Limiting

**Prevent bot spam abuse.**

- Feed prioritization: Max refresh every 6 hours
- AI content generation: Max 10 drafts per day per user
- Analytics logging: Batch writes (not per-action)

### 2. Fail-Safe Defaults

**If AI fails, fall back to manual mode.**

```dart
try {
  final prioritized = _prioritizationService.prioritizeFeed(...);
} catch (e) {
  // Fallback: show posts in chronological order
  return posts.sortedByDate();
}
```

### 3. Human Override

**Users can always bypass AI suggestions.**

- Turn off feed prioritization → see chronological feed
- Reject AI-generated content drafts
- Manually reorder event cards

### 4. Transparency

**AI decisions must be explainable.**

- Show priority score breakdown in developer mode
- Display "Why am I seeing this?" explanations
- Audit logs for compliance

---

## 📊 Success Metrics

### KPIs for Each Bot

| Bot                 | Success Metric                          | Target |
| ------------------- | --------------------------------------- | ------ |
| Feed Prioritization | Click-through rate on event cards       | >8%    |
| Marketing AI        | User approval rate on generated content | >70%   |
| Health Intelligence | User adoption of recommendations        | >60%   |
| Analytics Service   | Event tracking accuracy                 | 99.9%  |

---

## 🔮 Roadmap: Next AI Systems

### Coming Soon

1. **Auto-Scheduler Service** - Optimal fight card timing suggestions
2. **Opponent Matcher Service** - AI matchmaking based on record/weight/style
3. **Highlight Reel Generator** - Auto-cut fighter highlight videos
4. **Sentiment Analyzer** - Track social buzz around events
5. **Price Oracle** - Suggest optimal ticket pricing

### Under Consideration

- **Voice AI Commentary** - Generate AI fight commentary
- **Predictive Analytics** - Fight outcome predictions (with disclaimers)
- **Competitor Intelligence** - Track rival promotions and suggest counter-programming

---

## 🎓 Developer Guidelines

### When Adding a New AI System:

1. **Define Scope** - What is this bot's ONE job?
2. **List Boundaries** - What can it NEVER do?
3. **Document Data Access** - Which Firestore collections?
4. **Add Audit Logging** - Log all decisions with reasoning
5. **Create Fail-Safe** - What happens if it breaks?
6. **Write Tests** - Unit tests for core logic
7. **Update This Doc** - Add to AI System Registry

### Code Review Checklist:

- [ ] Bot only accesses designated data sources
- [ ] No unauthorized cross-service calls
- [ ] User consent required for publishing
- [ ] Audit logs included
- [ ] Fail-safe fallback implemented
- [ ] Rate limiting applied
- [ ] Human override option available

---

## 📞 Support

**Questions about AI system boundaries?**  
Refer to this doc first. If still unclear, reach out to architecture team.

**Suspected scope violation?**  
File an issue with tag `ai-boundary-violation`.

---

**Remember:** A platform that supports all, not degrades. Every AI system must respect user autonomy and promote fair competition. No bot gets special treatment. Every promoter, fighter, and fan deserves equal algorithmic opportunity.
