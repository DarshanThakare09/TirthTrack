import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/alerts/presentation/alert_form_screen.dart';
import '../features/alerts/presentation/alert_list_screen.dart';
import '../features/auth/presentation/access_denied_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/police/presentation/police_code_generator_screen.dart';
import '../features/police/presentation/police_detail_screen.dart';
import '../features/police/presentation/police_id_viewer_screen.dart';
import '../features/police/presentation/police_list_screen.dart';
import '../features/police/presentation/police_login_codes_screen.dart';
import '../features/police/presentation/police_providers.dart';
import '../features/police_bases/presentation/police_base_form_screen.dart';
import '../features/police_bases/presentation/police_base_list_screen.dart';
import '../features/profile/presentation/admin_profile_screen.dart';
import '../features/routes/presentation/route_detail_screen.dart';
import '../features/routes/presentation/route_form_screen.dart';
import '../features/routes/presentation/route_list_screen.dart';
import '../features/sectors/presentation/sector_detail_screen.dart';
import '../features/sectors/presentation/sector_form_screen.dart';
import '../features/sectors/presentation/sector_list_screen.dart';
import '../features/services/presentation/service_form_screen.dart';
import '../features/services/presentation/service_list_screen.dart';
import '../models/police_officer_model.dart';
import '../shared/widgets/admin_shell.dart';
import '../shared/widgets/state_widgets.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth changes so GoRouter re-evaluates redirects
  ref.watch(authStateStreamProvider);
  ref.watch(adminSessionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final adminSession = ref.read(adminSessionProvider);

      final isSplash = state.matchedLocation == '/splash' || state.matchedLocation == '/';
      final isLoggingIn = state.matchedLocation == '/login';
      final isAccessDenied = state.matchedLocation == '/access-denied';

      // Allow splash screen to handle initial startup animation & check
      if (isSplash) {
        return null;
      }

      // 1. Not authenticated
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. While verifying admin credentials
      if (adminSession.isLoading) {
        return null;
      }

      // 3. User is authenticated but NOT an Administrator
      if (adminSession.hasError || adminSession.value == null) {
        return isAccessDenied ? null : '/access-denied';
      }

      // 4. Authenticated admin on auth screens
      if (isLoggingIn || isAccessDenied) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ── Splash Screen ─────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Unauthenticated / Auth Guard Screens ──────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),

      // ── Authenticated Shell Routes (Admin Navigation via BottomNav & Drawer) ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // Primary Tab 1: Services & Facilities
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServiceListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final latStr = state.uri.queryParameters['lat'];
                  final lngStr = state.uri.queryParameters['lng'];
                  return ServiceFormScreen(
                    initialLat: latStr != null ? double.tryParse(latStr) : null,
                    initialLng: lngStr != null ? double.tryParse(lngStr) : null,
                  );
                },
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ServiceFormScreen(serviceId: id);
                },
              ),
            ],
          ),

          // Primary Tab 2: Alerts & Broadcasts
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const AlertFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AlertFormScreen(alertId: id);
                },
              ),
            ],
          ),

          // Primary Tab 3: Sector Allocation & Boundaries
          GoRoute(
            path: '/sectors',
            builder: (context, state) => const SectorListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const SectorFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return SectorDetailScreen(sectorId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SectorFormScreen(sectorId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Primary Tab 4: Police Code Generator
          GoRoute(
            path: '/police-codes',
            builder: (context, state) => const PoliceCodeGeneratorScreen(),
          ),

          // Primary Tab 5: Admin Profile & Credentials
          GoRoute(
            path: '/profile',
            builder: (context, state) => const AdminProfileScreen(),
          ),

          // Police Management (Drawer)
          GoRoute(
            path: '/police',
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return PoliceListScreen(initialFilter: filter);
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final policeId = state.pathParameters['id']!;
                  return PoliceDetailScreen(policeId: policeId);
                },
                routes: [
                  GoRoute(
                    path: 'login-codes',
                    builder: (context, state) {
                      final policeId = state.pathParameters['id']!;
                      final extra = state.extra;
                      if (extra is PoliceOfficerModel) {
                        return PoliceLoginCodesScreen(officer: extra);
                      }
                      return Consumer(
                        builder: (context, ref, _) {
                          final officerAsync =
                              ref.watch(policeDetailProvider(policeId));
                          return officerAsync.when(
                            data: (officer) =>
                                PoliceLoginCodesScreen(officer: officer),
                            loading: () => Scaffold(
                              appBar: AppBar(title: const Text('Login Codes')),
                              body: const LoadingWidget(
                                message: 'Loading officer data...',
                              ),
                            ),
                            error: (e, _) => Scaffold(
                              appBar: AppBar(title: const Text('Login Codes')),
                              body: ErrorStateWidget(
                                message: e.toString(),
                                onRetry: () =>
                                    ref.refresh(policeDetailProvider(policeId)),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'id-card',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final storagePath =
                          (extra?['storagePath'] as String?) ?? '';
                      final officerName =
                          (extra?['officerName'] as String?) ?? 'Police Officer';

                      return PoliceIdViewerScreen(
                        storagePath: storagePath,
                        officerName: officerName,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Police Bases (Drawer)
          GoRoute(
            path: '/police-bases',
            builder: (context, state) => const PoliceBaseListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PoliceBaseFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PoliceBaseFormScreen(baseId: id);
                },
              ),
            ],
          ),

          // Pilgrim Routes (Drawer)
          GoRoute(
            path: '/routes',
            builder: (context, state) => const RouteListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const RouteFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return RouteDetailScreen(routeId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return RouteFormScreen(routeId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
