/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL NETWORK INTEGRATION GUIDE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This guide shows how to wire up the complete social network infrastructure
/// into your DataFightCentral app.
///
/// ═══════════════════════════════════════════════════════════════════════════

## 1. ADD IMPORTS TO ROUTER CONFIG

```dart
// Add to lib/core/config/router_config.dart

// Enhanced Social Screens
import '../../features/social/screens/enhanced_friends_list_screen.dart';
import '../../features/social/screens/friend_requests_screen.dart';
import '../../features/social/screens/friend_suggestions_screen.dart';
```

## 2. ADD ROUTE DEFINITIONS

```dart
// Add these routes to your GoRouter routes array

GoRoute(
  path: '/friends',
  name: 'friends',
  pageBuilder: (context, state) => dfcSlidePage(
    state: state,
    child: const EnhancedFriendsListScreen(),
  ),
),

GoRoute(
  path: '/friend-requests',
  name: 'friend-requests',
  pageBuilder: (context, state) => dfcSlidePage(
    state: state,
    child: const FriendRequestsScreen(),
  ),
),

GoRoute(
  path: '/friend-suggestions',
  name: 'friend-suggestions',
  pageBuilder: (context, state) => dfcSlidePage(
    state: state,
    child: const FriendSuggestionsScreen(),
  ),
),
```

## 3. REGISTER SERVICES WITH PROVIDER

```dart
// Add to lib/main.dart or your app initialization

import 'package:data_fight_central/shared/services/social_services.dart';

// In your MultiProvider:
MultiProvider(
  providers: [
    // ... existing providers ...

    ChangeNotifierProvider(create: (_) => EnhancedFriendsService()),
    Provider(create: (_) => FriendSuggestionsEngine()),
    ChangeNotifierProvider(create: (_) => EnhancedMessagingService()),
  ],
  child: MaterialApp.router(...),
)
```

## 4. ADD TO HOME SCREEN NAVIGATION

```dart
// In lib/features/home/screens/home_screen.dart

// Add to bottom navigation bar items:
BottomNavigationBarItem(
  icon: Stack(
    children: [
      Icon(Icons.people),
      // Badge for pending requests
      StreamBuilder<int>(
        stream: context.watch<EnhancedFriendsService>().streamPendingRequestCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return SizedBox.shrink();

          return Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraitions(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    ],
  ),
  label: 'Friends',
),

// Add corresponding screen to _widgetOptions:
EnhancedFriendsListScreen(),
```

## 5. DEPLOY FIRESTORE RULES

```bash
# Deploy updated firestore rules with social network security
firebase deploy --only firestore:rules

# Verify rules are deployed
firebase firestore:rules get
```

## 6. TEST FRIEND FEATURES

```dart
// Example: Send friend request
final friendsService = context.read<EnhancedFriendsService>();

await friendsService.sendFriendRequest(
  recipientId: 'user123',
  message: 'Hey! Let\'s connect!',
);

// Example: Get friend suggestions
final suggestionsEngine = context.read<FriendSuggestionsEngine>();
final suggestions = await suggestionsEngine.generateSuggestions(limit: 10);

// Example: Stream friend count
StreamBuilder<int>(
  stream: friendsService.streamFriendCount(),
  builder: (context, snapshot) {
    return Text('Friends: ${snapshot.data ?? 0}');
  },
)
```

## 7. CREATE INDEXES IN FIRESTORE

```
# Required Firestore indexes (create these in Firebase Console)

Collection: connections
- Field: userId (Ascending) + connectedAt (Descending)

Collection: friend_requests
- Field: recipientId (Ascending) + status (Ascending) + createdAt (Descending)
- Field: senderId (Ascending) + status (Ascending) + createdAt (Descending)

Collection: friend_suggestions
- Field: userId (Ascending) + score (Descending)

Collection: group_chats
- Field: members (Array) + lastMessageAt (Descending)
```

## 8. INITIALIZE ONLINE STATUS (OPTIONAL)

```dart
// In your app initialization or auth handler

final friendsService = context.read<EnhancedFriendsService>();

// Set user online when app starts
await friendsService.setOnlineStatus(true);

// Set offline when app closes
WidgetsBinding.instance.addObserver(
  LifecycleEventHandler(
    resumeCallBack: () async {
      await friendsService.setOnlineStatus(true);
    },
    suspendingCallBack: () async {
      await friendsService.setOnlineStatus(false);
    },
  ),
);
```

## FEATURES COMPLETED ✅

### Data Models

- ✅ Friend (with connection strength, mutual friends, online status)
- ✅ FriendRequest (with expiration, mutual friends preview)
- ✅ FriendActivity (activity types, likes, comments)
- ✅ GroupChat (3-50 members, admin roles)
- ✅ GroupMessage (threading, attachments, read receipts)

### Services

- ✅ EnhancedFriendsService (complete friend management)
- ✅ FriendSuggestionsEngine (AI scoring with 4 factors)
- ✅ EnhancedMessagingService (1-on-1 + group chats)

### Screens

- ✅ EnhancedFriendsListScreen (with counts, online status, quick actions)
- ✅ FriendRequestsScreen (accept/reject/cancel)
- ✅ FriendSuggestionsScreen (AI-powered with compatibility scores)

### Security

- ✅ Firestore rules for all social collections
- ✅ Field validation and size limits
- ✅ Participant/member authentication

## OPTIONAL: Group Chat UI (Next Steps)

To complete group chat functionality, create:

1. GroupChatListScreen - shows all group chats
2. CreateGroupChatScreen - create new groups
3. GroupChatScreen - group conversation view
4. GroupSettingsScreen - manage members/admins

These can be added as needed based on priority.

## OPTIONAL: Friend Activity Feed (Next Steps)

To show friend activities:

1. Create FriendActivityService to track activities
2. Build ActivityFeedScreen with timeline
3. Add activity triggers (new post, fight result, training milestone)

═══════════════════════════════════════════════════════════════════════════
