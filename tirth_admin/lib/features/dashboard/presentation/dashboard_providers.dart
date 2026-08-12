import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/dashboard_stats_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRepository(client);
});

final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return await repo.getStats();
});
