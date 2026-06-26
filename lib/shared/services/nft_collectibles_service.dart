import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// NFT COLLECTIBLES SERVICE — Digital Fighter Cards & Moments
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

enum NFTRarity { common, uncommon, rare, epic, legendary, mythic }

enum NFTType {
  fighterCard,
  moment,
  championship,
  signature,
  knockout,
  submission,
}

class NFTCollectible {
  final String id;
  final String name;
  final String description;
  final NFTType type;
  final NFTRarity rarity;
  final String fighterId;
  final String fighterName;
  final String? eventId;
  final String imageUrl;
  final String? videoUrl;
  final int edition;
  final int totalEditions;
  final double mintPrice;
  final double? currentValue;
  final String ownerId;
  final DateTime mintedAt;
  final Map<String, dynamic> attributes;

  const NFTCollectible({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.fighterId,
    required this.fighterName,
    this.eventId,
    required this.imageUrl,
    this.videoUrl,
    required this.edition,
    required this.totalEditions,
    required this.mintPrice,
    this.currentValue,
    required this.ownerId,
    required this.mintedAt,
    this.attributes = const {},
  });

  factory NFTCollectible.fromMap(Map<String, dynamic> map) => NFTCollectible(
    id: map['id'] ?? '',
    name: map['name'] ?? 'Untitled',
    description: map['description'] ?? '',
    type: NFTType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => NFTType.fighterCard,
    ),
    rarity: NFTRarity.values.firstWhere(
      (r) => r.name == map['rarity'],
      orElse: () => NFTRarity.common,
    ),
    fighterId: map['fighterId'] ?? '',
    fighterName: map['fighterName'] ?? 'Unknown',
    eventId: map['eventId'],
    imageUrl: map['imageUrl'] ?? '',
    videoUrl: map['videoUrl'],
    edition: map['edition'] ?? 1,
    totalEditions: map['totalEditions'] ?? 100,
    mintPrice: (map['mintPrice'] ?? 0).toDouble(),
    currentValue: map['currentValue']?.toDouble(),
    ownerId: map['ownerId'] ?? '',
    mintedAt: (map['mintedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'rarity': rarity.name,
    'fighterId': fighterId,
    'fighterName': fighterName,
    'eventId': eventId,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'edition': edition,
    'totalEditions': totalEditions,
    'mintPrice': mintPrice,
    'currentValue': currentValue,
    'ownerId': ownerId,
    'attributes': attributes,
  };

  int get rarityMultiplier => switch (rarity) {
    NFTRarity.common => 1,
    NFTRarity.uncommon => 2,
    NFTRarity.rare => 5,
    NFTRarity.epic => 10,
    NFTRarity.legendary => 25,
    NFTRarity.mythic => 100,
  };
}

class NFTCollectiblesService with ChangeNotifier {
  static final NFTCollectiblesService _instance =
      NFTCollectiblesService._internal();
  factory NFTCollectiblesService() => _instance;
  NFTCollectiblesService._internal();

  bool _initialized = false;
  final List<NFTCollectible> _userCollection = [];
  final List<NFTCollectible> _marketplace = [];

  bool get initialized => _initialized;
  List<NFTCollectible> get userCollection => List.unmodifiable(_userCollection);
  List<NFTCollectible> get marketplace => List.unmodifiable(_marketplace);
  int get collectionValue => _userCollection.fold(
    0,
    (total, nft) => total + (nft.currentValue ?? nft.mintPrice).toInt(),
  );

  Future<void> initialize(String userId) async {
    if (_initialized) return;
    debugPrint('🎴 NFTCollectiblesService: Initializing...');
    await Future.wait([_loadUserCollection(userId), _loadMarketplace()]);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadUserCollection(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('nft_collectibles')
          .where('ownerId', isEqualTo: userId)
          .orderBy('mintedAt', descending: true)
          .limit(100)
          .get();
      _userCollection.clear();
      for (final doc in snapshot.docs) {
        _userCollection.add(
          NFTCollectible.fromMap({...doc.data(), 'id': doc.id}),
        );
      }
    } catch (e) {
      debugPrint('NFTCollectiblesService: Load collection failed: $e');
    }
  }

  Future<void> _loadMarketplace() async {
    try {
      final snapshot = await _firestore
          .collection('nft_marketplace')
          .where('isListed', isEqualTo: true)
          .orderBy('listedAt', descending: true)
          .limit(50)
          .get();
      _marketplace.clear();
      for (final doc in snapshot.docs) {
        _marketplace.add(NFTCollectible.fromMap({...doc.data(), 'id': doc.id}));
      }
    } catch (e) {
      debugPrint('NFTCollectiblesService: Load marketplace failed: $e');
    }
  }

  Future<NFTCollectible?> mintCollectible({
    required String userId,
    required String fighterId,
    required String fighterName,
    required NFTType type,
    String? eventId,
  }) async {
    try {
      final callable = _functions.httpsCallable('mintNFTCollectible');
      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'fighterId': fighterId,
        'fighterName': fighterName,
        'type': type.name,
        'eventId': eventId,
      });
      if (result.data['nft'] != null) {
        final nft = NFTCollectible.fromMap(
          result.data['nft'] as Map<String, dynamic>,
        );
        _userCollection.insert(0, nft);
        notifyListeners();
        return nft;
      }
    } catch (e) {
      debugPrint('NFTCollectiblesService: Mint failed: $e');
    }
    return null;
  }

  Future<bool> listForSale(String nftId, double price) async {
    try {
      await _firestore.collection('nft_marketplace').doc(nftId).set({
        'isListed': true,
        'askingPrice': price,
        'listedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchaseNFT(String nftId, String buyerId) async {
    try {
      final callable = _functions.httpsCallable('purchaseNFT');
      final result = await callable.call<Map<String, dynamic>>({
        'nftId': nftId,
        'buyerId': buyerId,
      });
      return result.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  List<NFTCollectible> getByRarity(NFTRarity rarity) =>
      _userCollection.where((n) => n.rarity == rarity).toList();
  List<NFTCollectible> getByFighter(String fighterId) =>
      _userCollection.where((n) => n.fighterId == fighterId).toList();
}
