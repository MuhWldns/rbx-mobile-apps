import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/panel_card.dart';
import '../widgets/gradient_button.dart';

final _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final UserService _userService = context.read<UserService>();
  final TextEditingController _robloxIdController = TextEditingController();

  bool _robloxSaving = false;
  Map<String, String>? _robloxResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.robloxUserId != null) {
      _robloxIdController.text = user!.robloxUserId!;
    }
  }

  @override
  void dispose() {
    _robloxIdController.dispose();
    super.dispose();
  }

  Future<void> _saveRobloxId() async {
    final value = _robloxIdController.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Roblox User ID tidak boleh kosong');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      setState(() => _error = 'Roblox User ID harus berupa angka');
      return;
    }

    setState(() {
      _robloxSaving = true;
      _error = null;
      _robloxResult = null;
    });

    try {
      final result = await _userService.saveRobloxId(value);
      setState(() => _robloxResult = result);
      if (mounted) {
        context.read<AuthProvider>().refreshUser();
        _showSnackBar('Roblox User ID berhasil disimpan!', isError: false);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      _showSnackBar(_error!, isError: true);
    } finally {
      setState(() => _robloxSaving = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.rose : AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('PROFILE', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              'Account Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola akun dan sambungkan Roblox ID kamu.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Account Info
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Account ID', value: user.publicId ?? user.id),
                  _InfoRow(label: 'Display Name', value: user.displayName ?? user.fullName ?? '-'),
                  _InfoRow(label: 'Email', value: user.email ?? '-'),
                  _InfoRow(label: 'Login Provider', value: user.lastLoginProvider ?? '-'),
                  _InfoRow(
                    label: 'Role',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: user.role == 'ADMIN'
                            ? AppTheme.violet.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        user.role,
                        style: TextStyle(
                          color: user.role == 'ADMIN'
                              ? AppTheme.violet
                              : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Roblox Account Binding
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Roblox Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sambungkan akun Roblox kamu untuk verifikasi kepemilikan game saat whitelist license.',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Connected status
                  if (user.robloxUserId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.emerald.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.emerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Roblox ID tersambung: ${user.robloxUserId}',
                            style: TextStyle(
                              color: AppTheme.emerald,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Input
                  Text(
                    'Roblox User ID',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _robloxIdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Contoh: 123456789',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (v) {
                            // Only allow digits
                            final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                            if (cleaned != v) {
                              _robloxIdController.value = TextEditingValue(
                                text: cleaned,
                                selection: TextSelection.collapsed(offset: cleaned.length),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: GradientButton(
                          text: _robloxSaving ? '...' : 'Save',
                          isLoading: _robloxSaving,
                          onPressed: _robloxSaving ? null : _saveRobloxId,
                        ),
                      ),
                    ],
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.rose, fontSize: 12),
                    ),
                  ],

                  // Success result
                  if (_robloxResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.emerald.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        'Verified: ${_robloxResult!['displayName']} (@${_robloxResult!['username']})',
                        style: TextStyle(
                          color: AppTheme.emerald,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cara menemukan Roblox User ID:',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _InstructionStep(number: '1', text: 'Buka browser, login ke roblox.com'),
                        _InstructionStep(number: '2', text: 'Klik profil kamu (avatar di kanan atas)'),
                        _InstructionStep(number: '3', text: 'Lihat URL: roblox.com/users/123456789/profile'),
                        _InstructionStep(number: '4', text: 'Angka tersebut adalah User ID kamu'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wallet Summary
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
                  Row(
                    children: [
                      Expanded(child: _WalletStat(label: 'Saldo', value: _rupiahFormat.format(user.walletBalance), color: Colors.white)),
                      Expanded(child: _WalletStat(label: 'Total Top Up', value: _rupiahFormat.format(user.totalTopUp), color: AppTheme.emerald)),
                      Expanded(child: _WalletStat(label: 'Total Spent', value: _rupiahFormat.format(user.totalSpent), color: AppTheme.rose)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.rose.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppTheme.rose,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _InfoRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          child ??
              Text(
                value ?? '-',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WalletStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
