import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../auth/presentation/auth_providers.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out of Admin Portal?',
      message: 'Are you sure you want to end your current administrative session?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(adminSessionProvider);
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: adminAsync.when(
        loading: () => const LoadingWidget(message: 'Loading administrator profile...'),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(adminSessionProvider),
        ),
        data: (admin) {
          if (admin == null) {
            return const ErrorStateWidget(
              title: 'Profile Not Found',
              message: 'Administrator profile information could not be retrieved.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            admin.fullName.isNotEmpty
                                ? admin.fullName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          admin.fullName,
                          style: AppTextStyles.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        if (admin.email != null)
                          Text(
                            admin.email!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.admin_panel_settings_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                admin.designation?.toUpperCase() ?? 'KUMBH MELA ADMINISTRATOR',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Administrative Record
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administrative Credentials',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ProfileInfoRow(
                          label: 'Employee Code',
                          value: admin.employeeCode ?? 'ADM-OFFICIAL',
                          icon: Icons.badge_outlined,
                        ),
                        _ProfileInfoRow(
                          label: 'Assigned Role',
                          value: admin.role.name.toUpperCase(),
                          icon: Icons.security_rounded,
                        ),
                        _ProfileInfoRow(
                          label: 'Designation',
                          value: admin.designation ?? 'Zonal Mela Authority',
                          icon: Icons.work_outline_rounded,
                        ),
                        if (admin.mobile != null)
                          _ProfileInfoRow(
                            label: 'Contact Phone',
                            value: admin.mobile!,
                            icon: Icons.phone_outlined,
                          ),
                        _ProfileInfoRow(
                          label: 'Admin ID',
                          value: admin.adminId,
                          icon: Icons.fingerprint_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // System & Security Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Environment',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ProfileInfoRow(
                          label: 'Portal Version',
                          value: 'TirthTrack Admin v1.0.0 (Nashik 2027)',
                          icon: Icons.info_outline_rounded,
                        ),
                        _ProfileInfoRow(
                          label: 'Target Event',
                          value: 'Nashik Kumbh Mela 2027',
                          icon: Icons.temple_hindu_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Sign Out Button
                AppButton(
                  text: 'Sign Out of Admin Portal',
                  variant: AppButtonVariant.danger,
                  icon: Icons.logout_rounded,
                  onPressed: () => _handleLogout(context, ref),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.onSurfaceMuted),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
