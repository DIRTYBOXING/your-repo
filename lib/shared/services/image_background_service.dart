import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/image_assets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// IMAGE BACKGROUND SERVICE — Dynamic Background Management
///
/// Manages: bundled DFC backgrounds, user-uploaded custom backgrounds,
/// categorised libraries (fight, event, training, wellness, promo),
/// seasonal/themed rotation, and Firestore-backed user background library.
/// ═══════════════════════════════════════════════════════════════════════════

final _db = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;

enum BackgroundCategory {
  hero,
  action,
  event,
  promo,
  training,
  wellness,
  logo,
  ppv,
  custom,
}

class BackgroundAsset {
  final String id;
  final String url;
  final String name;
  final BackgroundCategory category;
  final bool isLocal;
  final bool isPremium;
  final String? uploaderId;
  final DateTime? createdAt;

  const BackgroundAsset({
    required this.id,
    required this.url,
    required this.name,
    required this.category,
    this.isLocal = true,
    this.isPremium = false,
    this.uploaderId,
    this.createdAt,
  });

  factory BackgroundAsset.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BackgroundAsset(
      id: doc.id,
      url: d['url'] ?? '',
      name: d['name'] ?? 'Background',
      category: BackgroundCategory.values.firstWhere(
        (c) => c.name == d['category'],
        orElse: () => BackgroundCategory.custom,
      ),
      isLocal: false,
      isPremium: d['isPremium'] ?? false,
      uploaderId: d['uploaderId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'url': url,
    'name': name,
    'category': category.name,
    'isPremium': isPremium,
    'uploaderId': uploaderId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class ImageBackgroundService with ChangeNotifier {
  static final ImageBackgroundService _instance =
      ImageBackgroundService._internal();
  factory ImageBackgroundService() => _instance;
  ImageBackgroundService._internal();

  bool _initialized = false;
  final List<BackgroundAsset> _bundledBackgrounds = [];
  final List<BackgroundAsset> _userBackgrounds = [];
  final List<BackgroundAsset> _communityBackgrounds = [];

  bool get initialized => _initialized;
  List<BackgroundAsset> get bundledBackgrounds =>
      List.unmodifiable(_bundledBackgrounds);
  List<BackgroundAsset> get userBackgrounds =>
      List.unmodifiable(_userBackgrounds);
  List<BackgroundAsset> get communityBackgrounds =>
      List.unmodifiable(_communityBackgrounds);
  List<BackgroundAsset> get allBackgrounds => [
    ..._bundledBackgrounds,
    ..._userBackgrounds,
    ..._communityBackgrounds,
  ];

  /// Initialize with bundled assets + optional user library from Firestore.
  Future<void> initialize({String? userId}) async {
    if (_initialized) return;
    debugPrint('🖼️ ImageBackgroundService: Initializing...');
    _loadBundledBackgrounds();
    if (userId != null) {
      await Future.wait([
        _loadUserBackgrounds(userId),
        _loadCommunityBackgrounds(),
      ]);
    }
    _initialized = true;
    notifyListeners();
  }

  void _loadBundledBackgrounds() {
    _bundledBackgrounds.clear();
    _bundledBackgrounds.addAll([
      const BackgroundAsset(
        id: 'bg_hero',
        url: ImageAssets.bgHero,
        name: 'Hero Background',
        category: BackgroundCategory.hero,
      ),
      const BackgroundAsset(
        id: 'bg_action',
        url: ImageAssets.bgAction,
        name: 'Action Background',
        category: BackgroundCategory.action,
      ),
      const BackgroundAsset(
        id: 'bg_event',
        url: ImageAssets.bgEvent,
        name: 'Event Background',
        category: BackgroundCategory.event,
      ),
      const BackgroundAsset(
        id: 'bg_promo',
        url: ImageAssets.bgPromo,
        name: 'Promo Background',
        category: BackgroundCategory.promo,
      ),
      const BackgroundAsset(
        id: 'bg_logo_1024',
        url: ImageAssets.bgLogo1024,
        name: 'Logo Background',
        category: BackgroundCategory.logo,
      ),
      const BackgroundAsset(
        id: 'bg_logo_small',
        url: ImageAssets.bgLogoSmall,
        name: 'Logo Small',
        category: BackgroundCategory.logo,
      ),
      const BackgroundAsset(
        id: 'bg_central',
        url: ImageAssets.bgCentral,
        name: 'Central Background',
        category: BackgroundCategory.logo,
      ),
      const BackgroundAsset(
        id: 'bg_resized',
        url: ImageAssets.bgResized,
        name: 'Resized Background',
        category: BackgroundCategory.logo,
      ),
      const BackgroundAsset(
        id: 'bg_square',
        url: ImageAssets.bgSquare,
        name: 'Square Background',
        category: BackgroundCategory.logo,
      ),
    ]);
  }

  Future<void> _loadUserBackgrounds(String userId) async {
    try {
      final snap = await _db
          .collection('user_backgrounds')
          .where('uploaderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      _userBackgrounds.clear();
      for (final doc in snap.docs) {
        _userBackgrounds.add(BackgroundAsset.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('ImageBackgroundService: Load user backgrounds failed: $e');
    }
  }

  Future<void> _loadCommunityBackgrounds() async {
    try {
      final snap = await _db
          .collection('community_backgrounds')
          .where('approved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      _communityBackgrounds.clear();
      for (final doc in snap.docs) {
        _communityBackgrounds.add(BackgroundAsset.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint(
        'ImageBackgroundService: Load community backgrounds failed: $e',
      );
    }
  }

  /// Get backgrounds filtered by category.
  List<BackgroundAsset> getByCategory(BackgroundCategory category) {
    return allBackgrounds.where((b) => b.category == category).toList();
  }

  /// Get a sport-specific background using ImageAssets mapping.
  String backgroundForSport(String? sport) => ImageAssets.posterForSport(sport);

  /// Get PPV event poster as background.
  String backgroundForEvent(String eventId, {String? sport}) =>
      ImageAssets.ppvPosterForEvent(eventId, sport: sport);

  /// Upload a custom background image.
  Future<BackgroundAsset?> uploadBackground({
    required String userId,
    required String name,
    BackgroundCategory category = BackgroundCategory.custom,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = 'backgrounds/$userId/${ts}_bg.$ext';
      final ref = _storage.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
      final url = await ref.getDownloadURL();

      final asset = BackgroundAsset(
        id: '${userId}_$ts',
        url: url,
        name: name,
        category: category,
        isLocal: false,
        uploaderId: userId,
        createdAt: DateTime.now(),
      );

      await _db
          .collection('user_backgrounds')
          .doc(asset.id)
          .set(asset.toFirestore());
      _userBackgrounds.insert(0, asset);
      notifyListeners();
      return asset;
    } catch (e) {
      debugPrint('ImageBackgroundService: Upload failed: $e');
      return null;
    }
  }

  /// Delete a user-uploaded background.
  Future<bool> deleteBackground(String backgroundId, String userId) async {
    try {
      final doc = await _db
          .collection('user_backgrounds')
          .doc(backgroundId)
          .get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      if (data['uploaderId'] != userId) return false;

      // Delete from Storage
      final url = data['url'] as String?;
      if (url != null && url.contains('firebase')) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }

      await _db.collection('user_backgrounds').doc(backgroundId).delete();
      _userBackgrounds.removeWhere((b) => b.id == backgroundId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ImageBackgroundService: Delete failed: $e');
      return false;
    }
  }

  /// Rotate through bundled backgrounds for variety.
  BackgroundAsset rotatingBackground(int index) {
    if (_bundledBackgrounds.isEmpty) return _defaultBackground;
    return _bundledBackgrounds[index % _bundledBackgrounds.length];
  }

  BackgroundAsset get _defaultBackground => const BackgroundAsset(
    id: 'default',
    url: ImageAssets.bgHero,
    name: 'Default',
    category: BackgroundCategory.hero,
  );
}
