# Find Friends / Connect Community Feature Guide

**Platform:** DataFightCentral  
**Feature:** Smart Fighter & Community Discovery System  
**Status:** Implementation Blueprint  
**Version:** 1.0

---

## 🎯 Executive Summary

Build a combat sports-specific "Find Friends" system that helps users discover training partners, coaches, gyms, fighters, and mentors based on:

- Location (gym proximity)
- Fighting style (BJJ, boxing, MMA, etc.)
- Skill level (beginner to professional)
- Training goals (competition, fitness, self-defense)
- Mutual connections

---

## 📐 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE LAYER                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Search Bar]  [Filter Panel]  [Suggestions Feed]  [Requests]  │
│                                                                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  /api/friends/search          (Search by name, style, gym)      │
│  /api/friends/suggestions     (AI-powered recommendations)       │
│  /api/friends/requests        (Send, accept, decline, block)    │
│  /api/friends/nearby          (Location-based discovery)        │
│  /api/friends/import          (Contact sync - optional)         │
│                                                                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Search Service   │  │ Recommendation   │  │ Privacy      │  │
│  │ - Fuzzy matching │  │ Engine           │  │ Service      │  │
│  │ - Filter logic   │  │ - ML scoring     │  │ - Visibility │  │
│  │ - Pagination     │  │ - Mutual friends │  │ - Blocking   │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Connection       │  │ Notification     │  │ Analytics    │  │
│  │ Manager          │  │ Service          │  │ Service      │  │
│  │ - Request flow   │  │ - Push alerts    │  │ - Track      │  │
│  │ - Status updates │  │ - In-app notify  │  │   engagement │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Firestore]                [Redis Cache]      [Elasticsearch]  │
│  - users                    - Hot suggestions  - Indexed search │
│  - connections              - Active requests  - Fuzzy matching │
│  - connection_requests      - Recent searches  - Geo-queries    │
│  - user_preferences                                              │
│  - privacy_settings                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Schema (Firestore)

### 1. Users Collection (Existing - Extend)

```javascript
users/{userId}
{
  // Existing fields...
  id: "user123",
  displayName: "John Fighter",
  email: "john@example.com",
  profileImageUrl: "https://...",
  role: "fighter", // fighter, coach, gym_owner, fan

  // NEW: Discovery fields
  discovery: {
    fightingStyles: ["bjj", "muay_thai", "boxing"],
    skillLevel: "intermediate", // beginner, intermediate, advanced, professional
    trainingGoals: ["competition", "fitness", "self_defense"],
    homeGymId: "gym_abc123",
    location: {
      lat: -27.4698,
      lng: 153.0251,
      city: "Brisbane",
      state: "QLD",
      country: "Australia"
    },
    lookingFor: ["training_partners", "sparring", "coaching"],
    availability: ["weekday_mornings", "weekend_afternoons"]
  },

  // NEW: Privacy settings
  privacy: {
    discoverableBySearch: true,
    discoverableByLocation: true,
    showGymLocation: true,
    showRealName: true,
    allowMessageRequests: true,
    profileVisibility: "public" // public, friends_only, private
  },

  // NEW: Connection stats
  connections: {
    totalFriends: 42,
    pendingRequests: 3,
    sentRequests: 5,
    mutualGyms: 2
  }
}
```

### 2. Connections Collection (NEW)

```javascript
connections/{connectionId}
{
  id: "conn_xyz789",
  userId: "user123",
  friendId: "user456",
  status: "accepted", // pending, accepted, declined, blocked
  connectionType: "training_partner", // training_partner, coach, student, gym_member
  createdAt: Timestamp,
  acceptedAt: Timestamp,

  // Relationship metadata
  metadata: {
    mutualFriends: 5,
    mutualGyms: ["gym_abc", "gym_def"],
    sharedStyles: ["bjj", "wrestling"],
    connectionSource: "discovery_search" // search, suggestions, mutual_friends, gym_member
  }
}
```

