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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      color: AppColors.primary,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.temple_hindu_rounded,
                        color: AppColors.primary,
                        size: 150,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Verification Code',
                    style: AppTextStyles.displayMedium.copyWith(
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceMuted,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'We have sent a 6-digit code to\n'),
                        TextSpan(
                          text: widget.phone,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── OTP Field Container Card ────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          maxLength: AppConstants.otpLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                                AppConstants.otpLength),
                          ],
                          style: AppTextStyles.displayLarge.copyWith(
                            letterSpacing: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••',
                            hintStyle: AppTextStyles.displayLarge.copyWith(
                              letterSpacing: 14,
                              color: AppColors.border,
                            ),
                            counterText: '',
                            fillColor: AppColors.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                          validator: Validators.otp,
                          onFieldSubmitted: (_) => _verifyOtp(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Verify button ──────────────────────────────
                  AppButton(
                    label: 'Confirm & Continue',
                    icon: Icons.check_circle_rounded,
                    onPressed: isLoading ? null : _verifyOtp,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 28),

                  // ── Resend Timer ───────────────────────────────
                  Center(
                    child: _resendCooldown > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 16, color: AppColors.onSurfaceMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Resend code in ${_resendCooldown}s',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TextButton.icon(
                            onPressed: _resendOtp,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Resend OTP Code'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
