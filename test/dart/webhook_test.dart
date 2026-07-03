// test/dart/webhook_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payments webhook fixtures', () {
    test('load checkout.session.completed fixture', () async {
      final file = File(
        'test/fixtures/webhooks/checkout.session.completed.json',
      );
      final payload = jsonDecode(await file.readAsString());
      expect(payload['type'], equals('checkout.session.completed'));
      expect(payload['data']['object']['payment_status'], equals('paid'));
    });

    test('load payment_intent.succeeded fixture', () async {
      final file = File('test/fixtures/webhooks/payment_intent.succeeded.json');
      final payload = jsonDecode(await file.readAsString());
      expect(payload['type'], equals('payment_intent.succeeded'));
    });

    test('load charge.refunded fixture', () async {
      final file = File('test/fixtures/webhooks/charge.refunded.json');
      final payload = jsonDecode(await file.readAsString());
      expect(payload['type'], equals('charge.refunded'));
    });

    test('load charge.dispute.created fixture', () async {
      final file = File('test/fixtures/webhooks/charge.dispute.created.json');
      final payload = jsonDecode(await file.readAsString());
      expect(payload['type'], equals('charge.dispute.created'));
    });

    test('all fixtures parse as JSON', () async {
      final dir = Directory('test/fixtures/webhooks');
      final files = dir.listSync().whereType<File>().toList();
      for (final f in files) {
        final content = await f.readAsString();
        expect(() => jsonDecode(content), returnsNormally);
      }
    });
  });
}
