import 'package:datafightcentral/shared/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UNIT TESTS — NotificationModel serialisation & helpers
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  group('NotificationModel', () {
    final now = DateTime(2026, 6, 15, 10);
    final baseNotification = NotificationModel(
      id: 'n1',
      userId: 'user123',
      type: NotificationType.fightOffer,
      title: 'Fight Offer from Promoter',
      body: 'You have a new fight opportunity on June 20.',
      actionRoute: '/events',
      senderId: 'promoter1',
      senderName: 'Big Show Promotions',
      createdAt: now,
    );

    test('fields are stored correctly', () {
      expect(baseNotification.id, 'n1');
      expect(baseNotification.userId, 'user123');
      expect(baseNotification.type, NotificationType.fightOffer);
      expect(baseNotification.title, 'Fight Offer from Promoter');
      expect(baseNotification.isRead, false);
      expect(baseNotification.actionRoute, '/events');
      expect(baseNotification.senderId, 'promoter1');
    });

    test('toFirestore produces correct map', () {
      final map = baseNotification.toFirestore();
      expect(map['userId'], 'user123');
      expect(map['type'], 'fightOffer');
      expect(map['title'], 'Fight Offer from Promoter');
      expect(map['body'], 'You have a new fight opportunity on June 20.');
      expect(map['isRead'], false);
      expect(map['actionRoute'], '/events');
      expect(map['senderId'], 'promoter1');
      expect(map['senderName'], 'Big Show Promotions');
    });

    test('copyWith preserves unchanged fields', () {
      final read = baseNotification.copyWith(isRead: true);
      expect(read.isRead, true);
      expect(read.id, 'n1');
      expect(read.title, 'Fight Offer from Promoter');
      expect(read.type, NotificationType.fightOffer);
      expect(read.actionRoute, '/events');
    });

    test('copyWith changes specified fields', () {
      final updated = baseNotification.copyWith(
        title: 'Updated Title',
        type: NotificationType.achievement,
      );
      expect(updated.title, 'Updated Title');
      expect(updated.type, NotificationType.achievement);
      expect(updated.body, baseNotification.body); // unchanged
    });

    test('Equatable compares by value', () {
      final copy = NotificationModel(
        id: 'n1',
        userId: 'user123',
        type: NotificationType.fightOffer,
        title: 'Fight Offer from Promoter',
        body: 'You have a new fight opportunity on June 20.',
        actionRoute: '/events',
        createdAt: now,
      );
      // Same id, userId, type, title, body, isRead, actionRoute, createdAt
      expect(baseNotification, equals(copy));
    });

    test('timeAgo returns "just now" for recent', () {
      final recent = NotificationModel(
        id: 'r1',
        userId: 'u1',
        type: NotificationType.general,
        title: 'Test',
        body: 'Test body',
        createdAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      expect(recent.timeAgo, 'just now');
    });

    test('timeAgo returns minutes for <60min', () {
      final mins = NotificationModel(
        id: 'm1',
        userId: 'u1',
        type: NotificationType.general,
        title: 'Test',
        body: 'Test',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(mins.timeAgo, '15m ago');
    });

    test('timeAgo returns hours for <24h', () {
      final hours = NotificationModel(
        id: 'h1',
        userId: 'u1',
        type: NotificationType.general,
        title: 'Test',
        body: 'Test',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(hours.timeAgo, '3h ago');
    });

    test('timeAgo returns days for <7d', () {
      final days = NotificationModel(
        id: 'd1',
        userId: 'u1',
        type: NotificationType.general,
        title: 'Test',
        body: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(days.timeAgo, '5d ago');
    });

    test('timeAgo returns weeks for >=7d', () {
      final weeks = NotificationModel(
        id: 'w1',
        userId: 'u1',
        type: NotificationType.general,
        title: 'Test',
        body: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      );
      expect(weeks.timeAgo, '2w ago');
    });
  });

  group('NotificationType', () {
    test('every type has an icon', () {
      for (final type in NotificationType.values) {
        expect(
          type.icon.isNotEmpty,
          true,
          reason: '${type.name} should have an icon',
        );
      }
    });

    test('every type has a label', () {
      for (final type in NotificationType.values) {
        expect(
          type.label.isNotEmpty,
          true,
          reason: '${type.name} should have a label',
        );
      }
    });

    test('fightOffer has correct icon and label', () {
      expect(NotificationType.fightOffer.icon, '🥊');
      expect(NotificationType.fightOffer.label, 'Fight Offer');
    });

    test('achievement has correct icon and label', () {
      expect(NotificationType.achievement.icon, '🏆');
      expect(NotificationType.achievement.label, 'Achievement');
    });

    test('safetyAlert has correct icon', () {
      expect(NotificationType.safetyAlert.icon, '🛡️');
      expect(NotificationType.safetyAlert.label, 'Safety');
    });
  });
}
