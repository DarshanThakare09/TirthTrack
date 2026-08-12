import 'package:equatable/equatable.dart';
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

  LatLng get latLng => LatLng(latitude, longitude);

  factory PoliceBaseModel.fromJson(Map<String, dynamic> json) {
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
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      if (policeDetailId != null) 'police_detail_id': policeDetailId,
      'base_name': baseName.trim(),
      if (stationName != null) 'station_name': stationName!.trim(),
      if (sectorName != null) 'sector_name': sectorName!.trim(),
      'latitude': latitude,
      'longitude': longitude,
      if (contactNumber != null) 'contact_number': contactNumber!.trim(),
      if (inchargeName != null) 'incharge_name': inchargeName!.trim(),
      'total_staff': totalStaff,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  PoliceBaseModel copyWith({
    String? policeDetailId,
    String? baseName,
    String? stationName,
    String? sectorName,
    double? latitude,
    double? longitude,
    String? contactNumber,
    String? inchargeName,
    int? totalStaff,
    bool? isActive,
  }) {
    return PoliceBaseModel(
      id: id,
      policeDetailId: policeDetailId ?? this.policeDetailId,
      baseName: baseName ?? this.baseName,
      stationName: stationName ?? this.stationName,
      sectorName: sectorName ?? this.sectorName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactNumber: contactNumber ?? this.contactNumber,
      inchargeName: inchargeName ?? this.inchargeName,
      totalStaff: totalStaff ?? this.totalStaff,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        baseName,
        stationName,
        sectorName,
        latitude,
        longitude,
        totalStaff,
        isActive,
      ];
}
