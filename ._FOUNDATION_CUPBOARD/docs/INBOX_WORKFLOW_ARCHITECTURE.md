# DFC INBOX ARCHITECTURE — WORKFLOW & ATTACHMENTS

**Complete messaging system with flow states and rich attachment handling**

---

## 📬 SYSTEM OVERVIEW

The DFC Inbox is a **professional-grade messaging system** with:

1. **Workflow States** — Messages move through defined lifecycle stages
2. **Rich Attachments** — Multiple files per message with metadata tracking
3. **Categories** — Auto-sort messages (Primary, Social, Promotions, Updates)
4. **Actions** — Star, flag, archive, label, react
5. **Draft Management** — Save incomplete messages
6. **Search & Filters** — Advanced message discovery

---

## 🔄 MESSAGE WORKFLOW (LIFECYCLE STATES)

### State Diagram

```
┌──────────┐
│  DRAFT   │ ← User composes but hasn't sent yet
└────┬─────┘
     │ User taps "Send"
     ▼
┌──────────┐
│ SENDING  │ ← Upload in progress
└────┬─────┘
     │ Upload completes
     ▼
┌──────────┐
│   SENT   │ ← Message delivered to Firestore
└────┬─────┘
     │ Recipient's device receives
     ▼
┌──────────┐
│DELIVERED │ ← Recipient's device acknowledges receipt
└────┬─────┘
     │ Recipient opens message
     ▼
┌──────────┐
│   READ   │ ← Recipient viewed the message
└────┬─────┘
     │ User archives
     ▼
┌──────────┐
│ ARCHIVED │ ← Hidden from main inbox
└──────────┘

FAILURE BRANCH:
┌──────────┐
│  FAILED  │ ← Upload or send error
└────┬─────┘
     │ User taps "Retry"
     ▼
Back to SENDING
```

### State Definitions

| State         | Description                     | Visible To  | Actions Available             |
| ------------- | ------------------------------- | ----------- | ----------------------------- |
| **DRAFT**     | Message saved locally, not sent | Sender only | Edit, Delete, Send            |
| **SENDING**   | Upload in progress              | Sender only | Cancel                        |
| **SENT**      | Delivered to server             | Both        | Edit (5 min), Delete, Forward |
| **DELIVERED** | Received by recipient's device  | Both        | Reply, React, Star            |
| **READ**      | Opened by recipient             | Both        | Reply, React, Star, Archive   |
| **FAILED**    | Send/upload error               | Sender only | Retry, Delete                 |
| **ARCHIVED**  | Hidden from main view           | Owner only  | Unarchive, Delete             |

---

## 📎 ATTACHMENT SYSTEM

### Attachment Metadata Structure

```dart
class MessageAttachment {
  final String id;              // Unique identifier
  final String type;            // image, video, audio, document, pdf, other
  final String url;             // Firebase Storage download URL
  final String name;            // Original filename
  final int size;               // Bytes
  final String? mimeType;       // e.g., 'image/jpeg'
  final String? thumbnailUrl;   // Generated thumbnail (images/videos)
  final int? width;             // Image/video width
  final int? height;            // Image/video height
  final int? duration;          // Audio/video duration (seconds)
  final DateTime uploadedAt;    // Timestamp
  final String uploadedBy;      // User ID
  final bool scanned;           // Virus/malware scan status
  final Map<String, dynamic>? metadata; // Custom data
}
```

### Supported File Types

| Category      | Extensions                     | Max Size | Preview        |
| ------------- | ------------------------------ | -------- | -------------- |
| **Images**    | .jpg, .jpeg, .png, .gif, .webp | 10 MB    | ✅ Thumbnail   |
| **Videos**    | .mp4, .mov, .avi, .mkv         | 50 MB    | ✅ First frame |
| **Audio**     | .mp3, .wav, .aac, .m4a         | 25 MB    | ❌ Waveform    |
| **Documents** | .doc, .docx, .txt, .rtf        | 20 MB    | ❌ Icon        |
| **PDFs**      | .pdf                           | 20 MB    | ✅ First page  |
| **Other**     | All others                     | 10 MB    | ❌ Icon        |

