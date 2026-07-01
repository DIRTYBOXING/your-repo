import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/fight_collectible_model.dart';
import '../../../core/constants/image_assets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT COLLECT SERVICE — Minting, Collection, Trading & Pack Opening
///
/// Full collectible lifecycle: mint → collect → trade → marketplace.
/// Collection tracking with rarity counts, pack opening with weighted RNG,
/// and Firestore-backed ownership with audit trail.
/// ═══════════════════════════════════════════════════════════════════════════

final _db = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

class FightCollectService with ChangeNotifier {
  static final FightCollectService _instance = FightCollectService._internal();
  factory FightCollectService() => _instance;
  FightCollectService._internal();

  bool _initialized = false;
  final List<FightCollectible> _collection = [];
  final List<FightCollectible> _marketplace = [];
  final List<CollectiblePack> _availablePacks = [];
  final Map<CollectibleRarity, int> _rarityCounts = {};

  bool get initialized => _initialized;
  List<FightCollectible> get collection => List.unmodifiable(_collection);
  List<FightCollectible> get marketplace => List.unmodifiable(_marketplace);
  List<CollectiblePack> get availablePacks =>
      List.unmodifiable(_availablePacks);
  Map<CollectibleRarity, int> get rarityCounts =>
      Map.unmodifiable(_rarityCounts);

  int get totalCards => _collection.length;
  double get collectionValue => _collection.fold(
    0.0,
    (total, c) => total + (c.marketValue ?? c.mintPrice),
  );
  int get uniqueFighters => _collection.map((c) => c.fighterId).toSet().length;