### 3. Connection Requests Collection (NEW)

```javascript
connection_requests/{requestId}
{
  id: "req_abc123",
  senderId: "user123",
  receiverId: "user456",
  status: "pending", // pending, accepted, declined, expired
  message: "Hey! Saw you train at the same gym. Want to spar?",
  requestType: "friend_request",

  createdAt: Timestamp,
  expiresAt: Timestamp, // 30 days default
  respondedAt: Timestamp?
}
```

### 4. Friend Suggestions Cache (NEW)

```javascript
friend_suggestions/{userId}
{
  userId: "user123",
  generatedAt: Timestamp,
  expiresAt: Timestamp, // Refresh every 24 hours

  suggestions: [
    {
      suggestedUserId: "user789",
      score: 0.87, // 0-1 confidence score
      reasons: [
        "trains_at_same_gym",
        "similar_skill_level",
        "3_mutual_friends",
        "matching_training_goals"
      ],
      metadata: {
        mutualFriends: 3,
        mutualGyms: 1,
        distance: "2.3 km away"
      }
    }
  ]
}
```

### 5. Blocked Users Collection (NEW)

```javascript
blocked_users/{blockId}
{
  blockerId: "user123",
  blockedUserId: "user456",
  createdAt: Timestamp,
  reason: "spam" // optional: spam, harassment, inappropriate, other
}
```

---

## 🔌 API Endpoints

### 1. Search Users

```
GET /api/friends/search?q={query}&filters={json}

Query Parameters:
- q: Search query (name, username, gym)
- style: Filter by fighting style (bjj, boxing, etc.)
- level: Filter by skill level
- location: Filter by distance (e.g., "10km")
- type: Filter by user type (fighter, coach, etc.)
- limit: Results per page (default: 20)
- offset: Pagination offset

Response:
{
  "results": [
    {
      "userId": "user456",
      "displayName": "Jane Fighter",
      "profileImage": "https://...",
      "fightingStyles": ["bjj", "judo"],
      "skillLevel": "advanced",
      "homeGym": "Alpha Gym Brisbane",
      "distance": "3.2 km",
      "mutualFriends": 2,
      "connectionStatus": "none" // none, pending, connected, blocked
    }
  ],
  "total": 47,
  "hasMore": true
}
```

### 2. Get Suggestions

```
GET /api/friends/suggestions?count={number}

Response:
{
  "suggestions": [
    {
      "userId": "user789",
      "displayName": "Mike Grappler",
      "profileImage": "https://...",
      "score": 0.87,
      "reasons": [
        "Trains at your gym",
        "Similar skill level",
        "3 mutual friends"
      ],
      "metadata": {
        "mutualFriends": 3,
        "distance": "Same gym"
      }
    }
  ],
  "generatedAt": "2026-03-09T10:00:00Z"
}
```

### 3. Send Connection Request

```
POST /api/friends/requests

Body:
{
  "receiverId": "user456",
  "message": "Hey! Want to train together?",
  "requestType": "friend_request"
}

Response:
{
  "requestId": "req_abc123",
  "status": "pending",
  "createdAt": "2026-03-09T10:00:00Z"
}
```

### 4. Respond to Request

```
POST /api/friends/requests/{requestId}/respond

Body:
{
  "action": "accept" // accept, decline
}

Response:
{
  "status": "accepted",
  "connectionId": "conn_xyz789"
}
```

### 5. Get Nearby Users

```
GET /api/friends/nearby?lat={lat}&lng={lng}&radius={km}

Response:
{
  "nearby": [
    {
      "userId": "user999",
      "displayName": "Tom Boxer",
      "distance": "1.5 km",
      "gym": "Downtown Boxing Gym",
      "fightingStyles": ["boxing", "kickboxing"]
    }
  ]
}
```

### 6. Block User

