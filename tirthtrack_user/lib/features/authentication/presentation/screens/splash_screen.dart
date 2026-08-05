// ============================================================
// features/authentication/presentation/screens/splash_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/authentication/providers/auth_provider.dart';
import '../../../../features/profile/providers/profile_provider.dart';
import '../../../../router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

// Added WidgetsBindingObserver to detect when the app is brought to the foreground
class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Listen to app open/close events

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _startAnimationAndTimer();
  }

  void _startAnimationAndTimer() {
    _animationController.forward(from: 0.0); // Always forces animation to start from 0

    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;

      // Check session
      final user = ref.read(currentUserProvider);

      if (user == null) {
        if (mounted) context.go(AppRoutes.phoneLogin);
        return;
      }

      // Load profile to check completeness
      try {
        final profile = await ref.read(profileProvider.future);
        if (!mounted) return;

        if (!profile.isComplete) {
          context.go(AppRoutes.completeProfile);
        } else {
          context.go(AppRoutes.maps);
        }
      } catch (_) {
        if (mounted) context.go(AppRoutes.maps);
      }
    });
  }

  // This function triggers every time the app is minimized or re-opened
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAnimationAndTimer(); // Re-runs the animation when you open the app again
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up the observer
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xffFF7722);

    return Scaffold(
      backgroundColor: brandColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: brandColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/app_logo.png',
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
                width: 270,
                height: 240,
                fit: BoxFit.contain,
              ),
              Transform.translate(
                offset: const Offset(0, -25),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Journey with Devotion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
