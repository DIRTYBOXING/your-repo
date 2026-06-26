import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/image_assets.dart';

/// Full event lifecycle: draft → announced → onSale → upcoming → live → results → completed → archived → canceled
enum EventStatus {
  draft,
  announced,
  onSale,
  upcoming,
  live,
  results,
  completed,
  archived,
  canceled,
}

class EventModel {
  final String id;
  final String promoterId;
  final String name;
  final String? description;
  final String venue;
  final String city;
  final String? state;
  final String country;
  final DateTime eventDate;
  final DateTime? mainCardTime;
  final String? sportType;
  final EventStatus status;
  final String? posterUrl;
  final String? thumbnailUrl;
  final String? bannerUrl;
  final double? posterAspectRatio;
  final String? broadcastInfo;
  final String? streamUrl;
  final String? replayUrl;
  final String? ticketUrl;
  final bool? isFeatured;
  final List<String> fightIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Promotion name (e.g. BKFC, UFC, Cage Warriors)
  final String? promotionName;

  /// Source of this event data
  final String source; // manual, promoter_portal, api_import, csv_import

  /// Related image IDs for this event
  final List<String> imageIds;

  /// Canonical media asset IDs attached to this event.
  final List<String> mediaIds;

  /// Primary poster media asset ID for audit-safe event poster workflows.
  final String? posterMediaId;

  /// Sponsor logos/names displayed on the event card/poster
  /// Each entry is a Map with {name, logoUrl} — logoUrl is optional.
  final List<Map<String, String>> sponsors;

