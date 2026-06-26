import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Sponsorship — Fighter × Brand partnership deal
/// Links fighters with brands for endorsements, 1-on-1 coaching, equipment, travel
enum SponsorshipStatus {
  open, // Brand seeking offers
  applied, // Fighter applied
  shortlist, // Brand shortlisted fighter
  active, // Deal signed & live
  expired, // Contract ended
  rejected,
}

enum SponsorshipCategory {
  equipment, // Gloves, shorts, supplements
  coaching, // 1-on-1 training sessions
  apparel, // Branded clothing
  nutrition, // Meal plans, supplements
  travel, // Fight travel sponsorship
  media, // Content creation, streaming
  training, // Gym memberships, equipment
  recovery, // Physio, ice baths, massage
  technology, // Wearables, analytics
  lifestyle, // Hotels, insurance, cars
}

class Sponsorship extends Equatable {
  final String id;
  final String brandId;
  final String brandName;
  final String brandLogo;
  final String? fighterId; // null = open offer
  final String? fighterName;
  final String? fighterPhoto;
  final SponsorshipStatus status;
  final SponsorshipCategory category;
  final String title; // "Train with Coach Ray Mitchell"
  final String description;
  final double valueUSD; // Monthly value
  final int durationMonths;
  final DateTime createdAt;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final List<String>
  requirements; // ["KOs", "Social reach >10K", "Content weekly"]
  final List<String>
  deliverables; // ["Monthly coaching", "Social posts", "Event appearance"]
  final int? applicantCount;
  final List<String>? applicantIds; // Fighter IDs who applied
  final Map<String, dynamic>? metadata; // Custom fields
  final bool isVerified;
  final double rating; // Brand rating 0-5

  const Sponsorship({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.brandLogo,
    this.fighterId,
    this.fighterName,
    this.fighterPhoto,
    required this.status,
    required this.category,
    required this.title,
    required this.description,
    required this.valueUSD,
    required this.durationMonths,
    required this.createdAt,
    this.startsAt,
    this.expiresAt,
    this.requirements = const [],
    this.deliverables = const [],
    this.applicantCount,
    this.applicantIds,
    this.metadata,
    this.isVerified = false,
    this.rating = 3.0,
  });

  bool get isOpen => status == SponsorshipStatus.open;
  bool get isApplied => status == SponsorshipStatus.applied;
  bool get isActive => status == SponsorshipStatus.active;
  bool get isExpired => status == SponsorshipStatus.expired;

  double get monthlyValue => valueUSD;
  double get totalValue => valueUSD * durationMonths;

  Sponsorship copyWith({
    String? id,
    String? brandId,
    String? brandName,
    String? brandLogo,
    String? fighterId,
    String? fighterName,
    String? fighterPhoto,
    SponsorshipStatus? status,
    SponsorshipCategory? category,
    String? title,
    String? description,
    double? valueUSD,
    int? durationMonths,
    DateTime? createdAt,
    DateTime? startsAt,
    DateTime? expiresAt,
    List<String>? requirements,
    List<String>? deliverables,
    int? applicantCount,
    List<String>? applicantIds,
    Map<String, dynamic>? metadata,
    bool? isVerified,
    double? rating,
  }) {
    return Sponsorship(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      brandLogo: brandLogo ?? this.brandLogo,
      fighterId: fighterId ?? this.fighterId,
      fighterName: fighterName ?? this.fighterName,
      fighterPhoto: fighterPhoto ?? this.fighterPhoto,
      status: status ?? this.status,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      valueUSD: valueUSD ?? this.valueUSD,
      durationMonths: durationMonths ?? this.durationMonths,
      createdAt: createdAt ?? this.createdAt,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      requirements: requirements ?? this.requirements,
      deliverables: deliverables ?? this.deliverables,
      applicantCount: applicantCount ?? this.applicantCount,
      applicantIds: applicantIds ?? this.applicantIds,
      metadata: metadata ?? this.metadata,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'brandId': brandId,
      'brandName': brandName,
      'brandLogo': brandLogo,
      'fighterId': fighterId,
      'fighterName': fighterName,
      'fighterPhoto': fighterPhoto,
      'status': status.toString().split('.').last,
      'category': category.toString().split('.').last,
      'title': title,
      'description': description,
      'valueUSD': valueUSD,
      'durationMonths': durationMonths,
      'createdAt': FieldValue.serverTimestamp(),
      'startsAt': startsAt,
      'expiresAt': expiresAt,
      'requirements': requirements,
      'deliverables': deliverables,
      'applicantCount': applicantCount ?? 0,
      'applicantIds': applicantIds ?? [],
      'metadata': metadata,
      'isVerified': isVerified,
      'rating': rating,
    };
  }

  factory Sponsorship.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Sponsorship(
      id: doc.id,
      brandId: d['brandId'] ?? '',
      brandName: d['brandName'] ?? 'Unknown Brand',
      brandLogo: d['brandLogo'] ?? '',
      fighterId: d['fighterId'],
      fighterName: d['fighterName'],
      fighterPhoto: d['fighterPhoto'],
      status: _statusFromString(d['status']),
      category: _categoryFromString(d['category']),
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      valueUSD: (d['valueUSD'] as num?)?.toDouble() ?? 0.0,
      durationMonths: d['durationMonths'] ?? 1,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startsAt: (d['startsAt'] as Timestamp?)?.toDate(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      requirements: List<String>.from(d['requirements'] ?? []),
      deliverables: List<String>.from(d['deliverables'] ?? []),
      applicantCount: d['applicantCount'],
      applicantIds: List<String>.from(d['applicantIds'] ?? []),
      metadata: d['metadata'],
      isVerified: d['isVerified'] ?? false,
      rating: (d['rating'] as num?)?.toDouble() ?? 3.0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    brandId,
    fighterId,
    status,
    category,
    title,
    createdAt,
  ];
}

SponsorshipStatus _statusFromString(String? s) {
  if (s == null) return SponsorshipStatus.open;
  return SponsorshipStatus.values.firstWhere(
    (e) => e.toString().endsWith(s),
    orElse: () => SponsorshipStatus.open,
  );
}

SponsorshipCategory _categoryFromString(String? s) {
  if (s == null) return SponsorshipCategory.equipment;
  return SponsorshipCategory.values.firstWhere(
    (e) => e.toString().endsWith(s),
    orElse: () => SponsorshipCategory.equipment,
  );
}
