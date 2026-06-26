import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC Trading Card Model — Profile & Fighter Cards
/// ═══════════════════════════════════════════════════════════════════════════
class TradingCard extends Equatable {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? fighterId;
  final String? fighterName;
  final String? imageUrl;
  final String? gender; // 'male', 'female', etc. (for champion display)
  final String? backgroundUrl;
  final String cardType; // 'profile' | 'fighter'
  final String title;
  final String subtitle;
  final Map<String, dynamic> stats;
  final String? cardStyle; // e.g. 'ufc', 'basketball', 'manga', etc.
  final String? borderStyle; // e.g. 'diamond', 'gold', etc.
  final String? overlayEffect; // e.g. 'embers', 'snow', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  const TradingCard({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.fighterId,
    this.fighterName,
    this.imageUrl,
    this.gender,
    this.backgroundUrl,
    required this.cardType,
    required this.title,
    required this.subtitle,
    required this.stats,
    this.cardStyle,
    this.borderStyle,
    this.overlayEffect,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TradingCard.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TradingCard(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      ownerName: d['ownerName'] ?? '',
      fighterId: d['fighterId'],
      fighterName: d['fighterName'],
      imageUrl: d['imageUrl'],
      gender: d['gender'],
      backgroundUrl: d['backgroundUrl'],
      cardType: d['cardType'] ?? 'profile',
      title: d['title'] ?? '',
      subtitle: d['subtitle'] ?? '',
      stats: Map<String, dynamic>.from(d['stats'] ?? {}),
      cardStyle: d['cardStyle'],
      borderStyle: d['borderStyle'],
      overlayEffect: d['overlayEffect'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ownerId': ownerId,
    'ownerName': ownerName,
    'fighterId': fighterId,
    'fighterName': fighterName,
    'imageUrl': imageUrl,
    'gender': gender,
    'backgroundUrl': backgroundUrl,
    'cardType': cardType,
    'title': title,
    'subtitle': subtitle,
    'stats': stats,
    'cardStyle': cardStyle,
    'borderStyle': borderStyle,
    'overlayEffect': overlayEffect,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  @override
  List<Object?> get props => [
    id,
    ownerId,
    cardType,
    title,
    subtitle,
    stats,
    gender,
  ];
}
