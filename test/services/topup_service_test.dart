import 'package:flutter_test/flutter_test.dart';
import 'package:rbx_mobile_apps/services/topup_service.dart';

void main() {
  group('TopUpResult model', () {
    test('fromJson parses complete response', () {
      final json = {
        'orderId': 'order123',
        'publicId': 'TOP-IDR-2606-000001',
        'amount': 50000,
        'paymentUrl': 'https://bayar.gg/pay/123',
        'qrisImageUrl': 'https://bayar.gg/qris/123.png',
        'expiresAt': '2026-06-08T17:30:00.000Z',
      };

      final result = TopUpResult.fromJson(json);

      expect(result.orderId, 'order123');
      expect(result.publicId, 'TOP-IDR-2606-000001');
      expect(result.amount, 50000);
      expect(result.paymentUrl, 'https://bayar.gg/pay/123');
      expect(result.qrisImageUrl, 'https://bayar.gg/qris/123.png');
      expect(result.expiresAt, '2026-06-08T17:30:00.000Z');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'orderId': 'order456',
        'amount': 10000,
      };

      final result = TopUpResult.fromJson(json);

      expect(result.orderId, 'order456');
      expect(result.publicId, isNull);
      expect(result.amount, 10000);
      expect(result.paymentUrl, isNull);
      expect(result.qrisImageUrl, isNull);
      expect(result.expiresAt, isNull);
    });
  });

  group('TopUpStatus model', () {
    test('fromJson parses pending status', () {
      final json = {
        'paid': false,
        'status': 'PENDING',
        'amount': 50000,
        'finalAmount': null,
      };

      final status = TopUpStatus.fromJson(json);

      expect(status.paid, false);
      expect(status.status, 'PENDING');
      expect(status.amount, 50000);
      expect(status.finalAmount, isNull);
    });

    test('fromJson parses completed status', () {
      final json = {
        'paid': true,
        'status': 'COMPLETED',
        'amount': 50000,
        'finalAmount': 50000,
      };

      final status = TopUpStatus.fromJson(json);

      expect(status.paid, true);
      expect(status.status, 'COMPLETED');
      expect(status.amount, 50000);
      expect(status.finalAmount, 50000);
    });

    test('fromJson defaults to not paid and PENDING when missing', () {
      final json = <String, dynamic>{};

      final status = TopUpStatus.fromJson(json);

      expect(status.paid, false);
      expect(status.status, 'PENDING');
      expect(status.amount, 0);
      expect(status.finalAmount, isNull);
    });
  });
}
