import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CONTENT CONVEYOR BELT — High-Speed Content Processing Pipeline
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Automated content factory that:
///  1. Ingests raw content from multiple sources
///  2. Normalizes and categorizes via Gemini CF
///  3. Enriches with AI-generated metadata
///  4. Queues for moderation and approval
///  5. Auto-publishes approved content
///  6. Tracks content lifecycle metrics
///  7. Prioritizes based on engagement prediction
///  8. Wolverine Protocol: Auto-regenerates failed content
///
/// Pipeline Stages:
///  INTAKE → NORMALIZE → ENRICH → MODERATE → APPROVE → PUBLISH → ANALYZE
/// ═══════════════════════════════════════════════════════════════════════════

final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);
final _firestore = FirebaseFirestore.instance;

/// Content pipeline stages
enum PipelineStage {
  intake,
  normalize,
  enrich,
  moderate,
  approve,
  publish,
  analyze,
  failed,
  archived,
}

/// Content source types
enum ContentSource {
  userGenerated,
  aiGenerated,
  partnerFeed,
  newsScrape,
  socialImport,
  promoterSubmit,
  systemGenerated,
}

/// Content types for conveyor belt
enum ConveyorContentType {
  post,
  article,
  highlight,
  interview,
  analysis,
  prediction,
  promo,
  event,
  training,
  news,
}

/// Content priority levels
enum ContentPriority {
  critical, // Breaking news, live events
  high, // Featured content, top fighters
  normal, // Standard feed content
  low, // Archive material, filler
  background, // System maintenance content
}

/// Content item in the pipeline
class PipelineContent {
  final String id;
  final String title;
  final String body;
  final ConveyorContentType type;
  final ContentSource source;
  final PipelineStage stage;
  final ContentPriority priority;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final String? imageUrl;
  final String? videoUrl;
  final double? engagementScore;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? errorMessage;

  const PipelineContent({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.source,
    required this.stage,
    this.priority = ContentPriority.normal,
    this.metadata = const {},
    this.tags = const [],
    this.imageUrl,
    this.videoUrl,
    this.engagementScore,
    required this.createdAt,
    this.publishedAt,
    this.errorMessage,
  });

  PipelineContent copyWith({
    PipelineStage? stage,
    ContentPriority? priority,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    double? engagementScore,
    DateTime? publishedAt,
    String? errorMessage,
  }) => PipelineContent(
    id: id,
    title: title,
    body: body,
    type: type,
    source: source,
    stage: stage ?? this.stage,
    priority: priority ?? this.priority,
    metadata: metadata ?? this.metadata,
    tags: tags ?? this.tags,
    imageUrl: imageUrl,
    videoUrl: videoUrl,
    engagementScore: engagementScore ?? this.engagementScore,
    createdAt: createdAt,
    publishedAt: publishedAt ?? this.publishedAt,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'source': source.name,
    'stage': stage.name,
    'priority': priority.name,
    'metadata': metadata,
    'tags': tags,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'engagementScore': engagementScore,
    'createdAt': createdAt.toIso8601String(),
    'publishedAt': publishedAt?.toIso8601String(),
  };

  factory PipelineContent.fromMap(Map<String, dynamic> map) => PipelineContent(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    type: ConveyorContentType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => ConveyorContentType.post,
    ),
    source: ContentSource.values.firstWhere(
      (s) => s.name == map['source'],
      orElse: () => ContentSource.systemGenerated,
    ),
    stage: PipelineStage.values.firstWhere(
      (s) => s.name == map['stage'],
      orElse: () => PipelineStage.intake,
    ),
    priority: ContentPriority.values.firstWhere(
      (p) => p.name == map['priority'],
      orElse: () => ContentPriority.normal,
    ),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    tags: List<String>.from(map['tags'] ?? []),
    imageUrl: map['imageUrl'],
    videoUrl: map['videoUrl'],
    engagementScore: (map['engagementScore'] ?? 0).toDouble(),
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
    publishedAt: map['publishedAt'] != null
        ? DateTime.parse(map['publishedAt'])
        : null,
    errorMessage: map['errorMessage'],
  );
}

/// Pipeline processing result
class ProcessingResult {
  final String contentId;
  final PipelineStage fromStage;
  final PipelineStage toStage;
  final bool success;
  final String? message;
  final Map<String, dynamic>? enrichments;
  final DateTime processedAt;

  const ProcessingResult({
    required this.contentId,
    required this.fromStage,
    required this.toStage,
    required this.success,
    this.message,
    this.enrichments,
    required this.processedAt,
  });
}

/// Content Conveyor Belt Service
class ContentConveyorBelt with ChangeNotifier {
  static final ContentConveyorBelt _instance = ContentConveyorBelt._internal();
  factory ContentConveyorBelt() => _instance;
  ContentConveyorBelt._internal();

