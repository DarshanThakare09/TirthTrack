// ============================================================
// features/authentication/presentation/screens/phone_login_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = Validators.normalisePhone(_phoneController.text.trim());

    await ref.read(phoneLoginProvider.notifier).sendOtp(phone);

    final state = ref.read(phoneLoginProvider);

    if (!mounted) return;

    state.when(
      data: (_) => context.push(AppRoutes.otpVerification, extra: phone),
      error: (e, _) {
        final msg = e is AppException ? e.message : 'Failed to send OTP.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(phoneLoginProvider);
    final isLoading = loginState is AsyncLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // ── Hero Branding Container ──────────────────
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

                  const SizedBox(height: 36),

                  Text(
                    'Welcome Pilgrim',
                    style: AppTextStyles.displayMedium.copyWith(
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter your mobile number to begin your\nsacred Nashik Kumbh Mela journey.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceMuted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // ── Form Container Card ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mobile Number',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _phoneController,
                          hint: '+91 9876543210',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🇮🇳',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.phone_outlined, size: 20),
                              ],
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\s]')),
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validator: Validators.phone,
                          onFieldSubmitted: (_) => _sendOtp(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 14, color: AppColors.onSurfaceMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'A 6-digit OTP will be sent for instant authentication.',
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Send OTP button ────────────────────────────
                  AppButton(
                    label: 'Get Verification Code',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: isLoading ? null : _sendOtp,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 36),

                  // ── Terms note ─────────────────────────────────
                  Text(
                    'By continuing, you accept our Terms of Service\n& Privacy Policy.',
                    style: AppTextStyles.caption.copyWith(height: 1.4),
                    textAlign: TextAlign.center,
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
