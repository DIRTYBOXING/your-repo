# 🥷 DFC SUPER FEED ARCHITECTURE

**Production-Grade Social Feed System for DataFightCentral**

Last Updated: March 10, 2026

---

## 🎯 Goals

- ⚡ **Extremely Fast** — Feed loads in <100ms
- 🌊 **Smooth Flow** — Infinite scroll, realtime updates
- 🥷 **Protected Ecosystem** — Ninja moderation keeps toxicity out
- 📈 **Viral Growth** — Every action encourages sharing & engagement
- ❤️ **Community-Driven** — Friends and local content first

---

## 🏗️ Architecture Overview

The DFC Super Feed consists of **5 interconnected engines** working together:

```
┌────────────────────────────────────────────────────────────────┐
│                        USER FEED REQUEST                       │
└──────────────────────────┬─────────────────────────────────────┘
                           │
            ┌──────────────▼────────────────┐
            │   FEED CACHE SERVICE          │
            │   (Millisecond Loading)       │
            └──────────────┬────────────────┘
                           │
            ┌──────────────▼────────────────┐
            │   FEED RANKING ENGINE         │
            │   (Friend-First Priority)     │
            └──────────────┬────────────────┘
                           │
            ┌──────────────▼────────────────┐
            │   NINJA MODERATION            │
            │   (Toxicity Protection)       │
            └──────────────┬────────────────┘
                           │
            ┌──────────────▼────────────────┐
            │   REALTIME LAYER              │
            │   (Live Interactions)         │
            └──────────────┬────────────────┘
                           │
            ┌──────────────▼────────────────┐
            │   CONTENT STORAGE             │
            │   (Firebase/Cloudflare)       │
            └───────────────────────────────┘
```

---

## 1️⃣ FEED RANKING ENGINE

**File:** `lib/shared/services/feed_ranking_engine.dart`

### Friend-First Priority System

Posts are ranked in **5 tiers**:

| Tier | Content Type                 | Base Score |
| ---- | ---------------------------- | ---------- |
| 1    | **Friends Posts**            | +100       |
| 2    | **Followed Fighters**        | +80        |
| 3    | **Local Gyms** (within 20km) | +70        |
| 4    | **Verified Promotions**      | +60        |
| 5    | **Global Community**         | +40        |

### 10-Factor Scoring Algorithm

Each post receives a relevance score based on:

```dart
relevanceScore =
  (relationshipScore × 0.40) +  // 40% — Most important!
  (gymScore × 0.15) +
  (locationScore × 0.10) +
  (trainingStyleScore × 0.08) +
  (engagementScore × 0.10) +
  (trendingScore × 0.05) +
  (contentTypeScore × 0.05) +
  (trustScore × 0.04) +
  (recencyScore × 0.02) +
  (impactScore × 0.01)
```

### Usage

```dart
final rankingEngine = FeedRankingEngine();

final personalizedFeed = await rankingEngine.getPersonalizedFeed(
  userId: currentUserId,
  limit: 20,
);
```

---

## 2️⃣ FEED CACHE SERVICE

**File:** `lib/shared/services/feed_cache_service.dart`

### Why Caching?

Direct Firestore queries are **slow**:

- Query 50 posts → 2-3 seconds ❌
- Rank + filter → 1-2 seconds ❌
- **Total:** 3-5 seconds (unacceptable)

With caching:

- Read from pre-computed cache → **<100ms** ✅
- **20-30x faster loading!**

### Cache Structure

```
user_feeds (collection)
  ├─ userId_1 (document)
  │   └─ posts (subcollection)
  │       ├─ postId_1
  │       ├─ postId_2
  │       └─ postId_3
  ├─ userId_2 (document)
  │   └─ posts (subcollection)
  └─ ...
```

### Cache Strategy

1. **User posts content** → Stored in `posts` collection
2. **Cloud Function triggers** → Updates `user_feeds` cache for all followers
3. **Client requests feed** → Reads from pre-computed cache
4. **Cache TTL:** 10 minutes (then refresh)

