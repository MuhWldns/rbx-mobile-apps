import 'package:flutter_test/flutter_test.dart';
import 'package:rbx_mobile_apps/models/user.dart';

void main() {
  group('User model', () {
    test('fromJson parses complete user data correctly', () {
      final json = {
        'id': 'user123',
        'publicId': 'ACC-IDN-2606-000001',
        'email': 'test@example.com',
        'username': 'testuser',
        'fullName': 'Test User',
        'displayName': 'Test',
        'avatarUrl': 'https://example.com/avatar.png',
        'lastLoginAt': '2026-05-15T00:00:00.000Z',
        'lastLoginProvider': 'GOOGLE',
        'role': 'USER',
        'walletBalance': 50000,
        'totalTopUp': 100000,
        'totalSpent': 50000,
        'robloxUserId': '123456789',
        'freeAudio': {
          'dateKey': '2026-05-15',
          'usedToday': 1,
          'dailyLimit': 3,
          'paidAudioCost': 2000,
        },
        'providers': ['GOOGLE', 'DISCORD'],
      };

      final user = User.fromJson(json);

      expect(user.id, 'user123');
      expect(user.publicId, 'ACC-IDN-2606-000001');
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.fullName, 'Test User');
      expect(user.displayName, 'Test');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.lastLoginAt, '2026-05-15T00:00:00.000Z');
      expect(user.lastLoginProvider, 'GOOGLE');
      expect(user.role, 'USER');
      expect(user.walletBalance, 50000);
      expect(user.totalTopUp, 100000);
      expect(user.totalSpent, 50000);
      expect(user.robloxUserId, '123456789');
      expect(user.providers, ['GOOGLE', 'DISCORD']);
    });

    test('fromJson handles null/missing optional fields', () {
      final json = {
        'id': 'user456',
        'role': 'ADMIN',
        'walletBalance': 0,
        'totalTopUp': 0,
        'totalSpent': 0,
      };

      final user = User.fromJson(json);

      expect(user.id, 'user456');
      expect(user.publicId, isNull);
      expect(user.email, isNull);
      expect(user.username, isNull);
      expect(user.fullName, isNull);
      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.lastLoginProvider, isNull);
      expect(user.role, 'ADMIN');
      expect(user.walletBalance, 0);
      expect(user.totalTopUp, 0);
      expect(user.totalSpent, 0);
      expect(user.robloxUserId, isNull);
      expect(user.freeAudio, isNull);
      expect(user.providers, isEmpty);
    });

    test('fromJson defaults role to USER when missing', () {
      final json = {'id': 'user789'};
      final user = User.fromJson(json);
      expect(user.role, 'USER');
    });

    test('fromJson defaults wallet values to 0 when missing', () {
      final json = {'id': 'user000'};
      final user = User.fromJson(json);
      expect(user.walletBalance, 0);
      expect(user.totalTopUp, 0);
      expect(user.totalSpent, 0);
    });
  });

  group('FreeAudio model', () {
    test('fromJson parses correctly', () {
      final json = {
        'dateKey': '2026-06-08',
        'usedToday': 2,
        'dailyLimit': 3,
        'paidAudioCost': 2000,
      };

      final freeAudio = FreeAudio.fromJson(json);

      expect(freeAudio.dateKey, '2026-06-08');
      expect(freeAudio.usedToday, 2);
      expect(freeAudio.dailyLimit, 3);
      expect(freeAudio.paidAudioCost, 2000);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};

      final freeAudio = FreeAudio.fromJson(json);

      expect(freeAudio.dateKey, '');
      expect(freeAudio.usedToday, 0);
      expect(freeAudio.dailyLimit, 3);
      expect(freeAudio.paidAudioCost, 2000);
    });
  });
}
