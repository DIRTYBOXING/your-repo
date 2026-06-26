import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Article types matching the DFC Content Factory spec
enum DfcArticleType {
  eventAnnouncement,
  eventHypeFeature,
  resultsRecap,
  fighterStory,
  promoterProfile,
  cityFeature,
  bkfcSpecial,
}

/// Article statuses for the editorial pipeline
enum DfcArticleStatus { draftAi, draftManual, published, archived }

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ARTICLE MODEL — Production editorial content with AI pipeline
///
/// AI generates → DRAFT_AI → editor reviews → PUBLISHED → feeds pull it
/// Every article links to events, fighters, and approved images.
/// ═══════════════════════════════════════════════════════════════════════════
class DfcArticleModel extends Equatable {
  final String id;
  final String slug;
  final String title;
  final String? subtitle;
  final String bodyMarkdown;
  final DfcArticleType type;
  final DfcArticleStatus status;
  final String? eventId;
  final String? primaryImageId;
  final List<String> imageIds;
  final List<String> relatedFighterIds;
  final List<String> relatedEventIds;
  final List<String> tags;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const DfcArticleModel({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle,
    required this.bodyMarkdown,
    required this.type,
    required this.status,
    this.eventId,
    this.primaryImageId,
    this.imageIds = const [],
    this.relatedFighterIds = const [],
    this.relatedEventIds = const [],
    this.tags = const [],
    this.createdBy = 'dfc_ai_engine',
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  @override
  List<Object?> get props => [id, slug, type, status];

  bool get isPublished => status == DfcArticleStatus.published;

  factory DfcArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DfcArticleType typeFromString(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'event_announcement':
          return DfcArticleType.eventAnnouncement;
        case 'event_hype_feature':
          return DfcArticleType.eventHypeFeature;
        case 'results_recap':
          return DfcArticleType.resultsRecap;
        case 'fighter_story':
          return DfcArticleType.fighterStory;
        case 'promoter_profile':
          return DfcArticleType.promoterProfile;
        case 'city_feature':
          return DfcArticleType.cityFeature;
        case 'bkfc_special':
          return DfcArticleType.bkfcSpecial;
        default:
          return DfcArticleType.eventAnnouncement;
      }
    }

    DfcArticleStatus statusFromString(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'draft_ai':
          return DfcArticleStatus.draftAi;
        case 'draft_manual':
          return DfcArticleStatus.draftManual;
        case 'published':
          return DfcArticleStatus.published;
        case 'archived':
          return DfcArticleStatus.archived;
        default:
          return DfcArticleStatus.draftManual;
      }
    }

    DateTime ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return DfcArticleModel(
      id: doc.id,
      slug: (data['slug'] ?? doc.id).toString(),
      title: (data['title'] ?? '').toString(),
      subtitle: data['subtitle']?.toString(),
      bodyMarkdown: (data['bodyMarkdown'] ?? data['content'] ?? '').toString(),
      type: typeFromString(data['type']?.toString()),
      status: statusFromString(data['status']?.toString()),
      eventId: data['eventId']?.toString(),
      primaryImageId: data['primaryImageId']?.toString(),
      imageIds: (data['imageIds'] as List?)?.cast<String>() ?? const [],
      relatedFighterIds:
          (data['relatedFighterIds'] as List?)?.cast<String>() ?? const [],
      relatedEventIds:
          (data['relatedEventIds'] as List?)?.cast<String>() ?? const [],
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      createdBy: (data['createdBy'] ?? 'dfc_ai_engine').toString(),
      updatedBy: data['updatedBy']?.toString(),
      createdAt: ts(data['createdAt']),
      updatedAt: ts(data['updatedAt']),
      publishedAt: data['publishedAt'] != null ? ts(data['publishedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    String typeToString(DfcArticleType t) {
      switch (t) {
        case DfcArticleType.eventAnnouncement:
          return 'event_announcement';
        case DfcArticleType.eventHypeFeature:
          return 'event_hype_feature';
        case DfcArticleType.resultsRecap:
          return 'results_recap';
        case DfcArticleType.fighterStory:
          return 'fighter_story';
        case DfcArticleType.promoterProfile:
          return 'promoter_profile';
        case DfcArticleType.cityFeature:
          return 'city_feature';
        case DfcArticleType.bkfcSpecial:
          return 'bkfc_special';
      }
    }

    String statusToString(DfcArticleStatus s) {
      switch (s) {
        case DfcArticleStatus.draftAi:
          return 'draft_ai';
        case DfcArticleStatus.draftManual:
          return 'draft_manual';
        case DfcArticleStatus.published:
          return 'published';
        case DfcArticleStatus.archived:
          return 'archived';
      }
    }

    return {
      'slug': slug,
      'title': title,
      'subtitle': subtitle,
      'bodyMarkdown': bodyMarkdown,
      'type': typeToString(type),
      'status': statusToString(status),
      'eventId': eventId,
      'primaryImageId': primaryImageId,
      'imageIds': imageIds,
      'relatedFighterIds': relatedFighterIds,
      'relatedEventIds': relatedEventIds,
      'tags': tags,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      'isPublished': status == DfcArticleStatus.published,
    };
  }
}
