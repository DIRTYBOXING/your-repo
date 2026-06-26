import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'fightwire_post.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FOUNDATION CAMPAIGN MODEL
/// Pink Shield, Gold Coin Drive, Coffee Campaign
/// ═══════════════════════════════════════════════════════════════════════════

class DfcCampaign extends Equatable {
  final String id;
  final String title;
  final String description;
  final CampaignType type;

  // Fundraising
  final double goalAmount;
  final double raisedAmount;
  final String currency;

  // Impact
  final String impactStatement;
  final Map<String, dynamic> impactMetrics;
  final List<String> beneficiaries;

  // Media
  final String? imageUrl;
  final String? videoUrl;
  final List<String> galleryUrls;

  // Location
  final String? location;
  final double? lat;
  final double? lng;

  // Creator
  final String creatorId;
  final String creatorName;
  final bool isVerified;

  // Timing
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  // Engagement
  final int supportersCount;
  final int sharesCount;
  final int viewsCount;

  // Status
  final CampaignStatus status;
  final bool isFeatured;

  // Campaign-specific data
  final Map<String, dynamic>? customData;

  const DfcCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.goalAmount = 0.0,
    this.raisedAmount = 0.0,
    this.currency = 'AUD',
    required this.impactStatement,
    this.impactMetrics = const {},
    this.beneficiaries = const [],
    this.imageUrl,
    this.videoUrl,
    this.galleryUrls = const [],
    this.location,
    this.lat,
    this.lng,
    required this.creatorId,
    required this.creatorName,
    this.isVerified = false,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.supportersCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.status = CampaignStatus.active,
    this.isFeatured = false,
    this.customData,
  });

  @override
  List<Object?> get props => [id, title, type, createdAt];

  // Progress percentage
  double get progressPercentage {
    if (goalAmount == 0) return 0.0;
    return (raisedAmount / goalAmount * 100).clamp(0.0, 100.0);
  }

  bool get isActive => status == CampaignStatus.active;
  bool get isComplete => status == CampaignStatus.completed;
  bool get hasGoalReached => raisedAmount >= goalAmount;
  String get name => title;

  factory DfcCampaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DfcCampaign(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: CampaignType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CampaignType.goldCoin,
      ),
      goalAmount: data['goalAmount']?.toDouble() ?? 0.0,
      raisedAmount: data['raisedAmount']?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'AUD',
      impactStatement: data['impactStatement'] ?? '',
      impactMetrics: data['impactMetrics'] ?? {},
      beneficiaries: List<String>.from(data['beneficiaries'] ?? []),
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      galleryUrls: List<String>.from(data['galleryUrls'] ?? []),
      location: data['location'],
      lat: data['lat']?.toDouble(),
      lng: data['lng']?.toDouble(),
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      supportersCount: data['supportersCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CampaignStatus.active,
      ),
      isFeatured: data['isFeatured'] ?? false,
      customData: data['customData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'goalAmount': goalAmount,
      'raisedAmount': raisedAmount,
      'currency': currency,
      'impactStatement': impactStatement,
      'impactMetrics': impactMetrics,
      'beneficiaries': beneficiaries,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'galleryUrls': galleryUrls,
      'location': location,
      'lat': lat,
      'lng': lng,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'supportersCount': supportersCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'status': status.name,
      'isFeatured': isFeatured,
      'customData': customData,
    };
  }

  DfcCampaign copyWith({
    double? raisedAmount,
    int? supportersCount,
    int? sharesCount,
    int? viewsCount,
    CampaignStatus? status,
    Map<String, dynamic>? impactMetrics,
  }) {
    return DfcCampaign(
      id: id,
      title: title,
      description: description,
      type: type,
      goalAmount: goalAmount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
      currency: currency,
      impactStatement: impactStatement,
      impactMetrics: impactMetrics ?? this.impactMetrics,
      beneficiaries: beneficiaries,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      galleryUrls: galleryUrls,
      location: location,
      lat: lat,
      lng: lng,
      creatorId: creatorId,
      creatorName: creatorName,
      isVerified: isVerified,
      createdAt: createdAt,
      startDate: startDate,
      endDate: endDate,
      supportersCount: supportersCount ?? this.supportersCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      status: status ?? this.status,
      isFeatured: isFeatured,
      customData: customData,
    );
  }
}

enum CampaignStatus { draft, active, paused, completed, archived }

/// Campaign badge definitions
extension CampaignBadge on CampaignType {
  String get emoji {
    switch (this) {
      case CampaignType.pinkShield:
        return '🛡️';
      case CampaignType.goldCoin:
        return '🪙';
      case CampaignType.coffee:
        return '☕';
      case CampaignType.nightchill:
        return '🌙';
      case CampaignType.youth:
        return '🎓';
      case CampaignType.custom:
        return '⭐';
    }
  }

  String get displayName {
    switch (this) {
      case CampaignType.pinkShield:
        return 'Pink Shield';
      case CampaignType.goldCoin:
        return 'Gold Coin Drive';
      case CampaignType.coffee:
        return 'Buy a Coffee Not a Coffin';
      case CampaignType.nightchill:
        return 'NightChill Support';
      case CampaignType.youth:
        return 'Youth Training Fund';
      case CampaignType.custom:
        return 'Community Campaign';
    }
  }

  String get colorHex {
    switch (this) {
      case CampaignType.pinkShield:
        return '#FF69B4'; // Pink
      case CampaignType.goldCoin:
        return '#FFD700'; // Gold
      case CampaignType.coffee:
        return '#D2691E'; // Coffee brown
      case CampaignType.nightchill:
        return '#FFA500'; // Orange
      case CampaignType.youth:
        return '#4169E1'; // Royal blue
      case CampaignType.custom:
        return '#00CED1'; // Turquoise
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CAMPAIGN DONATION MODEL
/// ═══════════════════════════════════════════════════════════════════════════

class CampaignDonation extends Equatable {
  final String id;
  final String campaignId;
  final String userId;
  final String userName;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final bool isAnonymous;
  final String? message;
  final PaymentStatus status;

  const CampaignDonation({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.userName,
    required this.amount,
    this.currency = 'AUD',
    required this.createdAt,
    this.isAnonymous = false,
    this.message,
    this.status = PaymentStatus.completed,
  });

  @override
  List<Object?> get props => [id, campaignId, userId, amount, createdAt];

  factory CampaignDonation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampaignDonation(
      id: doc.id,
      campaignId: data['campaignId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      amount: data['amount']?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'AUD',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAnonymous: data['isAnonymous'] ?? false,
      message: data['message'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.completed,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'campaignId': campaignId,
      'userId': userId,
      'userName': isAnonymous ? 'Anonymous' : userName,
      'amount': amount,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAnonymous': isAnonymous,
      'message': message,
      'status': status.name,
    };
  }
}

enum PaymentStatus { pending, completed, failed, refunded }