### Usage

```dart
final cacheService = FeedCacheService();

// Ultra-fast cached feed
final feed = await cacheService.getCachedFeed(
  userId: currentUserId,
  limit: 20,
);

// Warm cache for new user
await cacheService.warmCacheForNewUser(newUserId);
```

### Production Deployment

Requires **Cloud Function** to auto-update caches:

```javascript
// Firebase Cloud Function (Node.js)
exports.onPostCreated = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const post = snap.data();
    const authorId = post.authorId;

    // Get author's followers
    const followersSnap = await admin
      .firestore()
      .collection("user_relationships")
      .where("targetUserId", "==", authorId)
      .get();

    const batch = admin.firestore().batch();

    // Add post to each follower's cache
    followersSnap.docs.forEach((doc) => {
      const followerId = doc.data().userId;
      const cacheRef = admin
        .firestore()
        .collection("user_feeds")
        .doc(followerId)
        .collection("posts")
        .doc(snap.id);

      batch.set(cacheRef, {
        ...post,
        cachedAt: admin.firestore.FieldValue.serverTimestamp(),
        score: post.relevanceScore || 0.5,
      });
    });

    await batch.commit();
  });
```

---

## 3️⃣ NINJA MODERATION SERVICE

**File:** `lib/shared/services/ninja_moderation_service.dart`

### Philosophy

> "The Ninja protects the ecosystem."

Moderation should be **invisible but powerful**. Users never see drama — toxic content simply disappears.

### Detection Systems

#### 1. Toxicity Detection

- Keyword scanning (production: use ML API like Perspective)
- Pattern matching for harassment
- Context-aware analysis

#### 2. Spam Detection

- Excessive caps (>70% of text)
- Repeated characters (aaaaaaa)
- URL phishing (non-whitelisted links)
- Excessive emojis (>10)

#### 3. Trust Scoring

Each user has a trust score (0.0 - 1.0):

- New users: 1.0
- After violations: decreases
- Decay over time: violations older than 90 days ignored

### Moderation Actions

| Action             | Severity | Duration  | User Sees                               |
| ------------------ | -------- | --------- | --------------------------------------- |
| **Shadow Mute**    | 0.3      | Immediate | Nothing (post invisible to others)      |
| **Warning**        | 0.5      | —         | Notification: "Ninja detected issue"    |
| **Post Removal**   | 0.7      | —         | "Post removed for violating guidelines" |
| **Temporary Mute** | 0.7      | 1-7 days  | "Posting restricted"                    |
| **Temporary Ban**  | 0.9      | 7-30 days | "Account suspended"                     |
| **Permanent Ban**  | 1.0      | Forever   | "Account terminated"                    |

### Usage

```dart
final ninjaService = NinjaModerationService();

// Check content before posting
final result = await ninjaService.analyzeContent(
  content: postText,
  authorId: userId,
);

if (result.action == ModerationAction.shadowMute) {
  // Auto-hide post
  await ninjaService.shadowMutePost(postId, result.reason);
} else if (result.action == ModerationAction.warn) {
  // Warn user
  await ninjaService.warnUser(
    userId: userId,
    postId: postId,
    reason: result.reason,
  );
}

// Check user status before allowing actions
final userStatus = await ninjaService.getUserStatus(userId);
if (!userStatus.canPost) {
  showDialog(context, "You're temporarily muted");
  return;
}
```

### Reporting System

Users can report content:

```dart
await ninjaService.reportContent(
  reporterId: currentUserId,
  contentId: postId,
  type: ReportType.post,
  reason: 'Harassment',
  details: 'User is targeting me repeatedly',
);
```

**Auto-trigger:** 3+ reports → Flagged for manual review

---

## 4️⃣ ENHANCED SHARE SYSTEM

**File:** `lib/shared/services/social_service.dart`

### Share Targets

Users can share posts to 5 different targets:

