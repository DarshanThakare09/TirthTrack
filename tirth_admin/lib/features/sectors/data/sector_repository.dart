import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/sector_model.dart';

class SectorRepository {
  SectorRepository(this._client);

  final sb.SupabaseClient _client;

  /// Fetch sectors with joined police base and count of sector nodes
  Future<List<SectorModel>> getSectors({String? searchQuery}) async {
    try {
      appLogger.d('SectorRepository: fetching sectors');
      final response = await _client
          .from(SupabaseTable.sectors)
          .select('*, police_bases:police_base_id(base_name), sector_nodes(id)')
          .order('created_at', ascending: false);

      final sectors = (response as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        final nodes = (map['sector_nodes'] as List<dynamic>?) ?? [];
        return SectorModel.fromJson(map, nodeCount: nodes.length);
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return sectors.where((s) {
          return s.sectorName.toLowerCase().contains(q) ||
              (s.sectorCode?.toLowerCase().contains(q) ?? false) ||
              (s.policeBaseName?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return sectors;
    } catch (e) {
      appLogger.e('SectorRepository getSectors error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Get single sector with police base info
  Future<SectorModel> getSectorById(String sectorId) async {
    try {
      final response = await _client
          .from(SupabaseTable.sectors)
          .select('*, police_bases:police_base_id(base_name), sector_nodes(id)')
          .eq('id', sectorId)
          .single();

      final nodes = (response['sector_nodes'] as List<dynamic>?) ?? [];
      return SectorModel.fromJson(response, nodeCount: nodes.length);
    } catch (e) {
      appLogger.e('SectorRepository getSectorById error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Create sector
  Future<SectorModel> createSector(SectorModel sector) async {
    try {
      appLogger.d('SectorRepository: creating sector ${sector.sectorName}');
      final response = await _client
          .from(SupabaseTable.sectors)
          .insert(sector.toUpsertJson())
          .select('*, police_bases:police_base_id(base_name)')
          .single();

      return SectorModel.fromJson(response);
    } catch (e) {
      appLogger.e('SectorRepository createSector error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Update sector
  Future<void> updateSector(String id, SectorModel sector) async {
    try {
      appLogger.d('SectorRepository: updating sector $id');
      await _client
          .from(SupabaseTable.sectors)
          .update(sector.toUpsertJson())
          .eq('id', id);
    } catch (e) {
      appLogger.e('SectorRepository updateSector error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Delete sector (cascades to sector_nodes)
  Future<void> deleteSector(String id) async {
    try {
      appLogger.d('SectorRepository: deleting sector $id');
      await _client.from(SupabaseTable.sectors).delete().eq('id', id);
    } catch (e) {
      appLogger.e('SectorRepository deleteSector error: $e');
      throw parseSupabaseException(e);
    }
  }

  // ── Sector Nodes (Boundary Polygon) ──────────────────────────────

  /// Get ordered boundary nodes for a sector
  Future<List<SectorNodeModel>> getSectorNodes(String sectorId) async {
    try {
      final response = await _client
          .from(SupabaseTable.sectorNodes)
          .select()
          .eq('sector_id', sectorId)
          .order('node_order', ascending: true);

      return (response as List<dynamic>)
          .map((e) => SectorNodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('SectorRepository getSectorNodes error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Add a boundary node to a sector
  Future<SectorNodeModel> addSectorNode(SectorNodeModel node) async {
    try {
      appLogger.d('SectorRepository: adding node order ${node.nodeOrder} to sector ${node.sectorId}');
      final response = await _client
          .from(SupabaseTable.sectorNodes)
          .insert(node.toUpsertJson())
          .select()
          .single();

      return SectorNodeModel.fromJson(response);
    } catch (e) {
      appLogger.e('SectorRepository addSectorNode error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Update a boundary node
  Future<void> updateSectorNode(String nodeId, SectorNodeModel node) async {
    try {
      await _client
          .from(SupabaseTable.sectorNodes)
          .update(node.toUpsertJson())
          .eq('id', nodeId);
    } catch (e) {
      appLogger.e('SectorRepository updateSectorNode error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Delete a boundary node and re-sequence remaining nodes
  Future<void> deleteSectorNode(String nodeId, String sectorId) async {
    try {
      await _client.from(SupabaseTable.sectorNodes).delete().eq('id', nodeId);

      // Fetch remaining and re-sequence node orders
      final remaining = await getSectorNodes(sectorId);
      for (int i = 0; i < remaining.length; i++) {
        final expectedOrder = i + 1;
        if (remaining[i].nodeOrder != expectedOrder) {
          await _client
              .from(SupabaseTable.sectorNodes)
              .update({'node_order': expectedOrder})
              .eq('id', remaining[i].id);
        }
      }
    } catch (e) {
      appLogger.e('SectorRepository deleteSectorNode error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Reorder all nodes of a sector in one batch
  Future<void> reorderSectorNodes(
    String sectorId,
    List<SectorNodeModel> reorderedNodes,
  ) async {
    try {
      // Step 1: Assign temporary negative orders to prevent UNIQUE(sector_id, node_order) collision
      for (int i = 0; i < reorderedNodes.length; i++) {
        await _client
            .from(SupabaseTable.sectorNodes)
            .update({'node_order': -(i + 1)})
            .eq('id', reorderedNodes[i].id);
      }

      // Step 2: Assign new 1-based positive orders
      for (int i = 0; i < reorderedNodes.length; i++) {
        await _client
            .from(SupabaseTable.sectorNodes)
            .update({'node_order': i + 1})
            .eq('id', reorderedNodes[i].id);
      }
    } catch (e) {
      appLogger.e('SectorRepository reorderSectorNodes error: $e');
      throw parseSupabaseException(e);
    }
  }
}
