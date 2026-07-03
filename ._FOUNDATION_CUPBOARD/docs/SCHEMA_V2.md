# DataFightCentral Firestore Schema v2.0 - Quantum Grade

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         FIRESTORE SCHEMA                                  │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐  │
│  │   USERS     │   │  METRICS    │   │  SIGNALS    │   │   EVENTS    │  │
│  │  (Identity) │   │ (Raw Data)  │   │ (Derived)   │   │ (Community) │  │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘  │
│         │                │                 │                  │          │
│         └────────────────┼─────────────────┼──────────────────┘          │
│                          │                 │                             │
│                          ▼                 ▼                             │
│                    ┌───────────┐    ┌───────────┐                        │
│                    │ GENKIT AI │───▶│  AI LOGS  │                        │
│                    │ (Server)  │    │  (Audit)  │                        │
│                    └───────────┘    └───────────┘                        │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## GOLDEN RULE

```
NEVER: User → AI → Firestore (AI writes data)
ALWAYS: User → Firestore → Engine → Signals → AI → Client (AI reads, interprets)
```

---

## Collections

### 1. `health_metrics` - Raw Input Data

This is where ALL raw health data goes. Device data, manual input, everything.

```javascript
/health_metrics/{metricId}
{
  // ═══ IDENTITY ═══
  "userId": "user_abc123",
  "recordedAt": Timestamp,          // When this applies to
  "source": "manual",               // manual | appleWatch | garmin | whoop | oura | fitbit | phoneCamera

  // ═══ VITAL SIGNS ═══
  "vitals": {
    "restingHeartRate": 58,         // BPM - morning measurement
    "heartRateVariability": 62,     // ms - HRV score
    "bloodOxygen": 98,              // SpO2 %
    "respiratoryRate": 14           // Breaths per minute
  },

  // ═══ BODY COMPOSITION ═══
  "body": {
    "weight": 80.2,                 // kg
    "bodyFatPercentage": 12.5,      // %
    "muscleMass": 38.2,             // kg
    "visceralFat": 8                // Score 1-59
  },

  // ═══ HYDRATION & ELECTROLYTES ═══
  "hydration": {
    "percentage": 62,               // Body hydration %
    "waterIntakeMl": 3200,          // ml consumed today
    "electrolytes": {
      "sodiumMg": 2100,             // Critical for weight cuts
      "potassiumMg": 3500,          // Heart & muscle function
      "magnesiumMg": 400            // Recovery & sleep
    },
    "supplementsTaken": ["electrolyte_mix", "multivitamin"]
  },

  // ═══ SLEEP ═══
  "sleep": {
    "totalHours": 7.5,
    "deepSleepHours": 1.8,
    "remSleepHours": 2.1,
    "lightSleepHours": 3.6,
    "qualityScore": 78,             // 0-100
    "sleepStart": Timestamp,
    "sleepEnd": Timestamp,
    "interruptions": 2
  },

  // ═══ TRAINING LOAD ═══
  "training": {
    "strikingMinutes": 45,
    "grapplingMinutes": 60,
    "conditioningMinutes": 30,
    "sparringRounds": 3,
    "perceivedExertion": 7,         // RPE 1-10
    "intensity": 8,                 // 1-10
    "notes": "Good technical session, felt sharp"
  },

  // ═══ SUBJECTIVE WELLNESS ═══
  "wellness": {
    "moodScore": 7,                 // 1-10
    "energyLevel": 6,               // 1-10
    "stressLevel": 4,               // 1-10
    "muscleSoreness": 5,            // 1-10
    "mentalClarity": 8,             // 1-10
    "motivation": 9,                // 1-10
    "notes": "Feeling good, slight hamstring tightness"
  },

  // ═══ WEIGHT CUT (if active) ═══
  "weightCut": {
    "phase": "waterLoading",        // maintenance | waterLoading | waterReduction | finalCut | rehydration | postFight
    "targetWeight": 77.1,           // kg
    "weighInDate": Timestamp,
    "daysRemaining": 7
  },

  // ═══ METADATA ═══
  "createdAt": Timestamp,
  "isVerified": true,               // Device-verified vs manual
  "deviceId": "apple_watch_series_9"
}
```

### 2. `health_signals` - Derived Intelligence

