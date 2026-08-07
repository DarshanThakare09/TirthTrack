// ============================================================
// features/profile/presentation/screens/profile_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../models/profile_model.dart';
import '../../providers/profile_provider.dart';
import '../widgets/profile_avatar_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final photoUrlState = ref.watch(profilePhotoUrlProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
              onPressed: () => context.push(AppRoutes.editProfile),
              tooltip: 'Edit Profile',
            ),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(profileProvider),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Hero Header Card ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ProfileAvatarWidget(
                      photoUrl: photoUrlState.valueOrNull,
                      name: profile.fullName,
                      radius: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName ?? 'Pilgrim',
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (profile.mobile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.mobile!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                  if (profile.city != null || profile.state != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            [profile.city, profile.state]
                                .where((v) => v != null)
                                .join(', '),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Personal Details Group ────────────────────────
            const _SectionHeader(title: 'Personal Information'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Full Name',
                    value: profile.fullName ?? '—',
                    showDivider: true,
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Mobile Number',
                    value: profile.mobile ?? '—',
                    showDivider: true,
                  ),
                  if (profile.email != null)
                    _InfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      value: profile.email!,
                      showDivider: true,
                    ),
                  _InfoTile(
                    icon: Icons.wc_outlined,
                    title: 'Gender',
                    value: profile.gender?.displayLabel ?? '—',
                    showDivider: true,
                  ),
                  _InfoTile(
                    icon: Icons.cake_outlined,
                    title: 'Date of Birth',
                    value: profile.dateOfBirth != null
                        ? DateFormat('dd MMMM yyyy').format(profile.dateOfBirth!)
                        : '—',
                    showDivider: profile.city != null || profile.state != null,
                  ),
                  if (profile.city != null)
                    _InfoTile(
                      icon: Icons.location_city_outlined,
                      title: 'City',
                      value: profile.city!,
                      showDivider: profile.state != null,
                    ),
                  if (profile.state != null)
                    _InfoTile(
                      icon: Icons.map_outlined,
                      title: 'State',
                      value: profile.state!,
                      showDivider: false,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── App Settings Group ───────────────────────────
            const _SectionHeader(title: 'Preferences & Support'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications & Alerts',
                    onTap: () => context.push(AppRoutes.notifications),
                    showDivider: true,
                  ),
                  _ActionTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () =>
                        launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
                    showDivider: true,
                  ),
                  _ActionTile(
                    icon: Icons.article_outlined,
                    title: 'Terms of Service',
                    onTap: () => launchUrl(Uri.parse(AppConstants.termsUrl)),
                    showDivider: true,
                  ),
                  _ActionTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About TirthTrack',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Tirth',
                      applicationVersion: AppConstants.appVersion,
                      applicationLegalese:
                          '© 2026 Tirth. All rights reserved.',
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Logout Button ─────────────────────────────────
            AppButton(
              label: 'Sign Out Account',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.filled,
              color: AppColors.primary,
              onPressed: () => _confirmSignOut(context, ref),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(signOutProvider.notifier).signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          letterSpacing: 1.2,
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceMuted)),
          subtitle: Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 60),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.iconDark, size: 20),
          ),
          title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceMuted),
          onTap: onTap,
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 60),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}
