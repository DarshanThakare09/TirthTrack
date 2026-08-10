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

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen>
    with WidgetsBindingObserver {
  bool _isGpsServiceEnabled = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationStateAndProceedIfGranted();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationStateAndProceedIfGranted();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkLocationStateAndProceedIfGranted() async {
    final service = LocationService.instance;
    final gpsEnabled = await service.isServiceEnabled();
    await ref.read(locationPermissionProvider.notifier).checkPermissionOnly();

    if (mounted) {
      setState(() {
        _isGpsServiceEnabled = gpsEnabled;
      });
    }

    final isAvailable = await service.isAvailable;
    if (isAvailable && mounted) {
      await ref.read(locationTrackingProvider.notifier).startTracking();
      if (mounted) {
        context.go(AppRoutes.maps);
      }
    }
  }

  Future<void> _requestAndProceed() async {
    setState(() => _isChecking = true);
    try {
      final service = LocationService.instance;
      final gpsEnabled = await service.isServiceEnabled();
      if (!gpsEnabled) {
        await service.openLocationSettings();
        if (mounted) {
          setState(() {
            _isGpsServiceEnabled = false;
            _isChecking = false;
          });
        }
        return;
      }

      await ref
          .read(locationTrackingProvider.notifier)
          .initializeLocationService();

      final isAvailable = await service.isAvailable;
      if (isAvailable && mounted) {
        context.go(AppRoutes.maps);
      } else {
        await _checkLocationStateAndProceedIfGranted();
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Location Access Required',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Live location is mandatory to provide real-time pilgrim safety, nearest ghat navigation, and emergency assistance during the Kumbh Mela.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Features ─────────────────────────────────────
              const _FeatureRow(
                icon: Icons.security_rounded,
                text: 'Live pilgrim safety & emergency assistance',
              ),
              const _FeatureRow(
                icon: Icons.route_rounded,
                text: 'Real-time position along Kumbh Mela routes',
              ),
              const _FeatureRow(
                icon: Icons.local_hospital_rounded,
                text: 'Instant distance to nearest medical & civic services',
              ),
              const _FeatureRow(
                icon: Icons.local_police_rounded,
                text: 'Quick navigation to emergency police chowkis',
              ),

              const SizedBox(height: 36),

              if (!_isGpsServiceEnabled)
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
                          const Icon(Icons.location_off_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Device Location (GPS) is turned off. Please enable GPS in device settings.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Turn On Device Location (GPS)',
                      icon: Icons.settings_rounded,
                      isLoading: _isChecking,
                      onPressed: () => ref
                          .read(locationPermissionProvider.notifier)
                          .openLocationSettings(),
                    ),
                  ],
                )
              else if (permissionStatus ==
                  LocationPermissionStatus.permanentlyDenied)
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
                              'Location access was permanently denied. Please allow location permissions in App Settings to proceed.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Open App Settings',
                      icon: Icons.settings_rounded,
                      isLoading: _isChecking,
                      onPressed: () => ref
                          .read(locationPermissionProvider.notifier)
                          .openSettings(),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    AppButton(
                      label: 'Enable Location & Continue',
                      icon: Icons.my_location_rounded,
                      isLoading: _isChecking,
                      onPressed: _requestAndProceed,
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