Calculated FROM health_metrics by the Health Intelligence Engine.
AI reads this layer - never the raw metrics.

```javascript
/health_signals/{signalId}
{
  // ═══ IDENTITY ═══
  "userId": "user_abc123",
  "signalDate": Timestamp,
  "calculatedAt": Timestamp,
  "sourceMetricsId": "metric_xyz",

  // ═══ COMPOSITE SCORES (0.0 - 1.0) ═══
  "scores": {
    "recovery": 0.72,               // Overall recovery readiness
    "trainingReadiness": 0.68,      // Ready to train hard?
    "fightReadiness": 0.75,         // Ready to compete?
    "stressLoad": 0.45,             // Accumulated stress
    "fatigueIndex": 0.38            // Accumulated fatigue
  },

  // ═══ RISK LEVELS ═══
  "risks": {
    "overall": "green",             // green | amber | orange | red
    "hydration": "green",
    "overtraining": "amber",
    "sleepDebt": "green",
    "weightCut": "green",
    "mentalHealth": "green"
  },

  // ═══ FLAGS ═══
  "activeFlags": [
    "moderate_training_load",
    "good_sleep_streak"
  ],
  // Available flags:
  // - low_sleep, severe_sleep_deprivation
  // - low_hrv, critically_low_hrv
  // - dehydration_warning, severe_dehydration
  // - high_training_volume, excessive_sparring
  // - dangerous_weight_cut, final_cut_phase
  // - crisis_support_needed, extreme_stress
  // - high_soreness, accumulated_fatigue

  // ═══ TRENDS (vs 7-day average, -1.0 to +1.0) ═══
  "trends": {
    "hrv": 0.12,                    // +12% vs average
    "sleep": -0.05,                 // -5% vs average
    "weight": 0.00,                 // Stable
    "mood": 0.08,                   // +8% vs average
    "energy": -0.02                 // -2% vs average
  },

  // ═══ RECOMMENDATIONS ═══
  "recommendations": {
    "primary": "Training readiness is good. Consider a quality technical session today.",
    "supporting": [
      "HRV trending up - recovery is working",
      "Stay on top of hydration"
    ]
  },

  // ═══ ESCALATION ═══
  "escalation": {
    "required": false,
    "reason": null,
    "acknowledgedAt": null
  }
}
```

### 3. `ai_logs` - Full Audit Trail

Every AI interaction is logged for safety, grants, and compliance.

```javascript
/ai_logs/{logId}
{
  "userId": "user_abc123",
  "flowName": "generateDailyInsight",   // generateDailyInsight | analyzeWeightCut | wellnessCheck
  "input": "{ ... }",                   // JSON stringified input
  "output": "{ ... }",                  // JSON stringified output
  "timestamp": Timestamp,
  "version": "1.0.0",
  "modelUsed": "gemini-1.5-flash",
  "tokensUsed": 450,
  "latencyMs": 1250,
  "escalationTriggered": false
}
```

### 4. `escalations` - Safety Alert Queue

When AI or system detects concerning patterns.

```javascript
/escalations/{escalationId}
{
  "userId": "user_abc123",
  "type": "wellness_check_critical",    // wellness_check_critical | dangerous_weight_cut | severe_dehydration | overtraining_syndrome
  "triggerSource": "ai_flow",           // ai_flow | signal_engine | manual_report

  "context": {
    "signalId": "signal_xyz",
    "moodScore": 2,
    "stressLevel": 9,
    "activeFlags": ["crisis_support_needed"]
  },

  "status": {
    "resolved": false,
    "acknowledgedByUser": false,
    "reviewedByStaff": false,
    "staffUserId": null,
    "staffNotes": null,
    "resolution": null                  // user_safe | referred_to_support | false_positive
  },

  "timestamp": Timestamp,
  "resolvedAt": null
}
```

---

## Data Flow Diagrams

