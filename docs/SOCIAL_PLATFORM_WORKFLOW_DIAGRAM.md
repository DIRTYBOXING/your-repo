# DFC SOCIAL PLATFORM WORKFLOW DIAGRAMS

**Visual representation of content flow across all social platforms**

---

## DIAGRAM 1: Complete Content Distribution Pipeline

```mermaid
graph TB
    Start([Admin Opens Content Command Center])

    Start --> Decision{Content Source?}

    Decision -->|Manual| Workshop[WORKSHOP Tab<br/>Manual Asset Upload]
    Decision -->|AI Generated| AIFeeder[AI FEEDER<br/>53 Samurai Agents]

    Workshop --> Warehouse[(WAREHOUSE INVENTORY<br/>- Title<br/>- URL<br/>- Type<br/>- Notes)]
    AIFeeder --> Warehouse

    Warehouse --> QueueDecision{Action?}

    QueueDecision -->|QUEUE| Samurai[Samurai Content Transformer<br/>Platform Optimization]
    QueueDecision -->|PUSH LIVE| DirectPublish[Direct to Social Engine]

    Samurai --> ApprovalQueue[Approval Queue<br/>Auto-Approved]
    ApprovalQueue --> SocialEngine[DFC Social Engine<br/>publishToAll]
    DirectPublish --> SocialEngine

    SocialEngine --> Platforms{8 Platforms}

    Platforms -->|Post| FB[📘 Facebook<br/>4 Pages]
    Platforms -->|Post| IG[📸 Instagram<br/>2 Accounts]
    Platforms -->|Post| TT[🎵 TikTok<br/>@datafightcentral]
    Platforms -->|Post| X[𝕏 X/Twitter<br/>@datafightcentral]
    Platforms -->|Post| YT[▶️ YouTube<br/>@DataFightCentral]
    Platforms -->|Post| LI[💼 LinkedIn<br/>DataFightCentral]
    Platforms -->|Post| SC[👻 Snapchat<br/>@datafightcentral]
    Platforms -->|Post| WA[💬 WhatsApp<br/>DFC Channel]

    FB --> Engagement[Engagement Tracking<br/>Likes • Comments • Shares]
    IG --> Engagement
    TT --> Engagement
    X --> Engagement
    YT --> Engagement
    LI --> Engagement
    SC --> Engagement
    WA --> Engagement

    Engagement --> Analytics[Analytics Engine<br/>Algorithm Signals]
    Analytics --> HypeRamp{Event Proximity?}

    HypeRamp -->|1 month out| Burst1[1x Promo Burst]
    HypeRamp -->|3 weeks out| Burst2[2x Promo Burst]
    HypeRamp -->|2 weeks out| Burst3[3x Promo Burst]
    HypeRamp -->|1 week out| Burst4[4x Promo Burst]
    HypeRamp -->|Days out| Burst6[6x Promo Burst]
    HypeRamp -->|Hours out| Burst7[7x Promo Burst]
    HypeRamp -->|FIGHT TIME| Burst8[8x PROMO BURST]

    Burst1 --> SwarmCoordinator
    Burst2 --> SwarmCoordinator
    Burst3 --> SwarmCoordinator
    Burst4 --> SwarmCoordinator
    Burst6 --> SwarmCoordinator
    Burst7 --> SwarmCoordinator
    Burst8 --> SwarmCoordinator

    SwarmCoordinator[Samurai Swarm Coordinator<br/>6-Hour Pump Cycle]
    SwarmCoordinator --> AIFeeder

    style Start fill:#FFD700,stroke:#FFA500,stroke-width:3px
    style SocialEngine fill:#FF1744,stroke:#D50000,stroke-width:3px
    style SwarmCoordinator fill:#00E5FF,stroke:#00B8D4,stroke-width:3px
    style Engagement fill:#76FF03,stroke:#64DD17,stroke-width:3px
    style Warehouse fill:#E1BEE7,stroke:#9C27B0,stroke-width:2px
```

---

## DIAGRAM 2: Platform-Specific Action Workflows

### Facebook User Journey

```mermaid
sequenceDiagram
    participant User
    participant DFC as DFC App
    participant Engine as DFC Social Engine
    participant FB as Facebook
    participant Algorithm as FB EdgeRank

    User->>DFC: Open IBC3 Promo Screen
    DFC->>User: Display Event Info + Copy Button
    User->>DFC: Click "COPY PROMO"
    DFC->>User: Clipboard Loaded ✅
    User->>FB: Open Facebook & Paste
    FB->>Algorithm: Post Published

    Note over Algorithm: Engagement Signals

    Algorithm->>FB: Friend Sees Post
    FB->>User: Friend Likes/Comments
    User->>Engine: Engagement Spike Detected
    Engine->>DFC: FORCE PUMP Triggered
    DFC->>FB: 8x More Promo Content

    Note over FB,Algorithm: Exponential Reach
```