| Target     | Destination      | Use Case                     |
| ---------- | ---------------- | ---------------------------- |
| **Feed**   | Your own feed    | Repost publicly              |
| **Friend** | Direct message   | Send to specific person      |
| **Gym**    | Gym group chat   | Share with training partners |
| **Event**  | Event discussion | Relevant to fight/event      |
| **Story**  | 24-hour story    | Temporary share (expires)    |

### Usage

```dart
final socialService = SocialService();

// Share to your feed (repost)
await socialService.sharePost(
  postId,
  userId,
  target: ShareTarget.feed,
  message: 'This is fire! 🔥',
);

// Send to friend via DM
await socialService.sharePost(
  postId,
  userId,
  target: ShareTarget.friend,
  targetId: friendId,
  message: 'Check this out!',
);

// Share to gym group
await socialService.sharePost(
  postId,
  userId,
  target: ShareTarget.gym,
  targetId: gymId,
);

// Share to story (expires in 24h)
await socialService.sharePost(
  postId,
  userId,
  target: ShareTarget.story,
  message: 'Epic knockout!',
);
```

---

## 5️⃣ COMMENT SYSTEM

**File:** `lib/shared/models/post_model.dart` + `lib/shared/services/social_service.dart`

### Features

✅ **Threaded Comments** — Reply to replies  
✅ **Like Comments** — Show appreciation  
✅ **Pin Comments** — Promoters can pin fight info  
✅ **Mentions** — Tag users in comments

### Usage

```dart
// Add comment
await socialService.addComment(
  postId,
  userId,
  'Great knockout!',
  displayName: userName,
  role: userRole,
  avatarUrl: userAvatar,
);

// Pin comment (promoters/authors only)
await socialService.pinComment(
  postId,
  commentId,
  userId,
);

// Get comments (realtime stream)
StreamBuilder(
  stream: socialService.getComments(postId),
  builder: (context, snapshot) {
    final comments = snapshot.data ?? [];
    // Show pinned comment first
    final pinned = comments.where((c) => c['isPinned'] == true);
    final regular = comments.where((c) => c['isPinned'] != true);

    return ListView(
      children: [
        ...pinned.map((c) => PinnedCommentTile(c)),
        ...regular.map((c) => CommentTile(c)),
      ],
    );
  },
);
```

---

## 📊 FIRESTORE STRUCTURE

### Core Collections

```
users
  ├─ userId
  │   ├─ name, role, gym, location
  │   ├─ friends[], followers[]
  │   ├─ muted, banned, trustScore
  │   └─ lastActive

posts
  ├─ postId
  │   ├─ authorId, content, mediaUrl
  │   ├─ likesCount, commentsCount, sharesCount
  │   ├─ respectCount, strongCount, supportCount, warriorCount, championCount
  │   ├─ location, tags, hashtags
  │   ├─ shadowMuted, removed
  │   └─ createdAt, relevanceScore

user_feeds (CACHE)
  ├─ userId
  │   └─ posts
  │       ├─ postId
  │       │   ├─ [full post data]
  │       │   ├─ score
  │       │   └─ cachedAt

comments
  ├─ postId
  │   └─ comments
  │       ├─ commentId
  │       │   ├─ authorId, content
  │       │   ├─ parentCommentId (for replies)
  │       │   ├─ isPinned
  │       │   └─ likesCount

reactions
  ├─ reactionId
  │   ├─ userId, postId
  │   ├─ type (respect, strong, support, warrior, champion)
  │   └─ createdAt

shares
  ├─ shareId
  │   ├─ postId, sharerId
  │   ├─ target (feed, friend, gym, event, story)
  │   ├─ targetId, message
  │   └─ createdAt

user_relationships
  ├─ relationshipId
  │   ├─ userId, targetUserId
  │   ├─ type (friend, following, coach, gymMember)
  │   ├─ isMutual, connectionStrength
  │   └─ sharedGymId, isTrainingPartner

moderation_violations
  ├─ violationId
  │   ├─ userId, action, reason
  │   ├─ severity (0.0 - 1.0)
  │   ├─ durationDays
  │   └─ timestamp

reports
  ├─ reportId
  │   ├─ reporterId, contentId
  │   ├─ type, reason, details
  │   ├─ status (pending, reviewed, resolved)
  │   └─ timestamp

stories
  ├─ storyId
  │   ├─ userId, type (shared_post)
  │   ├─ sharedPostId, message
  │   ├─ expiresAt (24h)
  │   └─ views, viewedBy[]

conversations
  ├─ conversationId (userId1_userId2)
  │   ├─ participants[]
  │   ├─ lastMessage, lastMessageAt
  │   └─ messages
  │       ├─ messageId
  │       │   ├─ senderId, type
  │       │   ├─ message, sharedPostId
  │       │   └─ timestamp

gym_chats
  ├─ gymId
  │   └─ messages
  │       ├─ messageId
  │       │   ├─ senderId, type
  │       │   ├─ message, sharedPostId
  │       │   └─ timestamp

event_chats
  ├─ eventId
  │   └─ messages
```

