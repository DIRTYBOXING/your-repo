import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/image_assets.dart';
import '../../core/utils/app_logger.dart';
import '../models/event_model.dart';
import '../models/media_asset_model.dart';
import '../models/ppv_model.dart';
import 'media_visibility_service.dart';

class CanonicalEventGraph {
  final List<String> eventIds;
  final List<String> ppvIds;
  final List<String> mediaAssetIds;
  final List<String> matchSignals;
  final String? primaryPosterUrl;
  final String? primaryThumbnailUrl;
  final String? primaryBannerUrl;

  const CanonicalEventGraph({
    required this.eventIds,
    required this.ppvIds,
    required this.mediaAssetIds,
    required this.matchSignals,
    this.primaryPosterUrl,
    this.primaryThumbnailUrl,
    this.primaryBannerUrl,
  });
}

class CanonicalEventGraphService {
  CanonicalEventGraphService({
    FirebaseFirestore? firestore,
    MediaVisibilityService? mediaVisibilityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _mediaVisibilityService =
           mediaVisibilityService ??
           MediaVisibilityService(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _firestore;
  final MediaVisibilityService _mediaVisibilityService;
  final Map<String, Future<String?>> _eventPosterCache = {};
  final Map<String, Future<String?>> _ppvPosterCache = {};

  Future<String?> resolveEventPosterUrl(
    EventModel event, {
    bool preferThumb = false,
  }) {
    final cacheKey = [
      'event',
      event.id,
      preferThumb ? 'thumb' : 'poster',
      event.posterMediaId ?? '',
      event.posterUrl ?? '',
      event.thumbnailUrl ?? '',
      event.bannerUrl ?? '',
      event.mediaIds.join(','),
      event.imageIds.join(','),
    ].join('|');

    return _eventPosterCache.putIfAbsent(cacheKey, () async {
      final graph = await buildEventGraph(event: event);
      return preferThumb
          ? graph.primaryThumbnailUrl ?? graph.primaryPosterUrl
          : graph.primaryPosterUrl;
    });
  }

  Future<String?> resolvePpvPosterUrl(
    PPVEvent ppvEvent, {
    bool preferThumb = false,
  }) {
    final cacheKey = [
      'ppv',
      ppvEvent.id,
      preferThumb ? 'thumb' : 'poster',
      ppvEvent.eventId,
      ppvEvent.posterUrl ?? '',
      ppvEvent.title,
      ppvEvent.promotion ?? '',
      ppvEvent.ticketUrl ?? '',
      ppvEvent.streamUrl ?? '',
    ].join('|');

    return _ppvPosterCache.putIfAbsent(cacheKey, () async {
      final graph = await buildEventGraph(ppvEvent: ppvEvent);
      return preferThumb
          ? graph.primaryThumbnailUrl ?? graph.primaryPosterUrl
          : graph.primaryPosterUrl;
    });
  }

  Future<CanonicalEventGraph> buildEventGraph({
    EventModel? event,
    PPVEvent? ppvEvent,
  }) async {
    final eventCandidates = await _collectEventCandidates(
      event: event,
      ppvEvent: ppvEvent,
    );
    final ppvCandidates = await _collectPpvCandidates(
      event: event,
      ppvEvent: ppvEvent,
    );
    final visibleAssets = await _collectVisibleAssets(eventCandidates);
    final preferredAssetId = _firstPosterMediaId(eventCandidates);

    final primaryPosterUrl = _pickPreferredArtworkUrl(
      eventCandidates: eventCandidates,
      ppvCandidates: ppvCandidates,
      visibleAssets: visibleAssets,
      preferredAssetId: preferredAssetId,
      preferThumb: false,
      preferBanner: false,
    );
    final primaryThumbnailUrl =
        _pickPreferredArtworkUrl(
          eventCandidates: eventCandidates,
          ppvCandidates: ppvCandidates,
          visibleAssets: visibleAssets,
          preferredAssetId: preferredAssetId,
          preferThumb: true,
          preferBanner: false,
        ) ??
        primaryPosterUrl;
    final primaryBannerUrl =
        _pickPreferredArtworkUrl(
          eventCandidates: eventCandidates,
          ppvCandidates: ppvCandidates,
          visibleAssets: visibleAssets,
          preferredAssetId: preferredAssetId,
          preferThumb: false,
          preferBanner: true,
        ) ??
        primaryPosterUrl;

    return CanonicalEventGraph(
      eventIds: eventCandidates.map((candidate) => candidate.id).toList(),
      ppvIds: ppvCandidates.map((candidate) => candidate.id).toList(),
      mediaAssetIds: visibleAssets.map((asset) => asset.id).toList(),
      matchSignals: _buildMatchSignals(
        event: event,
        ppvEvent: ppvEvent,
        eventCandidates: eventCandidates,
        ppvCandidates: ppvCandidates,
        visibleAssets: visibleAssets,
        primaryPosterUrl: primaryPosterUrl,
      ),
      primaryPosterUrl: primaryPosterUrl,
      primaryThumbnailUrl: primaryThumbnailUrl,
      primaryBannerUrl: primaryBannerUrl,
    );
  }

  Future<List<EventModel>> _collectEventCandidates({
    EventModel? event,
    PPVEvent? ppvEvent,
  }) async {
    final candidates = <EventModel>[];
    if (event != null) {
      candidates.add(event);
    }

    final directEventId = ppvEvent?.eventId;
    if (directEventId != null && directEventId.isNotEmpty) {
      try {
        final doc = await _firestore
            .collection('events')
            .doc(directEventId)
            .get();
        if (doc.exists) {
          candidates.add(EventModel.fromFirestore(doc));
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'Direct event lookup failed for canonical graph',
          error: error,
          stackTrace: stackTrace,
          tag: 'CanonicalEventGraph',
        );
      }
    }

    final title = event?.name ?? ppvEvent?.title;
    final promoter =
        event?.promotionName ?? event?.promoterId ?? ppvEvent?.promotion;
    final eventDate = event?.eventDate ?? ppvEvent?.eventDate;
    final streamUrl = event?.streamUrl ?? ppvEvent?.streamUrl;
    final ticketUrl = event?.ticketUrl ?? ppvEvent?.ticketUrl;

    final nearbyEvents = await _queryEventsAroundDate(eventDate);
    for (final candidate in nearbyEvents) {
      if (_looksLikeSameEvent(
        candidateTitle: candidate.name,
        candidatePromoter: candidate.promotionName ?? candidate.promoterId,
        candidateDate: candidate.eventDate,
        title: title,
        promoter: promoter,
        eventDate: eventDate,
        streamUrl: streamUrl,
        ticketUrl: ticketUrl,
        candidateStreamUrl: candidate.streamUrl,
        candidateTicketUrl: candidate.ticketUrl,
      )) {
        candidates.add(candidate);
      }
    }

    return _dedupeEvents(candidates);
  }

  Future<List<PPVEvent>> _collectPpvCandidates({
    EventModel? event,
    PPVEvent? ppvEvent,
  }) async {
    final candidates = <PPVEvent>[];
    if (ppvEvent != null) {
      candidates.add(ppvEvent);
    }

    final directIds = <String>{
      if (event != null && event.id.isNotEmpty) event.id,
      if (ppvEvent != null && ppvEvent.id.isNotEmpty) ppvEvent.id,
      if (ppvEvent != null && ppvEvent.eventId.isNotEmpty) ppvEvent.eventId,
    };

    for (final candidateId in directIds) {
      try {
        final directDoc = await _firestore
            .collection('ppv_events')
            .doc(candidateId)
            .get();
        if (directDoc.exists) {
          candidates.add(PPVEvent.fromFirestore(directDoc));
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'Direct PPV lookup failed for canonical graph',
          error: error,
          stackTrace: stackTrace,
          tag: 'CanonicalEventGraph',
        );
      }
    }

    final lookupEventId = event?.id ?? ppvEvent?.eventId;
    if (lookupEventId != null && lookupEventId.isNotEmpty) {
      try {
        final snapshot = await _firestore
            .collection('ppv_events')
            .where('eventId', isEqualTo: lookupEventId)
            .limit(5)
            .get();
        for (final doc in snapshot.docs) {
          candidates.add(PPVEvent.fromFirestore(doc));
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'Linked PPV lookup failed for canonical graph',
          error: error,
          stackTrace: stackTrace,
          tag: 'CanonicalEventGraph',
        );
      }
    }

    final title = event?.name ?? ppvEvent?.title;
    final promoter =
        event?.promotionName ?? event?.promoterId ?? ppvEvent?.promotion;
    final eventDate = event?.eventDate ?? ppvEvent?.eventDate;
    final streamUrl = event?.streamUrl ?? ppvEvent?.streamUrl;
    final ticketUrl = event?.ticketUrl ?? ppvEvent?.ticketUrl;

    final nearbyPpvs = await _queryPpvsAroundDate(eventDate);
    for (final candidate in nearbyPpvs) {
      if (_looksLikeSameEvent(
        candidateTitle: candidate.title,
        candidatePromoter: candidate.promotion,
        candidateDate: candidate.eventDate,
        title: title,
        promoter: promoter,
        eventDate: eventDate,
        streamUrl: streamUrl,
        ticketUrl: ticketUrl,
        candidateStreamUrl: candidate.streamUrl,
        candidateTicketUrl: candidate.ticketUrl,
      )) {
        candidates.add(candidate);
      }
    }

    return _dedupePpvs(candidates);
  }

  Future<List<MediaAssetModel>> _collectVisibleAssets(
    List<EventModel> eventCandidates,
  ) async {
    final linkedAssetIds = <String>{};
    for (final event in eventCandidates) {
      if (event.posterMediaId != null && event.posterMediaId!.isNotEmpty) {
        linkedAssetIds.add(event.posterMediaId!);
      }
      linkedAssetIds.addAll(event.mediaIds.where((value) => value.isNotEmpty));
      linkedAssetIds.addAll(event.imageIds.where((value) => value.isNotEmpty));
    }

    final assetsById = <String, MediaAssetModel>{};
    if (linkedAssetIds.isNotEmpty) {
      final directAssets = await _mediaVisibilityService.getAssetsByIds(
        linkedAssetIds,
      );
      for (final asset in directAssets) {
        if (MediaVisibilityService.isApprovedForPublicUse(asset)) {
          assetsById[asset.id] = asset;
        }
      }
    }

    for (final event in eventCandidates) {
      final queryAssets = await _queryLinkedAssets(event.id);
      for (final asset in queryAssets) {
        if (MediaVisibilityService.isApprovedForPublicUse(asset)) {
          assetsById[asset.id] = asset;
        }
      }
    }

    return assetsById.values.toList(growable: false);
  }

  Future<List<EventModel>> _queryEventsAroundDate(DateTime? eventDate) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('events');
      if (eventDate != null) {
        final start = Timestamp.fromDate(
          eventDate.subtract(const Duration(days: 3)),
        );
        final end = Timestamp.fromDate(eventDate.add(const Duration(days: 3)));
        query = query
            .where('eventDate', isGreaterThanOrEqualTo: start)
            .where('eventDate', isLessThanOrEqualTo: end)
            .orderBy('eventDate');
      }

      final snapshot = await query.limit(40).get();
      return snapshot.docs
          .map(EventModel.fromFirestore)
          .toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Nearby event query failed for canonical graph',
        error: error,
        stackTrace: stackTrace,
        tag: 'CanonicalEventGraph',
      );
      return const <EventModel>[];
    }
  }

