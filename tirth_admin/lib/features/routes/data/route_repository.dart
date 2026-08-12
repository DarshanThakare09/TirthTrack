import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/route_model.dart';

class RouteRepository {
  RouteRepository(this._client);

  final sb.SupabaseClient _client;

  /// Fetch all routes with node counts
  Future<List<RouteModel>> getRoutes({
    bool? activeOnly,
    String? searchQuery,
  }) async {
    try {
      appLogger.d('RouteRepository: fetching routes');
      var query = _client.from(SupabaseTable.routes).select('*, route_nodes(count)');

      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      final routes = (response as List<dynamic>).map((e) {
        final nodeCountList = e['route_nodes'] as List<dynamic>?;
        final count = (nodeCountList != null && nodeCountList.isNotEmpty)
            ? (nodeCountList.first['count'] as int? ?? 0)
            : 0;
        return RouteModel.fromJson(e as Map<String, dynamic>, nodeCount: count);
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return routes.where((r) {
          return r.routeName.toLowerCase().contains(q) ||
              (r.routeCode?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return routes;
    } catch (e) {
      appLogger.e('RouteRepository getRoutes error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Get single route by ID
  Future<RouteModel> getRouteById(String routeId) async {
    try {
      final response = await _client
          .from(SupabaseTable.routes)
          .select('*, route_nodes(count)')
          .eq('id', routeId)
          .single();

      final nodeCountList = response['route_nodes'] as List<dynamic>?;
      final count = (nodeCountList != null && nodeCountList.isNotEmpty)
          ? (nodeCountList.first['count'] as int? ?? 0)
          : 0;

      return RouteModel.fromJson(response, nodeCount: count);
    } catch (e) {
      appLogger.e('RouteRepository getRouteById error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Create new route
  Future<RouteModel> createRoute(RouteModel route) async {
    try {
      appLogger.d('RouteRepository: creating route ${route.routeName}');
      final response = await _client
          .from(SupabaseTable.routes)
          .insert(route.toUpsertJson())
          .select()
          .single();

      return RouteModel.fromJson(response);
    } catch (e) {
      appLogger.e('RouteRepository createRoute error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Update existing route
  Future<void> updateRoute(String id, RouteModel route) async {
    try {
      appLogger.d('RouteRepository: updating route $id');
      await _client
          .from(SupabaseTable.routes)
          .update(route.toUpsertJson())
          .eq('id', id);
    } catch (e) {
      appLogger.e('RouteRepository updateRoute error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Toggle route active status
  Future<void> toggleRouteActive(String id, bool isActive) async {
    try {
      await _client.from(SupabaseTable.routes).update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      appLogger.e('RouteRepository toggleRouteActive error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Delete route (cascade deletes route nodes in SQL)
  Future<void> deleteRoute(String id) async {
    try {
      appLogger.d('RouteRepository: deleting route $id');
      await _client.from(SupabaseTable.routes).delete().eq('id', id);
    } catch (e) {
      appLogger.e('RouteRepository deleteRoute error: $e');
      throw parseSupabaseException(e);
    }
  }

  // ── Route Nodes ────────────────────────────────────────────────

  /// Get nodes for a route ordered by node_order
  Future<List<RouteNodeModel>> getRouteNodes(String routeId) async {
    try {
      final response = await _client
          .from(SupabaseTable.routeNodes)
          .select()
          .eq('route_id', routeId)
          .order('node_order', ascending: true);

      return (response as List<dynamic>)
          .map((e) => RouteNodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('RouteRepository getRouteNodes error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Add a new node to a route
  Future<RouteNodeModel> addRouteNode(RouteNodeModel node) async {
    try {
      appLogger.d('RouteRepository: adding node ${node.nodeName} (order: ${node.nodeOrder})');
      final response = await _client
          .from(SupabaseTable.routeNodes)
          .insert(node.toUpsertJson())
          .select()
          .single();

      return RouteNodeModel.fromJson(response);
    } catch (e) {
      appLogger.e('RouteRepository addRouteNode error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Update an existing route node
  Future<void> updateRouteNode(String nodeId, RouteNodeModel node) async {
    try {
      appLogger.d('RouteRepository: updating node $nodeId');
      await _client
          .from(SupabaseTable.routeNodes)
          .update(node.toUpsertJson())
          .eq('id', nodeId);
    } catch (e) {
      appLogger.e('RouteRepository updateRouteNode error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Delete a route node
  Future<void> deleteRouteNode(String nodeId) async {
    try {
      appLogger.d('RouteRepository: deleting node $nodeId');
      await _client.from(SupabaseTable.routeNodes).delete().eq('id', nodeId);
    } catch (e) {
      appLogger.e('RouteRepository deleteRouteNode error: $e');
      throw parseSupabaseException(e);
    }
  }
}