### Instagram Story/Reels Flow

```mermaid
sequenceDiagram
    participant Admin
    participant Workshop as Workshop Tab
    participant Warehouse as Warehouse Inventory
    participant Transformer as Samurai Transformer
    participant Engine as Social Engine
    participant IG as Instagram

    Admin->>Workshop: Upload Video Asset
    Workshop->>Warehouse: Store (type='video')
    Admin->>Warehouse: Click "QUEUE"
    Warehouse->>Transformer: Route Asset

    Note over Transformer: Platform Optimization
    Transformer->>Transformer: Add Hashtag Stack<br/>#MMA #Boxing #FightNight
    Transformer->>Transformer: Format for Reels<br/>(60 sec max)

    Transformer->>Engine: Queue for Approval
    Engine->>Engine: Auto-Approve
    Admin->>Engine: Click "PUSH LIVE"
    Engine->>IG: Post to @datafightcentral

    Note over IG: Algorithm Processing
    IG->>IG: Watch Time Tracked
    IG->>IG: Completion Rate Calculated
    IG->>IG: Explore Page Boost
```

### TikTok For You Page Optimization

```mermaid
flowchart LR
    A[Video Upload<br/>to Workshop] --> B{Length Check}
    B -->|> 60sec| C[Trim to 60sec]
    B -->|< 60sec| D[Keep Original]
    C --> E[Add Captions]
    D --> E
    E --> F[Hashtag Injection<br/>#FightTok #FYP]
    F --> G[Character Limit<br/>150 chars max]
    G --> H[Emoji Optimization<br/>🥊🔥💪]
    H --> I[Post to TikTok]
    I --> J{FYP Algorithm}
    J -->|High Completion| K[BOOST]
    J -->|Low Completion| L[Suppress]
    K --> M[Viral Distribution]
    L --> N[Limited Reach]
    M --> O[Engagement Spike]
    O --> P[FORCE PUMP<br/>More Content]
    P --> I

    style I fill:#FF2D55,stroke:#D50000
    style K fill:#76FF03,stroke:#64DD17
    style P fill:#00E5FF,stroke:#00B8D4
```

### X/Twitter Intent Flow

```mermaid
stateDiagram-v2
    [*] --> IBC3Screen: User Opens Promo
    IBC3Screen --> CopyPromo: Click "COPY PROMO"
    IBC3Screen --> TweetIt: Click "TWEET IT"

    CopyPromo --> Clipboard: Loaded Full Text
    Clipboard --> [*]: User Pastes Anywhere

    TweetIt --> TwitterApp: Open with Pre-filled Content
    TwitterApp --> EncodeHashtags: %23IBC3 %23DannyMac
    EncodeHashtags --> CharLimit: Enforce 240 chars
    CharLimit --> PostTweet: User Clicks "Post"
    PostTweet --> XAlgorithm: Published

    XAlgorithm --> Trending: Retweets > Threshold
    XAlgorithm --> Timeline: Normal Distribution

    Trending --> ViralBoost: Exponential Reach
    Timeline --> StandardReach: Linear Growth

    ViralBoost --> [*]
    StandardReach --> [*]
```

---

## DIAGRAM 3: Event-Proximity Hype Ramp System

```mermaid
gantt
    title IBC3 Promotional Hype Ramp Calendar
    dateFormat  YYYY-MM-DD
    section Hype Phases
    Month Out (1x burst)      :a1, 2026-02-07, 7d
    Three Weeks Out (2x)      :a2, 2026-02-14, 7d
    Two Weeks Out (3x)        :a3, 2026-02-21, 7d
    One Week Out (4x)         :a4, 2026-02-28, 3d
    Days Out (6x)             :a5, 2026-03-03, 3d
    Hours Out (7x)            :a6, 2026-03-06, 1d
    FIGHT TIME (8x BURST)     :crit, a7, 2026-03-07, 1d
    section Content Volume
    1 post/day                :b1, 2026-02-07, 7d
    2 posts/day               :b2, 2026-02-14, 7d
    3 posts/day               :b3, 2026-02-21, 7d
    4 posts/day               :b4, 2026-02-28, 3d
    6 posts/day               :b5, 2026-03-03, 3d
    7 posts/day               :b6, 2026-03-06, 1d
    8 POSTS/DAY MAX HYPE      :crit, b7, 2026-03-07, 1d
```

---

