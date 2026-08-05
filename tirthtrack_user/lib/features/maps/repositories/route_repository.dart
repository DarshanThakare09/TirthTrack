// ============================================================
// features/maps/repositories/route_repository.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../models/route_model.dart';

class RouteRepository {
  RouteRepository(this._client);

  final SupabaseClient _client;

  /// Fetch all active routes.
  Future<List<RouteModel>> fetchActiveRoutes() async {
    try {
      appLogger.d('RouteRepository: fetching active routes');
      final data = await _client
          .from(SupabaseTable.routes)
          .select()
          .eq('is_active', true)
          .order('route_name');
      return (data as List)
          .map((json) => RouteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      appLogger.e('RouteRepository fetchActiveRoutes: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('RouteRepository unexpected: $e');
      throw const UnknownException();
    }
  }

  /// Fetch ordered nodes for a specific route.
  Future<List<RouteNodeModel>> fetchRouteNodes(String routeId) async {
    try {
      appLogger.d('RouteRepository: fetching nodes for $routeId');
      final data = await _client
          .from(SupabaseTable.routeNodes)
          .select()
          .eq('route_id', routeId)
          .order('node_order');
      return (data as List)
          .map((json) =>
              RouteNodeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      appLogger.e('RouteRepository fetchRouteNodes: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('RouteRepository fetchRouteNodes unexpected: $e');
      throw const UnknownException();
    }
  }
}
