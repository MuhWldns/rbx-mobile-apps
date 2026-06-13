import 'package:flutter_test/flutter_test.dart';
import 'package:rbx_mobile_apps/services/license_service.dart';

void main() {
  group('License model', () {
    test('fromJson parses complete license data', () {
      final json = {
        'id': 'lic123',
        'publicId': 'LIC-PER-2606-000001',
        'product': {'name': 'Advanced UI System'},
        'licenseKey': 'RBXR-A1B2-C3D4-E5F6-G7H8',
        'licenseType': 'PERSONAL',
        'status': 'ACTIVE',
        'maxGames': 3,
        'gameWhitelists': [
          {'id': 'gw1'},
          {'id': 'gw2'},
        ],
        'createdAt': '2026-06-01T00:00:00.000Z',
      };

      final license = License.fromJson(json);

      expect(license.id, 'lic123');
      expect(license.publicId, 'LIC-PER-2606-000001');
      expect(license.productName, 'Advanced UI System');
      expect(license.licenseKey, 'RBXR-A1B2-C3D4-E5F6-G7H8');
      expect(license.licenseType, 'PERSONAL');
      expect(license.status, 'ACTIVE');
      expect(license.maxGames, 3);
      expect(license.whitelistedGames, 2);
      expect(license.createdAt, '2026-06-01T00:00:00.000Z');
    });

    test('fromJson handles missing product and gameWhitelists', () {
      final json = {
        'id': 'lic456',
        'licenseKey': 'RBXR-XXXX-YYYY-ZZZZ',
        'licenseType': 'COMMERCIAL',
        'status': 'SUSPENDED',
        'maxGames': 10,
      };

      final license = License.fromJson(json);

      expect(license.id, 'lic456');
      expect(license.publicId, isNull);
      expect(license.productName, isNull);
      expect(license.licenseKey, 'RBXR-XXXX-YYYY-ZZZZ');
      expect(license.licenseType, 'COMMERCIAL');
      expect(license.status, 'SUSPENDED');
      expect(license.maxGames, 10);
      expect(license.whitelistedGames, 0);
      expect(license.createdAt, isNull);
    });

    test('fromJson uses productName fallback when product map is absent', () {
      final json = {
        'id': 'lic789',
        'productName': 'Fallback Name',
        'licenseKey': 'KEY',
        'licenseType': 'ENTERPRISE',
        'status': 'ACTIVE',
        'maxGames': 999,
      };

      final license = License.fromJson(json);
      expect(license.productName, 'Fallback Name');
    });

    test('fromJson defaults values correctly', () {
      final json = {'id': 'lic000'};

      final license = License.fromJson(json);

      expect(license.licenseKey, '');
      expect(license.licenseType, 'PERSONAL');
      expect(license.status, 'ACTIVE');
      expect(license.maxGames, 3);
      expect(license.whitelistedGames, 0);
    });
  });
}
