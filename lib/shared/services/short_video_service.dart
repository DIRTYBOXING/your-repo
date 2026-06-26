import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/image_assets.dart';
import '../models/community/short_video_model.dart';
import 'media_visibility_service.dart';

/// Service for Reels / Short Video CRUD, engagement, and moderation.
/// Reads/writes to Firestore `short_videos` collection.
class ShortVideoService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final bool _useDemoData;
  late final MediaVisibilityService _mediaVisibilityService =
      MediaVisibilityService(firestore: _firestore);

  ShortVideoService({bool useDemoData = false}) : _useDemoData = useDemoData;

  CollectionReference get _videos => _firestore.collection('short_videos');

  Future<String> uploadMedia({
    required XFile file,
    required String creatorId,
    required String folder,
  }) async {
    if (_useDemoData) {
      return 'https://demo.datafightcentral.dev/$folder/${file.name}';
    }

    final fileName = _sanitizeFileName(file.name);
    final ref = _storage.ref().child(
      'short_videos/$creatorId/$folder/'
      '${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );

    await ref.putData(
      await file.readAsBytes(),
      SettableMetadata(contentType: _contentTypeFor(fileName, folder)),
    );

    return ref.getDownloadURL();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────

  Future<String> createVideo({
    String? videoId,
    required String creatorId,
    required String creatorName,
    String creatorAvatarUrl = '',
    required String videoUrl,
    String? videoAssetId,
    String thumbnailUrl = '',
    String? thumbnailAssetId,
    required String title,
    String description = '',
    List<String> hashtags = const [],
    List<String> mentions = const [],
    VideoVisibility visibility = VideoVisibility.public,
    int durationSeconds = 30,
  }) async {
    if (_useDemoData) {
      return 'demo_reel_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (videoAssetId == null || videoAssetId.isEmpty) {
      throw Exception(
        'Reels must be uploaded through the canonical media pipeline',
      );
    }

    final safeThumbnailUrl =
        thumbnailAssetId == null || thumbnailAssetId.isEmpty
        ? ''
        : thumbnailUrl;

    final doc = videoId == null ? _videos.doc() : _videos.doc(videoId);
    await doc.set({
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorAvatarUrl': creatorAvatarUrl,
      'videoUrl': videoUrl,
      'videoAssetId': videoAssetId,
      'thumbnailUrl': safeThumbnailUrl,
      'thumbnailAssetId': thumbnailAssetId,
      'title': title,
      'description': description,
      'hashtags': hashtags,
      'mentions': mentions,
      'visibility': visibility.name,
      'durationSeconds': durationSeconds,
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'viewCount': 0,
      'likedByIds': <String>[],
      'savedByIds': <String>[],
      'isFlagged': false,
      'flagReason': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
    return doc.id;
  }

  Future<void> deleteVideo(String videoId) async {
    if (_useDemoData) return;
    await _videos.doc(videoId).delete();
    notifyListeners();
  }

  // ── FEED ──────────────────────────────────────────────────────────────

  Future<List<ShortVideoModel>> getReelsFeed({int limit = 20}) async {
    if (_useDemoData) return _demoReels();

    final snap = await _videos
        .where('visibility', isEqualTo: 'public')
        .where('isFlagged', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return _sanitizeVideos(
      snap.docs
          .map(
            (d) =>
                ShortVideoModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList(),
    );
  }

  Future<List<ShortVideoModel>> getMyReels(String userId) async {
    if (_useDemoData) {
      return _demoReels().where((r) => r.creatorId == userId).toList();
    }

    final snap = await _videos
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return _sanitizeVideos(
      snap.docs
          .map(
            (d) =>
                ShortVideoModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList(),
    );
  }

  Stream<List<ShortVideoModel>> reelsStream({int limit = 20}) {
    if (_useDemoData) {
      return Stream.value(_demoReels());
    }

    return _videos
        .where('visibility', isEqualTo: 'public')
        .where('isFlagged', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap(
          (snap) => _sanitizeVideos(
            snap.docs
                .map(
                  (d) => ShortVideoModel.fromMap(
                    d.data() as Map<String, dynamic>,
                    d.id,
                  ),
                )
                .toList(),
          ),
        );
  }

  Future<List<ShortVideoModel>> _sanitizeVideos(
    List<ShortVideoModel> videos,
  ) async {
    final sanitized = await Future.wait(videos.map(_sanitizeVideo));
    return sanitized.whereType<ShortVideoModel>().toList();
  }

  Future<ShortVideoModel?> _sanitizeVideo(ShortVideoModel video) async {
    final visibleVideoUrl = await _mediaVisibilityService
        .resolvePrimaryVisibleUrl(
          preferredAssetId: video.videoAssetId,
          assetIds: video.videoAssetId == null
              ? const <String>[]
              : [video.videoAssetId!],
          fallbackUrl: video.videoUrl,
        );

    if (visibleVideoUrl == null || visibleVideoUrl.isEmpty) {
      return null;
    }

    final visibleThumbnailUrl = await _mediaVisibilityService
        .resolvePrimaryVisibleUrl(
          preferredAssetId: video.thumbnailAssetId,
          assetIds: video.thumbnailAssetId == null
              ? const <String>[]
              : [video.thumbnailAssetId!],
          fallbackUrl: video.thumbnailUrl,
        );

    return video.copyWith(
      videoUrl: visibleVideoUrl,
      thumbnailUrl: visibleThumbnailUrl ?? '',
    );
  }

  // ── ENGAGEMENT ────────────────────────────────────────────────────────

  Future<void> toggleLike(String videoId, String userId) async {
    if (_useDemoData) return;

    final ref = _videos.doc(videoId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedByIds'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        txn.update(ref, {
          'likedByIds': likedBy,
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        likedBy.add(userId);
        txn.update(ref, {
          'likedByIds': likedBy,
          'likeCount': FieldValue.increment(1),
        });
      }
    });
    notifyListeners();
  }

  Future<void> toggleSave(String videoId, String userId) async {
    if (_useDemoData) return;

    final ref = _videos.doc(videoId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final savedBy = List<String>.from(data['savedByIds'] ?? []);

      if (savedBy.contains(userId)) {
        savedBy.remove(userId);
        txn.update(ref, {'savedByIds': savedBy});
      } else {
        savedBy.add(userId);
        txn.update(ref, {'savedByIds': savedBy});
      }
    });
    notifyListeners();
  }

  Future<void> incrementViewCount(String videoId) async {
    if (_useDemoData) return;
    await _videos.doc(videoId).update({'viewCount': FieldValue.increment(1)});
  }

  Future<void> incrementShareCount(String videoId) async {
    if (_useDemoData) return;
    await _videos.doc(videoId).update({'shareCount': FieldValue.increment(1)});
  }

  // ── MODERATION ────────────────────────────────────────────────────────

  Future<void> flagVideo(String videoId, String reason) async {
    if (_useDemoData) return;
    await _videos.doc(videoId).update({
      'isFlagged': true,
      'flagReason': reason,
    });
    notifyListeners();
  }

  Future<void> unflagVideo(String videoId) async {
    if (_useDemoData) return;
    await _videos.doc(videoId).update({'isFlagged': false, 'flagReason': null});
    notifyListeners();
  }

  /// User-facing report — writes to `content_reports` collection so Cloud
  /// Functions can auto-escalate at threshold and moderators can review.
  Future<void> reportVideo({
    required String videoId,
    required String reporterId,
    required String reason,
    String description = '',
  }) async {
    if (_useDemoData) return;
    await _firestore.collection('content_reports').add({
      'contentType': 'short_video',
      'contentId': videoId,
      'reporterId': reporterId,
      'reason': reason,
      'description': description,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── COMMENTS ──────────────────────────────────────────────────────────

  CollectionReference _commentsRef(String videoId) =>
      _videos.doc(videoId).collection('comments');

  Future<void> addComment({
    required String videoId,
    required String userId,
    required String userName,
    String userAvatarUrl = '',
    required String text,
  }) async {
    if (_useDemoData) return;

    await _commentsRef(videoId).add({
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'likedByIds': <String>[],
    });
    await _videos.doc(videoId).update({
      'commentCount': FieldValue.increment(1),
    });
    notifyListeners();
  }

  Future<void> deleteComment(String videoId, String commentId) async {
    if (_useDemoData) return;
    await _commentsRef(videoId).doc(commentId).delete();
    await _videos.doc(videoId).update({
      'commentCount': FieldValue.increment(-1),
    });
    notifyListeners();
  }

  Stream<List<ReelComment>> commentsStream(String videoId) {
    if (_useDemoData) {
      return Stream.value(_demoComments());
    }

    return _commentsRef(videoId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return ReelComment(
              id: d.id,
              userId: data['userId'] as String? ?? '',
              userName: data['userName'] as String? ?? '',
              userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
              text: data['text'] as String? ?? '',
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              likeCount: data['likeCount'] as int? ?? 0,
            );
          }).toList(),
        );
  }

  List<ReelComment> _demoComments() {
    final now = DateTime.now();
    return [
      ReelComment(
        id: 'c1',
        userId: 'fighter_002',
        userName: 'Jade Rivera',
        text: 'That knockout was INSANE 🔥🔥',
        createdAt: now.subtract(const Duration(minutes: 45)),
        likeCount: 12,
      ),
      ReelComment(
        id: 'c2',
        userId: 'fighter_003',
        userName: 'Dmitri Volkov',
        text: 'Clean technique. Respect.',
        createdAt: now.subtract(const Duration(minutes: 30)),
        likeCount: 8,
      ),
      ReelComment(
        id: 'c3',
        userId: 'fan_001',
        userName: 'Fight Fan Mike',
        text: 'This is why I love combat sports! 💪',
        createdAt: now.subtract(const Duration(minutes: 10)),
        likeCount: 3,
      ),
    ];
  }

  // ── DEMO DATA ─────────────────────────────────────────────────────────

  List<ShortVideoModel> _demoReels() {
    final now = DateTime.now();
    return [
      ShortVideoModel(
        id: 'demo_reel_1',
        creatorId: 'fighter_001',
        creatorName: 'Marcus Sterling',
        videoUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        thumbnailUrl: ImageAssets.bgAction,
        title: 'KO of the Year Contender 🥊',
        description:
            'Watch this incredible second-round knockout from UFC 312. Straight right hand, lights out!',
        hashtags: ['#KO', '#UFC', '#MMA', '#FightHighlight'],
        mentions: ['@UFC'],
        durationSeconds: 28,
        likeCount: 3420,
        commentCount: 187,
        shareCount: 524,
        viewCount: 45200,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ShortVideoModel(
        id: 'demo_reel_2',
        creatorId: 'fighter_002',
        creatorName: 'Jade Rivera',
        videoUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        thumbnailUrl: ImageAssets.bgEvent,
        title: 'Training Camp Day 14 💪',
        description:
            'Getting ready for the biggest fight of my career. 6am runs, 2-a-day sessions. No days off.',
        hashtags: ['#TrainingCamp', '#FightPrep', '#WMMA', '#Grind'],
        mentions: [],
        durationSeconds: 45,
        likeCount: 1890,
        commentCount: 92,
        shareCount: 201,
        viewCount: 18700,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ShortVideoModel(
        id: 'demo_reel_3',
        creatorId: 'fighter_003',
        creatorName: 'Dmitri Volkov',
        videoUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        thumbnailUrl: ImageAssets.bgCentral,
        title: 'Muay Thai Clinch Masterclass 🇹🇭',
        description:
            'Breaking down the fundamentals of the Thai clinch. Elbows, knees, sweeps — the full arsenal.',
        hashtags: ['#MuayThai', '#Clinch', '#Tutorial', '#StrikeFirst'],
        mentions: [],
        durationSeconds: 58,
        likeCount: 5610,
        commentCount: 340,
        shareCount: 1020,
        viewCount: 92400,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      ShortVideoModel(
        id: 'demo_reel_4',
        creatorId: 'promo_001',
        creatorName: 'BKFC Official',
        videoUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
        thumbnailUrl: ImageAssets.bgHero,
        title: 'BKFC 55 — Full Highlight Reel 🔥',
        description:
            'Every knockout, every finish from BKFC 55. Bare knuckle at its finest.',
        hashtags: ['#BKFC', '#BareKnuckle', '#Highlights', '#Combat'],
        mentions: ['@BKFC'],
        durationSeconds: 60,
        likeCount: 8230,
        commentCount: 512,
        shareCount: 2340,
        viewCount: 156800,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ShortVideoModel(
        id: 'demo_reel_5',
        creatorId: 'fighter_004',
        creatorName: 'Aisha Thompson',
        videoUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        thumbnailUrl: ImageAssets.bgPromo,
        title: 'Boxing Pad Work 🔔 Round 8',
        description:
            'Late rounds, high output. Keeping my hands up and throwing combos. Camp is going amazing.',
        hashtags: ['#Boxing', '#PadWork', '#WomenInBoxing', '#Cardio'],
        mentions: [],
        durationSeconds: 32,
        likeCount: 2140,
        commentCount: 78,
        shareCount: 156,
        viewCount: 23100,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  String _sanitizeFileName(String fileName) {
    final cleaned = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'upload.bin' : cleaned;
  }

  String _contentTypeFor(String fileName, String folder) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    return folder == 'thumbnails' ? 'image/jpeg' : 'video/mp4';
  }
}