  const EventModel({
    required this.id,
    required this.promoterId,
    required this.name,
    this.description,
    required this.venue,
    required this.city,
    this.state,
    required this.country,
    required this.eventDate,
    this.mainCardTime,
    this.sportType,
    this.status = EventStatus.upcoming,
    this.posterUrl,
    this.thumbnailUrl,
    this.bannerUrl,
    this.posterAspectRatio,
    this.broadcastInfo,
    this.streamUrl,
    this.replayUrl,
    this.ticketUrl,
    this.isFeatured,
    this.fightIds = const [],
    this.promotionName,
    this.source = 'manual',
    this.imageIds = const [],
    this.mediaIds = const [],
    this.posterMediaId,
    this.sponsors = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get fullLocation {
    final parts =
        [venue, city, if (state != null && state!.isNotEmpty) state, country]
            .where((e) => (e ?? '').toString().isNotEmpty)
            .map((e) => e!.toString())
            .toList();
    return parts.join(', ');
  }

  // Compatibility getters for legacy code paths
  bool get isLive => status == EventStatus.live;
  String? get streamingPlatform => broadcastInfo;
  String? get primaryPosterUrl =>
      _preferredArtworkUrl(posterUrl, thumbnailUrl, bannerUrl);
  String? get primaryThumbnailUrl =>
      _preferredArtworkUrl(thumbnailUrl, posterUrl, bannerUrl);
  String? get primaryBannerUrl =>
      _preferredArtworkUrl(bannerUrl, posterUrl, thumbnailUrl);
  double get effectivePosterAspectRatio => posterAspectRatio ?? (2 / 3);
  DateTime get date => eventDate;
  String get title => name;
  String get promoter => promoterId;

  String? _preferredArtworkUrl(
    String? primary,
    String? secondary,
    String? tertiary,
  ) {
    final candidates = [primary, secondary, tertiary]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    for (final candidate in candidates) {
      if (!ImageAssets.isGenericPosterAsset(candidate)) {
        return candidate;
      }
    }

    return candidates.isEmpty ? null : candidates.first;
  }

  EventModel copyWith({
    String? id,
    String? promoterId,
    String? name,
    String? description,
    String? venue,
    String? city,
    String? state,
    String? country,
    DateTime? eventDate,
    DateTime? mainCardTime,
    String? sportType,
    EventStatus? status,
    String? posterUrl,
    String? thumbnailUrl,
    String? bannerUrl,
    double? posterAspectRatio,
    String? broadcastInfo,
    String? streamUrl,
    String? replayUrl,
    String? ticketUrl,
    bool? isFeatured,
    List<String>? fightIds,
    String? promotionName,
    String? source,
    List<String>? imageIds,
    List<String>? mediaIds,
    String? posterMediaId,
    List<Map<String, String>>? sponsors,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      promoterId: promoterId ?? this.promoterId,
      name: name ?? this.name,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      eventDate: eventDate ?? this.eventDate,
      mainCardTime: mainCardTime ?? this.mainCardTime,
      sportType: sportType ?? this.sportType,
      status: status ?? this.status,
      posterUrl: posterUrl ?? this.posterUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      posterAspectRatio: posterAspectRatio ?? this.posterAspectRatio,
      broadcastInfo: broadcastInfo ?? this.broadcastInfo,
      streamUrl: streamUrl ?? this.streamUrl,
      replayUrl: replayUrl ?? this.replayUrl,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      fightIds: fightIds ?? this.fightIds,
      promotionName: promotionName ?? this.promotionName,
      source: source ?? this.source,
      imageIds: imageIds ?? this.imageIds,
      mediaIds: mediaIds ?? this.mediaIds,
      posterMediaId: posterMediaId ?? this.posterMediaId,
      sponsors: sponsors ?? this.sponsors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    // Map status string to enum
    EventStatus statusFromString(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'draft':
          return EventStatus.draft;
        case 'announced':
          return EventStatus.announced;
        case 'on_sale':
        case 'onsale':
          return EventStatus.onSale;
        case 'live':
          return EventStatus.live;
        case 'results':
          return EventStatus.results;
        case 'completed':
          return EventStatus.completed;
        case 'archived':
          return EventStatus.archived;
        case 'canceled':
          return EventStatus.canceled;
        case 'upcoming':
        default:
          return EventStatus.upcoming;
      }
    }

    DateTime ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    double? ratio(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return EventModel(
      id: doc.id,
      promoterId: (data['promoterId'] ?? data['promoter'] ?? '').toString(),
      name: (data['name'] ?? data['title'] ?? 'Event').toString(),
      description: data['description']?.toString(),
      venue: (data['venue'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      state: data['state']?.toString(),
      country: (data['country'] ?? '').toString(),
      eventDate: data['eventDate'] != null
          ? ts(data['eventDate'])
          : ts(data['date']),
      mainCardTime: data['mainCardTime'] != null
          ? ts(data['mainCardTime'])
          : null,
      sportType: data['sportType']?.toString(),
      status: statusFromString(data['status']?.toString()),
      posterUrl:
          data['posterUrl']?.toString() ??
          data['imageUrl']?.toString() ??
          data['heroImageUrl']?.toString(),
      thumbnailUrl:
          data['thumbnailUrl']?.toString() ??
          data['thumbUrl']?.toString() ??
          data['posterThumbUrl']?.toString(),
      bannerUrl:
          data['bannerUrl']?.toString() ??
          data['heroImageUrl']?.toString() ??
          data['coverImageUrl']?.toString(),
      posterAspectRatio:
          ratio(data['posterAspectRatio']) ?? ratio(data['aspectRatio']),
      broadcastInfo: (data['broadcastInfo'] ?? data['streamUrl'])?.toString(),
      streamUrl: data['streamUrl']?.toString(),
      replayUrl: data['replayUrl']?.toString(),
      ticketUrl: (data['ticketUrl'] ?? data['ticketsUrl'])?.toString(),
      isFeatured: data['isFeatured'] == null
          ? null
          : (data['isFeatured'] as bool? ?? false),
      fightIds: (data['fightIds'] as List?)?.cast<String>() ?? const [],
      promotionName: data['promotionName']?.toString(),
      source: (data['source'] ?? 'manual').toString(),
      imageIds: (data['imageIds'] as List?)?.cast<String>() ?? const [],
      mediaIds:
          (data['mediaIds'] as List?)?.cast<String>() ??
          (data['imageIds'] as List?)?.cast<String>() ??
          const [],
      posterMediaId: data['posterMediaId']?.toString(),
      sponsors:
          (data['sponsors'] as List?)
              ?.map((s) => Map<String, String>.from(s as Map))
              .toList() ??
          const [],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'promoterId': promoterId,
      'name': name,
      'description': description,
      'venue': venue,
      'city': city,
      'state': state,
      'country': country,
      'eventDate': Timestamp.fromDate(eventDate),
      if (mainCardTime != null)
        'mainCardTime': Timestamp.fromDate(mainCardTime!),
      'sportType': sportType,
      'status': status.name,
      'posterUrl': posterUrl,
      'thumbnailUrl': thumbnailUrl,
      'bannerUrl': bannerUrl,
      'posterAspectRatio': posterAspectRatio,
      'broadcastInfo': broadcastInfo,
      'streamUrl': streamUrl,
      'replayUrl': replayUrl,
      'ticketUrl': ticketUrl,
      'isFeatured': isFeatured ?? false,
      'fightIds': fightIds,
      'promotionName': promotionName,
      'source': source,
      'imageIds': imageIds,
      'mediaIds': mediaIds.isNotEmpty ? mediaIds : imageIds,
      'posterMediaId': posterMediaId,
      if (sponsors.isNotEmpty) 'sponsors': sponsors,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