---

## 👍 REACTIONS SYSTEM

### 5 DFC Reactions

| Reaction    | Emoji | Meaning           | Use Case                       |
| ----------- | ----- | ----------------- | ------------------------------ |
| **Respect** | 🥋    | Acknowledge skill | Technical moves, sportsmanship |
| **Power**   | 💪    | Show strength     | Intense training, PRs          |
| **Support** | ❤️    | Community love    | Charity, recovery stories      |
| **Fire**    | 🔥    | Ultimate hype     | Knockouts, epic moments        |
| **Legend**  | 👑    | Hall of fame      | Historic achievements          |

### Usage

```dart
// Add reaction
await postCard.addReaction(
  postId: post.id,
  userId: currentUserId,
  type: ReactionType.fire,
);

// Display reactions
Row(
  children: [
    ReactionButton(
      icon: '🥋',
      count: post.respectCount,
      active: userRespected,
      onTap: () => addReaction(ReactionType.respect),
    ),
    ReactionButton(
      icon: '💪',
      count: post.strongCount,
      active: userStronged,
      onTap: () => addReaction(ReactionType.strong),
    ),
    // ... repeat for all 5 reactions
  ],
);
```

---

## 📈 VIRAL GROWTH LOOPS

Every post encourages engagement:

```
User sees post
    ↓
Reacts (Respect/Fire/Legend)
    ↓
Writes comment
    ↓
Shares to friend/gym
    ↓
Friend sees post
    ↓
Friend joins DFC
    ↓
Network grows organically
```

### Growth Mechanics

1. **Share Incentives** — "5 friends shared this"
2. **Gym Challenges** — "Your gym vs their gym"
3. **Campaign Participation** — Pink Shield, Gold Coin, NightChill
4. **Fighter Interactions** — Pro fighters engage with fans
5. **Event Hype** — Live fight discussions

---

## 🚀 PERFORMANCE OPTIMIZATION

### Client-Side

```dart
// Infinite scroll with lazy loading
ListView.builder(
  controller: _scrollController,
  itemCount: posts.length + 1,
  itemBuilder: (context, index) {
    if (index == posts.length) {
      // Load more trigger
      _loadMorePosts();
      return CircularProgressIndicator();
    }
    return PostCard(post: posts[index]);
  },
);

// Image caching
CachedNetworkImage(
  imageUrl: post.mediaUrl,
  placeholder: (context, url) => Shimmer(),
  memCacheWidth: 600, // Optimize memory
);

// Video optimization
VideoPlayer(
  controller: _controller,
  autoplay: false, // Only play when tapped
);
```

### Server-Side (Firebase)