## DIAGRAM 4: Algorithm Engagement Decision Tree

```mermaid
graph TD
    Post[Post Published to Platform]

    Post --> FB_Algo{Facebook EdgeRank}
    Post --> IG_Algo{Instagram Algorithm}
    Post --> TT_Algo{TikTok FYP}
    Post --> X_Algo{X/Twitter Timeline}

    FB_Algo -->|High Engagement| FB_Boost[Show to More Friends]
    FB_Algo -->|Low Engagement| FB_Suppress[Limit Reach]

    IG_Algo -->|High Watch Time| IG_Explore[Push to Explore Page]
    IG_Algo -->|Low Watch Time| IG_Followers[Followers Only]

    TT_Algo -->|High Completion| TT_Viral[FYP Distribution]
    TT_Algo -->|Low Completion| TT_Limited[Limited Reach]

    X_Algo -->|Retweets > 10| X_Trending[Trending Topic]
    X_Algo -->|Retweets < 10| X_Timeline[Timeline Only]

    FB_Boost --> Notification[Notification Loop]
    IG_Explore --> Notification
    TT_Viral --> Notification
    X_Trending --> Notification

    Notification --> MoreEngagement[More Likes/Comments/Shares]
    MoreEngagement --> Analytics[DFC Analytics Detects Spike]
    Analytics --> ForcePump[FORCE PUMP Command]
    ForcePump --> SwarmPump[Samurai Swarm: Generate 8x Content]
    SwarmPump --> Post

    style Post fill:#FFD700,stroke:#FFA500,stroke-width:3px
    style ForcePump fill:#FF1744,stroke:#D50000,stroke-width:3px
    style SwarmPump fill:#00E5FF,stroke:#00B8D4,stroke-width:3px
    style Notification fill:#76FF03,stroke:#64DD17,stroke-width:2px
```

---

## DIAGRAM 5: IBC3 One-Click Distribution Architecture

```mermaid
C4Context
    title IBC3 World Promo System Architecture

    Person(user, "Promoter/Fan", "Views IBC3 promo screen")

    System(ibc3_screen, "IBC3 World Promo Screen", "Flutter UI with countdown, fight card, copy buttons")

    System_Boundary(dfc_engine, "DFC Promotional Engine") {
        System(social_engine, "DFC Social Engine", "Cross-platform distribution")
        System(samurai_swarm, "Samurai Swarm Coordinator", "AI content generation + hype ramp")
        System(transformer, "Content Transformer", "Platform-native formatting")
    }

    System_Ext(facebook, "Facebook", "4 official pages")
    System_Ext(instagram, "Instagram", "2 accounts")
    System_Ext(tiktok, "TikTok", "@datafightcentral")
    System_Ext(twitter, "X/Twitter", "@datafightcentral")
    System_Ext(youtube, "YouTube", "@DataFightCentral")
    System_Ext(linkedin, "LinkedIn", "Company page")
    System_Ext(snapchat, "Snapchat", "Channel")
    System_Ext(whatsapp, "WhatsApp", "Broadcast channel")

    System_Ext(danny_mac, "Danny Mac", "IBC Facebook Page")

    Rel(user, ibc3_screen, "Opens /ibc/world", "HTTPS")
    Rel(ibc3_screen, social_engine, "COPY PROMO clicked", "Clipboard")
    Rel(ibc3_screen, danny_mac, "IBC ON FACEBOOK clicked", "Deep Link")

    Rel(social_engine, transformer, "Format for platforms", "API")
    Rel(transformer, samurai_swarm, "Request AI variants", "API")

    Rel(social_engine, facebook, "Publish post", "Graph API")
    Rel(social_engine, instagram, "Publish post", "Graph API")
    Rel(social_engine, tiktok, "Publish video", "TikTok API")
    Rel(social_engine, twitter, "Tweet intent", "X API")
    Rel(social_engine, youtube, "Upload video", "YouTube API")
    Rel(social_engine, linkedin, "Post update", "LinkedIn API")
    Rel(social_engine, snapchat, "Send snap", "Snap Kit")
    Rel(social_engine, whatsapp, "Broadcast message", "WhatsApp API")

    Rel(facebook, user, "Notifications", "Push")
    Rel(instagram, user, "Notifications", "Push")
    Rel(tiktok, user, "FYP Feed", "Algorithm")
```

---

## DIAGRAM 6: Content Rotation Engine (6-Hour Windows)

