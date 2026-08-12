import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import 'auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasNetworkError = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    _animationController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 2000), () async {
      _checkAuthAndAdminSession();
    });
  }

  Future<void> _checkAuthAndAdminSession() async {
    if (!mounted) return;

    final user = ref.read(currentUserProvider);

    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final admin = await ref.read(adminSessionProvider.future);
      if (!mounted) return;

      setState(() {
        _hasNetworkError = false;
        _isRetrying = false;
      });

      if (admin != null && admin.isActive) {
        context.go('/dashboard');
      } else {
        context.go('/access-denied');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasNetworkError = true;
        _isRetrying = false;
      });
    }
  }

  void _onRetry() {
    setState(() {
      _isRetrying = true;
    });
    ref.invalidate(adminSessionProvider);
    _checkAuthAndAdminSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasNetworkError) {
      _startAnimationAndTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = AppColors.primary;

    if (_hasNetworkError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 36,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Connection Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unable to reach TirthTrack administration servers. Please check your network connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: _isRetrying ? 'Retrying...' : 'Retry Connection',
                  isLoading: _isRetrying,
                  onPressed: _onRetry,
                  width: 200,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