### Daily Check-In Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   USER      │     │  FIRESTORE  │     │   ENGINE    │     │   GENKIT    │
│  (Flutter)  │     │  (Metrics)  │     │  (Server)   │     │    (AI)     │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │                   │
       │ 1. Log metrics    │                   │                   │
       │──────────────────▶│                   │                   │
       │                   │                   │                   │
       │                   │ 2. Trigger        │                   │
       │                   │──────────────────▶│                   │
       │                   │                   │                   │
       │                   │ 3. Calculate      │                   │
       │                   │   scores & risks  │                   │
       │                   │◀──────────────────│                   │
       │                   │                   │                   │
       │                   │ 4. Write signal   │                   │
       │                   │◀──────────────────│                   │
       │                   │                   │                   │
       │                   │                   │ 5. Request        │
       │                   │                   │   insight         │
       │                   │                   │──────────────────▶│
       │                   │                   │                   │
       │                   │                   │ 6. AI interprets  │
       │                   │                   │◀──────────────────│
       │                   │                   │                   │
       │ 7. Show insight   │                   │                   │
       │◀──────────────────│                   │                   │
       │                   │                   │                   │
```

### Weight Cut Monitoring Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  FIGHTER    │     │   METRICS   │     │   ENGINE    │     │ ESCALATION  │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │                   │
       │ Daily weight      │                   │                   │
       │──────────────────▶│                   │                   │
       │                   │                   │                   │
       │ Hydration check   │                   │                   │
       │──────────────────▶│                   │                   │
       │                   │                   │                   │
       │                   │ Calculate rate    │                   │
       │                   │──────────────────▶│                   │
       │                   │                   │                   │
       │                   │   IF rate > 1.5%  │                   │
       │                   │   body weight/day │                   │
       │                   │                   │──────────────────▶│
       │                   │                   │   FLAG: dangerous │
       │                   │                   │                   │
       │ Gentle warning    │                   │                   │
       │◀──────────────────│                   │                   │
       │ + support link    │                   │                   │
       │                   │                   │                   │
```

---

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users - owner only
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Health Metrics - owner only write, owner only read
    match /health_metrics/{metricId} {
      allow create: if request.auth.uid == request.resource.data.userId;
      allow read, update, delete: if request.auth.uid == resource.data.userId;
    }

    // Health Signals - owner read only (system writes via Cloud Functions)
    match /health_signals/{signalId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if false; // Only Cloud Functions
    }

    // AI Logs - system only (never client accessible)
    match /ai_logs/{logId} {
      allow read, write: if false;
    }

    // Escalations - admin read, system write
    match /escalations/{escalationId} {
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow write: if false; // Only Cloud Functions
    }

    // Events - public read, verified promoters write
    match /events/{eventId} {
      allow read: if true;
      allow create: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'promoter';
      allow update, delete: if request.auth.uid == resource.data.organizer.userId;
    }

    // Gyms - public read, owner write
    match /gyms/{gymId} {
      allow read: if true;
      allow write: if request.auth.uid == resource.data.owner.userId;
    }

    // Subscriptions - owner only
    match /subscriptions/{subscriptionId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if false; // Only Cloud Functions (Stripe webhooks)
    }
  }
}
```

---

## Composite Indexes

```
// Health Metrics - User timeline
Collection: health_metrics
Fields: userId ASC, recordedAt DESC

// Health Signals - User timeline
Collection: health_signals
Fields: userId ASC, signalDate DESC

// Events - Upcoming by date
Collection: events
Fields: status ASC, details.date ASC

// Escalations - Unresolved queue
Collection: escalations
Fields: status.resolved ASC, timestamp DESC

// AI Logs - User audit
Collection: ai_logs
Fields: userId ASC, timestamp DESC
```

---

## Data Retention & Compliance

| Collection     | Retention         | Deletion     | GDPR Basis          |
| -------------- | ----------------- | ------------ | ------------------- |
| users          | Account lifetime  | On request   | Consent             |
| health_metrics | 2 years           | Auto-archive | Legitimate interest |
| health_signals | 1 year            | Auto-delete  | Legitimate interest |
| ai_logs        | 90 days           | Auto-delete  | Legitimate interest |
| escalations    | Permanent         | Never        | Safety/Legal        |
| events         | 1 year post-event | Auto-archive | Public interest     |

---

## Version History

| Version | Date       | Changes                                                        |
| ------- | ---------- | -------------------------------------------------------------- |
| 2.0     | 2026-02-04 | Quantum-grade schema, health intelligence engine, Genkit flows |
| 1.0     | 2025       | Initial schema                                                 |
