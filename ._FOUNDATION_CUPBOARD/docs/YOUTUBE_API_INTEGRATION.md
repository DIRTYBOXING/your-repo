# YouTube API Integration Guide for DataFightCentral

## 🎯 Overview

Integrating YouTube videos into DataFightCentral will supercharge your promotional powerhouse with:

- **Fight highlight reels** in fighter profiles
- **Promotional videos** in event details
- **Training tutorials** in fight camp sections
- **News clips** in FightWire feed
- **Viral growth** through shareable video content

---

## 📦 Step 1: Add YouTube Player Package

### Update `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Existing dependencies...

  # Add YouTube Player
  youtube_player_flutter: ^9.0.3 # Check pub.dev for latest version
  youtube_explode_dart: ^2.2.3 # For extracting video info
```

Run:

```bash
flutter pub get
```

---

## 🔑 Step 2: Get YouTube Data API Key

### A. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project: **"DataFightCentral YouTube Integration"**
3. Enable billing (required for API access)

### B. Enable YouTube Data API v3

1. Go to **APIs & Services** → **Library**
2. Search for **"YouTube Data API v3"**
3. Click **Enable**

### C. Create API Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Copy your API key (format: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)
4. **Restrict the API key**:
   - Click **Edit API Key**
   - Under **API restrictions**, select **Restrict key**
   - Choose **YouTube Data API v3**
   - Save

### D. Set Usage Quotas

YouTube Data API v3 has a daily quota of **10,000 units/day** (free tier).

**Cost per operation:**

- Search: 100 units
- Video details: 1 unit
- Playlist items: 1 unit

**Example:** You can perform ~100 searches/day or fetch 10,000 video details/day.

---

## 🔐 Step 3: Store API Key Securely

### Option A: Environment Variables (Recommended)

Create `.env` file (add to `.gitignore`):

```env
YOUTUBE_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

Load in `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}
```

Access key:

```dart
final apiKey = dotenv.env['YOUTUBE_API_KEY'];
```

### Option B: Firebase Remote Config (Production)

Store the API key in Firebase Remote Config for dynamic updates without app redeployment.

---

## 🎬 Step 4: Implementation Locations

### 1. **Fighter Profiles** (`lib/features/profile/screens/profile_screen.dart`)

**Use case:** Highlight reel section showing fighter's best moments

```dart
// Add a "Highlight Reel" section after achievements
Widget _buildHighlightReel(FighterModel fighter) {
  if (fighter.youtubeVideoId == null) return SizedBox.shrink();

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.surfaceColor, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_fill,
                  color: Colors.red, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Highlight Reel',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        YoutubePlayer(
          controller: YoutubePlayerController(
            initialVideoId: fighter.youtubeVideoId!,
            flags: YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
            ),
          ),
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          progressColors: ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
        ),
      ],
    ),
  );
}
```

**Update FighterModel** (`lib/shared/models/fighter_model.dart`):

```dart
class FighterModel extends Equatable {
  // ... existing fields
  final String? youtubeVideoId; // Add this field

  const FighterModel({
    // ... existing parameters
    this.youtubeVideoId,
  });
}
```

---

### 2. **Event Details** (`lib/features/events/screens/event_details_screen.dart`)

**Use case:** Promotional trailer for upcoming events

Add after event info section:

```dart
Widget _buildEventPromo(EventModel event) {
  if (event.promoVideoUrl == null) return SizedBox.shrink();

  final videoId = YoutubePlayer.convertUrlToId(event.promoVideoUrl!);
  if (videoId == null) return SizedBox.shrink();

  return Container(
    margin: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎥 Event Promo',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: YoutubePlayer(
            controller: YoutubePlayerController(
              initialVideoId: videoId,
              flags: YoutubePlayerFlags(
                autoPlay: false,
                enableCaption: true,
              ),
            ),
            showVideoProgressIndicator: true,
          ),
        ),
      ],
    ),
  );
}
```

---

### 3. **FightWire News** (`lib/features/fightwire/screens/fightwire_screen.dart`)

**Use case:** Embed news clips and interviews

Create a video tile widget:

