import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/topup_service.dart';
import '../widgets/panel_card.dart';
import '../widgets/gradient_button.dart';

final _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

enum TopUpStep { input, processing, qris, success, failed, timeout }

const List<int> _quickAmounts = [10000, 25000, 50000, 100000, 250000, 500000];

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final TopUpService _topUpService = TopUpService();
  final TextEditingController _amountController = TextEditingController(text: '10000');

  TopUpStep _step = TopUpStep.input;
  String? _error;

  // Order state
  String? _orderId;
  String? _qrisImageUrl;
  int _orderAmount = 0;
  String? _expiresAt;

  // Polling
  Timer? _pollingTimer;
  DateTime? _pollingStart;
  static const _pollingInterval = Duration(seconds: 3);
  static const _pollingTimeout = Duration(minutes: 5);

  // Countdown
  Timer? _countdownTimer;
  String _countdown = '';

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _startPolling(String reference) {
    setState(() => _step = TopUpStep.qris);
    _pollingStart = DateTime.now();

    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      try {
        final status = await _topUpService.getStatus(reference);

        if (status.paid || status.status == 'COMPLETED') {
          _pollingTimer?.cancel();
          setState(() => _step = TopUpStep.success);
          if (mounted) {
            context.read<AuthProvider>().refreshUser();
          }
          return;
        }

        if (status.status == 'FAILED' || status.status == 'CANCELED') {
          _pollingTimer?.cancel();
          setState(() {
            _step = TopUpStep.failed;
            _error = 'Pembayaran gagal atau dibatalkan.';
          });
          return;
        }

        // Check timeout
        if (DateTime.now().difference(_pollingStart!) > _pollingTimeout) {
          _pollingTimer?.cancel();
          setState(() => _step = TopUpStep.timeout);
        }
      } catch (_) {
        // Ignore polling errors, keep trying
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_expiresAt == null) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final expires = DateTime.parse(_expiresAt!);
      final diff = expires.difference(DateTime.now());

      if (diff.isNegative) {
        setState(() => _countdown = 'Expired');
        _countdownTimer?.cancel();
        return;
      }

      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      setState(() => _countdown = '$minutes:${seconds.toString().padLeft(2, '0')}');
    });
  }

  Future<void> _handleSubmit() async {
    setState(() => _error = null);

    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount < 1000) {
      setState(() => _error = 'Minimal top up Rp 1.000.');
      return;
    }
    if (amount > 500000) {
      setState(() => _error = 'Maksimal QRIS Rp 500.000.');
      return;
    }

    setState(() => _step = TopUpStep.processing);

    try {
      final user = context.read<AuthProvider>().user;
      final result = await _topUpService.createTopUp(
        amount: amount,
        customerName: user?.displayName ?? user?.fullName,
        customerEmail: user?.email,
      );

      setState(() {
        _orderId = result.orderId;
        _qrisImageUrl = result.qrisImageUrl;
        _orderAmount = result.amount;
        _expiresAt = result.expiresAt;
      });

      if (result.qrisImageUrl != null) {
        _startPolling(result.orderId);
        _startCountdown();
      }
    } catch (e) {
      setState(() {
        _step = TopUpStep.input;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _handleReset() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _step = TopUpStep.input;
      _error = null;
      _orderId = null;
      _qrisImageUrl = null;
      _orderAmount = 0;
      _expiresAt = null;
      _countdown = '';
    });
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
            Text('TOP UP', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              'Isi saldo dengan QRIS',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Scan QR code untuk mengisi saldo.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Current balance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Saldo saat ini: ',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                  ),
                  Text(
                    _rupiahFormat.format(user.walletBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step content
            _buildStepContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case TopUpStep.input:
        return _buildInputStep();
      case TopUpStep.processing:
        return _buildProcessingStep();
      case TopUpStep.qris:
        return _buildQrisStep();
      case TopUpStep.success:
        return _buildSuccessStep();
      case TopUpStep.failed:
        return _buildFailedStep();
      case TopUpStep.timeout:
        return _buildTimeoutStep();
    }
  }

  Widget _buildInputStep() {
    return Column(
      children: [
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nominal top up',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Rp',
                      style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '10000',
                        ),
                        onChanged: (v) {
                          final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (cleaned != v) {
                            _amountController.value = TextEditingValue(
                              text: cleaned,
                              selection: TextSelection.collapsed(offset: cleaned.length),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Minimum Rp 1.000, maksimum Rp 500.000.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 16),

              // Quick amounts
              const Text(
                'Pilih nominal',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((qa) {
                  final isSelected = _amountController.text == qa.toString();
                  return GestureDetector(
                    onTap: () => setState(() => _amountController.text = qa.toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.violet.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.violet.withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        _rupiahFormat.format(qa),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.rose, fontSize: 13)),
              ],

              const SizedBox(height: 20),
              GradientButton(
                text: 'Lanjut ke QRIS',
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingStep() {
    return PanelCard(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.violet,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Membuat pembayaran...',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar.',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisStep() {
    return Column(
      children: [
        // QR Code
        PanelCard(
          child: Column(
            children: [
              const Text(
                'Scan QR Code',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan e-wallet atau mobile banking untuk scan',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (_qrisImageUrl != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.network(
                    _qrisImageUrl!,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 220,
                        width: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status panel
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Pembayaran',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Nominal', value: _rupiahFormat.format(_orderAmount)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Menunggu pembayaran',
                              style: TextStyle(color: AppTheme.amber, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_countdown.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Berlaku', value: _countdown),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Polling indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.violet.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Mengecek status pembayaran...',
                      style: TextStyle(color: AppTheme.violet, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleReset,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Batalkan & Kembali',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    final user = context.read<AuthProvider>().user;
    return PanelCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.emerald.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppTheme.emerald, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Top Up Berhasil!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Saldo Anda telah bertambah ${_rupiahFormat.format(_orderAmount)}',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.emerald.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text('Saldo baru:', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  _rupiahFormat.format(user?.walletBalance ?? 0),
                  style: const TextStyle(color: AppTheme.emerald, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(text: 'Top Up Lagi', onPressed: _handleReset),
        ],
      ),
    );
  }

  Widget _buildFailedStep() {
    return PanelCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.rose.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, color: AppTheme.rose, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pembayaran Gagal',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Pembayaran tidak berhasil diproses.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GradientButton(text: 'Coba Lagi', onPressed: _handleReset),
        ],
      ),
    );
  }

  Widget _buildTimeoutStep() {
    return PanelCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded, color: AppTheme.amber, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Terbayar',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pembayaran belum terdeteksi dalam 5 menit. Jika sudah membayar, saldo akan otomatis masuk.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (_orderId != null) _startPolling(_orderId!);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Cek Lagi',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: GradientButton(text: 'Buat Baru', onPressed: _handleReset)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
