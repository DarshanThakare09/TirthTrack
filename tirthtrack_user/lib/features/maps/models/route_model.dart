// ============================================================
// features/maps/models/route_model.dart
// ============================================================

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

class RouteModel extends Equatable {
  const RouteModel({
    required this.id,
    required this.routeName,
    this.routeCode,
    this.description,
    this.totalDistanceKm,
    this.estimatedTimeMinutes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String routeName;
  final String? routeCode;
  final String? description;
  final double? totalDistanceKm;
  final int? estimatedTimeMinutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get formattedDistance {
    if (totalDistanceKm == null) return 'N/A';
    return '${totalDistanceKm!.toStringAsFixed(1)} km';
  }

  String get formattedTime {
    if (estimatedTimeMinutes == null) return 'N/A';
    final h = estimatedTimeMinutes! ~/ 60;
    final m = estimatedTimeMinutes! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      routeName: json['route_name'] as String,
      routeCode: json['route_code'] as String?,
      description: json['description'] as String?,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble(),
      estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, routeName, routeCode, totalDistanceKm, estimatedTimeMinutes];
}

// ── Route Node Model ──────────────────────────────────────────
class RouteNodeModel extends Equatable {
  const RouteNodeModel({
    required this.id,
    required this.routeId,
    required this.nodeOrder,
    required this.nodeName,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.distanceFromStartKm,
    required this.createdAt,
  });

  final String id;
  final String routeId;
  final int nodeOrder;
  final String nodeName;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? distanceFromStartKm;
  final DateTime createdAt;

  LatLng get latLng => LatLng(latitude, longitude);
  gmaps.LatLng get googleLatLng => gmaps.LatLng(latitude, longitude);

  factory RouteNodeModel.fromJson(Map<String, dynamic> json) {
    return RouteNodeModel(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      nodeOrder: json['node_order'] as int,
      nodeName: json['node_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      distanceFromStartKm:
          (json['distance_from_start_km'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, routeId, nodeOrder, latitude, longitude];
}
