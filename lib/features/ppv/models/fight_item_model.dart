import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual Fight Item (can be purchased separately from full event)
class FightItem {
  final String id;
  final String ppvEventId;
  final String fightNumber; // "Main Event", "Co-Main", "Fight 3", etc.
  final String fighter1Name;
  final String fighter1Id;
  final String fighter2Name;
  final String fighter2Id;
  final String weightClass;
  final String title; // e.g., "Lightweight Title Bout"
  final String description;
  final double price;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? result; // "Fighter1 KO Round 2", etc.
  final FightPriority priority;
  final int purchaseCount;
  final DateTime createdAt;

  FightItem({
    required this.id,
    required this.ppvEventId,
    required this.fightNumber,
    required this.fighter1Name,
    required this.fighter1Id,
    required this.fighter2Name,
    required this.fighter2Id,
    required this.weightClass,
    required this.title,
    required this.description,
    required this.price,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    this.result,
    this.priority = FightPriority.undercard,
    this.purchaseCount = 0,
    required this.createdAt,
  });

  factory FightItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FightItem(
      id: doc.id,
      ppvEventId: data['ppvEventId'] ?? '',
      fightNumber: data['fightNumber'] ?? '',
      fighter1Name: data['fighter1Name'] ?? '',
      fighter1Id: data['fighter1Id'] ?? '',
      fighter2Name: data['fighter2Name'] ?? '',
      fighter2Id: data['fighter2Id'] ?? '',
      weightClass: data['weightClass'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      durationSeconds: data['durationSeconds'] ?? 0,
      result: data['result'],
      priority: FightPriority.values.firstWhere(
        (e) => e.toString() == 'FightPriority.${data['priority']}',
        orElse: () => FightPriority.undercard,
      ),
      purchaseCount: data['purchaseCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ppvEventId': ppvEventId,
      'fightNumber': fightNumber,
      'fighter1Name': fighter1Name,
      'fighter1Id': fighter1Id,
      'fighter2Name': fighter2Name,
      'fighter2Id': fighter2Id,
      'weightClass': weightClass,
      'title': title,
      'description': description,
      'price': price,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'result': result,
      'priority': priority.toString().split('.').last,
      'purchaseCount': purchaseCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

enum FightPriority { mainEvent, coMain, featured, undercard }

/// Fight Item Purchase
class FightItemPurchase {
  final String id;
  final String fightItemId;
  final String ppvEventId;
  final String userId;
  final String userEmail;
  final double amountPaid;
  final String stripePaymentId;
  final DateTime purchasedAt;

  FightItemPurchase({
    required this.id,
    required this.fightItemId,
    required this.ppvEventId,
    required this.userId,
    required this.userEmail,
    required this.amountPaid,
    required this.stripePaymentId,
    required this.purchasedAt,
  });

  factory FightItemPurchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FightItemPurchase(
      id: doc.id,
      fightItemId: data['fightItemId'] ?? '',
      ppvEventId: data['ppvEventId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      stripePaymentId: data['stripePaymentId'] ?? '',
      purchasedAt: (data['purchasedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fightItemId': fightItemId,
      'ppvEventId': ppvEventId,
      'userId': userId,
      'userEmail': userEmail,
      'amountPaid': amountPaid,
      'stripePaymentId': stripePaymentId,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
    };
  }
}

/// PPV Package (bundles of fights)
class PPVPackage {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> includedEventIds; // Can access these events
  final PackageType type;
  final int durationDays; // Access duration
  final bool isActive;
  final DateTime createdAt;

  PPVPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.includedEventIds,
    required this.type,
    this.durationDays = 30,
    this.isActive = true,
    required this.createdAt,
  });

  factory PPVPackage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PPVPackage(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      includedEventIds: List<String>.from(data['includedEventIds'] ?? []),
      type: PackageType.values.firstWhere(
        (e) => e.toString() == 'PackageType.${data['type']}',
        orElse: () => PackageType.multiEvent,
      ),
      durationDays: data['durationDays'] ?? 30,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'includedEventIds': includedEventIds,
      'type': type.toString().split('.').last,
      'durationDays': durationDays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

enum PackageType {
  multiEvent, // 3-pack, 5-pack
  monthly, // All events this month
  subscription, // Recurring monthly
}
