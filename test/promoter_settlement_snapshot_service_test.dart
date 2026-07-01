import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datafightcentral/shared/services/promoter_settlement_snapshot_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PromoterSettlementSnapshotService', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('uses Atlas settlement authority when available', () async {
      await firestore.collection('events').doc('event-main').set({
        'name': 'DFC Fight Night',
        'venue': 'Brisbane Arena',
        'promotionName': 'DFC Promotions',
        'eventDate': Timestamp.fromDate(DateTime(2026, 4, 17)),
      });
      await firestore.collection('ppv_purchases').doc('buy-1').set({
        'eventId': 'event-main',
        'amountCents': 2500,
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 17, 12)),
        'status': 'completed',
      });
      await firestore.collection('revenue_shares').doc('share-1').set({
        'ppvEventId': 'event-main',
        'totalRevenue': 25.00,
        'promoterAmount': 16.78,
        'platformAmount': 7.19,
        'totalPurchases': 1,
        'payoutStatus': 'processing',
      });

      final client = MockClient((request) async {
        expect(request.url.path, '/ppv/settlements/event-main');
        return http.Response(
          jsonEncode({
            'event_id': 'event-main',
            'gross_cents': 2500,
            'fees_cents': 103,
            'net_cents': 2397,
            'fee_bps': 1000,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PromoterSettlementSnapshotService(
        firestore: firestore,
        client: client,
        atlasBaseUrl: 'http://localhost:8000',
      );

      final snapshot = await service.getSnapshot(eventId: 'event-main');

      expect(snapshot.hasBackendSettlement, isTrue);
      expect(snapshot.grossSales, 25.0);
      expect(snapshot.stripeFees, 1.03);
      expect(snapshot.netRevenue, 23.97);
      expect(snapshot.revenueShareDelta.abs(), lessThan(0.01));
      expect(snapshot.confidenceLabel, 'LOCKED');
    });

    test('flags review when backend settlement is missing', () async {
      await firestore.collection('events').doc('event-main').set({
        'name': 'DFC Fight Night',
      });
      await firestore.collection('ppv_purchases').doc('buy-1').set({
        'eventId': 'event-main',
        'amountCents': 2000,
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 17, 12)),
        'status': 'completed',
      });

      final client = MockClient((_) async => http.Response('Not found', 404));

      final service = PromoterSettlementSnapshotService(
        firestore: firestore,
        client: client,
        atlasBaseUrl: 'http://localhost:8000',
      );

      final snapshot = await service.getSnapshot(eventId: 'event-main');

      expect(snapshot.usingLiveData, isTrue);
      expect(snapshot.hasBackendSettlement, isFalse);
      expect(snapshot.needsReview, isTrue);
      expect(snapshot.confidenceDetail, contains('Atlas settlement snapshot'));
    });
  });
}
