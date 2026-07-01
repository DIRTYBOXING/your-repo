import 'package:datafightcentral/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UNIT TESTS — UserModel serialisation round-trip
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  group('UserModel', () {
    test('copyWith preserves unchanged fields', () {
      final user = UserModel(
        id: 'u1',
        email: 'test@dfc.com',
        displayName: 'Fighter One',
        role: UserRole.fighter,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final updated = user.copyWith(displayName: 'Fighter Two');

      expect(updated.displayName, 'Fighter Two');
      expect(updated.id, 'u1');
      expect(updated.email, 'test@dfc.com');
      expect(updated.role, UserRole.fighter);
    });

    test('toFirestore produces correct map', () {
      final user = UserModel(
        id: 'u2',
        email: 'coach@dfc.com',
        displayName: 'Coach Mike',
        role: UserRole.coach,
        bio: 'MMA coach',
        emailVerified: true,
        onboardingCompleted: true,
        createdAt: DateTime(2026, 2),
        updatedAt: DateTime(2026, 2),
      );

      final map = user.toFirestore();

      expect(map['email'], 'coach@dfc.com');
      expect(map['displayName'], 'Coach Mike');
      expect(map['role'], 'coach');
      expect(map['bio'], 'MMA coach');
      expect(map['emailVerified'], true);
      expect(map['onboardingCompleted'], true);
    });

    test('UserRole.fromString handles all roles', () {
      expect(UserRole.fromString('fighter'), UserRole.fighter);
      expect(UserRole.fromString('coach'), UserRole.coach);
      expect(UserRole.fromString('gym'), UserRole.gym);
      expect(UserRole.fromString('promoter'), UserRole.promoter);
      expect(UserRole.fromString('sponsor'), UserRole.sponsor);
      expect(UserRole.fromString('fan'), UserRole.fan);
      expect(UserRole.fromString('admin'), UserRole.admin);
    });

    test('UserRole.fromString defaults to fan for unknown', () {
      expect(UserRole.fromString('unknown'), UserRole.fan);
      expect(UserRole.fromString(''), UserRole.fan);
    });

    test('UserRole displayName is human readable', () {
      expect(UserRole.fighter.displayName, 'Fighter');
      expect(UserRole.coach.displayName, 'Coach');
      expect(UserRole.gym.displayName, 'Gym');
      expect(UserRole.promoter.displayName, 'Promoter');
    });

    test('Equatable equality works', () {
      final a = UserModel(
        id: 'u3',
        email: 'a@b.com',
        role: UserRole.fan,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final b = UserModel(
        id: 'u3',
        email: 'a@b.com',
        role: UserRole.fan,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(a, equals(b));
    });
  });
}