```dart
class VideoNewsTile extends StatelessWidget {
  final String videoId;
  final String title;
  final String source;

  const VideoNewsTile({
    required this.videoId,
    required this.title,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to full screen video player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenVideoPlayer(videoId: videoId),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.video_library, color: Colors.red, size: 14),
                      SizedBox(width: 6),
                      Text(
                        source,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 4. **Training Camp** (`lib/features/training/screens/fight_camp_tools_screen.dart`)

**Use case:** Tutorial videos for techniques and drills

Create a tutorial section:

```dart
Widget _buildTutorials() {
  final tutorials = [
    {
      'id': 'dQw4w9WgXcQ', // Replace with actual video IDs
      'title': 'Perfect Your Jab',
      'duration': '8:45',
    },
    {
      'id': 'dQw4w9WgXcQ',
      'title': 'Ground & Pound Mastery',
      'duration': '12:30',
    },
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '📚 Training Tutorials',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: 12),
      ...tutorials.map((tutorial) => TutorialTile(
        videoId: tutorial['id']!,
        title: tutorial['title']!,
        duration: tutorial['duration']!,
      )),
    ],
  );
}
```

---

## 🚀 Step 5: Create Reusable Video Service

Create `lib/shared/services/youtube_service.dart`:

```dart
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YouTubeService {
  late final YoutubeExplode _yt;
  final String _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';

  YouTubeService() {
    _yt = YoutubeExplode();
  }

  /// Get video details
  Future<Video> getVideoDetails(String videoId) async {
    return await _yt.videos.get(videoId);
  }

  /// Search for videos
  Future<List<Video>> searchVideos(String query, {int maxResults = 10}) async {
    final searchResults = await _yt.search.search(query);
    return searchResults.take(maxResults).toList();
  }

  /// Get channel videos
  Future<List<Video>> getChannelVideos(String channelId) async {
    final channel = await _yt.channels.get(channelId);
    final uploads = await _yt.channels.getUploads(channel.id);
    return uploads.toList();
  }

  /// Extract video ID from URL
  String? extractVideoId(String url) {
    // Handles: youtube.com/watch?v=xxx, youtu.be/xxx, youtube.com/embed/xxx
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Dispose
  void dispose() {
    _yt.close();
  }
}
```

---

## 📱 Step 6: Full Screen Video Player

Create `lib/shared/widgets/full_screen_video_player.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoId;

  const FullScreenVideoPlayer({super.key, required this.videoId});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );

    // Force landscape for full screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          onReady: () {
            print('Video ready');
          },
        ),
      ),
    );
  }
}
```

---

## 🎨 Step 7: YouTube Branding Guidelines

**IMPORTANT:** Follow [YouTube Brand Guidelines](https://developers.google.com/youtube/terms/branding-guidelines):

1. ✅ Use official YouTube play button icon
2. ✅ Display "Powered by YouTube" when showing thumbnails
3. ✅ Maintain YouTube's aspect ratio (16:9)
4. ❌ Don't modify YouTube's logo or colors
5. ❌ Don't use YouTube player for background music

---

## 📊 Step 8: Track Video Engagement

Update Firestore to track video views:

```dart
Future<void> trackVideoView(String videoId, String userId) async {
  await FirebaseFirestore.instance.collection('video_views').add({
    'videoId': videoId,
    'userId': userId,
    'timestamp': FieldValue.serverTimestamp(),
    'platform': 'mobile',
  });
}
```

Analytics schema:

```
video_views/
  ├─ videoId: String
  ├─ userId: String
  ├─ timestamp: Timestamp
  ├─ watchDuration: int (seconds)
  └─ completed: bool
```

---

## 🌟 Step 9: Premium Features for Monetization

### A. Exclusive Training Content

```dart
Widget _buildPremiumTutorials() {
  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppTheme.neonCyan.withValues(alpha: 0.15),
          AppTheme.neonMagenta.withValues(alpha: 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.neonGold, width: 2),
    ),
    child: Column(
      children: [
        Icon(Icons.lock, color: AppTheme.neonGold, size: 48),
        SizedBox(height: 12),
        Text(
          '🥇 Premium Training Library',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '100+ exclusive technique videos from champions',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            context.push('/subscription');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonGold,
            foregroundColor: Colors.black,
          ),
          child: Text('Unlock Premium'),
        ),
      ],
    ),
  );
}
```

### B. Pay-Per-View Event Replays

Store event replays with access control:

```dart
class EventReplayModel {
  final String eventId;
  final String youtubeVideoId;
  final double price; // e.g., \$9.99
  final bool isPremiumOnly;
  final DateTime availableUntil;
}
```

---

## 🔥 Step 10: Viral Growth Features

### A. Share Video Clips

```dart
void shareVideoClip(String videoId, String title) async {
  final videoUrl = 'https://youtu.be/$videoId';
  await Share.share(
    '🥊 Check out this epic moment on DataFightCentral!\\n\\n'
    '$title\\n\\n'
    '$videoUrl\\n\\n'
    'Join us: https://datafightcentral.com',
    subject: title,
  );

  // Track share
  await FirebaseFirestore.instance.collection('shared_videos').add({
    'videoId': videoId,
    'sharedBy': currentUserId,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
```

### B. Video Reactions System

```dart
Widget _buildVideoReactions(String videoId) {
  return Row(
    children: [
      _buildReactionButton('🔥', 'fire', videoId),
      _buildReactionButton('💪', 'power', videoId),
      _buildReactionButton('😱', 'wow', videoId),
      _buildReactionButton('🥊', 'knockout', videoId),
    ],
  );
}
```

---

## 📈 Success Metrics to Track

1. **Video Views**: Total plays across all videos
2. **Completion Rate**: % of users who watch >80% of video
3. **Share Rate**: Videos shared / Videos viewed
4. **Conversion Rate**: Video views → Profile visits → Follows
5. **Engagement Time**: Average watch duration
6. **Premium Conversions**: Free users → Paid subscribers via video CTAs

---

## 🚨 Important Notes

1. **Quota Management**: Monitor your API usage in Google Cloud Console
2. **Caching**: Cache video thumbnails and metadata to reduce API calls
3. **Error Handling**: Handle cases where videos are deleted or made private
4. **Data Usage**: Warn users about data consumption when streaming on mobile
5. **Autoplay**: Default to autoplay OFF to respect user preferences
6. **Accessibility**: Ensure captions are enabled for all videos

---

## 🎯 Immediate Action Items

1. ✅ Add `youtube_player_flutter` package
2. ✅ Get YouTube Data API key from Google Cloud
3. ✅ Add API key to `.env` file
4. ✅ Implement highlight reel in fighter profiles
5. ✅ Add promotional videos to event details
6. ✅ Create tutorial section in training camp
7. ✅ Build share functionality for viral growth
8. ✅ Track video engagement in Firestore

---

## 🌐 Additional Resources

- [YouTube Data API Documentation](https://developers.google.com/youtube/v3)
- [YouTube Player Flutter Package](https://pub.dev/packages/youtube_player_flutter)
- [YouTube Brand Guidelines](https://developers.google.com/youtube/terms/branding-guidelines)
- [Google Cloud Console](https://console.cloud.google.com/)

---

**Made your app light up? Share your implementation!** 🚀 #DataFightCentral #UFC #MMA