### Attachment Upload Flow

```
User selects file(s)
    ↓
Validate file type & size
    ↓
Generate unique attachment ID
    ↓
Upload to Firebase Storage:
    messages/{userId}/{conversationId}/{attachmentId}.{ext}
    ↓
Track upload progress (0% → 100%)
    ↓
Generate thumbnail (if image/video)
    ↓
Create MessageAttachment object
    ↓
Attach to message
    ↓
Send message with attachments array
```

### Multiple Attachments

**Limit:** Up to **10 attachments per message**

**Storage Path:**

```
messages/
  {userId}/
    {conversationId}/
      {timestamp1}-{hash1}.jpg
      {timestamp2}-{hash2}.pdf
      {timestamp3}-{hash3}.mp4
```

**Metadata Tracking:**

```dart
// Each attachment stores:
{
  'id': 'attachment-unique-id',
  'type': 'image',
  'url': 'https://storage.googleapis.com/...',
  'name': 'receipt.jpg',
  'size': 245678,
  'mimeType': 'image/jpeg',
  'thumbnailUrl': 'https://storage.googleapis.com/.../thumb_receipt.jpg',
  'width': 1920,
  'height': 1080,
  'uploadedAt': Timestamp,
  'uploadedBy': 'user-123',
  'scanned': true,
}
```

---

## 📁 INBOX CATEGORIES

Messages are **auto-categorized** based on sender and content:

### 1. PRIMARY (Default)

- Personal 1:1 conversations
- Direct messages from contacts
- Manual categorization

**Badge Color:** 🔵 Cyan

### 2. SOCIAL

- Group chats
- Community messages
- Social network notifications

**Badge Color:** 🟣 Magenta

### 3. PROMOTIONS

- Marketing emails
- Event announcements
- Promotional content

**Badge Color:** 🟡 Gold

### 4. UPDATES

- System notifications
- App updates
- Scheduled reminders

**Badge Color:** 🟢 Green

### 5. SPAM (Hidden)

- Filtered messages
- Reported content
- Auto-detected spam

**Badge Color:** 🔴 Red

---

## 🏷️ MESSAGE ACTIONS

### Available Actions Per Message

| Action      | Icon | Description                  | Shortcut             |
| ----------- | ---- | ---------------------------- | -------------------- |
| **Star**    | ⭐   | Mark as important            | Tap star icon        |
| **Flag**    | 🚩   | Flag for follow-up           | Long press           |
| **Reply**   | 💬   | Respond to message           | Swipe right          |
| **Forward** | ➡️   | Send to another conversation | Long press → Forward |
| **Edit**    | ✏️   | Modify sent message (5 min)  | Long press → Edit    |
| **React**   | 😊   | Add emoji reaction           | Tap + hold           |
| **Archive** | 📦   | Hide from main inbox         | Swipe left           |
| **Label**   | 🏷️   | Add custom tag               | Long press → Label   |
| **Delete**  | 🗑️   | Remove permanently           | Swipe left → Delete  |

### Conversation Actions

| Action      | Icon | Description           |
| ----------- | ---- | --------------------- |
| **Pin**     | 📌   | Keep at top of inbox  |
| **Mute**    | 🔇   | Disable notifications |
| **Archive** | 📦   | Hide conversation     |
| **Block**   | 🚫   | Block sender          |
| **Report**  | ⚠️   | Report spam/abuse     |

---

## 💾 DRAFT MANAGEMENT

### Auto-Save Drafts

**When:**

- User types message but doesn't send
- User closes app while composing
- User switches conversations

**Storage:**