```
POST /api/friends/block

Body:
{
  "userId": "user456",
  "reason": "spam"
}

Response:
{
  "blocked": true,
  "blockId": "block_abc"
}
```

---

## 🧠 Recommendation Algorithm

### Scoring Factors (0-100 points)

1. **Mutual Connections (30 points max)**
   - 10 points per mutual friend (max 3)
   - 5 points per mutual gym membership

2. **Training Compatibility (25 points max)**
   - 10 points for matching fighting style
   - 10 points for matching skill level (±1 level)
   - 5 points for matching training goals

3. **Proximity (20 points max)**
   - 20 points: Same gym
   - 15 points: < 5km away
   - 10 points: 5-10km away
   - 5 points: 10-25km away
   - 0 points: > 25km away

4. **Activity & Engagement (15 points max)**
   - 5 points: Active last 7 days
   - 5 points: Has complete profile
   - 5 points: Has training history

5. **Availability Match (10 points max)**
   - 10 points: Overlapping training schedule

### Filter Logic

```javascript
// Exclude from suggestions:
- Already connected users
- Blocked users
- Users who blocked you
- Users with privacy settings = "private"
- Expired suggestions (> 30 days old)
```

---

## 🎨 UI/UX Wireframes

### Mobile Layout

```
┌─────────────────────────────────────────┐
│  ←  Find Friends                    ⚙️  │ Header
├─────────────────────────────────────────┤
│                                          │
│  🔍 Search fighters, gyms, coaches...   │ Search Bar
│                                          │
├─────────────────────────────────────────┤
│  Suggested for You            See all → │
│  ┌──────┐ ┌──────┐ ┌──────┐            │
│  │  👤  │ │  👤  │ │  👤  │            │ Horizontal
│  │ Jane │ │ Mike │ │ Tom  │            │ Scroll Cards
│  │ +Add │ │ +Add │ │ +Add │            │
│  └──────┘ └──────┘ └──────┘            │
├─────────────────────────────────────────┤
│  Filters: [All] [BJJ] [Boxing] [Nearby]│ Filter Chips
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │  👤  Sarah Fighter    2 mutuals │   │ Search
│  │  BJJ • Intermediate • 3.2 km    │   │ Results
│  │                 [Add Friend] ➕  │   │ Grid
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  👤  Alex Coach       Same gym  │   │
│  │  Boxing • Advanced • Alpha Gym  │   │
│  │                 [Add Friend] ➕  │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Desktop Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  🥊 DFC  [Home] [FightWire] [Find Friends] [PPV]    🔔 👤         │ Header
├─────────┬───────────────────────────────────────────────┬───────────┤
│         │                                               │           │
│ FILTERS │  🔍 Search fighters, gyms, coaches...        │ REQUESTS  │
│         │                                               │           │
│ Style:  │  ═══════════════════════════════════════     │ ┌───────┐ │
│ ☑ BJJ   │  Suggested for You              See all →    │ │  👤   │ │
│ ☐ Boxing│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐           │ │ John  │ │
│ ☐ MMA   │  │ 👤  │ │ 👤  │ │ 👤  │ │ 👤  │           │ │ wants │ │
│         │  │Jane │ │Mike │ │Tom  │ │Amy  │           │ │  to   │ │
│ Level:  │  │+Add │ │+Add │ │+Add │ │+Add │           │ │connect│ │
│ ☐ Begin │  └─────┘ └─────┘ └─────┘ └─────┘           │ │[✓][✗]│ │
│ ☑ Inter │                                               │ └───────┘ │
│ ☐ Advan │  ═══════════════════════════════════════     │ ┌───────┐ │
│         │  Search Results                               │ │  👤   │ │
│ Distanc │  ┌──────────┐ ┌──────────┐ ┌──────────┐     │ │ Sarah │ │
│ ○ < 5km │  │   👤     │ │   👤     │ │   👤     │     │ │ sent  │ │
│ ● <10km │  │  Sarah F │ │  Alex C  │ │  Tim G   │     │ │request│ │
│ ○ <25km │  │  2 mut   │ │ Same gym │ │  5 mut   │     │ └───────┘ │
│         │  │  +Add    │ │  +Add    │ │  +Add    │     │           │
│         │  └──────────┘ └──────────┘ └──────────┘     │ Pending   │
│         │  ┌──────────┐ ┌──────────┐ ┌──────────┐     │ (You):    │
│         │  │   👤     │ │   👤     │ │   👤     │     │ • Mike    │
│         │  └──────────┘ └──────────┘ └──────────┘     │ • Tom     │
│         │                                               │           │
└─────────┴───────────────────────────────────────────────┴───────────┘
```

