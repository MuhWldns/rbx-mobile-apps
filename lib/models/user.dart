class FreeAudio {
  final String dateKey;
  final int usedToday;
  final int dailyLimit;
  final int paidAudioCost;

  FreeAudio({
    required this.dateKey,
    required this.usedToday,
    required this.dailyLimit,
    required this.paidAudioCost,
  });

  factory FreeAudio.fromJson(Map<String, dynamic> json) {
    return FreeAudio(
      dateKey: json['dateKey'] ?? '',
      usedToday: json['usedToday'] ?? 0,
      dailyLimit: json['dailyLimit'] ?? 3,
      paidAudioCost: json['paidAudioCost'] ?? 2000,
    );
  }
}

class User {
  final String id;
  final String? publicId;
  final String? email;
  final String? username;
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;
  final String? lastLoginAt;
  final String? lastLoginProvider;
  final String role;
  final int walletBalance;
  final int totalTopUp;
  final int totalSpent;
  final String? robloxUserId;
  final FreeAudio? freeAudio;
  final List<String> providers;

  User({
    required this.id,
    this.publicId,
    this.email,
    this.username,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.lastLoginAt,
    this.lastLoginProvider,
    required this.role,
    required this.walletBalance,
    required this.totalTopUp,
    required this.totalSpent,
    this.robloxUserId,
    this.freeAudio,
    required this.providers,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      publicId: json['publicId'],
      email: json['email'],
      username: json['username'],
      fullName: json['fullName'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      lastLoginAt: json['lastLoginAt'],
      lastLoginProvider: json['lastLoginProvider'],
      role: json['role'] ?? 'USER',
      walletBalance: json['walletBalance'] ?? 0,
      totalTopUp: json['totalTopUp'] ?? 0,
      totalSpent: json['totalSpent'] ?? 0,
      robloxUserId: json['robloxUserId'],
      freeAudio: json['freeAudio'] != null
          ? FreeAudio.fromJson(json['freeAudio'])
          : null,
      providers: List<String>.from(json['providers'] ?? []),
    );
  }
}