```dart
// Firestore: conversations/{convId}
{
  'draftMessage': 'Hey, I was thinking...',
  'draftAttachments': [
    {
      'id': 'draft-att-1',
      'type': 'image',
      'url': 'temp-local-url',
      'name': 'photo.jpg',
      'size': 123456,
    }
  ],
}
```

### Draft Indicator

```
┌─────────────────────────────┐
│ 📝 John Smith               │
│ Draft: Hey, I was thinking  │ ← Red "Draft:" prefix
│ 2 hours ago                 │
└─────────────────────────────┘
```

### Draft Recovery

1. User opens conversation
2. System checks `draftMessage` field
3. If exists, populate composer with draft
4. Show banner: "Draft restored from 2 hours ago"
5. User can continue editing or delete draft

---

## 🔍 SEARCH & FILTERS

### Search Options

**By Text:**

```dart
searchMessages(
  userId: 'user-123',
  query: 'invoice',
)
```

**By Category:**

```dart
conversationsByCategory(
  userId: 'user-123',
  category: InboxCategory.promotions,
)
```

**By Priority:**

```dart
searchMessages(
  userId: 'user-123',
  priority: MessagePriority.urgent,
)
```

**By Date Range:**

```dart
searchMessages(
  userId: 'user-123',
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 3, 8),
)
```

**By Starred:**

```dart
getStarredMessages('user-123')
```

**By Labels:**

```dart
searchMessages(
  userId: 'user-123',
  labels: ['work', 'urgent'],
)
```

### Advanced Filters

```
┌─────────────────────────────┐
│ FILTERS                     │
├─────────────────────────────┤
│ ☐ Unread only               │
│ ☑ Has attachments           │
│ ☐ Starred                   │
│ ☐ Flagged                   │
│ ☐ From today                │
│ ☐ Priority: Urgent          │
│ ☐ Category: Primary         │
│                             │
│ [ APPLY ]  [ RESET ]        │
└─────────────────────────────┘
```

---

## 🎨 UI COMPONENTS

### Inbox List View

```
┌───────────────────────────────────────┐
│ 📬 INBOX                    🔍 ⚙️   │ ← Header
├───────────────────────────────────────┤
│ [ Primary | Social | Promos | • • • ]│ ← Category tabs
├───────────────────────────────────────┤
│                                       │
│ 📌 Danny Mac                    now   │ ← Pinned
│ IBC 3 fight card looks fire 🔥  [3]  │
│ 📎 2 attachments                      │
│                                       │
│ ⭐ DFC Founder              2h ago    │ ← Starred
│ DFC Headquarters session tomorrow?    │
│ ✓✓ Read                               │
│                                       │
│ Sarah Johnson               5h ago    │
│ Draft: See you at the event...   📝  │ ← Draft indicator
│                                       │
│ Training Bot               yesterday  │
│ 💪 Your workout stats are ready       │
│ ✓ Delivered                           │
│                                       │
└───────────────────────────────────────┘
```

### Message Thread View

```
┌───────────────────────────────────────┐
│ ← Danny Mac                      ⋮   │ ← Back + Options
├───────────────────────────────────────┤
│                                       │
│      ┌─────────────────────┐         │ ← Incoming
│      │ Hey! Check this out │         │
│      │ ┌─────────────┐     │         │
│      │ │ [IMG THUMB] │     │         │ ← Image attachment
│      │ └─────────────┘     │         │
│      │ 10:15 AM        ✓✓  │         │
│      └─────────────────────┘         │
│                                       │
│         ┌─────────────────────┐      │ ← Outgoing
│         │ Nice! 🔥            │      │
│         │ 10:16 AM        ✓✓  │      │
│         └─────────────────────┘      │
│                                       │
│ ┌─────────────────────────────────┐  │ ← Reply indicator
│ │ ↪ Replying to: "Hey! Check..."  │  │
│ │ [X]                              │  │
│ └─────────────────────────────────┘  │
│                                       │
│ ┌─────────────────────────────────┐  │ ← Attachment preview
│ │ 📎 receipt.pdf (248 KB)      [X]│  │
│ └─────────────────────────────────┘  │
│                                       │
│ [ Type a message...         📎 📷 ]  │ ← Composer
│                            [ SEND ]   │
└───────────────────────────────────────┘
```