---

## 🔐 Privacy & Safety Features

### User Controls

- **Profile Visibility:** Public / Friends-only / Private
- **Search Visibility:** Allow discovery via search (on/off)
- **Location Visibility:** Show gym/location (on/off)
- **Message Requests:** Allow messages from non-friends (on/off)
- **Block List:** Manage blocked users
- **Data Export:** Download all connection data (GDPR)

### Platform Safety

- **Rate Limiting:** Max 50 friend requests per day
- **Spam Detection:** Flag users sending bulk requests
- **Content Moderation:** Review reported profiles
- **Verification Badges:** Verified gyms, coaches, fighters
- **Age Restrictions:** 13+ minimum (COPPA compliance)

---

## 🚀 Implementation Roadmap

### Phase 1: Core Infrastructure (Weeks 1-2)

- [ ] Database schema implementation
- [ ] Basic search API (name, username)
- [ ] Connection request flow (send, accept, decline)
- [ ] Privacy settings UI

### Phase 2: Discovery Features (Weeks 3-4)

- [ ] Filter by style, level, location
- [ ] Nearby users (geo-search)
- [ ] Suggestions algorithm v1 (rule-based)
- [ ] Mutual friends calculation

### Phase 3: AI Recommendations (Weeks 5-6)

- [ ] ML scoring model training
- [ ] Suggestions cache implementation
- [ ] Personalized recommendations
- [ ] A/B testing framework

### Phase 4: Engagement Boosters (Weeks 7-8)

- [ ] "New member" onboarding flow
- [ ] Badges (mutual gym, shared style)
- [ ] Connection streaks
- [ ] Suggested training groups

### Phase 5: Polish & Scale (Weeks 9-10)

- [ ] Performance optimization (caching, indexing)
- [ ] Mobile app integration
- [ ] Push notifications
- [ ] Analytics dashboard

---

## 📊 Success Metrics

### Primary KPIs

- **Connection Rate:** % of users who make ≥1 connection within 7 days
- **Search-to-Connect:** % of searches that result in connection request
- **Suggestion CTR:** % of suggested profiles clicked
- **Acceptance Rate:** % of friend requests accepted

### Secondary KPIs

- **Avg Connections per User:** Target: 10-20 friends
- **Time to First Connection:** Target: < 48 hours
- **Daily Active Discoverers:** Users searching/browsing daily
- **Retention:** % of users who return after first connection

---

## 🔗 Integration with Existing DFC Features

### 1. Home Screen

- Add "Find Friends" card to dashboard
- Show pending requests badge in navigation

### 2. Profile Screen

- "Add Friend" button on user profiles
- Display mutual friends count
- Show connection status

### 3. FightWire (Social Feed)

- Suggest friends to follow in feed
- "Add Friend" CTA on post interactions

### 4. Events

- Show "Friends Attending" on event pages
- Suggest connecting with event attendees

### 5. Gyms/Maps

- List gym members when viewing gym details
- "Connect with trainers" on gym page

### 6. Messaging

- Only allow DMs between connected friends (privacy)
- Send connection request via message button

---

## 🛠️ Technical Implementation (Flutter/Dart)

