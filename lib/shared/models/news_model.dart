import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// News article model for combat sports news
class NewsModel extends Equatable {
  final String id;
  final String authorId;
  final String title;
  final String summary;
  final String content;
  final String? featuredImageUrl;
  final List<String> mediaUrls;
  final List<String> tags;
  final List<String> categories;
  final String? sourceUrl;
  final String? sourceName;
  final List<String> relatedFighterIds;
  final List<String> relatedEventIds;
  final List<String> relatedGymIds;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isFeatured;
  final bool isBreakingNews;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? readTime; // e.g., "5 min read"
  final Map<String, dynamic>? seoMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NewsModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.summary,
    required this.content,
    this.featuredImageUrl,
    this.mediaUrls = const [],
    this.tags = const [],
    this.categories = const [],
    this.sourceUrl,
    this.sourceName,
    this.relatedFighterIds = const [],
    this.relatedEventIds = const [],
    this.relatedGymIds = const [],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isFeatured = false,
    this.isBreakingNews = false,
    this.isPublished = false,
    this.publishedAt,
    this.readTime,
    this.seoMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total engagement
  int get totalEngagement => likesCount + commentsCount + sharesCount;

  /// Has related content
  bool get hasRelatedContent =>
      relatedFighterIds.isNotEmpty ||
      relatedEventIds.isNotEmpty ||
      relatedGymIds.isNotEmpty;

  /// Calculate read time from content
  static String calculateReadTime(String content) {
    // Average reading speed: 200 words per minute
    final wordCount = content.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes min read';
  }

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      content: data['content'] ?? '',
      featuredImageUrl: data['featuredImageUrl'],
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      sourceUrl: data['sourceUrl'],
      sourceName: data['sourceName'],
      relatedFighterIds: List<String>.from(data['relatedFighterIds'] ?? []),
      relatedEventIds: List<String>.from(data['relatedEventIds'] ?? []),
      relatedGymIds: List<String>.from(data['relatedGymIds'] ?? []),
      viewsCount: data['viewsCount'] ?? 0,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      isBreakingNews: data['isBreakingNews'] ?? false,
      isPublished: data['isPublished'] ?? false,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      readTime: data['readTime'],
      seoMetadata: data['seoMetadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'title': title,
      'summary': summary,
      'content': content,
      'featuredImageUrl': featuredImageUrl,
      'mediaUrls': mediaUrls,
      'tags': tags,
      'categories': categories,
      'sourceUrl': sourceUrl,
      'sourceName': sourceName,
      'relatedFighterIds': relatedFighterIds,
      'relatedEventIds': relatedEventIds,
      'relatedGymIds': relatedGymIds,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isFeatured': isFeatured,
      'isBreakingNews': isBreakingNews,
      'isPublished': isPublished,
      'publishedAt': publishedAt != null
          ? Timestamp.fromDate(publishedAt!)
          : null,
      'readTime': readTime,
      'seoMetadata': seoMetadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NewsModel copyWith({
    String? id,
    String? authorId,
    String? title,
    String? summary,
    String? content,
    String? featuredImageUrl,
    List<String>? mediaUrls,
    List<String>? tags,
    List<String>? categories,
    String? sourceUrl,
    String? sourceName,
    List<String>? relatedFighterIds,
    List<String>? relatedEventIds,
    List<String>? relatedGymIds,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isFeatured,
    bool? isBreakingNews,
    bool? isPublished,
    DateTime? publishedAt,
    String? readTime,
    Map<String, dynamic>? seoMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewsModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      relatedFighterIds: relatedFighterIds ?? this.relatedFighterIds,
      relatedEventIds: relatedEventIds ?? this.relatedEventIds,
      relatedGymIds: relatedGymIds ?? this.relatedGymIds,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isBreakingNews: isBreakingNews ?? this.isBreakingNews,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      readTime: readTime ?? this.readTime,
      seoMetadata: seoMetadata ?? this.seoMetadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, authorId, isPublished];
}