### Attachment Gallery

```
┌───────────────────────────────────────┐
│ ← ATTACHMENTS (8)              [•••]  │
├───────────────────────────────────────┤
│                                       │
│ ┌────┬────┬────┬────┐               │
│ │IMG │IMG │IMG │VID │               │ ← Grid view
│ │1.2M│980K│1.5M│4.2M│               │
│ └────┴────┴────┴────┘               │
│                                       │
│ ┌────┬────┬────┬────┐               │
│ │PDF │DOC │MP3 │ZIP │               │
│ │680K│1.1M│2.8M│5.3M│               │
│ └────┴────┴────┴────┘               │
│                                       │
│ [ Download All ]  [ Delete All ]     │
└───────────────────────────────────────┘
```

---

## 🛠️ IMPLEMENTATION GUIDE

### 1. Basic Message Send

```dart
final service = EnhancedMessagingService();

await service.sendMessage(
  conversationId: 'conv-123',
  senderId: 'user-456',
  senderName: 'DFC Founder',
  text: 'IBC 3 is going to be epic! 🥊',
  priority: MessagePriority.normal,
);
```

### 2. Send with Attachments

```dart
// Upload attachments first
final attachments = await service.uploadAttachments(
  userId: 'user-456',
  conversationId: 'conv-123',
  files: [
    MapEntry(imageBytes, 'fight-poster.jpg'),
    MapEntry(pdfBytes, 'event-details.pdf'),
  ],
  onProgress: (index, progress) {
    print('File $index: ${(progress * 100).toInt()}%');
  },
);

// Send message with attachments
await service.sendMessage(
  conversationId: 'conv-123',
  senderId: 'user-456',
  senderName: 'DFC Founder',
  text: 'Here are the IBC 3 materials',
  attachments: attachments,
);
```

### 3. Save Draft

```dart
await service.saveDraft(
  conversationId: 'conv-123',
  text: 'Hey, I was thinking about...',
  attachments: [attachment1, attachment2],
);
```

### 4. Mark as Read

```dart
// Single message
await service.markAsRead('conv-123', 'msg-789');

// Entire conversation
await service.markConversationAsRead('conv-123', 'user-456');
```

### 5. Star Message

```dart
await service.toggleStar('conv-123', 'msg-789');
```

### 6. Add Reaction

```dart
await service.addReaction(
  'conv-123', // conversationId
  'msg-789',  // messageId
  '🔥',        // emoji
  'user-456', // userId
);
```

### 7. Edit Message

```dart
await service.editMessage(
  'conv-123',
  'msg-789',
  'Updated message text',
);
```

### 8. Archive Conversation

```dart
await service.toggleArchive('conv-123');
```

### 9. Search Messages

```dart
final results = await service.searchMessages(
  userId: 'user-456',
  query: 'IBC',
  category: InboxCategory.primary,
  starred: true,
  startDate: DateTime(2026, 3, 1),
);
```

### 10. Stream Conversations by Category

```dart
service.conversationsByCategory(
  userId: 'user-456',
  category: InboxCategory.promotions,
).listen((conversations) {
  print('Promotions: ${conversations.length}');
});
```

---

## 📊 FIRESTORE STRUCTURE

### Collection: `conversations`

