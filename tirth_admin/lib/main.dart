import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Configuration
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    appLogger.w('Could not load .env file, continuing with environment fallback: $e');
  }

  // Initialize Supabase Client
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      debug: false,
    );
    appLogger.i('Supabase initialized successfully for TirthTrack Admin');
  } catch (e) {
    appLogger.e('Supabase initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: TirthTrackAdminApp(),
    ),
  );
}

class TirthTrackAdminApp extends ConsumerWidget {
  const TirthTrackAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
