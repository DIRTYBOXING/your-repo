import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:datafightcentral/features/ppv/services/ppv_access_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  group('PPVAccessService.hasAccess', () {
    late FakeFirebaseFirestore firestore;
    late _MockFirebaseAuth auth;
    late _MockUser user;
    late PPVAccessService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = _MockFirebaseAuth();
      user = _MockUser();

      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('user_123');

      service = PPVAccessService(firestore: firestore, auth: auth);
    });

    test('returns true for an active canonical purchase record', () async {
      await firestore.collection('ppv_events').doc('canonical_evt').set({
        'eventId': 'legacy_evt',
      });
      await firestore
          .collection('ppv_purchases')
          .doc('user_123_canonical_evt')
          .set({
            'userId': 'user_123',
            'ppvId': 'canonical_evt',
            'status': 'completed',
            'accessGranted': true,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      expect(await service.hasAccess('legacy_evt'), isTrue);
    });

    test('returns false when a refunded purchase record exists', () async {
      await firestore
          .collection('ppv_purchases')
          .doc('user_123_evt_refunded')
          .set({
            'userId': 'user_123',
            'ppvId': 'evt_refunded',
            'status': 'refunded',
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      await firestore
          .collection('ppv_access')
          .doc('user_123_evt_refunded')
          .set({
            'userId': 'user_123',
            'eventId': 'evt_refunded',
            'isActive': true,
            'grantedAt': Timestamp.fromDate(DateTime.now()),
          });

      expect(await service.hasAccess('evt_refunded'), isFalse);
    });

    test(
      'falls back to nested access records when purchases are not authoritative',
      () async {
        await firestore
            .collection('ppv_purchases')
            .doc('user_123_evt_access_only')
            .set({
              'userId': 'user_123',
              'ppvId': 'evt_access_only',
              'note': 'legacy non-authoritative purchase stub',
            });
        await firestore
            .collection('users')
            .doc('user_123')
            .collection('ppv_access')
            .doc('evt_access_only')
            .set({
              'userId': 'user_123',
              'eventId': 'evt_access_only',
              'isActive': true,
              'grantedAt': Timestamp.fromDate(DateTime.now()),
            });

        expect(await service.hasAccess('evt_access_only'), isTrue);
      },
    );

    test('returns false when there is no signed-in user', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(await service.hasAccess('evt_anything'), isFalse);
    });
  });
}