```
conversations/
  {conversationId}/
    participants: ['user-123', 'user-456']
    participantNames: {
      'user-123': 'DFC Founder',
      'user-456': 'Danny Mac'
    }
    participantPhotoUrls: {
      'user-123': 'https://...',
      'user-456': 'https://...'
    }
    lastMessage: 'IBC 3 is going to be epic!'
    lastMessageAt: Timestamp
    lastSenderId: 'user-123'
    unreadCounts: {
      'user-123': 0,
      'user-456': 3
    }
    createdAt: Timestamp

    // Enhanced fields
    category: 'primary'
    muted: false
    pinned: true
    archived: false
    labels: ['work', 'events']
    draftMessage: 'Hey, I was thinking...'
    draftAttachments: [...]
    metadata: {}

    /messages/
      {messageId}/
        conversationId: 'conv-123'
        senderId: 'user-123'
        senderName: 'DFC Founder'
        senderPhotoUrl: 'https://...'
        text: 'Check out this IBC 3 poster!'
        sentAt: Timestamp
        status: 'read'
        deliveredAt: Timestamp
        readAt: Timestamp
        priority: 'normal'
        category: 'primary'

        // Threading
        replyToId: 'msg-456'
        replyToText: 'When is IBC 3?'
        threadId: 'thread-789'

        // Attachments
        attachments: [
          {
            id: 'att-001',
            type: 'image',
            url: 'https://storage.googleapis.com/...',
            name: 'ibc3-poster.jpg',
            size: 245678,
            mimeType: 'image/jpeg',
            thumbnailUrl: 'https://...',
            width: 1920,
            height: 1080,
            uploadedAt: Timestamp,
            uploadedBy: 'user-123',
            scanned: true
          }
        ]

        // Actions
        starred: false
        flagged: false
        archived: false
        labels: ['urgent', 'events']
        reactions: {
          '🔥': ['user-456', 'user-789'],
          '👍': ['user-456']
        }

        // Edit history
        edited: false
        editedAt: null
        originalText: null

        // Scheduled
        scheduledFor: null

        metadata: {}
```

### Firestore Indexes Required

```
conversations:
  - participants ASC, lastMessageAt DESC
  - participants ASC, pinned DESC, lastMessageAt DESC
  - participants ASC, archived ASC, lastMessageAt DESC

messages (collection group):
  - conversationId ASC, sentAt ASC
  - conversationId ASC, archived ASC, sentAt ASC
  - status ASC, senderId ASC
  - starred ASC, sentAt DESC
  - flagged ASC, sentAt DESC
```

---

## 🚀 WORKFLOW EXAMPLES

### Example 1: Send Message with Image

**User Actions:**

1. User opens conversation
2. Taps camera icon
3. Selects image from gallery
4. Types caption
5. Taps "Send"

**System Flow:**

```
Tap Send
  ↓
Validate image size (< 10 MB) ✓
  ↓
Set status: SENDING
  ↓
Upload image to Storage:
  messages/user-123/conv-456/1234567890-image.jpg
  ↓
Progress: 0% → 25% → 50% → 75% → 100%
  ↓
Generate thumbnail
  ↓
Create MessageAttachment object
  ↓
Create EnhancedMessage with attachment
  ↓
Write to Firestore:
  conversations/conv-456/messages/msg-789
  ↓
Set status: SENT
  ↓
Update conversation lastMessage
  ↓
Increment recipient unread count
  ↓
Clear draft
  ↓
Notify recipient (push notification)
  ↓
Recipient's device receives
  ↓
Set status: DELIVERED
  ↓
Recipient opens message
  ↓
Set status: READ
  ↓
Clear recipient unread count
```

### Example 2: Draft Recovery

**User Actions:**

1. User starts typing message
2. Attaches file
3. Switches to different conversation (message not sent)
4. App auto-saves draft
5. User returns to original conversation
6. Draft is restored

**System Flow:**

```
User types "Hey, I was..."
  ↓
User attaches receipt.pdf
  ↓
Auto-save timer triggers (5 seconds)
  ↓
Upload receipt.pdf to temp storage (if not sent)
  ↓
Save to Firestore:
  conversations/conv-123 {
    draftMessage: 'Hey, I was...',
    draftAttachments: [{...}]
  }
  ↓
User switches conversation
  ↓
User returns to conv-123
  ↓
Load conversation data
  ↓
Check draftMessage field
  ↓
If exists, populate composer:
  - Set text field: "Hey, I was..."
  - Load attachment preview: receipt.pdf
  ↓
Show banner: "📝 Draft restored from 5 minutes ago"
  ↓
User can:
  - Continue editing
  - Send immediately
  - Delete draft
```

