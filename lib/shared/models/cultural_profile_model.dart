import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Combat Role - Everyone in the fight ecosystem
enum CombatRole {
  fighter,
  coach,
  mentor,
  promoter,
  mc, // Bruce Buffer, Michael Schiavello
  announcer,
  ringmaster,
  referee,
  judge,
  doctor,
  cutman,
  matchmaker,
  commissioner,
  mediaPersonnel,
  gymOwner,
  communityLeader,
}

/// Honour types - Recognition without politics
enum HonourType {
  voiceOfAGeneration, // Legendary MCs
  lifetimeContribution, // Long service
  grassrootsPillar, // Local community
  communityMentor, // Helping others
  safetyChampion, // Protecting fighters
  internationalAmbassador, // Global reach
  legendaryStatus, // Hall of fame level
  risingVoice, // Emerging talent
}

/// Honour - Recognition earned
class Honour extends Equatable {
  final String title;
  final HonourType type;
  final String? awardedBy; // 'COMMUNITY', 'PROMOTION', 'SYSTEM'
  final int? year;
  final String? description;

  const Honour({
    required this.title,
    required this.type,
    this.awardedBy,
    this.year,
    this.description,
  });

  factory Honour.fromMap(Map<String, dynamic> map) {
    return Honour(
      title: map['title'] ?? '',
      type: HonourType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => HonourType.communityMentor,
      ),
      awardedBy: map['awardedBy'],
      year: map['year'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.name,
      'awardedBy': awardedBy,
      'year': year,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [title, type, year];
}

/// Cultural Profile - MCs, refs, mentors, legends
class CulturalProfile extends Equatable {
  final String id;
  final String name;
  final CombatRole role;
  final String knownFor;
  final String? bio;
  final String? photoUrl;

  final List<String> associatedPromotions;
  final List<String> signatureMoments;
  final List<String> disciplines; // Boxing, MMA, etc
  final List<Honour> honours;

  final String? philosophy;
  final List<String> eras; // 1990s, 2000s, etc

  final bool verified;
  final bool isActive;
  final bool isFallen; // Memorial

  final String? country;
  final String? region;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CulturalProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.knownFor,
    this.bio,
    this.photoUrl,
    this.associatedPromotions = const [],
    this.signatureMoments = const [],
    this.disciplines = const [],
    this.honours = const [],
    this.philosophy,
    this.eras = const [],
    this.verified = false,
    this.isActive = true,
    this.isFallen = false,
    this.country,
    this.region,
    this.createdAt,
    this.updatedAt,
  });

  factory CulturalProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CulturalProfile(
      id: doc.id,
      name: data['name'] ?? '',
      role: CombatRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => CombatRole.communityLeader,
      ),
      knownFor: data['knownFor'] ?? '',
      bio: data['bio'],
      photoUrl: data['photoUrl'],
      associatedPromotions: List<String>.from(
        data['associatedPromotions'] ?? [],
      ),
      signatureMoments: List<String>.from(data['signatureMoments'] ?? []),
      disciplines: List<String>.from(data['disciplines'] ?? []),
      honours:
          (data['honours'] as List<dynamic>?)
              ?.map((h) => Honour.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
      philosophy: data['philosophy'],
      eras: List<String>.from(data['eras'] ?? []),
      verified: data['verified'] ?? false,
      isActive: data['isActive'] ?? true,
      isFallen: data['isFallen'] ?? false,
      country: data['country'],
      region: data['region'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'role': role.name,
      'knownFor': knownFor,
      'bio': bio,
      'photoUrl': photoUrl,
      'associatedPromotions': associatedPromotions,
      'signatureMoments': signatureMoments,
      'disciplines': disciplines,
      'honours': honours.map((h) => h.toMap()).toList(),
      'philosophy': philosophy,
      'eras': eras,
      'verified': verified,
      'isActive': isActive,
      'isFallen': isFallen,
      'country': country,
      'region': region,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, name, role, verified];
}

/// Seed data for legends - Editorial recognition, not impersonation
class CultureSeedData {
  static const bruceBuffer = CulturalProfile(
    id: 'bruce_buffer',
    name: 'Bruce Buffer',
    role: CombatRole.mc,
    knownFor: 'The Voice of the UFC and iconic fight introductions.',
    bio:
        'Legendary octagon announcer who transformed fight introductions into an art form.',
    associatedPromotions: ['UFC'],
    signatureMoments: [
      '"IIIIIT\'S TIIIIIME"',
      'UFC debut 1996',
      'UFC Hall of Fame',
    ],
    disciplines: ['MMA'],
    honours: [
      Honour(
        title: 'Voice of a Generation',
        type: HonourType.voiceOfAGeneration,
        awardedBy: 'COMMUNITY',
        year: 2020,
      ),
      Honour(
        title: 'UFC Hall of Fame Contributor',
        type: HonourType.legendaryStatus,
        awardedBy: 'UFC',
        year: 2020,
      ),
    ],
    philosophy: 'Energy, respect, and professionalism in every introduction.',
    eras: ['1990s', '2000s', '2010s', '2020s'],
    verified: true,
    country: 'USA',
  );

  static const michaelSchiavello = CulturalProfile(
    id: 'michael_schiavello',
    name: 'Michael Schiavello',
    role: CombatRole.announcer,
    knownFor: 'Legendary voice of ONE Championship and combat storytelling.',
    bio:
        'Australian commentator known for bringing passion, poetry, and respect to martial arts broadcasting.',
    associatedPromotions: ['ONE Championship', 'K-1', 'GLORY'],
    signatureMoments: [
      '"GOODNIGHT IRENE!"',
      'K-1 broadcasts',
      'ONE Championship commentary',
    ],
    disciplines: ['MMA', 'Kickboxing', 'Muay Thai'],
    honours: [
      Honour(
        title: 'Voice of Martial Arts in Asia',
        type: HonourType.voiceOfAGeneration,
        awardedBy: 'COMMUNITY',
      ),
      Honour(
        title: 'Combat Sports Historian',
        type: HonourType.lifetimeContribution,
        awardedBy: 'COMMUNITY',
      ),
    ],
    philosophy: 'Martial arts is storytelling. Every fight has a narrative.',
    eras: ['2000s', '2010s', '2020s'],
    verified: true,
    country: 'Australia',
  );

  static const List<CulturalProfile> allSeeds = [
    bruceBuffer,
    michaelSchiavello,
  ];
}
