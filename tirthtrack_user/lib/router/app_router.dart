// ============================================================
// router/app_router.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/screens/otp_verification_screen.dart';
import '../features/authentication/presentation/screens/phone_login_screen.dart';
import '../features/authentication/presentation/screens/splash_screen.dart';
import '../features/chatbot/presentation/screens/chat_session_screen.dart';
import '../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../features/location/presentation/screens/location_permission_screen.dart';
import '../features/maps/presentation/screens/maps_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/complete_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../shared/widgets/main_shell.dart';
import 'router_notifier.dart';

// ── Route Paths ──────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const phoneLogin = '/auth/phone';
  static const otpVerification = '/auth/otp';
  static const completeProfile = '/complete-profile';
  static const locationPermission = '/location-permission';

  // Main shell
  static const main = '/main';
  static const maps = '/main/maps';
  static const chatbot = '/main/chatbot';
  static const chatSession = '/main/chatbot/session';
  static const profile = '/main/profile';
  static const editProfile = '/main/profile/edit';
  static const notifications = '/main/profile/notifications';
}

// ── Router Provider ──────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Splash ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),

      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.phoneLogin,
        pageBuilder: (context, state) => _slide(state, const PhoneLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        pageBuilder: (context, state) {
          final phone = state.extra as String? ?? '';
          return _slide(state, OtpVerificationScreen(phone: phone));
        },
      ),

      // ── Onboarding ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.completeProfile,
        pageBuilder: (context, state) =>
            _slide(state, const CompleteProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.locationPermission,
        pageBuilder: (context, state) =>
            _slide(state, const LocationPermissionScreen()),
      ),

      // ── Main Shell ────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.maps,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MapsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chatbot,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ChatbotScreen()),
                routes: [
                  GoRoute(
                    path: 'session/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final title = state.extra as String?;
                      return _slide(
                        state,
                        ChatSessionScreen(sessionId: id, sessionTitle: title),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) =>
                        _slide(state, const EditProfileScreen()),
                  ),
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (context, state) =>
                        _slide(state, const NotificationsScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

// ── Page Transition ──────────────────────────────────────────
CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(1, 0), end: Offset.zero).chain(
            CurveTween(curve: Curves.easeInOutCubic),
          ),
        ),
        child: child,
      );
    },
  );
}