### Example 3: Multi-Attachment Upload

**User Actions:**

1. User taps attachment icon
2. Selects "Choose Multiple"
3. Selects 5 files (2 images, 2 PDFs, 1 video)
4. Adds caption
5. Taps "Send"

**System Flow:**

```
Validate all files:
  - image1.jpg (2.1 MB) ✓
  - image2.png (1.5 MB) ✓
  - contract.pdf (680 KB) ✓
  - receipt.pdf (450 KB) ✓
  - demo.mp4 (4.8 MB) ✓
  ↓
Total: 9.53 MB (under 50 MB limit) ✓
  ↓
Set status: SENDING
  ↓
Upload attachments in parallel:

  Thread 1: image1.jpg
    Upload progress: 0% → 100% ✓
    Generate thumbnail ✓

  Thread 2: image2.png
    Upload progress: 0% → 100% ✓
    Generate thumbnail ✓

  Thread 3: contract.pdf
    Upload progress: 0% → 100% ✓

  Thread 4: receipt.pdf
    Upload progress: 0% → 100% ✓

  Thread 5: demo.mp4
    Upload progress: 0% → 100% ✓
    Generate video thumbnail (first frame) ✓
    ↓
All uploads complete
  ↓
Create EnhancedMessage:
  text: 'All the IBC 3 documents'
  attachments: [
    {id: 'att-1', type: 'image', url: '...', name: 'image1.jpg', ...},
    {id: 'att-2', type: 'image', url: '...', name: 'image2.png', ...},
    {id: 'att-3', type: 'pdf', url: '...', name: 'contract.pdf', ...},
    {id: 'att-4', type: 'pdf', url: '...', name: 'receipt.pdf', ...},
    {id: 'att-5', type: 'video', url: '...', name: 'demo.mp4', ...}
  ]
  ↓
Write to Firestore
  ↓
Set status: SENT
  ↓
Recipient receives notification:
  "DFC Founder sent 5 attachments"
```

---

## 🎯 KEY FEATURES

✅ **Workflow States** — Draft → Sending → Sent → Delivered → Read  
✅ **Multiple Attachments** — Up to 10 files per message  
✅ **Auto-Categorization** — Primary, Social, Promotions, Updates  
✅ **Draft Auto-Save** — Never lose message progress  
✅ **Rich Metadata** — Track file type, size, thumbnails  
✅ **Message Actions** — Star, flag, archive, label, react  
✅ **Advanced Search** — Filter by date, priority, category, starred  
✅ **Reactions** — Emoji reactions with user tracking  
✅ **Edit History** — Track message edits with original text  
✅ **Pin/Mute/Archive** — Organize conversations

---

## 📱 MOBILE UI PATTERNS

### Swipe Actions (Inbox List)

```
Swipe RIGHT →
┌─────────────────┐
│ 📌 Pin          │ ← Primary action
└─────────────────┘

Swipe LEFT ←
┌─────────────────┬─────────────┐
│ 📦 Archive      │ 🗑️ Delete   │
└─────────────────┴─────────────┘
```

### Long Press Menu (Message)

```
┌─────────────────────────────┐
│ 💬 Reply                    │
│ ⭐ Star                     │
│ 🚩 Flag                     │
│ ➡️ Forward                  │
│ ✏️ Edit                     │
│ 📋 Copy                     │
│ 🏷️ Add Label               │
│ 🗑️ Delete                  │
└─────────────────────────────┘
```

### Attachment Picker

