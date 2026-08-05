// ============================================================
// features/authentication/presentation/screens/otp_verification_screen.dart
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  int _resendCooldown = AppConstants.otpResendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _resendCooldown = AppConstants.otpResendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final otp = _otpController.text.trim();

    await ref.read(otpVerificationProvider.notifier).verifyOtp(
          phone: widget.phone,
          token: otp,
        );

    final state = ref.read(otpVerificationProvider);
    if (!mounted) return;

    state.when(
      data: (_) {
        context.go(AppRoutes.maps);
      },
      error: (e, _) {
        final msg = e is AppException ? e.message : 'Invalid OTP.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        _otpController.clear();
      },
      loading: () {},
    );
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    await ref.read(phoneLoginProvider.notifier).sendOtp(widget.phone);
    if (mounted) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully.')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verifyState = ref.watch(otpVerificationProvider);
    final isLoading = verifyState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Header Branding Container ──────────────────
                Image.asset(
                  'assets/icons/app_logo.png',
                  width: 56,
                  height: 56,
                  color: AppColors.primary,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sms_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                Text('Verify OTP', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium,
                    children: [
                      const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                      TextSpan(
                        text: widget.phone,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── OTP Field ──────────────────────────────────
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  maxLength: AppConstants.otpLength,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(AppConstants.otpLength),
                  ],
                  style: AppTextStyles.headlineLarge.copyWith(
                    letterSpacing: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '——————',
                    counterText: '',
                  ),
                  validator: Validators.otp,
                  onFieldSubmitted: (_) => _verifyOtp(),
                ),

                const SizedBox(height: 32),

                // ── Verify button ──────────────────────────────
                AppButton(
                  label: 'Verify',
                  icon: Icons.verified_rounded,
                  onPressed: isLoading ? null : _verifyOtp,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 24),

                // ── Resend ─────────────────────────────────────
                Center(
                  child: _resendCooldown > 0
                      ? Text(
                          'Resend OTP in ${_resendCooldown}s',
                          style: AppTextStyles.bodySmall,
                        )
                      : TextButton(
                          onPressed: _resendOtp,
                          child: const Text('Resend OTP'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
