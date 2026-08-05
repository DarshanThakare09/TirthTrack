// ============================================================
// features/location/models/live_location_model.dart
// ============================================================

import 'package:equatable/equatable.dart';

enum LocationSourceEnum { gps, network, manual }

extension LocationSourceEnumX on LocationSourceEnum {
  String get dbValue => name;
}

LocationSourceEnum locationSourceFromDb(String? v) {
  if (v == null) return LocationSourceEnum.gps;
  return LocationSourceEnum.values
      .where((e) => e.name == v)
      .firstOrNull ?? LocationSourceEnum.gps;
}

class LiveLocationModel extends Equatable {
  const LiveLocationModel({
    required this.id,
    required this.profileId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.batteryPercentage,
    this.locationSource = LocationSourceEnum.gps,
    required this.recordedAt,
  });

  final String id;
  final String profileId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final int? batteryPercentage;
  final LocationSourceEnum locationSource;
  final DateTime recordedAt;

  Map<String, dynamic> toInsertJson() {
    return {
      'profile_id': profileId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (batteryPercentage != null)
        'battery_percentage': batteryPercentage,
      'location_source': locationSource.dbValue,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  factory LiveLocationModel.fromJson(Map<String, dynamic> json) {
    return LiveLocationModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      batteryPercentage: json['battery_percentage'] as int?,
      locationSource:
          locationSourceFromDb(json['location_source'] as String?),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, profileId, latitude, longitude, recordedAt];
}
