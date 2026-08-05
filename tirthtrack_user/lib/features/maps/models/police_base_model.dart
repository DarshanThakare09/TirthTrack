// ============================================================
// features/maps/models/police_base_model.dart
// ============================================================

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

class PoliceBaseModel extends Equatable {
  const PoliceBaseModel({
    required this.id,
    this.policeDetailId,
    required this.baseName,
    this.stationName,
    this.sectorName,
    required this.latitude,
    required this.longitude,
    this.contactNumber,
    this.inchargeName,
    this.totalStaff = 0,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  final String id;
  final String? policeDetailId;
  final String baseName;
  final String? stationName;
  final String? sectorName;
  final double latitude;
  final double longitude;
  final String? contactNumber;
  final String? inchargeName;
  final int totalStaff;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed client-side.
  final double? distanceKm;

  LatLng get latLng => LatLng(latitude, longitude);
  gmaps.LatLng get googleLatLng => gmaps.LatLng(latitude, longitude);

  factory PoliceBaseModel.fromJson(Map<String, dynamic> json,
      {double? distanceKm}) {
    return PoliceBaseModel(
      id: json['id'] as String,
      policeDetailId: json['police_detail_id'] as String?,
      baseName: json['base_name'] as String,
      stationName: json['station_name'] as String?,
      sectorName: json['sector_name'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      contactNumber: json['contact_number'] as String?,
      inchargeName: json['incharge_name'] as String?,
      totalStaff: (json['total_staff'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceKm: distanceKm,
    );
  }

  PoliceBaseModel withDistance(double km) => PoliceBaseModel(
        id: id,
        policeDetailId: policeDetailId,
        baseName: baseName,
        stationName: stationName,
        sectorName: sectorName,
        latitude: latitude,
        longitude: longitude,
        contactNumber: contactNumber,
        inchargeName: inchargeName,
        totalStaff: totalStaff,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        distanceKm: km,
      );

  @override
  List<Object?> get props => [id, baseName, latitude, longitude];
}

// ── Sector Model ──────────────────────────────────────────────
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
  });

  final String id;
  final String sectorName;
  final String? sectorCode;
  final String? description;
  final String? policeBaseId;
  final String? colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SectorModel.fromJson(Map<String, dynamic> json) {
    return SectorModel(
      id: json['id'] as String,
      sectorName: json['sector_name'] as String,
      sectorCode: json['sector_code'] as String?,
      description: json['description'] as String?,
      policeBaseId: json['police_base_id'] as String?,
      colorHex: json['color_hex'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, sectorName];
}

// ── Sector Node Model ─────────────────────────────────────────
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

  @override
  List<Object?> get props => [id, sectorId, nodeOrder];
}