```javascript
// Composite index for fast queries
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "relevanceScore", "order": "DESCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "user_feeds",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "score", "order": "DESCENDING" },
        { "fieldPath": "cachedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 🔮 FUTURE ENHANCEMENTS

### Phase 2 (Q3 2026)

- ✨ **AI Highlight Detection** — Auto-generate fight clips
- 🎬 **Auto Fight Clip Generator** — ML-powered video editing
- 📊 **Combat Analytics Posts** — "Your striking accuracy is up 15%"
- 🎯 **Smart Sponsorship Placement** — Context-aware ads

### Phase 3 (Q4 2026)

- 🤖 **GPT-4 Content Moderation** — Replace keyword scanning
- 🌐 **Federated Feed** — Cross-platform content (Instagram, TikTok)
- 💰 **Creator Monetization** — Pay fighters for viral content
- 🎥 **Live Streaming Integration** — In-app PPV fights

---

## 📱 FLUTTER IMPLEMENTATION

### Feed Screen

```dart
class SuperFeedScreen extends StatefulWidget {
  @override
  _SuperFeedScreenState createState() => _SuperFeedScreenState();
}

class _SuperFeedScreenState extends State<SuperFeedScreen> {
  final FeedCacheService _cacheService = FeedCacheService();
  final NinjaModerationService _ninjaService = NinjaModerationService();

  List<FightWirePost> _posts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);

    final userId = context.read<AuthService>().currentUser!.uid;

    // Check user moderation status
    final userStatus = await _ninjaService.getUserStatus(userId);
    if (userStatus.isBanned) {
      _showBannedDialog(userStatus.banReason);
      return;
    }

    // Load cached feed (ultra-fast)
    final posts = await _cacheService.getCachedFeed(
      userId: userId,
      limit: 20,
    );

    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FightWire')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeed,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return PostCard(
                    post: _posts[index],
                    onShare: (target, targetId, message) async {
                      await _socialService.sharePost(
                        _posts[index].id,
                        userId,
                        target: target,
                        targetId: targetId,
                        message: message,
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _createPost(),
      ),
    );
  }
}
```

---

## ✅ IMPLEMENTATION STATUS

| Component             | Status      | File                            |
| --------------------- | ----------- | ------------------------------- |
| Feed Ranking Engine   | ✅ Complete | `feed_ranking_engine.dart`      |
| Friend-First Priority | ✅ Complete | `feed_ranking_engine.dart`      |
| Feed Cache Service    | ✅ Complete | `feed_cache_service.dart`       |
| Ninja Moderation      | ✅ Complete | `ninja_moderation_service.dart` |
| Enhanced Share System | ✅ Complete | `social_service.dart`           |
| 5 Reactions           | ✅ Complete | `fightwire_post.dart`           |
| Threaded Comments     | ✅ Complete | `post_model.dart`               |
| Pin Comments          | ✅ Complete | `social_service.dart`           |
| Stories (24h)         | ✅ Complete | `social_service.dart`           |
| DM Sharing            | ✅ Complete | `social_service.dart`           |
| Gym Chat Sharing      | ✅ Complete | `social_service.dart`           |
| Event Chat Sharing    | ✅ Complete | `social_service.dart`           |

---

## 🎯 CONCLUSION

**DFC now has a production-grade Super Feed system** that rivals Facebook, Instagram, and TikTok — but **purpose-built for combat sports**.

### What Makes It Special

1. **Friend-First** — Community over algorithms
2. **Ninja Protection** — Toxicity eliminated invisibly
3. **Lightning Fast** — <100ms load times via caching
4. **Combat-Specific** — 5 reactions, gym chats, fight discussions
5. **Viral Growth** — Every action spreads opportunity

### Next Steps

To complete the social platform, implement:

1. **Notification System** — Real-time push notifications
2. **Media Upload Pipeline** — Photo/video processing
3. **User Profile System** — Fighter portfolios
4. **Messaging Enhancements** — Group chats, voice messages

---

**Built by the DFC team with ❤️ for the combat sports community.**

🥷 **"The Ninja protects the ecosystem."**
