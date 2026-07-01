import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/ppv_model.dart';

class PromoterSettlementSnapshotService {
  PromoterSettlementSnapshotService({
    FirebaseFirestore? firestore,
    http.Client? client,
    String? atlasBaseUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _client = client ?? http.Client(),
       _atlasBaseUrl = atlasBaseUrl ?? _defaultAtlasBaseUrl;

  static const String _defaultAtlasBaseUrl = String.fromEnvironment(
    'ATLAS_URL',
    defaultValue: 'http://localhost:8000',
  );

  final FirebaseFirestore _firestore;
  final http.Client _client;
  final String _atlasBaseUrl;

  Future<PromoterSettlementSnapshot> getSnapshot({
    required String eventId,
    PPVEvent? ppvEvent,
    String? fallbackEventName,
    String? fallbackVenue,
    DateTime? fallbackEventDate,
    String? fallbackPromoterName,
  }) async {
    try {
      final resolvedPpvEvent = await _resolvePpvEvent(eventId, ppvEvent);
      final futures = await Future.wait([
        _firestore.collection('events').doc(eventId).get(),
        _loadPurchaseDocs(eventId: eventId, ppvEventId: resolvedPpvEvent?.id),
        _loadRevenueShareDoc(
          eventId: eventId,
          ppvEventId: resolvedPpvEvent?.id,
        ),
        _loadBackendSettlement(
          eventId: eventId,
          ppvEventId: resolvedPpvEvent?.id,
        ),
        _loadLatestReconciliationDoc(
          eventId: eventId,
          ppvEventId: resolvedPpvEvent?.id,
        ),
      ]);

      final eventDoc = futures[0] as DocumentSnapshot<Map<String, dynamic>>;
      final purchaseDocs =
          futures[1] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
      final revenueShareDoc =
          futures[2] as QueryDocumentSnapshot<Map<String, dynamic>>?;
      final backendSettlement = futures[3] as _AtlasSettlementSnapshot?;
      final reconciliationDoc =
          futures[4] as QueryDocumentSnapshot<Map<String, dynamic>>?;
      final settlementDocs = await Future.wait([
        _loadRefundDocs(
          eventId: eventId,
          ppvEventId: resolvedPpvEvent?.id,
          purchaseDocs: purchaseDocs,
        ),
        _loadDisputeDocs(
          eventId: eventId,
          ppvEventId: resolvedPpvEvent?.id,
          purchaseDocs: purchaseDocs,
        ),
      ]);
      final refundDocs = settlementDocs[0];
      final disputeDocs = settlementDocs[1];

      final eventData = eventDoc.data() ?? const <String, dynamic>{};
      final revenueShareData =
          revenueShareDoc?.data() ?? const <String, dynamic>{};
      final reconciliationData =
          reconciliationDoc?.data() ?? const <String, dynamic>{};
      final hasReconciliation = reconciliationDoc != null;

      final eventName = _firstNonEmpty([
        fallbackEventName,
        resolvedPpvEvent?.title,
        eventData['name']?.toString(),
        eventData['title']?.toString(),
        eventId,
      ]);
      final venue = _firstNonEmpty([
        fallbackVenue,
        eventData['venue']?.toString(),
        eventData['location']?.toString(),
        revenueShareData['venue']?.toString(),
        'Venue pending',
      ]);
      final promoterName = _firstNonEmpty([
        fallbackPromoterName,
        eventData['promotionName']?.toString(),
        revenueShareData['promoterName']?.toString(),
        resolvedPpvEvent?.promotion,
        resolvedPpvEvent?.promoterId,
        'Promoter pending',
      ]);

      final eventDate =
          fallbackEventDate ??
          _readDate(
            eventData['eventDate'] ??
                eventData['date'] ??
                eventData['startTime'] ??
                resolvedPpvEvent?.eventDate,
          ) ??
          DateTime.now();

      final priceValue = _resolvePrice(
        resolvedPpvEvent: resolvedPpvEvent,
        revenueShareData: revenueShareData,
        purchaseDocs: purchaseDocs,
      );

      int verifiedPurchases = 0;
      int refundedPurchases = 0;
      double grossSales = 0;
      double stripeFees = 0;
      double refundedAmount = 0;
      DateTime? lastPurchaseAt;
      final ledger = <PromoterSettlementLedgerRow>[];

      final refundAmountsByPaymentIntent = <String, double>{};
      double unmappedRefundedAmount = 0;
      for (final doc in refundDocs) {
        final data = doc.data();
        final amount = _readSettlementAmount(
          data,
          centKeys: const ['amountCents', 'amountRefundedCents'],
        );
        if (amount <= 0) continue;

        final paymentIntentId = _readPaymentIntentId(data);
        if (paymentIntentId == null) {
          unmappedRefundedAmount += amount;
          continue;
        }

        refundAmountsByPaymentIntent[paymentIntentId] =
            (refundAmountsByPaymentIntent[paymentIntentId] ?? 0) + amount;
      }

      final latestDisputeByPaymentIntent =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      final unmappedReviewDisputes =
          <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in disputeDocs) {
        final data = doc.data();
        final paymentIntentId = _readPaymentIntentId(data);
        if (paymentIntentId == null) {
          if (_requiresDisputeReview(data)) {
            unmappedReviewDisputes.add(doc);
          }
          continue;
        }

        final existing = latestDisputeByPaymentIntent[paymentIntentId];
        final existingAt = existing == null
            ? null
            : _readSettlementUpdatedAt(existing.data());
        final candidateAt = _readSettlementUpdatedAt(data);
        if (existing == null ||
            (candidateAt != null &&
                (existingAt == null || candidateAt.isAfter(existingAt)))) {
          latestDisputeByPaymentIntent[paymentIntentId] = doc;
        }
      }

      final reviewDisputes = <QueryDocumentSnapshot<Map<String, dynamic>>>[
        ...latestDisputeByPaymentIntent.values.where(
          (doc) => _requiresDisputeReview(doc.data()),
        ),
        ...unmappedReviewDisputes,
      ];
      final activeDisputeCount = reviewDisputes.length;
      final activeDisputeAmount = reviewDisputes.fold<double>(
        0,
        (totalAmount, doc) =>
            totalAmount +
            _readSettlementAmount(
              doc.data(),
            ),
      );

      final sortedPurchaseDocs = [...purchaseDocs]
        ..sort((left, right) {
          final leftAt =
              _readDate(
                left.data()['createdAt'] ??
                    left.data()['purchasedAt'] ??
                    left.data()['grantedAt'],
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final rightAt =
              _readDate(
                right.data()['createdAt'] ??
                    right.data()['purchasedAt'] ??
                    right.data()['grantedAt'],
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return leftAt.compareTo(rightAt);
        });

      for (final doc in sortedPurchaseDocs) {
        final data = doc.data();
        final amount = _resolvePurchaseAmount(data, priceValue);
        final paymentIntentId = _readPaymentIntentId(data);
        final refundAmount =
            refundAmountsByPaymentIntent[paymentIntentId] ??
            _resolveRefundAmount(data, amount);
        final isRefund = _isFullyRefunded(data, amount, refundAmount);
        final purchasedAt =
            _readDate(
              data['createdAt'] ?? data['purchasedAt'] ?? data['grantedAt'],
            ) ??
            DateTime.now();
        lastPurchaseAt = purchasedAt;

        if (isRefund) {
          refundedPurchases += 1;
        } else {
          verifiedPurchases += 1;
          grossSales += amount;
        }
        if (refundAmount > 0) {
          refundedAmount += refundAmount;
        }

        final stripeFee = isRefund || amount <= 0
            ? 0.0
            : (amount * 0.029 + 0.30).toDouble();
        stripeFees += stripeFee;
        final net = isRefund
            ? 0.0
            : math.max(0.0, amount - stripeFee - refundAmount).toDouble();
        final effectiveBuys = math.max(verifiedPurchases, 1);
        final dfcPct = PPVEvent.calculateSlidingFee(effectiveBuys);

        ledger.add(
          PromoterSettlementLedgerRow(
            txNum: ledger.length + 1,
            time: purchasedAt,
            gross: amount,
            net: net,
            dfcPct: dfcPct,
            promoterCut: net * (1 - dfcPct),
            isRefund: isRefund || refundAmount > 0,
          ),
        );
      }

      refundedAmount += unmappedRefundedAmount;

      final ledgerNetRevenue = math
          .max(0.0, grossSales - stripeFees)
          .toDouble();
      final reconciliationGrossSales =
          _readDouble(reconciliationData['totalGrossCents']) / 100;
      final reconciliationNetRevenue =
          _readDouble(reconciliationData['totalNetCents']) / 100;
      final reconciliationRefundedAmount =
          _readDouble(reconciliationData['totalRefundedCents']) / 100;
      final reconciliationDfcCut =
          _readDouble(reconciliationData['totalDfcCents']) / 100;
      final reconciliationPromoterCut =
          _readDouble(reconciliationData['totalPromoterCents']) / 100;
      final reconciliationReserveAmount =
          _readDouble(reconciliationData['totalReserveCents']) / 100;
      final reconciliationPayableNow =
          _readDouble(reconciliationData['totalPayableCents']) / 100;
      final authoritativeGrossSales = hasReconciliation
          ? reconciliationGrossSales
          : (backendSettlement?.gross ?? grossSales);
      final authoritativeStripeFees = backendSettlement?.fees ?? stripeFees;
      final authoritativeNetRevenue = hasReconciliation
          ? reconciliationNetRevenue
          : (backendSettlement?.net ?? ledgerNetRevenue);
      final dfcPct = PPVEvent.calculateSlidingFee(verifiedPurchases);
      final dfcCut = hasReconciliation
          ? reconciliationDfcCut
          : authoritativeNetRevenue * dfcPct;
      final promoterCut = hasReconciliation
          ? reconciliationPromoterCut
          : authoritativeNetRevenue - dfcCut;
      final reserveAmount = hasReconciliation
          ? reconciliationReserveAmount
          : authoritativeNetRevenue * 0.02;
      final payableNow = hasReconciliation
          ? reconciliationPayableNow
          : math.max(0.0, promoterCut - reserveAmount).toDouble();

      final recordedGross = _readDouble(revenueShareData['totalRevenue']);
      final recordedPromoterAmount = _readDouble(
        revenueShareData['promoterAmount'],
      );
      final recordedPlatformAmount = _readDouble(
        revenueShareData['platformAmount'],
      );
      final recordedPurchases =
          (revenueShareData['totalPurchases'] as num?)?.toInt() ?? 0;
      final revenueShareDelta = revenueShareDoc == null
          ? 0.0
          : (recordedGross - authoritativeGrossSales).toDouble();
      final backendDelta = backendSettlement == null
          ? 0.0
          : (backendSettlement.gross - grossSales).toDouble();
      final payoutStatus =
          reconciliationData['payoutState']?.toString() ??
          reconciliationData['payoutStatus']?.toString() ??
          revenueShareData['payoutStatus']?.toString() ??
          revenueShareData['status']?.toString() ??
          'pending';
      final payoutAttemptCount =
          (reconciliationData['payoutAttemptCount'] as num?)?.toInt() ?? 0;
      final payoutFailureReason = reconciliationData['payoutFailureReason']
          ?.toString();
      final reserveReleaseState =
          reconciliationData['reserveReleaseState']?.toString() ?? 'pending';
      final reserveReleaseAt =
          _readDate(
            reconciliationData['reserveReleaseAt'] ??
                reconciliationData['reserveReleaseDate'],
          ) ??
          eventDate.add(const Duration(days: 28));
      final reconciledAt = _readDate(reconciliationData['reconciledAt']);
      final eventStartTime =
          _readDate(reconciliationData['eventStartTime']) ?? eventDate;
      final totalGrossCents = hasReconciliation
          ? _readInt(reconciliationData['totalGrossCents'])
          : (authoritativeGrossSales * 100).round();
      final totalNetCents = hasReconciliation
          ? _readInt(reconciliationData['totalNetCents'])
          : (authoritativeNetRevenue * 100).round();
      final totalRefundedCents = hasReconciliation
          ? _readInt(reconciliationData['totalRefundedCents'])
          : (refundedAmount * 100).round();
      final totalPayableCents = hasReconciliation
          ? _readInt(reconciliationData['totalPayableCents'])
          : (payableNow * 100).round();
      final lastPayoutAt = _readDate(
        reconciliationData['payoutCompletedAt'] ??
            reconciliationData['payoutFailedAt'] ??
            reconciliationData['payoutRequestedAt'] ??
            reconciliationData['payoutLastAttemptAt'] ??
            revenueShareData['paidOutAt'] ??
            revenueShareData['updatedAt'] ??
            revenueShareData['createdAt'],
      );

      return PromoterSettlementSnapshot(
        eventId: eventId,
        ppvEventId: resolvedPpvEvent?.id,
        eventName: eventName,
        venue: venue,
        promoterName: promoterName,
        eventDate: eventDate,
        ppvPriceValue: priceValue,
        currency: resolvedPpvEvent?.currency ?? 'AUD',
        usingLiveData:
            purchaseDocs.isNotEmpty ||
            revenueShareDoc != null ||
            backendSettlement != null ||
            hasReconciliation,
        hasPpvLane: resolvedPpvEvent != null,
        hasRevenueShare: revenueShareDoc != null,
        hasReconciliation: hasReconciliation,
        hasBackendSettlement: backendSettlement != null,
        totalPurchases: verifiedPurchases,
        refundedPurchases: refundedPurchases,
        grossSales: authoritativeGrossSales,
        stripeFees: authoritativeStripeFees,
        netRevenue: authoritativeNetRevenue,
        dfcPct: dfcPct,
        dfcCut: dfcCut,
        promoterCut: promoterCut,
        reserveAmount: reserveAmount,
        payableNow: payableNow,
        ledgerGrossSales: grossSales,
        ledgerStripeFees: stripeFees,
        ledgerNetRevenue: ledgerNetRevenue,
        backendGross: backendSettlement?.gross ?? 0,
        backendFees: backendSettlement?.fees ?? 0,
        backendNet: backendSettlement?.net ?? 0,
        backendDelta: backendDelta,
        recordedGross: recordedGross,
        recordedPromoterAmount: recordedPromoterAmount,
        recordedPlatformAmount: recordedPlatformAmount,
        recordedPurchases: recordedPurchases,
        revenueShareDelta: revenueShareDelta,
        refundedAmount: hasReconciliation
            ? reconciliationRefundedAmount
            : refundedAmount,
        activeDisputeCount: activeDisputeCount,
        activeDisputeAmount: activeDisputeAmount,
        payoutStatus: payoutStatus,
        payoutAttemptCount: payoutAttemptCount,
        payoutFailureReason: payoutFailureReason,
        reserveReleaseState: reserveReleaseState,
        reserveReleaseAt: reserveReleaseAt,
        reconciledAt: reconciledAt,
        eventStartTime: eventStartTime,
        totalGrossCents: totalGrossCents,
        totalNetCents: totalNetCents,
        totalRefundedCents: totalRefundedCents,
        totalPayableCents: totalPayableCents,
        lastPurchaseAt: lastPurchaseAt,
        lastPayoutAt: lastPayoutAt,
        ledger: ledger,
      );
    } catch (_) {
      return PromoterSettlementSnapshot(
        eventId: eventId,
        ppvEventId: ppvEvent?.id,
        eventName: fallbackEventName ?? ppvEvent?.title ?? eventId,
        venue: fallbackVenue ?? 'Venue pending',
        promoterName:
            fallbackPromoterName ?? ppvEvent?.promotion ?? 'Promoter pending',
        eventDate: fallbackEventDate ?? ppvEvent?.eventDate ?? DateTime.now(),
        ppvPriceValue: ppvEvent?.standardPrice ?? 20.0,
        currency: ppvEvent?.currency ?? 'AUD',
        usingLiveData: false,
        hasPpvLane: ppvEvent != null,
        hasRevenueShare: false,
        hasReconciliation: false,
        hasBackendSettlement: false,
        totalPurchases: ppvEvent?.purchaseCount ?? 0,
        refundedPurchases: 0,
        grossSales: ppvEvent?.totalRevenue ?? 0,
        stripeFees: 0,
        netRevenue: ppvEvent?.totalRevenue ?? 0,
        dfcPct: PPVEvent.calculateSlidingFee(ppvEvent?.purchaseCount ?? 0),
        dfcCut: 0,
        promoterCut: 0,
        reserveAmount: 0,
        payableNow: 0,
        ledgerGrossSales: ppvEvent?.totalRevenue ?? 0,
        ledgerStripeFees: 0,
        ledgerNetRevenue: ppvEvent?.totalRevenue ?? 0,
        backendGross: 0,
        backendFees: 0,
        backendNet: 0,
        backendDelta: 0,
        recordedGross: 0,
        recordedPromoterAmount: 0,
        recordedPlatformAmount: 0,
        recordedPurchases: 0,
        revenueShareDelta: 0,
        refundedAmount: 0,
        activeDisputeCount: 0,
        activeDisputeAmount: 0,
        payoutStatus: 'pending',
        payoutAttemptCount: 0,
        payoutFailureReason: null,
        reserveReleaseState: 'pending',
        reserveReleaseAt:
            (fallbackEventDate ?? ppvEvent?.eventDate ?? DateTime.now()).add(
              const Duration(days: 28),
            ),
        reconciledAt: null,
        eventStartTime:
            fallbackEventDate ?? ppvEvent?.eventDate ?? DateTime.now(),
        totalGrossCents: ((ppvEvent?.totalRevenue ?? 0) * 100).round(),
        totalNetCents: ((ppvEvent?.totalRevenue ?? 0) * 100).round(),
        totalRefundedCents: 0,
        totalPayableCents: 0,
        lastPurchaseAt: null,
        lastPayoutAt: null,
        ledger: const [],
      );
    }
  }

  Future<PPVEvent?> _resolvePpvEvent(String eventId, PPVEvent? provided) async {
    if (provided != null) return provided;

    final directDoc = await _firestore
        .collection('ppv_events')
        .doc(eventId)
        .get();
    if (directDoc.exists) {
      return PPVEvent.fromFirestore(directDoc);
    }

    final byEventId = await _firestore
        .collection('ppv_events')
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    if (byEventId.docs.isEmpty) return null;
    return PPVEvent.fromFirestore(byEventId.docs.first);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadPurchaseDocs({
    required String eventId,
    String? ppvEventId,
  }) async {
    final queryPairs = <String>{
      'eventId::$eventId',
      'ppvId::$eventId',
      if (ppvEventId != null && ppvEventId.isNotEmpty)
        'ppvEventId::$ppvEventId',
      if (ppvEventId != null && ppvEventId.isNotEmpty) 'ppvId::$ppvEventId',
    };

    final queries = queryPairs.map((pair) {
      final parts = pair.split('::');
      return _firestore
          .collection('ppv_purchases')
          .where(parts.first, isEqualTo: parts.last)
          .get();
    });

    final snapshots = await Future.wait(queries);
    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs) doc.id: doc,
    };
    return merged.values.toList(growable: false);
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _loadRevenueShareDoc({
    required String eventId,
    String? ppvEventId,
  }) async {
    final lookupIds = <String>{
      eventId,
      if (ppvEventId != null && ppvEventId.isNotEmpty) ppvEventId,
    };

    for (final lookupId in lookupIds) {
      final snapshot = await _firestore
          .collection('revenue_shares')
          .where('ppvEventId', isEqualTo: lookupId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first;
      }
    }

    return null;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _loadLatestReconciliationDoc({
    required String eventId,
    String? ppvEventId,
  }) async {
    final lookupIds = <String>{
      eventId,
      if (ppvEventId != null && ppvEventId.isNotEmpty) ppvEventId,
    };

    final snapshots = await Future.wait(
      lookupIds.map(
        (lookupId) => _firestore
            .collection('reconciliations')
            .where('eventId', isEqualTo: lookupId)
            .limit(25)
            .get(),
      ),
    );

    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        merged[doc.id] = doc;
      }
    }

    final docs = merged.values.toList(growable: false)
      ..sort((left, right) {
        final leftAt =
            _readDate(
              left.data()['reconciledAt'] ??
                  left.data()['updatedAt'] ??
                  left.data()['createdAt'],
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final rightAt =
            _readDate(
              right.data()['reconciledAt'] ??
                  right.data()['updatedAt'] ??
                  right.data()['createdAt'],
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return rightAt.compareTo(leftAt);
      });

    return docs.isEmpty ? null : docs.first;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadRefundDocs({
    required String eventId,
    String? ppvEventId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> purchaseDocs,
  }) {
    return _loadLinkedSettlementDocs(
      collection: 'refunds',
      eventId: eventId,
      ppvEventId: ppvEventId,
      purchaseDocs: purchaseDocs,
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadDisputeDocs({
    required String eventId,
    String? ppvEventId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> purchaseDocs,
  }) {
    return _loadLinkedSettlementDocs(
      collection: 'disputes',
      eventId: eventId,
      ppvEventId: ppvEventId,
      purchaseDocs: purchaseDocs,
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadLinkedSettlementDocs({
    required String collection,
    required String eventId,
    String? ppvEventId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> purchaseDocs,
  }) async {
    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    final lookupIds = <String>{
      eventId,
      if (ppvEventId != null && ppvEventId.isNotEmpty) ppvEventId,
    };

    for (final lookupId in lookupIds) {
      queries.add(
        _firestore
            .collection(collection)
            .where('eventId', isEqualTo: lookupId)
            .get(),
      );
      queries.add(
        _firestore
            .collection(collection)
            .where('ppvId', isEqualTo: lookupId)
            .get(),
      );
    }

    final paymentIntentIds = purchaseDocs
        .map((doc) => _readPaymentIntentId(doc.data()))
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    for (final chunk in _chunk(paymentIntentIds, 10)) {
      queries.add(
        _firestore
            .collection(collection)
            .where('paymentIntentId', whereIn: chunk)
            .get(),
      );
    }

    final snapshots = await Future.wait(queries);
    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs) doc.id: doc,
    };
    return merged.values.toList(growable: false);
  }

  List<List<T>> _chunk<T>(List<T> values, int size) {
    if (values.isEmpty) return const [];

    final chunks = <List<T>>[];
    for (var index = 0; index < values.length; index += size) {
      final end = math.min(index + size, values.length);
      chunks.add(values.sublist(index, end));
    }
    return chunks;
  }

  Future<_AtlasSettlementSnapshot?> _loadBackendSettlement({
    required String eventId,
    String? ppvEventId,
  }) async {
    final lookupIds = <String>[
      eventId,
      if (ppvEventId != null && ppvEventId.isNotEmpty && ppvEventId != eventId)
        ppvEventId,
    ];

    for (final lookupId in lookupIds) {
      try {
        final response = await _client
            .get(Uri.parse('$_atlasBaseUrl/ppv/settlements/$lookupId'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 404) {
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }

        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) {
          continue;
        }

        return _AtlasSettlementSnapshot(
          eventId: (body['event_id'] ?? lookupId).toString(),
          gross: _readDouble(body['gross_cents']) / 100,
          fees: _readDouble(body['fees_cents']) / 100,
          net: _readDouble(body['net_cents']) / 100,
          feeBps: (body['fee_bps'] as num?)?.toInt() ?? 0,
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  double _resolvePrice({
    required PPVEvent? resolvedPpvEvent,
    required Map<String, dynamic> revenueShareData,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> purchaseDocs,
  }) {
    if (resolvedPpvEvent != null && resolvedPpvEvent.standardPrice > 0) {
      return resolvedPpvEvent.standardPrice;
    }

    final price = _readDouble(revenueShareData['price']);
    if (price > 0) return price;

    final priceCents = _readDouble(revenueShareData['priceCents']);
    if (priceCents > 0) return priceCents / 100;

    for (final doc in purchaseDocs) {
      final amount = _readDouble(doc.data()['amountCents']);
      if (amount > 0) return amount / 100;
    }

    return 20.0;
  }

  double _resolvePurchaseAmount(
    Map<String, dynamic> data,
    double fallbackPrice,
  ) {
    final amountCents = _readDouble(data['amountCents']);
    if (amountCents > 0) return amountCents / 100;

    final amount = _readDouble(data['amount']);
    if (amount > 0) return amount;

    return fallbackPrice;
  }

  double _resolveRefundAmount(
    Map<String, dynamic> data,
    double purchaseAmount,
  ) {
    final explicitRefund = _readSettlementAmount(
      data,
      centKeys: const ['refundAmountCents', 'amountRefundedCents'],
      amountKeys: const ['refundAmount'],
    );
    if (explicitRefund > 0) {
      return math.min(explicitRefund, purchaseAmount);
    }

    final status = data['status']?.toString().toLowerCase() ?? '';
    final paymentStatus = data['paymentStatus']?.toString().toLowerCase() ?? '';
    if (data['refunded'] == true ||
        status == 'refunded' ||
        paymentStatus == 'refunded') {
      return purchaseAmount;
    }

    return 0;
  }

  bool _isFullyRefunded(
    Map<String, dynamic> data,
    double purchaseAmount,
    double refundAmount,
  ) {
    if (data['refunded'] == true) return true;
    return refundAmount > 0 && refundAmount >= purchaseAmount;
  }

  String? _readPaymentIntentId(Map<String, dynamic> data) {
    for (final key in const [
      'paymentIntentId',
      'stripePaymentIntentId',
      'stripePaymentId',
    ]) {
      final value = data[key]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  double _readSettlementAmount(
    Map<String, dynamic> data, {
    List<String> centKeys = const ['amountCents'],
    List<String> amountKeys = const ['amount'],
  }) {
    for (final key in centKeys) {
      final value = _readDouble(data[key]);
      if (value > 0) {
        return value / 100;
      }
    }

    for (final key in amountKeys) {
      final value = _readDouble(data[key]);
      if (value > 0) {
        return value;
      }
    }

    return 0;
  }

  bool _requiresDisputeReview(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    if (status.isEmpty) return false;
    return status != 'won' && status != 'warning_closed';
  }

  DateTime? _readSettlementUpdatedAt(Map<String, dynamic> data) {
    return _readDate(data['updatedAt']) ??
        _readDate(data['resolvedAt']) ??
        _readDate(data['createdAt']) ??
        _readDate(data['stripeCreatedAt']);
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _readInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}

class PromoterSettlementSnapshot {
  const PromoterSettlementSnapshot({
    required this.eventId,
    required this.ppvEventId,
    required this.eventName,
    required this.venue,
    required this.promoterName,
    required this.eventDate,
    required this.ppvPriceValue,
    required this.currency,
    required this.usingLiveData,
    required this.hasPpvLane,
    required this.hasRevenueShare,
    required this.hasReconciliation,
    required this.hasBackendSettlement,
    required this.totalPurchases,
    required this.refundedPurchases,
    required this.grossSales,
    required this.stripeFees,
    required this.netRevenue,
    required this.dfcPct,
    required this.dfcCut,
    required this.promoterCut,
    required this.reserveAmount,
    required this.payableNow,
    required this.ledgerGrossSales,
    required this.ledgerStripeFees,
    required this.ledgerNetRevenue,
    required this.backendGross,
    required this.backendFees,
    required this.backendNet,
    required this.backendDelta,
    required this.recordedGross,
    required this.recordedPromoterAmount,
    required this.recordedPlatformAmount,
    required this.recordedPurchases,
    required this.revenueShareDelta,
    required this.refundedAmount,
    required this.activeDisputeCount,
    required this.activeDisputeAmount,
    required this.payoutStatus,
    required this.payoutAttemptCount,
    required this.payoutFailureReason,
    required this.reserveReleaseState,
    required this.reserveReleaseAt,
    required this.reconciledAt,
    required this.eventStartTime,
    required this.totalGrossCents,
    required this.totalNetCents,
    required this.totalRefundedCents,
    required this.totalPayableCents,
    required this.lastPurchaseAt,
    required this.lastPayoutAt,
    required this.ledger,
  });

  final String eventId;
  final String? ppvEventId;
  final String eventName;
  final String venue;
  final String promoterName;
  final DateTime eventDate;
  final double ppvPriceValue;
  final String currency;
  final bool usingLiveData;
  final bool hasPpvLane;
  final bool hasRevenueShare;
  final bool hasReconciliation;
  final bool hasBackendSettlement;
  final int totalPurchases;
  final int refundedPurchases;
  final double grossSales;
  final double stripeFees;
  final double netRevenue;
  final double dfcPct;
  final double dfcCut;
  final double promoterCut;
  final double reserveAmount;
  final double payableNow;
  final double ledgerGrossSales;
  final double ledgerStripeFees;
  final double ledgerNetRevenue;
  final double backendGross;
  final double backendFees;
  final double backendNet;
  final double backendDelta;
  final double recordedGross;
  final double recordedPromoterAmount;
  final double recordedPlatformAmount;
  final int recordedPurchases;
  final double revenueShareDelta;
  final double refundedAmount;
  final int activeDisputeCount;
  final double activeDisputeAmount;
  final String payoutStatus;
  final int payoutAttemptCount;
  final String? payoutFailureReason;
  final String reserveReleaseState;
  final DateTime reserveReleaseAt;
  final DateTime? reconciledAt;
  final DateTime eventStartTime;
  final int totalGrossCents;
  final int totalNetCents;
  final int totalRefundedCents;
  final int totalPayableCents;
  final DateTime? lastPurchaseAt;
  final DateTime? lastPayoutAt;
  final List<PromoterSettlementLedgerRow> ledger;

  String get payoutState => payoutStatus;

  bool get hasPayoutBlock => payoutState.toLowerCase() == 'blocked';

  bool get hasPayoutFailure {
    switch (payoutState.toLowerCase()) {
      case 'failed':
      case 'error':
      case 'rejected':
      case 'transfer_failed':
        return true;
      default:
        return false;
    }
  }

  bool get needsReview =>
      usingLiveData &&
      (activeDisputeCount > 0 ||
          hasPayoutBlock ||
          hasPayoutFailure ||
          !hasBackendSettlement ||
          !hasRevenueShare ||
          revenueShareDelta.abs() >= 1.0 ||
          backendDelta.abs() >= 1.0);

  String get confidenceLabel {
    if (!usingLiveData) return 'DEMO';
    return needsReview ? 'REVIEW' : 'LOCKED';
  }

  String get confidenceDetail {
    if (!usingLiveData) {
      return hasPpvLane
          ? 'Projected numbers only until real purchases land.'
          : 'Create the PPV lane before settlement proof can lock.';
    }
    if (activeDisputeCount > 0) {
      return 'Customer payment risk is open: $activeDisputeCount dispute${activeDisputeCount == 1 ? '' : 's'} still need review before payout sign-off.';
    }
    if (hasPayoutBlock) {
      return payoutFailureReason == null || payoutFailureReason!.isEmpty
          ? 'The payout lane is currently blocked and needs operator review before settlement can move.'
          : 'The payout lane is blocked: $payoutFailureReason.';
    }
    if (hasPayoutFailure) {
      return 'The latest payout state is failed or rejected. Keep the event in review until the payout lane is corrected.';
    }
    if (!hasBackendSettlement) {
      return 'Purchase activity is live, but the Atlas settlement snapshot has not been generated yet.';
    }
    if (!hasRevenueShare) {
      return 'Atlas settlement is present, but the revenue share record has not synced yet.';
    }
    if (!hasReconciliation) {
      return 'Atlas settlement and revenue share totals agree, but the latest reconciliation snapshot is still pending.';
    }
    if (backendDelta.abs() >= 1.0) {
      return 'Atlas settlement and purchase ledger totals need review before payout sign-off.';
    }
    if (revenueShareDelta.abs() >= 1.0) {
      return 'Ledger and revenue share totals need review before payout sign-off.';
    }
    return 'Atlas settlement, purchase ledger, and revenue share totals agree.';
  }

  String get payoutStatusLabel {
    switch (payoutState.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'transferred':
        return 'Paid';
      case 'processing':
        return 'Processing';
      case 'requested':
        return 'Requested';
      case 'scheduled':
        return 'Scheduled';
      case 'blocked':
        return 'Blocked';
      case 'not_requested':
        return hasReconciliation ? 'Pending' : 'Awaiting Sync';
      default:
        return hasReconciliation || hasRevenueShare
            ? 'Pending'
            : 'Awaiting Sync';
    }
  }
}

class PromoterSettlementLedgerRow {
  const PromoterSettlementLedgerRow({
    required this.txNum,
    required this.time,
    required this.gross,
    required this.net,
    required this.dfcPct,
    required this.promoterCut,
    required this.isRefund,
  });

  final int txNum;
  final DateTime time;
  final double gross;
  final double net;
  final double dfcPct;
  final double promoterCut;
  final bool isRefund;
}

class _AtlasSettlementSnapshot {
  const _AtlasSettlementSnapshot({
    required this.eventId,
    required this.gross,
    required this.fees,
    required this.net,
    required this.feeBps,
  });

  final String eventId;
  final double gross;
  final double fees;
  final double net;
  final int feeBps;
}
