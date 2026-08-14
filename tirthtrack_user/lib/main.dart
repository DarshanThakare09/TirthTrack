// ============================================================
// main.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    appLogger.i("Environment variables loaded successfully.");
  } catch (e) {
    appLogger.w("Could not load .env file, fallback to environment defaults: $e");
  }

  // Initialize Supabase Singleton
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    appLogger.i("Supabase initialized successfully.");
  } catch (e) {
    appLogger.e("Failed to initialize Supabase: $e");
  }

  // Initialize Local Notifications
  try {
    await LocalNotificationService.instance.initialize();
    appLogger.i("Local Notification Service initialized successfully.");
  } catch (e) {
    appLogger.e("Failed to initialize Local Notification Service: $e");
  }

  runApp(
    const ProviderScope(
      child: TirthTrackApp(),
    ),
  );
}

class TirthTrackApp extends ConsumerWidget {
  const TirthTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
