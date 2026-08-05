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
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editProfile),
            tooltip: 'Edit Profile',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Header Card ─────────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border, width: 1),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryContainer, Colors.white],
                  ),
                ),
                child: Column(
                  children: [
                    ProfileAvatarWidget(
                      photoUrl: photoUrlState.valueOrNull,
                      name: profile.fullName,
                      radius: 46,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.fullName ?? 'Pilgrim',
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (profile.mobile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.mobile!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                    if (profile.city != null || profile.state != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            [profile.city, profile.state]
                                .where((v) => v != null)
                                .join(', '),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Personal Information ─────────────────────────
            const _SectionHeader(title: 'Personal Information'),
            _InfoTile(
              icon: Icons.person_outline_rounded,
              title: 'Full Name',
              value: profile.fullName ?? '—',
            ),
            _InfoTile(
              icon: Icons.phone_outlined,
              title: 'Mobile',
              value: profile.mobile ?? '—',
            ),
            if (profile.email != null)
              _InfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: profile.email!,
              ),
            _InfoTile(
              icon: Icons.wc_outlined,
              title: 'Gender',
              value: profile.gender?.displayLabel ?? '—',
            ),
            _InfoTile(
              icon: Icons.cake_outlined,
              title: 'Date of Birth',
              value: profile.dateOfBirth != null
                  ? DateFormat('dd MMMM yyyy').format(profile.dateOfBirth!)
                  : '—',
            ),
            if (profile.city != null)
              _InfoTile(
                icon: Icons.location_city_outlined,
                title: 'City',
                value: profile.city!,
              ),
            if (profile.state != null)
              _InfoTile(
                icon: Icons.map_outlined,
                title: 'State',
                value: profile.state!,
              ),

            const SizedBox(height: 16),

            // ── App Actions ───────────────────────────────────
            const _SectionHeader(title: 'App'),
            _ActionTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => context.push(AppRoutes.notifications),
            ),
            _ActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () =>
                  launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
            ),
            _ActionTile(
              icon: Icons.article_outlined,
              title: 'Terms of Service',
              onTap: () => launchUrl(Uri.parse(AppConstants.termsUrl)),
            ),
            _ActionTile(
              icon: Icons.info_outline_rounded,
              title: 'About Tirth',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Tirth',
                applicationVersion: AppConstants.appVersion,
                applicationLegalese:
                    '© 2026 Tirth. All rights reserved.',
              ),
            ),

            const SizedBox(height: 16),

            // ── Logout Button ─────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text(
                'Sign Out',
                style: AppTextStyles.button.copyWith(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1.5),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _confirmSignOut(context, ref),
            ),

            const SizedBox(height: 32),
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
              style: TextStyle(color: AppColors.error),
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
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          letterSpacing: 1.2,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
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
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.iconDark, size: 20),
        ),
        title: Text(title, style: AppTextStyles.labelSmall),
        subtitle: Text(value, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.iconDark, size: 20),
        ),
        title: Text(title, style: AppTextStyles.bodyMedium),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.iconDark),
        onTap: onTap,
      ),
    );
  }
}