```mermaid
timeline
    title 24-Hour Content Rotation Cycle
    section Midnight
        00:00 : Window A Opens
              : Fight Highlights
              : Main Event Promos
    section Morning
        06:00 : Window B Opens
              : Training Content
              : Fighter Spotlights
    section Midday
        12:00 : Window C Opens
              : Event Announcements
              : Ticket Sales
    section Evening
        18:00 : Window D Opens
              : Live Fight Coverage
              : PPV Reminders
    section Next Cycle
        00:00 : Window A Repeats
              : Content Rotation Resets
```

```mermaid
pie title Content Distribution by Window
    "Window A (00:00-06:00)" : 25
    "Window B (06:00-12:00)" : 25
    "Window C (12:00-18:00)" : 25
    "Window D (18:00-00:00)" : 25
```

---

## DIAGRAM 7: Workshop Asset Routing Pipeline

```mermaid
stateDiagram-v2
    [*] --> AssetUpload: Admin Uploads Content

    state AssetUpload {
        [*] --> FormInput
        FormInput --> TypeSelection: Select Type
        TypeSelection --> ImageType: Image
        TypeSelection --> VideoType: Video
        TypeSelection --> CaptionType: Caption
        ImageType --> URLEntry
        VideoType --> URLEntry
        CaptionType --> TextEntry
        URLEntry --> NotesEntry
        TextEntry --> NotesEntry
        NotesEntry --> [*]: Submit to Warehouse
    }

    AssetUpload --> WarehouseInventory: Asset Stored

    state WarehouseInventory {
        [*] --> Listed
        Listed --> PerAssetActions: User Selects Action
        Listed --> BulkActions: User Selects Bulk

        PerAssetActions --> QueueButton: QUEUE
        PerAssetActions --> PushButton: PUSH LIVE

        BulkActions --> RouteTop10: ROUTE TOP 10
        BulkActions --> PushTop5: PUSH TOP 5 LIVE
    }

    WarehouseInventory --> SamuraiQueue: Assets Routed

    state SamuraiQueue {
        [*] --> Transform
        Transform --> FormatFacebook
        Transform --> FormatInstagram
        Transform --> FormatTikTok
        Transform --> FormatTwitter
        Transform --> FormatYouTube
        Transform --> FormatLinkedIn
        Transform --> FormatSnapchat
        Transform --> FormatWhatsApp
        FormatFacebook --> AutoApprove
        FormatInstagram --> AutoApprove
        FormatTikTok --> AutoApprove
        FormatTwitter --> AutoApprove
        FormatYouTube --> AutoApprove
        FormatLinkedIn --> AutoApprove
        FormatSnapchat --> AutoApprove
        FormatWhatsApp --> AutoApprove
        AutoApprove --> [*]: Ready to Publish
    }

    SamuraiQueue --> PublishDecision

    state PublishDecision {
        [*] --> CheckMode
        CheckMode --> QueueOnly: If QUEUE clicked
        CheckMode --> InstantPublish: If PUSH LIVE clicked
    }

    PublishDecision --> [*]: Complete

    note right of WarehouseInventory
        Supports:
        - Per-asset actions
        - Bulk routing (top 10)
        - Bulk publish (top 5)
    end note

    note right of SamuraiQueue
        Auto-formats for:
        - Character limits
        - Hashtag optimization
        - Platform-native style
    end note
```

---

## DIAGRAM 8: Notification Feedback Loop

```mermaid
graph LR
    A[User Publishes Post] --> B{Platform Detects Engagement}

    B -->|Like| C[Send Notification to Liker's Friends]
    B -->|Comment| D[Send Notification to Followers]
    B -->|Share| E[Send Notification to Sharer's Network]

    C --> F[Friend Sees Post]
    D --> F
    E --> F

    F --> G{Friend Interacts?}

    G -->|Yes| H[More Notifications Sent]
    G -->|No| I[Reach Plateaus]

    H --> J[Network Effect Amplification]
    J --> K[DFC Analytics Detects Spike]
    K --> L{Spike Threshold?}

    L -->|> 50% increase| M[FORCE PUMP Triggered]
    L -->|< 50% increase| N[Continue Normal Schedule]

    M --> O[Samurai Swarm: 8x Content Burst]
    O --> A

    N --> P[6-Hour Pump Cycle Continues]
    P --> A

    I --> Q[End of Cycle]

    style A fill:#FFD700,stroke:#FFA500,stroke-width:2px
    style M fill:#FF1744,stroke:#D50000,stroke-width:3px
    style O fill:#00E5FF,stroke:#00B8D4,stroke-width:3px
    style K fill:#76FF03,stroke:#64DD17,stroke-width:2px
```

---

## DIAGRAM 9: Platform Algorithm Characteristics

