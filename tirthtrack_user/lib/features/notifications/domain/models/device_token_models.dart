import 'package:equatable/equatable.dart';

class DeviceTokenModel extends Equatable {
  final String id;
  final String profileId;
  final String platform; // android, ios, web
  final String? deviceName;
  final String? deviceId;
  final String fcmToken;
  final String? appVersion;
  final String? osVersion;
  final bool isActive;
  final DateTime? lastSeenAt;

  const DeviceTokenModel({
    required this.id,
    required this.profileId,
    required this.platform,
    this.deviceName,
    this.deviceId,
    required this.fcmToken,
    this.appVersion,
    this.osVersion,
    this.isActive = true,
    this.lastSeenAt,
  });

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      platform: json['platform'] as String? ?? 'android',
      deviceName: json['device_name'] as String?,
      deviceId: json['device_id'] as String?,
      fcmToken: json['fcm_token'] as String,
      appVersion: json['app_version'] as String?,
      osVersion: json['os_version'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'platform': platform,
      'device_name': deviceName,
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'app_version': appVersion,
      'os_version': osVersion,
      'is_active': isActive,
      'last_seen_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, profileId, platform, fcmToken, isActive];
}
