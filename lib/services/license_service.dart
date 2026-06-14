import 'package:dio/dio.dart';

import '../core/constants.dart';

class License {
  final String id;
  final String? publicId;
  final String? productName;
  final String licenseKey;
  final String licenseType;
  final String status;
  final int maxGames;
  final int whitelistedGames;
  final String? createdAt;

  License({
    required this.id,
    this.publicId,
    this.productName,
    required this.licenseKey,
    required this.licenseType,
    required this.status,
    required this.maxGames,
    required this.whitelistedGames,
    this.createdAt,
  });

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: json['id'] ?? '',
      publicId: json['publicId'],
      productName: json['product']?['name'] ?? json['productName'],
      licenseKey: json['licenseKey'] ?? '',
      licenseType: json['licenseType'] ?? 'PERSONAL',
      status: json['status'] ?? 'ACTIVE',
      maxGames: json['maxGames'] ?? 3,
      whitelistedGames: (json['gameWhitelists'] as List?)?.length ??
          (json['games'] as List?)?.length ??
          0,
      createdAt: json['createdAt'],
    );
  }
}

class LicenseService {
  LicenseService({required this.dio});

  final Dio dio;

  Future<List<License>> fetchLicenses() async {
    final res = await dio.get<Map<String, dynamic>>(AppConstants.licenses);
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal memuat licenses');
    }
    final list = data['licenses'] as List? ?? [];
    return list
        .map((l) => License.fromJson(l as Map<String, dynamic>))
        .toList();
  }
}
