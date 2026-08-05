// ============================================================
// features/location/presentation/screens/location_permission_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../providers/location_provider.dart';

class LocationPermissionScreen extends ConsumerWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(locationPermissionProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // ── Illustration ────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Enable Location',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tirth needs your location to show nearby services, routes, and police bases during Kumbh Mela.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Features ─────────────────────────────────────
              _FeatureRow(
                icon: Icons.route_rounded,
                text: 'Show your position on routes',
              ),
              _FeatureRow(
                icon: Icons.local_hospital_rounded,
                text: 'Find nearest services',
              ),
              _FeatureRow(
                icon: Icons.local_police_rounded,
                text: 'Locate police bases',
              ),

              const SizedBox(height: 36),

              if (permissionStatus == LocationPermissionStatus.permanentlyDenied)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Location access was denied permanently. Please enable it from app settings.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Open Settings',
                      icon: Icons.settings_rounded,
                      onPressed: () => ref
                          .read(locationPermissionProvider.notifier)
                          .openSettings(),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Continue Without Location',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => context.go(AppRoutes.maps),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    AppButton(
                      label: 'Allow Location',
                      icon: Icons.my_location_rounded,
                      onPressed: () => _requestAndProceed(context, ref),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Not Now',
                      variant: AppButtonVariant.text,
                      onPressed: () => context.go(AppRoutes.maps),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestAndProceed(BuildContext context, WidgetRef ref) async {
    await ref.read(locationPermissionProvider.notifier).checkAndRequest();
    await ref.read(locationTrackingProvider.notifier).startTracking();
    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null) {
      ref.read(currentPositionProvider.notifier).state = pos;
    }
    if (context.mounted) {
      context.go(AppRoutes.maps);
    }
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