  /// Initialize service: load user collection + marketplace + packs.
  Future<void> initialize(String userId) async {
    if (_initialized) return;
    debugPrint('🃏 FightCollectService: Initializing...');
    await Future.wait([
      _loadCollection(userId),
      _loadMarketplace(),
      _loadAvailablePacks(),
    ]);
    _computeRarityCounts();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadCollection(String userId) async {
    try {
      final snap = await _db
          .collection('fight_collectibles')
          .where('ownerId', isEqualTo: userId)
          .orderBy('mintedAt', descending: true)
          .limit(200)
          .get();
      _collection.clear();
      for (final doc in snap.docs) {
        _collection.add(FightCollectible.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('FightCollectService: Load collection failed: $e');
    }
  }

  Future<void> _loadMarketplace() async {
    try {
      final snap = await _db
          .collection('fight_collectibles')
          .where('isListed', isEqualTo: true)
          .orderBy('listedAt', descending: true)
          .limit(50)
          .get();
      _marketplace.clear();
      for (final doc in snap.docs) {
        _marketplace.add(FightCollectible.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('FightCollectService: Load marketplace failed: $e');
    }
  }

  Future<void> _loadAvailablePacks() async {
    try {
      final snap = await _db
          .collection('collectible_packs')
          .where('isAvailable', isEqualTo: true)
          .orderBy('price')
          .limit(20)
          .get();
      _availablePacks.clear();
      for (final doc in snap.docs) {
        _availablePacks.add(CollectiblePack.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('FightCollectService: Load packs failed: $e');
    }

    // Seed default packs if none exist
    if (_availablePacks.isEmpty) {
      _availablePacks.addAll(_defaultPacks);
    }
  }

  void _computeRarityCounts() {
    _rarityCounts.clear();
    for (final c in _collection) {
      _rarityCounts[c.rarity] = (_rarityCounts[c.rarity] ?? 0) + 1;
    }
  }

  // ── Stream user collection (real-time) ──────────────────────────────
  Stream<List<FightCollectible>> collectionStream(String userId) {
    return _db
        .collection('fight_collectibles')
        .where('ownerId', isEqualTo: userId)
        .orderBy('mintedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(FightCollectible.fromFirestore).toList(),
        );
  }

  // ── Marketplace stream ──────────────────────────────────────────────
  Stream<List<FightCollectible>> marketplaceStream() {
    return _db
        .collection('fight_collectibles')
        .where('isListed', isEqualTo: true)
        .orderBy('listedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(FightCollectible.fromFirestore).toList(),
        );
  }

  // ── Mint a new collectible ──────────────────────────────────────────
  Future<FightCollectible?> mintCollectible({
    required String userId,
    required String userName,
    required String fighterId,
    required String fighterName,
    required CollectibleType type,
    required CollectibleRarity rarity,
    required String imageUrl,
    String? eventId,
    String? eventName,
    Map<String, dynamic>? stats,
    String? cardStyle,
  }) async {
    try {
      final maxEditions = FightCollectible.maxEditionsForRarity(rarity);
      final mintPrice = FightCollectible.mintPriceForRarity(rarity);

      // Check edition count
      final existing = await _db
          .collection('fight_collectibles')
          .where('fighterId', isEqualTo: fighterId)
          .where('rarity', isEqualTo: rarity.name)
          .where('type', isEqualTo: type.name)
          .count()
          .get();
      final edition = (existing.count ?? 0) + 1;
      if (edition > maxEditions) {
        debugPrint('FightCollectService: Max editions reached for $rarity');
        return null;
      }

      final ref = _db.collection('fight_collectibles').doc();
      final collectible = FightCollectible(
        id: ref.id,
        name: '$fighterName ${type.name}',
        description:
            '${rarity.name.toUpperCase()} ${type.name} — Edition #$edition of $maxEditions',
        type: type,
        rarity: rarity,
        fighterId: fighterId,
        fighterName: fighterName,
        eventId: eventId,
        eventName: eventName,
        imageUrl: imageUrl,
        edition: edition,
        totalEditions: maxEditions,
        mintPrice: mintPrice,
        ownerId: userId,
        ownerName: userName,
        mintedAt: DateTime.now(),
        stats: stats ?? {},
        cardStyle: cardStyle,
      );

      await ref.set(collectible.toFirestore());

      // Log mint event
      await _db.collection('collectible_events').add({
        'type': 'mint',
        'collectibleId': ref.id,
        'userId': userId,
        'rarity': rarity.name,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _collection.insert(0, collectible);
      _computeRarityCounts();
      notifyListeners();
      return collectible;
    } catch (e) {
      debugPrint('FightCollectService: Mint failed: $e');
      return null;
    }
  }

  // ── Open a pack (weighted RNG) ──────────────────────────────────────
  Future<List<FightCollectible>> openPack({
    required String userId,
    required String userName,
    required CollectiblePack pack,
  }) async {
    try {
      // Call Cloud Function if available, else local RNG
      try {
        final callable = _functions.httpsCallable('openCollectiblePack');
        final result = await callable.call<Map<String, dynamic>>({
          'userId': userId,
          'packId': pack.id,
        });
        if (result.data['cards'] != null) {
          final cardDocs = await Future.wait(
            (result.data['cards'] as List).map(
              (c) => _db
                  .collection('fight_collectibles')
                  .doc(c['id'] as String)
                  .get(),
            ),
          );
          final cards = cardDocs
              .where((doc) => doc.exists)
              .map(FightCollectible.fromFirestore)
              .toList();
          _collection.insertAll(0, cards);
          _computeRarityCounts();
          notifyListeners();
          return cards;
        }
      } catch (_) {
        // Fall through to local pack opening
      }

      // Local pack opening with weighted rarity
      final cards = <FightCollectible>[];
      final rng = Random();
      for (int i = 0; i < pack.cardCount; i++) {
        final rarity = _rollRarity(rng, pack.guaranteedMinRarity);
        final card = await mintCollectible(
          userId: userId,
          userName: userName,
          fighterId: 'pack_${pack.id}_${rng.nextInt(999999)}',
          fighterName: 'Pack Card ${i + 1}',
          type: CollectibleType.fighterCard,
          rarity: rarity,
          imageUrl: ImageAssets.fightPlaceholder,
        );
        if (card != null) cards.add(card);
      }
      return cards;
    } catch (e) {
      debugPrint('FightCollectService: Open pack failed: $e');
      return [];
    }
  }

  CollectibleRarity _rollRarity(Random rng, CollectibleRarity minRarity) {
    const weights = {
      CollectibleRarity.common: 50,
      CollectibleRarity.uncommon: 25,
      CollectibleRarity.rare: 15,
      CollectibleRarity.epic: 7,
      CollectibleRarity.legendary: 2.5,
      CollectibleRarity.mythic: 0.5,
    };

    final minIndex = CollectibleRarity.values.indexOf(minRarity);
    final eligible = CollectibleRarity.values
        .where((r) => r.index >= minIndex)
        .toList();
    final totalWeight = eligible.fold(0.0, (acc, r) => acc + (weights[r] ?? 0));
    var roll = rng.nextDouble() * totalWeight;

    for (final rarity in eligible) {
      roll -= weights[rarity] ?? 0;
      if (roll <= 0) return rarity;
    }
    return minRarity;
  }

  // ── List for sale on marketplace ────────────────────────────────────
  Future<bool> listForSale(String collectibleId, double price) async {
    try {
      await _db.collection('fight_collectibles').doc(collectibleId).update({
        'isListed': true,
        'askingPrice': price,
        'listedAt': FieldValue.serverTimestamp(),
      });
      final idx = _collection.indexWhere((c) => c.id == collectibleId);
      if (idx >= 0) {
        // Reload the updated item
        final doc = await _db
            .collection('fight_collectibles')
            .doc(collectibleId)
            .get();
        if (doc.exists) {
          _collection[idx] = FightCollectible.fromFirestore(doc);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FightCollectService: List for sale failed: $e');
      return false;
    }
  }

  // ── Remove from marketplace ─────────────────────────────────────────
  Future<bool> delistFromSale(String collectibleId) async {
    try {
      await _db.collection('fight_collectibles').doc(collectibleId).update({
        'isListed': false,
        'askingPrice': null,
        'listedAt': null,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FightCollectService: Delist failed: $e');
      return false;
    }
  }

  // ── Purchase from marketplace ───────────────────────────────────────
  Future<bool> purchaseCollectible({
    required String collectibleId,
    required String buyerId,
    required String buyerName,
  }) async {
    try {
      final callable = _functions.httpsCallable('purchaseCollectible');
      final result = await callable.call<Map<String, dynamic>>({
        'collectibleId': collectibleId,
        'buyerId': buyerId,
        'buyerName': buyerName,
      });
      if (result.data['success'] == true) {
        await _loadMarketplace();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      // Fallback to direct transfer (for demo mode)
      try {
        final batch = _db.batch();
        final ref = _db.collection('fight_collectibles').doc(collectibleId);
        batch.update(ref, {
          'ownerId': buyerId,
          'ownerName': buyerName,
          'isListed': false,
          'askingPrice': null,
          'listedAt': null,
        });
        batch.set(_db.collection('collectible_events').doc(), {
          'type': 'purchase',
          'collectibleId': collectibleId,
          'buyerId': buyerId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        await _loadMarketplace();
        notifyListeners();
        return true;
      } catch (e2) {
        debugPrint('FightCollectService: Purchase failed: $e2');
        return false;
      }
    }
  }

  // ── Filter helpers ──────────────────────────────────────────────────
  List<FightCollectible> getByRarity(CollectibleRarity rarity) =>
      _collection.where((c) => c.rarity == rarity).toList();

  List<FightCollectible> getByFighter(String fighterId) =>
      _collection.where((c) => c.fighterId == fighterId).toList();

  List<FightCollectible> getByType(CollectibleType type) =>
      _collection.where((c) => c.type == type).toList();

  /// Refresh all data.
  Future<void> refresh(String userId) async {
    _initialized = false;
    await initialize(userId);
  }

  // ── Default packs for demo ──────────────────────────────────────────
  static const _defaultPacks = [
    CollectiblePack(
      id: 'starter_pack',
      name: 'Starter Pack',
      description: '3 cards — guaranteed Uncommon or better',
      price: 9.99,
      cardCount: 3,
      guaranteedMinRarity: CollectibleRarity.common,
      imageUrl: ImageAssets.bgAction,
    ),
    CollectiblePack(
      id: 'contender_pack',
      name: 'Contender Pack',
      description: '5 cards — guaranteed Rare or better',
      price: 24.99,
      cardCount: 5,
      guaranteedMinRarity: CollectibleRarity.uncommon,
      imageUrl: ImageAssets.bgEvent,
    ),
    CollectiblePack(
      id: 'champion_pack',
      name: 'Champion Pack',
      description: '7 cards — guaranteed Epic or better',
      price: 49.99,
      cardCount: 7,
      guaranteedMinRarity: CollectibleRarity.rare,
      imageUrl: ImageAssets.bgPromo,
    ),
    CollectiblePack(
      id: 'mythic_pack',
      name: 'Mythic Pack',
      description: '10 cards — guaranteed Legendary or better',
      price: 99.99,
      cardCount: 10,
      guaranteedMinRarity: CollectibleRarity.epic,
      imageUrl: ImageAssets.bgHero,
    ),
  ];
}
