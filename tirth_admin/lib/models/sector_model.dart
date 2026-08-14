import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';

class SectorModel extends Equatable {
  const SectorModel({
    required this.id,
    required this.sectorName,
    this.sectorCode,
    this.description,
    this.policeBaseId,
    this.colorHex,
    required this.createdAt,
    required this.updatedAt,
    this.policeBaseName,
    this.nodeCount = 0,
    this.nodes = const [],
  });

  final String id;
  final String sectorName;
  final String? sectorCode;
  final String? description;
  final String? policeBaseId;
  final String? colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? policeBaseName;
  final int nodeCount;
  final List<SectorNodeModel> nodes;

  Color get displayColor {
    if (colorHex == null || colorHex!.isEmpty) return AppColors.primary;
    try {
      final hex = colorHex!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        return Color(int.parse('0x$hex'));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  List<LatLng> get polygonPoints {
    final sorted = List<SectorNodeModel>.from(nodes)
      ..sort((a, b) => a.nodeOrder.compareTo(b.nodeOrder));
    return sorted.map((n) => n.latLng).toList();
  }

  LatLng? get centerPoint {
    if (nodes.isEmpty) return null;
    double latSum = 0;
    double lngSum = 0;
    for (final node in nodes) {
      latSum += node.latitude;
      lngSum += node.longitude;
    }
    return LatLng(latSum / nodes.length, lngSum / nodes.length);
  }

  factory SectorModel.fromJson(Map<String, dynamic> json, {int nodeCount = 0}) {
    final policeBase = json['police_bases'] as Map<String, dynamic>?;
    final rawNodes = json['sector_nodes'] as List<dynamic>?;
    List<SectorNodeModel> parsedNodes = [];

    if (rawNodes != null && rawNodes.isNotEmpty && rawNodes.first is Map<String, dynamic>) {
      parsedNodes = rawNodes
          .map((n) => SectorNodeModel.fromJson(n as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.nodeOrder.compareTo(b.nodeOrder));
    }

    final effectiveNodeCount = parsedNodes.isNotEmpty ? parsedNodes.length : nodeCount;

    return SectorModel(
      id: json['id'] as String,
      sectorName: json['sector_name'] as String,
      sectorCode: json['sector_code'] as String?,
      description: json['description'] as String?,
      policeBaseId: json['police_base_id'] as String?,
      colorHex: json['color_hex'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      policeBaseName: policeBase?['base_name'] as String?,
      nodeCount: effectiveNodeCount,
      nodes: parsedNodes,
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'sector_name': sectorName.trim(),
      if (sectorCode != null && sectorCode!.trim().isNotEmpty)
        'sector_code': sectorCode!.trim(),
      if (description != null) 'description': description!.trim(),
      'police_base_id': policeBaseId,
      if (colorHex != null && colorHex!.trim().isNotEmpty)
        'color_hex': colorHex!.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  SectorModel copyWith({
    String? sectorName,
    String? sectorCode,
    String? description,
    String? policeBaseId,
    String? colorHex,
    String? policeBaseName,
    int? nodeCount,
    List<SectorNodeModel>? nodes,
  }) {
    return SectorModel(
      id: id,
      sectorName: sectorName ?? this.sectorName,
      sectorCode: sectorCode ?? this.sectorCode,
      description: description ?? this.description,
      policeBaseId: policeBaseId ?? this.policeBaseId,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      policeBaseName: policeBaseName ?? this.policeBaseName,
      nodeCount: nodeCount ?? this.nodeCount,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sectorName,
        sectorCode,
        policeBaseId,
        colorHex,
        nodeCount,
        nodes,
      ];
}

class SectorNodeModel extends Equatable {
  const SectorNodeModel({
    required this.id,
    required this.sectorId,
    required this.nodeOrder,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final String sectorId;
  final int nodeOrder;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  LatLng get latLng => LatLng(latitude, longitude);

  factory SectorNodeModel.fromJson(Map<String, dynamic> json) {
    return SectorNodeModel(
      id: json['id'] as String,
      sectorId: json['sector_id'] as String,
      nodeOrder: json['node_order'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'sector_id': sectorId,
      'node_order': nodeOrder,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  SectorNodeModel copyWith({
    int? nodeOrder,
    double? latitude,
    double? longitude,
  }) {
    return SectorNodeModel(
      id: id,
      sectorId: sectorId,
      nodeOrder: nodeOrder ?? this.nodeOrder,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, sectorId, nodeOrder, latitude, longitude];
}
