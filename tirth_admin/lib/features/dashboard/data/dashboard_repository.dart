import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/dashboard_stats_model.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final sb.SupabaseClient _client;

  Future<DashboardStatsModel> getStats() async {
    try {
      appLogger.d('DashboardRepository: fetching dashboard statistics');

      // Run parallel queries to fetch real live counts from database
      final results = await Future.wait([
        // 0: Total police
        _client.from(SupabaseTable.policeDetails).count(sb.CountOption.exact),
        // 1: Pending police
        _client
            .from(SupabaseTable.policeDetails)
            .count(sb.CountOption.exact)
            .eq('verification_status', 'pending'),
        // 2: Verified police
        _client
            .from(SupabaseTable.policeDetails)
            .count(sb.CountOption.exact)
            .eq('verification_status', 'verified'),
        // 3: Total routes
        _client.from(SupabaseTable.routes).count(sb.CountOption.exact),
        // 4: Active routes
        _client
            .from(SupabaseTable.routes)
            .count(sb.CountOption.exact)
            .eq('is_active', true),
        // 5: Total services
        _client.from(SupabaseTable.services).count(sb.CountOption.exact),
        // 6: Active services
        _client
            .from(SupabaseTable.services)
            .count(sb.CountOption.exact)
            .eq('is_active', true),
        // 7: Total police bases
        _client.from(SupabaseTable.policeBases).count(sb.CountOption.exact),
        // 8: Total sectors
        _client.from(SupabaseTable.sectors).count(sb.CountOption.exact),
        // 9: Active alerts
        _client
            .from(SupabaseTable.alerts)
            .count(sb.CountOption.exact)
            .eq('is_active', true),
        // 10: Total alerts
        _client.from(SupabaseTable.alerts).count(sb.CountOption.exact),
      ]);

      return DashboardStatsModel(
        totalPolice: results[0],
        pendingPolice: results[1],
        verifiedPolice: results[2],
        totalRoutes: results[3],
        activeRoutes: results[4],
        totalServices: results[5],
        activeServices: results[6],
        totalPoliceBases: results[7],
        totalSectors: results[8],
        activeAlerts: results[9],
        totalAlerts: results[10],
      );
    } catch (e) {
      appLogger.e('DashboardRepository getStats error: $e');
      throw parseSupabaseException(e);
    }
  }
}