  Future<List<PPVEvent>> _queryPpvsAroundDate(DateTime? eventDate) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('ppv_events');
      if (eventDate != null) {
        final start = Timestamp.fromDate(
          eventDate.subtract(const Duration(days: 3)),
        );
        final end = Timestamp.fromDate(eventDate.add(const Duration(days: 3)));
        query = query
            .where('eventDate', isGreaterThanOrEqualTo: start)
            .where('eventDate', isLessThanOrEqualTo: end)
            .orderBy('eventDate');
      }

      final snapshot = await query.limit(40).get();
      return snapshot.docs
          .map(PPVEvent.fromFirestore)
          .toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Nearby PPV query failed for canonical graph',
        error: error,
        stackTrace: stackTrace,
        tag: 'CanonicalEventGraph',
      );
      return const <PPVEvent>[];
    }
  }

  Future<List<MediaAssetModel>> _queryLinkedAssets(String eventId) async {
    final assetsById = <String, MediaAssetModel>{};
    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      _firestore
          .collection('media_assets')
          .where('eventId', isEqualTo: eventId)
          .limit(20)
          .get(),
      _firestore
          .collection('media_assets')
          .where('entityId', isEqualTo: eventId)
          .limit(20)
          .get(),
    ];

    try {
      final snapshots = await Future.wait(queries);
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          assetsById[doc.id] = MediaAssetModel.fromFirestore(doc);
        }
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Linked media lookup failed for canonical graph',
        error: error,
        stackTrace: stackTrace,
        tag: 'CanonicalEventGraph',
      );
    }

    return assetsById.values.toList(growable: false);
  }

  String? _pickPreferredArtworkUrl({
    required List<EventModel> eventCandidates,
    required List<PPVEvent> ppvCandidates,
    required List<MediaAssetModel> visibleAssets,
    required String? preferredAssetId,
    required bool preferThumb,
    required bool preferBanner,
  }) {
    final rankedUrls = <_RankedArtworkUrl>[];

    for (final event in eventCandidates) {
      _addEventArtworkCandidates(
        rankedUrls,
        event,
        preferThumb: preferThumb,
        preferBanner: preferBanner,
      );
    }

    for (final asset in visibleAssets) {
      if (asset.downloadUrl.isEmpty) {
        continue;
      }
      rankedUrls.add(
        _RankedArtworkUrl(
          url: asset.downloadUrl,
          score: _scoreAsset(
            asset,
            preferredAssetId: preferredAssetId,
            preferThumb: preferThumb,
            preferBanner: preferBanner,
          ),
          source: 'media:${asset.id}',
        ),
      );
    }

    for (final ppv in ppvCandidates) {
      final posterUrl = ppv.posterUrl?.trim();
      if (_isUsableArtworkUrl(posterUrl)) {
        rankedUrls.add(
          _RankedArtworkUrl(
            url: posterUrl!,
            score: 260 + (preferThumb ? 5 : 15),
            source: 'ppv:${ppv.id}',
          ),
        );
      }
    }

    final mappedPoster = _mappedPosterFallback(
      eventCandidates: eventCandidates,
      ppvCandidates: ppvCandidates,
      preferThumb: preferThumb,
    );
    if (mappedPoster != null) {
      rankedUrls.add(
        _RankedArtworkUrl(
          url: mappedPoster,
          score: 150,
          source: 'image-assets-map',
        ),
      );
    }

    if (rankedUrls.isEmpty) {
      return null;
    }

    rankedUrls.sort((left, right) => right.score.compareTo(left.score));
    return rankedUrls.first.url;
  }

  void _addEventArtworkCandidates(
    List<_RankedArtworkUrl> rankedUrls,
    EventModel event, {
    required bool preferThumb,
    required bool preferBanner,
  }) {
    void addUrl(String? rawUrl, int baseScore, String source) {
      final url = rawUrl?.trim();
      if (!_isUsableArtworkUrl(url)) {
        return;
      }
      rankedUrls.add(
        _RankedArtworkUrl(
          url: url!,
          score: baseScore + (_svgBonus(url)),
          source: source,
        ),
      );
    }

    if (preferBanner) {
      addUrl(event.bannerUrl, 420, 'event:${event.id}:banner');
      addUrl(event.posterUrl, 360, 'event:${event.id}:poster');
      addUrl(event.thumbnailUrl, 300, 'event:${event.id}:thumb');
      return;
    }

    if (preferThumb) {
      addUrl(event.thumbnailUrl, 420, 'event:${event.id}:thumb');
      addUrl(event.posterUrl, 360, 'event:${event.id}:poster');
      addUrl(event.bannerUrl, 300, 'event:${event.id}:banner');
      return;
    }

    addUrl(event.posterUrl, 420, 'event:${event.id}:poster');
    addUrl(event.bannerUrl, 340, 'event:${event.id}:banner');
    addUrl(event.thumbnailUrl, 320, 'event:${event.id}:thumb');
  }

  int _scoreAsset(
    MediaAssetModel asset, {
    required String? preferredAssetId,
    required bool preferThumb,
    required bool preferBanner,
  }) {
    var score = 100;
    if (asset.id == preferredAssetId) {
      score += 300;
    }

    switch (asset.kind) {
      case MediaAssetKind.poster:
        score += preferThumb ? 290 : 320;
      case MediaAssetKind.banner:
        score += preferBanner ? 320 : 260;
      case MediaAssetKind.genericImage:
        score += 200;
      case MediaAssetKind.story:
        score += preferThumb ? 220 : 140;
      case MediaAssetKind.postMedia:
        score += 130;
      default:
        score += 40;
    }

    final ratio = asset.aspectRatio;
    if (ratio != null) {
      if (preferThumb && ratio >= 0.85 && ratio <= 1.15) {
        score += 25;
      }
      if (!preferThumb && !preferBanner && ratio >= 0.6 && ratio <= 0.9) {
        score += 20;
      }
      if (preferBanner && ratio >= 1.4) {
        score += 20;
      }
    }

    score += _svgBonus(asset.downloadUrl);
    return score;
  }

  String? _mappedPosterFallback({
    required List<EventModel> eventCandidates,
    required List<PPVEvent> ppvCandidates,
    required bool preferThumb,
  }) {
    final event = eventCandidates.isNotEmpty ? eventCandidates.first : null;
    final ppv = ppvCandidates.isNotEmpty ? ppvCandidates.first : null;
    return ImageAssets.posterAssetForEventMetadata(
      eventId: event?.id ?? ppv?.eventId,
      title: event?.name ?? ppv?.title,
      promoter: event?.promotionName ?? event?.promoterId ?? ppv?.promotion,
      eventDate: event?.eventDate ?? ppv?.eventDate,
      streamUrl: event?.streamUrl ?? ppv?.streamUrl,
      ticketUrl: event?.ticketUrl ?? ppv?.ticketUrl,
      preferThumb: preferThumb,
    );
  }

  List<String> _buildMatchSignals({
    required EventModel? event,
    required PPVEvent? ppvEvent,
    required List<EventModel> eventCandidates,
    required List<PPVEvent> ppvCandidates,
    required List<MediaAssetModel> visibleAssets,
    required String? primaryPosterUrl,
  }) {
    return <String>[
      if (event != null) 'event:${event.id}',
      if (ppvEvent != null) 'ppv:${ppvEvent.id}',
      if (eventCandidates.isNotEmpty) 'eventMatches:${eventCandidates.length}',
      if (ppvCandidates.isNotEmpty) 'ppvMatches:${ppvCandidates.length}',
      if (visibleAssets.isNotEmpty) 'approvedAssets:${visibleAssets.length}',
      if (primaryPosterUrl != null && primaryPosterUrl.isNotEmpty)
        'resolvedArtwork',
    ];
  }

  bool _looksLikeSameEvent({
    required String candidateTitle,
    required String? candidatePromoter,
    required DateTime? candidateDate,
    required String? title,
    required String? promoter,
    required DateTime? eventDate,
    required String? streamUrl,
    required String? ticketUrl,
    required String? candidateStreamUrl,
    required String? candidateTicketUrl,
  }) {
    var score = 0;
    final normalizedTitle = _normalizeTitle(title);
    final normalizedCandidateTitle = _normalizeTitle(candidateTitle);
    if (normalizedTitle.isNotEmpty && normalizedCandidateTitle.isNotEmpty) {
      if (normalizedTitle == normalizedCandidateTitle) {
        score += 3;
      } else if (normalizedTitle.contains(normalizedCandidateTitle) ||
          normalizedCandidateTitle.contains(normalizedTitle)) {
        score += 2;
      }
    }

    final normalizedPromoter = _normalizeTitle(promoter);
    final normalizedCandidatePromoter = _normalizeTitle(candidatePromoter);
    if (normalizedPromoter.isNotEmpty &&
        normalizedCandidatePromoter.isNotEmpty &&
        (normalizedPromoter == normalizedCandidatePromoter ||
            normalizedPromoter.contains(normalizedCandidatePromoter) ||
            normalizedCandidatePromoter.contains(normalizedPromoter))) {
      score += 1;
    }

    if (eventDate != null && candidateDate != null) {
      final hours = eventDate.difference(candidateDate).inHours.abs();
      if (hours <= 30) {
        score += 2;
      }
    }

    if (_normalizedUrlKey(streamUrl).isNotEmpty &&
        _normalizedUrlKey(streamUrl) == _normalizedUrlKey(candidateStreamUrl)) {
      score += 1;
    }
    if (_normalizedUrlKey(ticketUrl).isNotEmpty &&
        _normalizedUrlKey(ticketUrl) == _normalizedUrlKey(candidateTicketUrl)) {
      score += 1;
    }

    return score >= 3;
  }

  List<EventModel> _dedupeEvents(List<EventModel> events) {
    final byId = <String, EventModel>{};
    for (final event in events) {
      if (event.id.isEmpty) {
        continue;
      }
      byId[event.id] = event;
    }
    return byId.values.toList(growable: false);
  }

  List<PPVEvent> _dedupePpvs(List<PPVEvent> events) {
    final byId = <String, PPVEvent>{};
    for (final event in events) {
      if (event.id.isEmpty) {
        continue;
      }
      byId[event.id] = event;
    }
    return byId.values.toList(growable: false);
  }

  String? _firstPosterMediaId(List<EventModel> eventCandidates) {
    for (final event in eventCandidates) {
      final posterMediaId = event.posterMediaId;
      if (posterMediaId != null && posterMediaId.isNotEmpty) {
        return posterMediaId;
      }
    }
    return null;
  }

  bool _isUsableArtworkUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }
    return !ImageAssets.isGenericPosterAsset(url);
  }

  String _normalizeTitle(String? raw) {
    if (raw == null) {
      return '';
    }
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizedUrlKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(raw.trim());
    if (uri == null) {
      return raw.trim().toLowerCase();
    }

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return '$host$path';
  }

  int _svgBonus(String? url) {
    final value = url?.toLowerCase() ?? '';
    return value.contains('.svg') ? 15 : 0;
  }
}

class _RankedArtworkUrl {
  final String url;
  final int score;
  final String source;

  const _RankedArtworkUrl({
    required this.url,
    required this.score,
    required this.source,
  });
}
