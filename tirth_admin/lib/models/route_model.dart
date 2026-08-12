import 'package:equatable/equatable.dart';
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
    this.nodeCount = 0,
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
  final int nodeCount;

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

  factory RouteModel.fromJson(Map<String, dynamic> json, {int nodeCount = 0}) {
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
      nodeCount: nodeCount,
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'route_name': routeName.trim(),
      if (routeCode != null && routeCode!.trim().isNotEmpty)
        'route_code': routeCode!.trim(),
      if (description != null) 'description': description!.trim(),
      if (totalDistanceKm != null) 'total_distance_km': totalDistanceKm,
      if (estimatedTimeMinutes != null)
        'estimated_time_minutes': estimatedTimeMinutes,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  RouteModel copyWith({
    String? routeName,
    String? routeCode,
    String? description,
    double? totalDistanceKm,
    int? estimatedTimeMinutes,
    bool? isActive,
    int? nodeCount,
  }) {
    return RouteModel(
      id: id,
      routeName: routeName ?? this.routeName,
      routeCode: routeCode ?? this.routeCode,
      description: description ?? this.description,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      nodeCount: nodeCount ?? this.nodeCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        routeName,
        routeCode,
        totalDistanceKm,
        estimatedTimeMinutes,
        isActive,
        nodeCount,
      ];
}

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

  Map<String, dynamic> toUpsertJson() {
    return {
      'route_id': routeId,
      'node_order': nodeOrder,
      'node_name': nodeName.trim(),
      'latitude': latitude,
      'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (distanceFromStartKm != null)
        'distance_from_start_km': distanceFromStartKm,
    };
  }

  RouteNodeModel copyWith({
    int? nodeOrder,
    String? nodeName,
    double? latitude,
    double? longitude,
    double? altitude,
    double? distanceFromStartKm,
  }) {
    return RouteNodeModel(
      id: id,
      routeId: routeId,
      nodeOrder: nodeOrder ?? this.nodeOrder,
      nodeName: nodeName ?? this.nodeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      distanceFromStartKm: distanceFromStartKm ?? this.distanceFromStartKm,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        routeId,
        nodeOrder,
        nodeName,
        latitude,
        longitude,
        distanceFromStartKm,
      ];
}
