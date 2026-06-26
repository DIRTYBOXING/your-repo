import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:datafightcentral/services/dfc_api_client.dart';
import 'package:datafightcentral/services/dfc_payment_client.dart';

void main() {
  group('DfcApiClient', () {
    test('fetchEvent returns parsed JSON on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/events/ppv_test');
        return http.Response(
          jsonEncode({
            'eventId': 'ppv_test',
            'title': 'Test Event',
            'price': '9.99',
          }),
          200,
        );
      });

      final api = DfcApiClient(
        client: mockClient,
        tokenProvider: () => 'test-token',
      );

      final event = await api.fetchEvent('ppv_test');
      expect(event['eventId'], 'ppv_test');
      expect(event['title'], 'Test Event');
      expect(event['price'], '9.99');
    });

    test('fetchEvent throws on non-2xx', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error":"not found"}', 404);
      });

      final api = DfcApiClient(client: mockClient, tokenProvider: () => null);

      expect(() => api.fetchEvent('missing'), throwsException);
    });

    test('post sends auth header when token present', () async {
      String? capturedAuth;
      final mockClient = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{"ok":true}', 200);
      });

      final api = DfcApiClient(
        client: mockClient,
        tokenProvider: () => 'my-bearer-token',
      );

      await api.post('/test', {'key': 'value'});
      expect(capturedAuth, 'Bearer my-bearer-token');
    });

    test('sendAssetRequest posts correct payload', () async {
      Map<String, dynamic>? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"ok":true}', 200);
      });

      final api = DfcApiClient(client: mockClient, tokenProvider: () => null);

      await api.sendAssetRequest('test@example.com', {'eventId': 'e1'});
      expect(capturedBody!['to'], 'test@example.com');
      expect(capturedBody!['payload']['eventId'], 'e1');
    });
  });

  group('DfcPaymentClient', () {
    test('createPpvPurchase returns checkout session on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/checkout');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['userId'], 'user_123');
        expect(body['eventId'], 'ppv_test');
        expect(body['tier'], 'standard');
        return http.Response(
          jsonEncode({
            'session_id': 'cs_test_123',
            'checkout_url': 'https://checkout.stripe.com/pay/cs_test_123',
            'tier': 'standard',
          }),
          200,
        );
      });

      final payments = DfcPaymentClient(
        client: mockClient,
        tokenProvider: () => 'token',
      );

      final result = await payments.createPpvPurchase(
        userId: 'user_123',
        eventId: 'ppv_test',
        tier: 'standard',
      );
      expect(result['session_id'], 'cs_test_123');
    });

    test('createPpvPurchase throws on failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error":"bad request"}', 400);
      });

      final payments = DfcPaymentClient(
        client: mockClient,
        tokenProvider: () => null,
      );

      expect(
        () => payments.createPpvPurchase(
          userId: 'user_123',
          eventId: 'e1',
          tier: 'standard',
        ),
        throwsException,
      );
    });

    test(
      'waitForEntitlement resolves when checkout session is complete',
      () async {
        var attempts = 0;
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/orders/cs_test_123');
          attempts += 1;

          if (attempts == 1) {
            return http.Response(jsonEncode({'status': 'pending'}), 200);
          }

          return http.Response(
            jsonEncode({'sessionId': 'cs_test_123', 'status': 'complete'}),
            200,
          );
        });

        final payments = DfcPaymentClient(
          client: mockClient,
          tokenProvider: () => 'token',
        );

        final result = await payments.waitForEntitlement(
          sessionId: 'cs_test_123',
          maxAttempts: 2,
        );

        expect(result['granted'], true);
        expect(attempts, 2);
      },
    );
  });
}
