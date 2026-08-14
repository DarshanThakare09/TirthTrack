import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../auth/presentation/auth_providers.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final adminSession = ref.watch(adminSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          return ref.refresh(dashboardStatsProvider.future);
        },
        child: statsAsync.when(
          loading: () => const LoadingWidget(message: 'Loading dashboard metrics...'),
          error: (err, _) => ErrorStateWidget(
            message: err.toString(),
            onRetry: () => ref.refresh(dashboardStatsProvider),
          ),
          data: (stats) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner
                  _buildWelcomeCard(adminSession),
                  const SizedBox(height: 20),

                  // Pending Police Verification Alert Callout (if any)
                  if (stats.pendingPolice > 0) ...[
                    _buildPendingPoliceBanner(context, stats.pendingPolice),
                    const SizedBox(height: 20),
                  ],

                  // Overview Metrics Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Operational Overview',
                        style: AppTextStyles.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Refresh data',
                        onPressed: () => ref.refresh(dashboardStatsProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Metric Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: constraints.maxWidth > 700 ? 1.4 : 1.15,
                        children: [
                          _MetricCard(
                            title: 'Police Officers',
                            value: stats.totalPolice.toString(),
                            subtitle: '${stats.pendingPolice} Pending',
                            icon: Icons.local_police_rounded,
                            iconColor: AppColors.info,
                            onTap: () => context.go('/police'),
                          ),
                          _MetricCard(
                            title: 'Active Routes',
                            value: stats.activeRoutes.toString(),
                            subtitle: 'Total: ${stats.totalRoutes}',
                            icon: Icons.alt_route_rounded,
                            iconColor: AppColors.primary,
                            onTap: () => context.go('/routes'),
                          ),
                          _MetricCard(
                            title: 'Public Services',
                            value: stats.activeServices.toString(),
                            subtitle: 'Total: ${stats.totalServices}',
                            icon: Icons.medical_services_rounded,
                            iconColor: AppColors.success,
                            onTap: () => context.go('/services'),
                          ),
                          _MetricCard(
                            title: 'Police Bases',
                            value: stats.totalPoliceBases.toString(),
                            subtitle: 'Active Deployment',
                            icon: Icons.shield_rounded,
                            iconColor: const Color(0xFF6366F1),
                            onTap: () => context.go('/police-bases'),
                          ),
                          _MetricCard(
                            title: 'Sectors',
                            value: stats.totalSectors.toString(),
                            subtitle: 'Zonal Boundaries',
                            icon: Icons.map_rounded,
                            iconColor: const Color(0xFF0D9488),
                            onTap: () => context.go('/sectors'),
                          ),
                          _MetricCard(
                            title: 'Active Alerts',
                            value: stats.activeAlerts.toString(),
                            subtitle: 'Total: ${stats.totalAlerts}',
                            icon: Icons.notification_important_rounded,
                            iconColor: AppColors.error,
                            onTap: () => context.go('/alerts'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Quick Actions Section
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(adminSession) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1810), Color(0xFF1E1E24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'KUMBH MELA 2027 • CONTROL CENTER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome, ${adminSession?.fullName ?? "Administrator"}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adminSession?.designation ?? 'System Administrator',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.temple_hindu_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPoliceBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Police Verification${count > 1 ? "s" : ""} Pending',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Review uploaded police badges and ID documents to grant login access.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AppButton(
            text: 'Review',
            variant: AppButtonVariant.primary,
            height: 38,
            width: 90,
            onPressed: () => context.go('/police?filter=pending'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickActionChip(
          icon: Icons.add_road_rounded,
          label: 'Add Route',
          onTap: () => context.go('/routes/new'),
        ),
        _QuickActionChip(
          icon: Icons.add_business_rounded,
          label: 'Add Facility / Service',
          onTap: () => context.go('/services/new'),
        ),
        _QuickActionChip(
          icon: Icons.add_moderator_rounded,
          label: 'Add Police Base',
          onTap: () => context.go('/police-bases/new'),
        ),
        _QuickActionChip(
          icon: Icons.add_location_alt_rounded,
          label: 'Add Sector',
          onTap: () => context.go('/sectors/new'),
        ),
        _QuickActionChip(
          icon: Icons.add_alert_rounded,
          label: 'Broadcast Alert',
          onTap: () => context.go('/alerts/new'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.onSurfaceDisabled,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onPressed: onTap,
    );
  }
}