### Service Layer

```dart
// lib/shared/services/friend_service.dart

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users
  Future<List<UserModel>> searchUsers({
    required String query,
    List<String>? styles,
    String? skillLevel,
    double? radiusKm,
  }) async {
    Query query = _firestore.collection('users')
      .where('discovery.discoverableBySearch', isEqualTo: true);

    if (styles != null) {
      query = query.where('discovery.fightingStyles', arrayContainsAny: styles);
    }

    // Apply additional filters...

    final snapshot = await query.limit(20).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // Get suggestions
  Future<List<UserSuggestion>> getSuggestions(String userId) async {
    final suggestionsDoc = await _firestore
      .collection('friend_suggestions')
      .doc(userId)
      .get();

    if (!suggestionsDoc.exists || _isCacheExpired(suggestionsDoc)) {
      // Generate fresh suggestions
      return await _generateSuggestions(userId);
    }

    return (suggestionsDoc.data()!['suggestions'] as List)
      .map((json) => UserSuggestion.fromJson(json))
      .toList();
  }

  // Send connection request
  Future<String> sendConnectionRequest({
    required String receiverId,
    String? message,
  }) async {
    final request = {
      'senderId': _authService.currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(Duration(days: 30)),
    };

    final docRef = await _firestore.collection('connection_requests').add(request);

    // Send notification
    await _notificationService.sendFriendRequest(receiverId);

    return docRef.id;
  }

  // Accept request
  Future<void> acceptRequest(String requestId) async {
    final requestDoc = await _firestore
      .collection('connection_requests')
      .doc(requestId)
      .get();

    final data = requestDoc.data()!;

    // Create bidirectional connection
    await _createConnection(data['senderId'], data['receiverId']);

    // Update request status
    await requestDoc.reference.update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Notify sender
    await _notificationService.sendRequestAccepted(data['senderId']);
  }

  Future<void> _createConnection(String user1, String user2) async {
    final batch = _firestore.batch();

    // Create connection documents
    batch.set(_firestore.collection('connections').doc(), {
      'userId': user1,
      'friendId': user2,
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_firestore.collection('connections').doc(), {
      'userId': user2,
      'friendId': user1,
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
```

### Screen Implementation

```dart
// lib/features/social/screens/find_friends_screen.dart

class FindFriendsScreen extends StatefulWidget {
  @override
  _FindFriendsScreenState createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _searchResults = [];
  List<UserSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final suggestions = await _friendService.getSuggestions(
        AuthService.currentUserId
      );
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results = await _friendService.searchUsers(query: query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Friends'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search fighters, gyms, coaches...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _search,
            ),
          ),

          // Suggestions carousel
          if (_suggestions.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Suggested for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: Text('See all')),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return _SuggestionCard(suggestion: _suggestions[index]);
                },
              ),
            ),
          ],

          // Search results
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _UserResultCard(user: _searchResults[index]);
                  },
                ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📚 Related Files

- [Enhanced Messaging Service](../lib/features/messaging/services/enhanced_messaging_service.dart)
- [Social Service](../lib/shared/services/social_service.dart)
- [User Model](../lib/shared/models/user_model.dart)
- [Firestore Schema](../docs/FIRESTORE_SCHEMA.md)
- [Messaging Architecture 2030](../docs/MESSAGING_ARCHITECTURE_2030.md)

---

## 🎯 Next Steps

1. **Review & Approve:** Get stakeholder sign-off on scope
2. **Design Mockups:** Create high-fidelity designs in Figma
3. **Backend Setup:** Implement Firestore schema + Cloud Functions
4. **Frontend Build:** Develop Flutter screens + widgets
5. **Testing:** Unit tests, integration tests, user acceptance testing
6. **Launch:** Phased rollout with A/B testing

---

**Last Updated:** March 9, 2026  
**Owner:** DataFightCentral Product Team  
**Status:** Ready for Implementation