```mermaid
mindmap
  root((Social Platform Algorithms))
    Facebook EdgeRank
      Engagement Weighting
        Likes: 1 point
        Comments: 2 points
        Shares: 3 points
      Time Decay
        Recent posts boosted
      Post Type Priority
        Video > Image > Text
    Instagram Algorithm
      Relationship Signals
        DMs exchanged
        Profile visits
        Story views
      Interest Signals
        Liked content categories
        Hashtag follows
      Timeliness
        Recency factor
    TikTok FYP
      Completion Rate
        Critical metric
      Rewatches
        Strong signal
      Device/Account Settings
        Language preference
        Region
    X/Twitter Timeline
      Recency > All
        Chronological bias
      Engagement Velocity
        Retweets in first hour
      Reply Depth
        Conversation threads
    YouTube Recommendations
      Watch Time
        Total minutes watched
      CTR
        Thumbnail/title performance
      Session Time
        Keep viewers on platform
```

---

## DIAGRAM 10: Cross-Platform Hashtag Strategy

```mermaid
flowchart TB
    Start[Base Content Created]

    Start --> Platform{Target Platform?}

    Platform -->|Facebook| FB_Hash["#DFC #CombatSports #FightNight<br/>+ Extended CTA text"]
    Platform -->|Instagram| IG_Hash["#DFC #MMA #Boxing #Kickboxing<br/>#MuayThai #BJJ #Wrestling<br/>#BareKnuckle #FightNight<br/>#DataFightCentral"]
    Platform -->|TikTok| TT_Hash["#FightTok #CombatSports<br/>#FYP #Viral"]
    Platform -->|X/Twitter| X_Hash["#DFC #MMA #Boxing<br/>(240 char limit)"]
    Platform -->|YouTube| YT_Hash["#CombatSports #FightNight<br/>#MMA + Subscribe CTA"]
    Platform -->|LinkedIn| LI_Hash["#CombatSportsIndustry<br/>#SportsMarketing<br/>#FightPromotion"]
    Platform -->|Snapchat| SC_Hash["Minimal hashtags<br/>Emoji focus 🥊🔥"]
    Platform -->|WhatsApp| WA_Hash["*Bold formatting*<br/>Direct links only"]

    FB_Hash --> Publish[Publish to Platform]
    IG_Hash --> Publish
    TT_Hash --> Publish
    X_Hash --> Publish
    YT_Hash --> Publish
    LI_Hash --> Publish
    SC_Hash --> Publish
    WA_Hash --> Publish

    Publish --> Track[Track Engagement]
    Track --> Winning{Which Hashtags Perform Best?}

    Winning --> Analyze[Analytics Dashboard]
    Analyze --> Optimize[Optimize Future Posts]
    Optimize --> Start

    style Publish fill:#FFD700,stroke:#FFA500,stroke-width:2px
    style Track fill:#76FF03,stroke:#64DD17,stroke-width:2px
    style Optimize fill:#00E5FF,stroke:#00B8D4,stroke-width:2px
```

---

## LEGEND

### Symbols Used

- **Rectangle:** Action/Process
- **Diamond:** Decision Point
- **Parallelogram:** Input/Output
- **Circle:** Start/End
- **Cylinder:** Database/Storage
- **Rounded Rectangle:** Subprocess
- **Arrow:** Flow Direction

### Color Coding

- 🟡 **Gold (#FFD700):** User Actions / Input
- 🔴 **Red (#FF1744):** Critical Processes / FORCE PUMP
- 🔵 **Cyan (#00E5FF):** AI Automation / Swarm Activities
- 🟢 **Green (#76FF03):** Engagement Tracking / Success States
- 🟣 **Purple (#9C27B0):** Data Storage / Warehouse

---

## USAGE INSTRUCTIONS

### Viewing Diagrams in VS Code

1. Install "Markdown Preview Mermaid Support" extension
2. Open this file in VS Code
3. Press `Ctrl+Shift+V` to open preview pane
4. Diagrams will render interactively

### Exporting for Presentations

**Option 1: Use Mermaid Live Editor**

1. Copy diagram code block
2. Paste into https://mermaid.live
3. Export as PNG/SVG

**Option 2: Use VS Code Screenshot**

1. Open preview pane
2. Take screenshot of rendered diagram
3. Include in PowerPoint/Keynote

**Option 3: GitHub Rendering**

1. Commit this file to GitHub
2. GitHub automatically renders Mermaid diagrams
3. Share link with stakeholders

---

**All diagrams represent production systems currently deployed in DataFightCentral.**

**For Danny Mac:** These workflows power the IBC3 promotional engine you saw in action. Each diagram maps to real code in the DFC codebase.

---

**Document Version:** 1.0  
**Last Updated:** March 8, 2026  
**Maintained By:** DFC Development Team
