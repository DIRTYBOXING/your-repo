import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FIGHT COLLECTIBLE MODEL — Digital Fighter Cards, Moments & Drops
///
/// Rarity tiers: Common → Uncommon → Rare → Epic → Legendary → Mythic
/// Types: fighter card, knockout moment, championship, signature, submission
/// Powers the FightCollect marketplace & collection tracking system.
/// ═══════════════════════════════════════════════════════════════════════════

enum CollectibleRarity { common, uncommon, rare, epic, legendary, mythic }

enum CollectibleType {
  fighterCard,
  knockoutMoment,
  championship,
  signatureMove,
  submissionFinish,
  eventPoster,
  trainingMontage,
}

class FightCollectible extends Equatable {
  final String id;
  final String name;
  final String description;
  final CollectibleType type;
  final CollectibleRarity rarity;
  final String fighterId;
  final String fighterName;
  final String? eventId;
  final String? eventName;
  final String imageUrl;
  final String? animationUrl;
  final int edition;
  final int totalEditions;
  final double mintPrice;
  final double? marketValue;
  final String ownerId;
  final String ownerName;
  final bool isListed;
  final double? askingPrice;
  final DateTime mintedAt;
  final DateTime? listedAt;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> attributes;
  final String? cardStyle;
  final String? borderEffect;
  final String? overlayEffect;

  const FightCollectible({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.fighterId,
    required this.fighterName,
    this.eventId,
    this.eventName,
    required this.imageUrl,
    this.animationUrl,
    required this.edition,
    required this.totalEditions,
    required this.mintPrice,
    this.marketValue,
    required this.ownerId,
    required this.ownerName,
    this.isListed = false,
    this.askingPrice,
    required this.mintedAt,
    this.listedAt,
    this.stats = const {},
    this.attributes = const {},
    this.cardStyle,
    this.borderEffect,
    this.overlayEffect,
  });

  factory FightCollectible.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FightCollectible(
      id: doc.id,
      name: d['name'] ?? 'Untitled',
      description: d['description'] ?? '',
      type: CollectibleType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => CollectibleType.fighterCard,
      ),
      rarity: CollectibleRarity.values.firstWhere(
        (r) => r.name == d['rarity'],
        orElse: () => CollectibleRarity.common,
      ),
      fighterId: d['fighterId'] ?? '',
      fighterName: d['fighterName'] ?? 'Unknown',
      eventId: d['eventId'],
      eventName: d['eventName'],
      imageUrl: d['imageUrl'] ?? '',
      animationUrl: d['animationUrl'],
      edition: d['edition'] ?? 1,
      totalEditions: d['totalEditions'] ?? 100,
      mintPrice: (d['mintPrice'] ?? 0).toDouble(),
      marketValue: d['marketValue']?.toDouble(),
      ownerId: d['ownerId'] ?? '',
      ownerName: d['ownerName'] ?? '',
      isListed: d['isListed'] ?? false,
      askingPrice: d['askingPrice']?.toDouble(),
      mintedAt: (d['mintedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      listedAt: (d['listedAt'] as Timestamp?)?.toDate(),
      stats: Map<String, dynamic>.from(d['stats'] ?? {}),
      attributes: Map<String, dynamic>.from(d['attributes'] ?? {}),
      cardStyle: d['cardStyle'],
      borderEffect: d['borderEffect'],
      overlayEffect: d['overlayEffect'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'type': type.name,
    'rarity': rarity.name,
    'fighterId': fighterId,
    'fighterName': fighterName,
    'eventId': eventId,
    'eventName': eventName,
    'imageUrl': imageUrl,
    'animationUrl': animationUrl,
    'edition': edition,
    'totalEditions': totalEditions,
    'mintPrice': mintPrice,
    'marketValue': marketValue,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'isListed': isListed,
    'askingPrice': askingPrice,
    'mintedAt': Timestamp.fromDate(mintedAt),
    'listedAt': listedAt != null ? Timestamp.fromDate(listedAt!) : null,
    'stats': stats,
    'attributes': attributes,
    'cardStyle': cardStyle,
    'borderEffect': borderEffect,
    'overlayEffect': overlayEffect,
  };

  /// Rarity display color hex (for UI theming).
  int get rarityColorHex => switch (rarity) {
    CollectibleRarity.common => 0xFF9E9E9E,
    CollectibleRarity.uncommon => 0xFF4CAF50,
    CollectibleRarity.rare => 0xFF2196F3,
    CollectibleRarity.epic => 0xFF9C27B0,
    CollectibleRarity.legendary => 0xFFFF9800,
    CollectibleRarity.mythic => 0xFFFF3366,
  };

  /// Rarity label with edition info.
  String get rarityLabel =>
      '${rarity.name.toUpperCase()} #$edition / $totalEditions';

  /// Price tier for minting.
  static double mintPriceForRarity(CollectibleRarity rarity) =>
      switch (rarity) {
        CollectibleRarity.common => 5.0,
        CollectibleRarity.uncommon => 15.0,
        CollectibleRarity.rare => 50.0,
        CollectibleRarity.epic => 150.0,
        CollectibleRarity.legendary => 500.0,
        CollectibleRarity.mythic => 2500.0,
      };

  /// Max editions per rarity tier.
  static int maxEditionsForRarity(CollectibleRarity rarity) => switch (rarity) {
    CollectibleRarity.common => 1000,
    CollectibleRarity.uncommon => 500,
    CollectibleRarity.rare => 100,
    CollectibleRarity.epic => 25,
    CollectibleRarity.legendary => 10,
    CollectibleRarity.mythic => 1,
  };

  @override
  List<Object?> get props => [id, ownerId, edition];
}

/// Represents a pack that can be opened to reveal collectibles.
class CollectiblePack extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final int cardCount;
  final CollectibleRarity guaranteedMinRarity;
  final String imageUrl;
  final bool isAvailable;
  final DateTime? availableUntil;

  const CollectiblePack({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.cardCount,
    required this.guaranteedMinRarity,
    required this.imageUrl,
    this.isAvailable = true,
    this.availableUntil,
  });

  factory CollectiblePack.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CollectiblePack(
      id: doc.id,
      name: d['name'] ?? 'Pack',
      description: d['description'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      cardCount: d['cardCount'] ?? 3,
      guaranteedMinRarity: CollectibleRarity.values.firstWhere(
        (r) => r.name == d['guaranteedMinRarity'],
        orElse: () => CollectibleRarity.common,
      ),
      imageUrl: d['imageUrl'] ?? '',
      isAvailable: d['isAvailable'] ?? true,
      availableUntil: (d['availableUntil'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id];
}
