import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Fighter's application to fill an open bout slot.
enum BoutOfferStatus { pending, accepted, rejected, withdrawn }

class BoutOfferModel extends Equatable {
  final String id;
  final String slotId;
  final String fighterId;
  final String fighterName;
  final String? fighterNickname;
  final String fighterRecord; // "W-L-D"
  final String fighterCountry;
  final String? fighterPhotoUrl;
  final String weightClass;
  final BoutOfferStatus status;
  final String? message;
  final double? offeredPurse;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BoutOfferModel({
    required this.id,
    required this.slotId,
    required this.fighterId,
    required this.fighterName,
    this.fighterNickname,
    required this.fighterRecord,
    required this.fighterCountry,
    this.fighterPhotoUrl,
    required this.weightClass,
    this.status = BoutOfferStatus.pending,
    this.message,
    this.offeredPurse,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BoutOfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoutOfferModel(
      id: doc.id,
      slotId: data['slotId'] ?? '',
      fighterId: data['fighterId'] ?? '',
      fighterName: data['fighterName'] ?? '',
      fighterNickname: data['fighterNickname'],
      fighterRecord: data['fighterRecord'] ?? '0-0-0',
      fighterCountry: data['fighterCountry'] ?? '',
      fighterPhotoUrl: data['fighterPhotoUrl'],
      weightClass: data['weightClass'] ?? '',
      status: BoutOfferStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BoutOfferStatus.pending,
      ),
      message: data['message'],
      offeredPurse: (data['offeredPurse'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'slotId': slotId,
    'fighterId': fighterId,
    'fighterName': fighterName,
    'fighterNickname': fighterNickname,
    'fighterRecord': fighterRecord,
    'fighterCountry': fighterCountry,
    'fighterPhotoUrl': fighterPhotoUrl,
    'weightClass': weightClass,
    'status': status.name,
    'message': message,
    'offeredPurse': offeredPurse,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };

  BoutOfferModel copyWith({
    String? id,
    String? slotId,
    String? fighterId,
    String? fighterName,
    String? fighterNickname,
    String? fighterRecord,
    String? fighterCountry,
    String? fighterPhotoUrl,
    String? weightClass,
    BoutOfferStatus? status,
    String? message,
    double? offeredPurse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoutOfferModel(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      fighterId: fighterId ?? this.fighterId,
      fighterName: fighterName ?? this.fighterName,
      fighterNickname: fighterNickname ?? this.fighterNickname,
      fighterRecord: fighterRecord ?? this.fighterRecord,
      fighterCountry: fighterCountry ?? this.fighterCountry,
      fighterPhotoUrl: fighterPhotoUrl ?? this.fighterPhotoUrl,
      weightClass: weightClass ?? this.weightClass,
      status: status ?? this.status,
      message: message ?? this.message,
      offeredPurse: offeredPurse ?? this.offeredPurse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, slotId, fighterId, status];
}