```
┌─────────────────────────────┐
│ 📷 Camera                   │ ← Take photo/video
│ 🖼️ Photos & Videos          │ ← Gallery
│ 📁 Files                    │ ← Documents
│ 📄 Document Scanner         │ ← Scan PDF
│ 🎤 Voice Message            │ ← Record audio
│ 📍 Location                 │ ← Share location
└─────────────────────────────┘
```

---

## 🔐 SECURITY & PRIVACY

### Attachment Scanning

```dart
// Before storing, scan for:
- Malware/viruses
- Inappropriate content
- Copyright violations
- File size limits
- Banned file types
```

### Access Control

```
Firestore Rules:
- Users can only read conversations they're participants in
- Users can only send messages from their own userId
- Attachments are user-isolated in Storage
- Draft attachments deleted after 7 days if not sent
```

### Data Retention

| Data Type             | Retention       | Deletion         |
| --------------------- | --------------- | ---------------- |
| **Active Messages**   | Indefinite      | User deletes     |
| **Archived Messages** | 2 years         | Auto-delete      |
| **Deleted Messages**  | 30 days         | Permanent delete |
| **Attachments**       | Matches message | Cascade delete   |
| **Drafts**            | 7 days          | Auto-delete      |
| **Read Receipts**     | Indefinite      | With message     |

---

## ⚡ PERFORMANCE OPTIMIZATIONS

### Pagination

```dart
// Load 50 messages at a time
messagesStream(conversationId).take(50)

// Load more on scroll
messagesStream(conversationId)
  .startAfter(lastMessage)
  .limit(50)
```

### Thumbnail Generation

```dart
// Images: Generate 200x200 thumbnail
// Videos: Extract first frame as thumbnail
// PDFs: Render first page as thumbnail
// Store thumbnails separately for fast loading
```

### Caching

```
Local cache:
- Last 100 conversations
- Last 1000 messages
- Attachment metadata (not files)
- Draft autosaves

Cloud cache:
- Thumbnail URLs (24 hours)
- Read receipts (1 hour)
```

---

## 🧪 TESTING CHECKLIST

- [ ] Send message with text only
- [ ] Send message with 1 image
- [ ] Send message with multiple attachments (10 max)
- [ ] Draft auto-save triggers after 5 seconds
- [ ] Draft recovery after app restart
- [ ] Mark message as read updates status
- [ ] Star/unstar message
- [ ] Flag/unflag message
- [ ] Archive/unarchive conversation
- [ ] Pin/unpin conversation
- [ ] Mute/unmute conversation
- [ ] Add emoji reaction
- [ ] Remove emoji reaction
- [ ] Edit message within 5 minutes
- [ ] Search messages by text
- [ ] Filter messages by category
- [ ] Forward message to another conversation
- [ ] Delete message (soft delete)
- [ ] Upload progress shows correctly
- [ ] Failed upload shows retry button
- [ ] Attachment previews render correctly
- [ ] Attachment download works
- [ ] Unread badge updates in real-time

---

## 📚 REFERENCES

**Files:**

- `lib/features/messaging/models/enhanced_message_model.dart` — Data models
- `lib/features/messaging/services/enhanced_messaging_service.dart` — Business logic
- `lib/features/messaging/screens/inbox_screen.dart` — Inbox UI (to be updated)
- `lib/features/messaging/screens/chat_thread_screen.dart` — Chat UI (to be updated)

**Firebase:**

- Firestore: `conversations/{convId}` + `conversations/{convId}/messages/{msgId}`
- Storage: `messages/{userId}/{conversationId}/{attachmentId}.{ext}`

**Dependencies:**

- `cloud_firestore` — Database
- `firebase_storage` — File storage
- `image_picker` — Photo/video selection
- `file_picker` — Document selection

---

**System Status:** ✅ Models & Service Complete | 🔄 UI Integration Pending

**Last Updated:** March 8, 2026  
**Next Step:** Update inbox_screen.dart and chat_thread_screen.dart to use EnhancedMessagingService
