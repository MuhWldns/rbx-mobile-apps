import 'dart:convert';
import '../core/constants.dart';
import '../core/http_client.dart';

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
      whitelistedGames: (json['gameWhitelists'] as List?)?.length ?? 0,
      createdAt: json['createdAt'],
    );
  }
}

class LicenseService {
  final ApiClient _client = ApiClient();

  /// Fetch user's licenses.
  Future<List<License>> fetchLicenses() async {
    final response = await _client.get(AppConstants.licenses);
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal memuat licenses');
    }

    final list = data['licenses'] as List? ?? [];
    return list.map((l) => License.fromJson(l)).toList();
  }
}
