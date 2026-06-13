import 'dart:convert';
import '../core/constants.dart';
import '../core/http_client.dart';

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
  final ApiClient _client = ApiClient();

  /// Create a QRIS top-up payment.
  Future<TopUpResult> createTopUp({
    required int amount,
    String? customerName,
    String? customerEmail,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
    };
    if (customerName != null) body['customer_name'] = customerName;
    if (customerEmail != null) body['customer_email'] = customerEmail;

    final response = await _client.post(AppConstants.topupCreate, body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Gagal membuat pembayaran');
    }

    return TopUpResult.fromJson(data);
  }

  /// Poll payment status.
  Future<TopUpStatus> getStatus(String reference) async {
    final response = await _client.get(AppConstants.topupStatus(reference));
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal mengecek status');
    }

    return TopUpStatus.fromJson(data);
  }
}
