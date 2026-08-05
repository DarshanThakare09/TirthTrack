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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // ── Brand Header with Splash Logo ─────────────
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/app_logo.png',
                      width: 44,
                      height: 44,
                      color: AppColors.primary,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.temple_hindu_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Tirth', style: AppTextStyles.brandTitle),
                  ],
                ),

                const SizedBox(height: 40),

                Text('Welcome', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Enter your mobile number to continue your\npilgrimage journey.',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: 36),

                // ── Phone field ────────────────────────────────
                AppTextField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  hint: '+91 9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_rounded),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: Validators.phone,
                  onFieldSubmitted: (_) => _sendOtp(),
                ),

                const SizedBox(height: 8),
                Text(
                  'We will send a 6-digit OTP to verify your number.',
                  style: AppTextStyles.caption,
                ),

                const SizedBox(height: 32),

                // ── Send OTP button ────────────────────────────
                AppButton(
                  label: 'Send OTP',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: isLoading ? null : _sendOtp,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 48),

                // ── Terms note ─────────────────────────────────
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
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
