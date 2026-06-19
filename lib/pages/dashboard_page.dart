import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../services/license_service.dart';
import '../widgets/panel_card.dart';
import '../widgets/product_card.dart';

final _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Dummy products shaped exactly like the `GET /products` response.
/// Swap this for a real `ProductService.fetchProducts()` call later —
/// the JSON shape matches so `Product.fromJson` stays unchanged.
final List<Product> _dummyProducts = <Map<String, dynamic>>[
  {
    'id': 'clx4prod1',
    'name': 'UI System Pro',
    'slug': 'ui-system-pro',
    'shortDesc': 'Professional UI framework for Roblox games',
    'thumbnail': '/images/ui-system-pro.png',
    'pricePersonal': 50000,
    'priceCommercial': 150000,
    'priceEnterprise': 500000,
    'featured': true,
    'version': '1.2.0',
    'tags': ['ui', 'framework', 'professional'],
    'category': {'id': 'clx4cat1', 'name': 'UI Systems', 'slug': 'ui-systems'},
    'image': '/images/ui-system-pro.png',
    'soldCount': 42,
    'createdAt': '2026-05-01T10:00:00.000Z',
  },
  {
    'id': 'clx4prod2',
    'name': 'Anti-Cheat Kit',
    'slug': 'anti-cheat-kit',
    'shortDesc': 'Server-side exploit detection and mitigation',
    'thumbnail': '/images/anti-cheat.png',
    'pricePersonal': 75000,
    'priceCommercial': 200000,
    'priceEnterprise': 600000,
    'featured': false,
    'version': '2.0.1',
    'tags': ['security', 'anti-cheat'],
    'category': {
      'id': 'clx4cat2',
      'name': 'Utility Scripts',
      'slug': 'utility-scripts',
    },
    'image': '/images/anti-cheat.png',
    'soldCount': 128,
    'createdAt': '2026-04-20T10:00:00.000Z',
  },
  {
    'id': 'clx4prod3',
    'name': 'DataStore Manager',
    'slug': 'datastore-manager',
    'shortDesc': 'Reliable save system with caching and retries',
    'thumbnail': '/images/datastore.png',
    'pricePersonal': 35000,
    'priceCommercial': 100000,
    'priceEnterprise': 350000,
    'featured': true,
    'version': '3.4.0',
    'tags': ['data', 'utility'],
    'category': {
      'id': 'clx4cat2',
      'name': 'Utility Scripts',
      'slug': 'utility-scripts',
    },
    'image': '/images/datastore.png',
    'soldCount': 87,
    'createdAt': '2026-05-10T10:00:00.000Z',
  },
].map(Product.fromJson).toList();

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final LicenseService _licenseService = context.read<LicenseService>();
  List<License> _licenses = [];
  bool _licensesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    try {
      final licenses = await _licenseService.fetchLicenses();
      if (mounted) {
        setState(() {
          _licenses = licenses;
          _licensesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _licensesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeLicenses =
        _licenses.where((l) => l.status == 'ACTIVE').length;
    final freeUsed = user.freeAudio?.usedToday ?? 0;
    final freeLimit = user.freeAudio?.dailyLimit ?? 3;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('DASHBOARD',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              'Hello, ${user.displayName ?? user.fullName ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back to RBX Royale.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Profile Card
            PanelCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    backgroundColor: AppTheme.violet.withOpacity(0.2),
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person, color: AppTheme.violet)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.fullName ?? user.email ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wallet Card
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.violet.withOpacity(0.1),
                          AppTheme.fuchsia.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rupiahFormat.format(user.walletBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total top up: ${_rupiahFormat.format(user.totalTopUp)} · Total spent: ${_rupiahFormat.format(user.totalSpent)}',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/topup'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        backgroundColor: AppTheme.violet,
                      ),
                      child: const Text(
                        'Top Up Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Audio Quota Card
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Audio Quota',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Free audio today',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$freeUsed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '/$freeLimit',
                                  style: TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Resets daily',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: freeLimit > 0 ? (freeUsed / freeLimit).clamp(0.0, 1.0) : 0,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.violet),
                      minHeight: 8,
                    ),
                  ),
                  if (freeUsed >= freeLimit) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Quota exhausted. Next audio will cost ${_rupiahFormat.format(user.freeAudio?.paidAudioCost ?? 2000)}/file.',
                      style: const TextStyle(
                        color: AppTheme.amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Licenses Card
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Licenses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_licensesLoading)
                    const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$activeLicenses',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' active',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _licenses.isEmpty
                          ? 'Belum punya license.'
                          : '${_licenses.length} total license dimiliki.',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Top Up',
                    onTap: () => context.go('/topup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    onTap: () => context.go('/profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Featured products (dummy)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Coming soon',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dummyProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ProductCard(product: _dummyProducts[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.violet, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
