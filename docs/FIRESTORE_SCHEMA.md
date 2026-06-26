# Firestore Data Schema

Based on the DataFightCentral Vision.

## 1. User Management (`users` collection)

The root content for all user identities.

- **Collection:** `users`
  - **DocID:** `uid` (from Firebase Auth)
  - **Fields:**
    - `email`: string
    - `role`: string ('fighter', 'coach', 'gym', 'promoter', 'sponsor', 'fan', 'admin')
    - `displayName`: string
    - `photoUrl`: string
    - `onboardingCompleted`: boolean
    - `createdAt`: timestamp
    - `updatedAt`: timestamp
    - `isVerified`: boolean
    - `settings`: map
      - `notifications`: boolean
      - `privacyLevel`: string ('public', 'private', 'connections_only')
  - **Sub-collections:**
    - `connections`: (followers/following)
    - `notifications`: (user specific alerts)

## 1.1 User Onboarding (`user_onboarding` collection)

Onboarding journey metadata tied to a user.

- **Collection:** `user_onboarding`
  - **DocID:** `uid`
  - **Fields:**
    - `selectedRole`: string
    - `intents`: array<string>
    - `preferredPractices`: array<string>
    - `opportunityInterests`: array<string>
    - `mindLoad`: number
    - `bodyLoad`: number
    - `soulLoad`: number
    - `storyIntro`: string
    - `updatesOptIn`: boolean
    - `completedAt`: timestamp

## 2. Fighter Profiles (`fighters` collection)

Specific data for the "Fighter" role.

- **Collection:** `fighters`
  - **DocID:** `uid` (same as user)
  - **Fields:**
    - `fullName`: string
    - `nickname`: string
    - `weightClass`: string
    - `sportType`: string (MMA/Boxing/etc)
    - `stance`: string
    - `gymId`: string (ref)
    - `record`: map
      - `wins`: number
      - `losses`: number
      - `draws`: number
    - `fightStockValue`: number (calculated metric)
  - **Sub-collections:**
    - `health_logs`: (Secure, private logs)
      - `date`: timestamp
      - `sleepHours`: number
      - `weight`: number
      - `mood`: string
      - `metrics`: map (heartRate, stress)
    - `achievements`: list of badges/titles

## 2.1 Fighter Stats (`fighter_stats` collection)

Aggregated performance metrics powering dashboards.

- **Collection:** `fighter_stats`
  - **DocID:** `fighterId`
  - **Fields:**
    - `totalSparringMinutes`: number
    - `totalStrikesLanded`: number
    - `totalStrikesThrown`: number
    - `totalTakedowns`: number
    - `totalTakedownsAttempted`: number
    - `winRate`: number
    - `performanceHistory`: array<map>
      - `date`: timestamp
      - `rating`: number

## 2.2 Training Sessions (`training_sessions` collection)

Atomic training logs for load and readiness analytics.

- **Collection:** `training_sessions`
  - **DocID:** auto-id
  - **Fields:**
    - `fighterId`: string
    - `date`: timestamp
    - `sessionType`: string (sparring, conditioning, skill, recovery)
    - `durationMinutes`: number
    - `rpe`: number (1-10)
    - `intensity`: number (optional)
    - `notes`: string
    - `metrics`: map (heartRate, calories, rounds)

## 2.3 Training Cycles (`training_cycles` collection)

Macro / meso cycle planning.

- **Collection:** `training_cycles`
  - **DocID:** auto-id
  - **Fields:**
    - `fighterId`: string
    - `name`: string
    - `phase`: string (base, build, peak, taper, recovery)
    - `startDate`: timestamp
    - `endDate`: timestamp
    - `weeklyLoadTargets`: array<number>
    - `goal`: string

## 3. Gyms & Locations (`gyms` collection)

For the Map & Discovery pillar.

- **Collection:** `gyms`
  - **DocID:** auto-id
  - **Fields:**
    - `ownerId`: string (ref to user)
    - `name`: string
    - `location`: geo-point
    - `address`: string
    - `disciplines`: array<string>
    - `facilities`: array<string>
    - `isAccredited`: boolean
    - `promotionalTier`: string ('free', 'gold', 'platinum')
    - `photos`: array<url>

## 4. Social Feed (`posts` collection)

The social combat network.

- **Collection:** `posts`
  - **DocID:** auto-id
  - **Fields:**
    - `authorId`: string
    - `authorRole`: string
    - `content`: string
    - `mediaUrls`: array<string>
    - `createdAt`: timestamp
    - `likeCount`: number
    - `commentCount`: number
    - `tags`: array<string>
  - **Sub-collections:**
    - `comments`
    - `likes` (for scalability, might be a top-level collection `likes` pointing to posts)

## 5. Events & Matchmaking (`events` collection)

Promoter tools and calendars.

- **Collection:** `events`
  - **DocID:** auto-id
  - **Fields:**
    - `promoterId`: string
    - `name`: string
    - `date`: timestamp
    - `venue`: map (name, location)
    - `fightCard`: array<map>
      - `redCornerId`: string
      - `blueCornerId`: string
      - `weightClass`: string
    - `ticketLink`: string
    - `ppvLink`: string

## 6. Market & Ads (`marketplace` collection)

Promotion and advertising engine.

- **Collection:** `ads`
  - **DocID:** auto-id
  - **Fields:**
    - `advertiserId`: string
    - `type`: string ('gym_promo', 'sponsor', 'event_boost')
    - `targetLocation`: geo-point (optional)
    - `radiusKm`: number
    - `status`: string ('active', 'paused', 'completed')
    - `metrics`: map
      - `impressions`: number
      - `clicks`: number

## 7. AI & Analytics (`analytics` collection)

Processed insights and "Fight Stocks".

- **Collection:** `fight_stocks`
  - **DocID:** `fighterId`
  - **Fields:**
    - `currentValue`: number
    - `history`: array<map> (timestamp, value)
    - `factors`: map (engagement_score, win_streak_bonus)

- **Collection:** `ai_insights`
  - **DocID:** auto-id
  - **Fields:**
    - `targetId`: string (user or fight)
    - `type`: string ('style_breakdown', 'training_load', 'training_readiness')
    - `content`: string (markdown)
    - `generatedAt`: timestamp
    - `model`: string (e.g., 'gemini-pro')
    - `metrics`: map (readinessScore, loadFactor, sessionCount)

## 8. Security & Logs (`audit_logs` collection)

For admin and safety compliance.

- **Collection:** `audit_logs`
  - **DocID:** auto-id
  - **Fields:**
    - `actorId`: string
    - `action`: string
    - `targetId`: string
    - `timestamp`: timestamp
    - `metadata`: map
