import 'package:cloud_firestore/cloud_firestore.dart';

class SourceTrustProfile {
  final String key;
  final String label;
  final List<String> domains;
  final double trustScore;
  final double rankingWeight;
  final bool highPriority;

  const SourceTrustProfile({
    required this.key,
    required this.label,
    required this.domains,
    required this.trustScore,
    this.rankingWeight = 1.0,
    this.highPriority = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'domains': domains,
      'trustScore': trustScore,
      'rankingWeight': rankingWeight,
      'highPriority': highPriority,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SourceTrustProfile.fromMap(Map<String, dynamic> data) {
    return SourceTrustProfile(
      key: (data['key'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
      domains: ((data['domains'] as List?) ?? const [])
          .map((domain) => domain.toString().toLowerCase())
          .where((domain) => domain.isNotEmpty)
          .toList(),
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 0.0,
      rankingWeight: (data['rankingWeight'] as num?)?.toDouble() ?? 1.0,
      highPriority: data['highPriority'] == true,
    );
  }

  SourceTrustProfile copyWith({
    String? key,
    String? label,
    List<String>? domains,
    double? trustScore,
    double? rankingWeight,
    bool? highPriority,
  }) {
    return SourceTrustProfile(
      key: key ?? this.key,
      label: label ?? this.label,
      domains: domains ?? this.domains,
      trustScore: trustScore ?? this.trustScore,
      rankingWeight: rankingWeight ?? this.rankingWeight,
      highPriority: highPriority ?? this.highPriority,
    );
  }
}

class SourceTrustDecision {
  final bool approved;
  final double trustScore;
  final double rankingWeight;
  final String profileKey;
  final String reason;
  final bool highPriority;

  const SourceTrustDecision({
    required this.approved,
    required this.trustScore,
    required this.rankingWeight,
    required this.profileKey,
    required this.reason,
    required this.highPriority,
  });
}

/// Central trust rules for external feed sources.
class SourceTrustRulesService {
  static const String collectionName = 'feed_source_trust_profiles';

  static final SourceTrustRulesService _instance =
      SourceTrustRulesService._internal();
  factory SourceTrustRulesService() => _instance;
  SourceTrustRulesService._internal();

  List<SourceTrustProfile>? _cachedProfiles;
  bool _seedAttempted = false;

  static const List<SourceTrustProfile> defaultProfiles = [
    SourceTrustProfile(
      key: 'dfc_owned',
      label: 'Data Fight Central',
      domains: [
        'datafightcentral.web.app',
        'www.datafightcentral.web.app',
        'datafightcentral.com',
        'www.datafightcentral.com',
      ],
      trustScore: 0.97,
      rankingWeight: 1.5,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'ufc',
      label: 'UFC',
      domains: ['ufc.com', 'www.ufc.com'],
      trustScore: 0.98,
      rankingWeight: 1.45,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'espn_mma',
      label: 'ESPN MMA',
      domains: ['espn.com', 'www.espn.com'],
      trustScore: 0.93,
      rankingWeight: 1.2,
    ),
    SourceTrustProfile(
      key: 'one',
      label: 'ONE Championship',
      domains: ['onefc.com', 'www.onefc.com'],
      trustScore: 0.95,
      rankingWeight: 1.35,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'paramount_studio',
      label: 'Paramount Studio',
      domains: ['paramount.com', 'www.paramount.com'],
      trustScore: 0.94,
      rankingWeight: 1.3,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'youtube_combat',
      label: 'YouTube Combat',
      domains: ['youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be'],
      trustScore: 0.88,
      rankingWeight: 1.1,
    ),
    SourceTrustProfile(
      key: 'instagram_partner',
      label: 'Instagram Partner',
      // Content shared to DFC by the account owner is lawfully cleared
      // for promotional use (events, posters, fight cards).
      domains: ['instagram.com', 'www.instagram.com', 'cdninstagram.com'],
      trustScore: 0.92,
      rankingWeight: 1.3,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'eventbrite',
      label: 'Eventbrite',
      domains: ['eventbrite.com', 'www.eventbrite.com'],
      trustScore: 0.84,
      rankingWeight: 1.08,
    ),
    SourceTrustProfile(
      key: 'ultimate_legends',
      label: 'Ultimate Legends',
      domains: ['ultimatelegends.com.au', 'www.ultimatelegends.com.au'],
      trustScore: 0.95,
      rankingWeight: 1.65,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'aussie_promoters',
      label: 'Australian Promoter Network',
      domains: [],
      trustScore: 0.91,
      rankingWeight: 1.35,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'dfc_partner_promotions',
      label: 'DFC Partner Promotions',
      domains: [],
      trustScore: 0.93,
      rankingWeight: 1.45,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'facebook_partner',
      label: 'Facebook Partner',
      // Content shared to DFC by the account owner is lawfully cleared
      // for promotional use (events, posters, fight cards).
      domains: [
        'facebook.com',
        'www.facebook.com',
        'm.facebook.com',
        'fbcdn.net',
      ],
      trustScore: 0.92,
      rankingWeight: 1.3,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'bkfc',
      label: 'BKFC',
      domains: ['bareknuckle.tv', 'www.bareknuckle.tv'],
      trustScore: 0.9,
      rankingWeight: 1.25,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'rizin',
      label: 'RIZIN Fighting Federation',
      domains: ['rizinff.com', 'www.rizinff.com', 'rizin.com'],
      trustScore: 0.95,
      rankingWeight: 1.4,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'paramount_plus',
      label: 'Paramount+ Streaming',
      domains: [
        'paramountplus.com',
        'www.paramountplus.com',
        'support.paramountplus.com',
      ],
      trustScore: 0.95,
      rankingWeight: 1.4,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'misfit_mafia_bkfc',
      label: 'Misfit Mafia / Christine Ferea',
      domains: [],
      trustScore: 0.91,
      rankingWeight: 1.4,
      highPriority: true,
    ),
    SourceTrustProfile(
      key: 'bunty_boxer',
      label: 'Bunty Boxer / Aussie Combat',
      domains: [],
      trustScore: 0.89,
      rankingWeight: 1.3,
      highPriority: true,
    ),
  ];

  Future<void> ensureProfilesSeeded() async {
    if (_seedAttempted) {
      return;
    }
    _seedAttempted = true;

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection(collectionName)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return;
      }

      final batch = firestore.batch();
      for (final profile in defaultProfiles) {
        final ref = firestore.collection(collectionName).doc(profile.key);
        batch.set(ref, profile.toMap());
      }
      await batch.commit();
    } catch (_) {
      // Fall back to in-memory defaults when Firestore is unavailable.
    }
  }

  Future<List<SourceTrustProfile>> getProfiles({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedProfiles != null) {
      return _cachedProfiles!;
    }

    await ensureProfilesSeeded();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();
      if (snapshot.docs.isEmpty) {
        _cachedProfiles = defaultProfiles;
      } else {
        _cachedProfiles =
            snapshot.docs
                .map((doc) => SourceTrustProfile.fromMap(doc.data()))
                .where((profile) => profile.key.isNotEmpty)
                .toList()
              ..sort(
                (left, right) => right.trustScore.compareTo(left.trustScore),
              );
      }
    } catch (_) {
      _cachedProfiles = defaultProfiles;
    }

    return _cachedProfiles!;
  }

  Stream<List<SourceTrustProfile>> streamProfiles() async* {
    await ensureProfilesSeeded();

    try {
      yield* FirebaseFirestore.instance
          .collection(collectionName)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return defaultProfiles;
            }

            return snapshot.docs
                .map((doc) => SourceTrustProfile.fromMap(doc.data()))
                .where((profile) => profile.key.isNotEmpty)
                .toList()
              ..sort(
                (left, right) => right.trustScore.compareTo(left.trustScore),
              );
          });
    } catch (_) {
      yield defaultProfiles;
    }
  }

  Future<void> upsertProfile(SourceTrustProfile profile) async {
    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(profile.key)
        .set(profile.toMap(), SetOptions(merge: true));
    _cachedProfiles = null;
  }

  Future<SourceTrustDecision> assess({
    String? url,
    required String source,
  }) async {
    final profiles = await getProfiles();
    final uri = url == null ? null : Uri.tryParse(url);
    final host = uri?.host.toLowerCase();

    if (host != null && host.isNotEmpty) {
      for (final profile in profiles) {
        if (profile.domains.contains(host)) {
          return SourceTrustDecision(
            approved: true,
            trustScore: profile.trustScore,
            rankingWeight: profile.rankingWeight,
            profileKey: profile.key,
            reason: 'Trusted domain match: $host',
            highPriority: profile.highPriority,
          );
        }
      }
    }

    final normalizedSource = source.toLowerCase();
    for (final profile in profiles) {
      if (normalizedSource.contains(profile.label.toLowerCase()) ||
          normalizedSource.contains(profile.key.replaceAll('_', ' '))) {
        return SourceTrustDecision(
          approved: true,
          trustScore: (profile.trustScore - 0.05).clamp(0.0, 1.0),
          rankingWeight: profile.rankingWeight,
          profileKey: profile.key,
          reason: 'Trusted source label match: $source',
          highPriority: profile.highPriority,
        );
      }
    }

    return const SourceTrustDecision(
      approved: false,
      trustScore: 0.0,
      rankingWeight: 0.0,
      profileKey: 'untrusted',
      reason: 'Source did not match trusted profiles',
      highPriority: false,
    );
  }
}
