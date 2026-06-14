import 'package:dio/dio.dart';

import '../core/constants.dart';

class TopUpResult {
  final String orderId;
  final String? publicId;
  final int amount;
  final String? paymentUrl;
  final String? qrisImageUrl;
  final String? expiresAt;

  TopUpResult({
    required this.orderId,
    this.publicId,
    required this.amount,
    this.paymentUrl,
    this.qrisImageUrl,
    this.expiresAt,
  });

  factory TopUpResult.fromJson(Map<String, dynamic> json) {
    return TopUpResult(
      orderId: json['orderId'] ?? '',
      publicId: json['publicId'],
      amount: json['amount'] ?? 0,
      paymentUrl: json['paymentUrl'],
      qrisImageUrl: json['qrisImageUrl'],
      expiresAt: json['expiresAt'],
    );
  }
}

class TopUpStatus {
  final bool paid;
  final String status;
  final int amount;
  final int? finalAmount;

  TopUpStatus({
    required this.paid,
    required this.status,
    required this.amount,
    this.finalAmount,
  });

  factory TopUpStatus.fromJson(Map<String, dynamic> json) {
    return TopUpStatus(
      paid: json['paid'] ?? false,
      status: json['status'] ?? 'PENDING',
      amount: json['amount'] ?? 0,
      finalAmount: json['finalAmount'],
    );
  }
}

class TopUpService {
  TopUpService({required this.dio});

  final Dio dio;

  Future<TopUpResult> createTopUp({
    required int amount,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    final body = <String, dynamic>{'amount': amount};
    if (customerName != null) body['customer_name'] = customerName;
    if (customerEmail != null) body['customer_email'] = customerEmail;
    if (customerPhone != null) body['customer_phone'] = customerPhone;

    final res = await dio.post<Map<String, dynamic>>(
      AppConstants.topupCreate,
      data: body,
    );
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 201) {
      throw Exception(data['error'] ?? 'Gagal membuat pembayaran');
    }
    return TopUpResult.fromJson(data);
  }

  Future<TopUpStatus> getStatus(String reference) async {
    final res = await dio.get<Map<String, dynamic>>(
      AppConstants.topupStatus(reference),
    );
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal mengecek status');
    }
    return TopUpStatus.fromJson(data);
  }
}