  bool _initialized = false;
  bool _isRunning = false;
  Timer? _conveyorTimer;

  // Pipeline queues by stage
  final Map<PipelineStage, Queue<PipelineContent>> _queues = {
    for (var stage in PipelineStage.values) stage: Queue<PipelineContent>(),
  };

  // Processing history
  final List<ProcessingResult> _history = [];

  // Stats
  int _totalProcessed = 0;
  int _totalFailed = 0;
  int _totalPublished = 0;

  // Getters
  bool get initialized => _initialized;
  bool get isRunning => _isRunning;
  int get totalProcessed => _totalProcessed;
  int get totalFailed => _totalFailed;
  int get totalPublished => _totalPublished;
  int get queuedCount => _queues.values.fold(0, (total, q) => total + q.length);

  /// Initialize the conveyor belt
  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('🏭 ContentConveyorBelt: Initializing...');
    _initialized = true;
    notifyListeners();
    debugPrint('🏭 ContentConveyorBelt: Ready to process');
  }

  /// Start the conveyor belt
  void start({Duration interval = const Duration(seconds: 5)}) {
    if (_isRunning) return;
    _isRunning = true;
    _conveyorTimer = Timer.periodic(interval, (_) => _processNextBatch());
    notifyListeners();
    debugPrint('🏭 ContentConveyorBelt: Started');
  }

  /// Stop the conveyor belt
  void stop() {
    _conveyorTimer?.cancel();
    _conveyorTimer = null;
    _isRunning = false;
    notifyListeners();
    debugPrint('🏭 ContentConveyorBelt: Stopped');
  }

  /// Add content to the intake queue
  Future<String> intake({
    required String title,
    required String body,
    required ConveyorContentType type,
    required ContentSource source,
    ContentPriority priority = ContentPriority.normal,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    String? imageUrl,
    String? videoUrl,
  }) async {
    final id = 'content_${DateTime.now().millisecondsSinceEpoch}';
    final content = PipelineContent(
      id: id,
      title: title,
      body: body,
      type: type,
      source: source,
      stage: PipelineStage.intake,
      priority: priority,
      metadata: metadata ?? {},
      tags: tags ?? [],
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      createdAt: DateTime.now(),
    );

    _queues[PipelineStage.intake]!.add(content);
    notifyListeners();
    debugPrint('🏭 ContentConveyorBelt: Intake - ${content.title}');
    return id;
  }

  /// Process content via Nuclear CF
  Future<ProcessingResult> processViaCF(PipelineContent content) async {
    try {
      final callable = _functions.httpsCallable('conveyorBeltProcess');
      final result = await callable.call<Map<String, dynamic>>({
        'contentId': content.id,
        'title': content.title,
        'body': content.body,
        'type': content.type.name,
        'source': content.source.name,
        'currentStage': content.stage.name,
        'priority': content.priority.name,
        'tags': content.tags,
      });

      if (result.data['processed'] != null) {
        final processed = result.data['processed'] as Map<String, dynamic>;
        return ProcessingResult(
          contentId: content.id,
          fromStage: content.stage,
          toStage: _getNextStage(content.stage),
          success: true,
          message: processed['message'] ?? 'Processed successfully',
          enrichments: processed['enrichments'] as Map<String, dynamic>?,
          processedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('ContentConveyorBelt: CF processing failed: $e');
    }

    return ProcessingResult(
      contentId: content.id,
      fromStage: content.stage,
      toStage: PipelineStage.failed,
      success: false,
      message: 'Processing failed',
      processedAt: DateTime.now(),
    );
  }

  /// Process next batch from queues
  Future<void> _processNextBatch() async {
    // Process in priority order: critical → high → normal → low → background
    for (final priority in ContentPriority.values) {
      for (final stage in [
        PipelineStage.intake,
        PipelineStage.normalize,
        PipelineStage.enrich,
        PipelineStage.moderate,
        PipelineStage.approve,
      ]) {
        final queue = _queues[stage]!;
        if (queue.isEmpty) continue;

        // Find items matching priority
        final toProcess = <PipelineContent>[];
        for (final content in queue) {
          if (content.priority == priority) {
            toProcess.add(content);
            if (toProcess.length >= 3) break; // Batch size
          }
        }

        // Process batch
        for (final content in toProcess) {
          queue.remove(content);
          await _processItem(content);
        }
      }
    }
  }

  /// Process a single item through pipeline
  Future<void> _processItem(PipelineContent content) async {
    final result = await processViaCF(content);
    _history.add(result);
    _totalProcessed++;

    if (result.success) {
      final nextStage = result.toStage;
      final enrichedContent = content.copyWith(
        stage: nextStage,
        metadata: result.enrichments != null
            ? {...content.metadata, ...result.enrichments!}
            : content.metadata,
        publishedAt: nextStage == PipelineStage.publish ? DateTime.now() : null,
      );

      if (nextStage == PipelineStage.publish) {
        await _publishContent(enrichedContent);
        _totalPublished++;
      } else if (nextStage != PipelineStage.analyze) {
        _queues[nextStage]!.add(enrichedContent);
      }
    } else {
      _totalFailed++;
      final failedContent = content.copyWith(
        stage: PipelineStage.failed,
        errorMessage: result.message,
      );
      _queues[PipelineStage.failed]!.add(failedContent);
    }

    notifyListeners();
  }

  /// Get next stage in pipeline
  PipelineStage _getNextStage(PipelineStage current) {
    switch (current) {
      case PipelineStage.intake:
        return PipelineStage.normalize;
      case PipelineStage.normalize:
        return PipelineStage.enrich;
      case PipelineStage.enrich:
        return PipelineStage.moderate;
      case PipelineStage.moderate:
        return PipelineStage.approve;
      case PipelineStage.approve:
        return PipelineStage.publish;
      case PipelineStage.publish:
        return PipelineStage.analyze;
      default:
        return current;
    }
  }

  /// Publish content to Firestore
  Future<void> _publishContent(PipelineContent content) async {
    try {
      final mediaUrls =
          content.imageUrl != null && content.imageUrl!.isNotEmpty
              ? <String>[content.imageUrl!]
              : <String>[];
      await _firestore.collection('posts').doc(content.id).set({
        ...content.toMap(),
        'mediaUrls': mediaUrls,
        'thumbnailUrl': mediaUrls.isNotEmpty ? mediaUrls.first : null,
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🏭 ContentConveyorBelt: Published - ${content.title}');
    } catch (e) {
      debugPrint('ContentConveyorBelt: Publish failed: $e');
    }
  }

  /// Retry failed content
  Future<void> retryFailed() async {
    final failedQueue = _queues[PipelineStage.failed]!;
    final toRetry = failedQueue.toList();
    failedQueue.clear();

    for (final content in toRetry) {
      final retryContent = content.copyWith(
        stage: PipelineStage.intake,
      );
      _queues[PipelineStage.intake]!.add(retryContent);
    }

    notifyListeners();
    debugPrint(
      '🏭 ContentConveyorBelt: Retrying ${toRetry.length} failed items',
    );
  }

  /// Get queue status
  Map<String, int> getQueueStatus() => {
    for (var entry in _queues.entries) entry.key.name: entry.value.length,
  };

  /// Get pipeline stats
  Map<String, dynamic> getPipelineStats() => {
    'isRunning': _isRunning,
    'totalProcessed': _totalProcessed,
    'totalFailed': _totalFailed,
    'totalPublished': _totalPublished,
    'successRate': _totalProcessed > 0
        ? ((_totalProcessed - _totalFailed) / _totalProcessed * 100)
              .toStringAsFixed(1)
        : '0',
    'queueStatus': getQueueStatus(),
    'recentHistory': _history
        .take(10)
        .map(
          (r) => {
            'contentId': r.contentId,
            'from': r.fromStage.name,
            'to': r.toStage.name,
            'success': r.success,
          },
        )
        .toList(),
  };

  /// Bulk intake from source
  Future<List<String>> bulkIntake({
    required List<Map<String, dynamic>> items,
    required ContentSource source,
    ContentPriority priority = ContentPriority.normal,
  }) async {
    final ids = <String>[];
    for (final item in items) {
      final id = await intake(
        title: item['title'] ?? 'Untitled',
        body: item['body'] ?? '',
        type: ConveyorContentType.values.firstWhere(
          (t) => t.name == item['type'],
          orElse: () => ConveyorContentType.post,
        ),
        source: source,
        priority: priority,
        metadata: item['metadata'] as Map<String, dynamic>?,
        tags: List<String>.from(item['tags'] ?? []),
        imageUrl: item['imageUrl'],
        videoUrl: item['videoUrl'],
      );
      ids.add(id);
    }
    return ids;
  }

  /// Get content by ID from any queue
  PipelineContent? findContent(String id) {
    for (final queue in _queues.values) {
      for (final content in queue) {
        if (content.id == id) return content;
      }
    }
    return null;
  }

  /// Fast-track content to publish (skip moderation)
  Future<void> fastTrack(String contentId) async {
    final content = findContent(contentId);
    if (content == null) return;

    // Remove from current queue
    _queues[content.stage]!.remove(content);

    // Add directly to approve queue with high priority
    final fastContent = content.copyWith(
      stage: PipelineStage.approve,
      priority: ContentPriority.high,
    );
    _queues[PipelineStage.approve]!.addFirst(fastContent);
    notifyListeners();
    debugPrint('🏭 ContentConveyorBelt: Fast-tracked - ${content.title}');
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
