// ============================================================
// features/notifications/models/notification_models.dart
// ============================================================

import 'package:equatable/equatable.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

// ── Alert Type & Priority Enums ───────────────────────────────
enum AlertTypeEnum {
  general, emergency, weather, traffic, security, medical, announcement
}

enum AlertPriorityEnum { low, medium, high, critical }

extension AlertPriorityEnumX on AlertPriorityEnum {
  Color get color {
    switch (this) {
      case AlertPriorityEnum.low:      return AppColors.priorityLow;
      case AlertPriorityEnum.medium:   return AppColors.priorityMedium;
      case AlertPriorityEnum.high:     return AppColors.priorityHigh;
      case AlertPriorityEnum.critical: return AppColors.priorityCritical;
    }
  }

  String get displayLabel {
    switch (this) {
      case AlertPriorityEnum.low:      return 'Low';
      case AlertPriorityEnum.medium:   return 'Medium';
      case AlertPriorityEnum.high:     return 'High';
      case AlertPriorityEnum.critical: return 'Critical';
    }
  }
}

extension AlertTypeEnumX on AlertTypeEnum {
  String get dbValue => name;
  IconData get icon {
    switch (this) {
      case AlertTypeEnum.emergency:    return Icons.warning_rounded;
      case AlertTypeEnum.weather:      return Icons.thunderstorm_rounded;
      case AlertTypeEnum.traffic:      return Icons.traffic_rounded;
      case AlertTypeEnum.security:     return Icons.security_rounded;
      case AlertTypeEnum.medical:      return Icons.medical_services_rounded;
      case AlertTypeEnum.announcement: return Icons.campaign_rounded;
      default:                         return Icons.info_outline_rounded;
    }
  }
}

AlertTypeEnum alertTypeFromDb(String? v) {
  if (v == null) return AlertTypeEnum.general;
  return AlertTypeEnum.values.where((e) => e.name == v).firstOrNull ?? AlertTypeEnum.general;
}

AlertPriorityEnum alertPriorityFromDb(String? v) {
  if (v == null) return AlertPriorityEnum.medium;
  return AlertPriorityEnum.values.where((e) => e.name == v).firstOrNull ?? AlertPriorityEnum.medium;
}

// ── Alert Model ───────────────────────────────────────────────
class AlertModel extends Equatable {
  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.alertType,
    required this.priority,
    this.expiresAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String message;
  final AlertTypeEnum alertType;
  final AlertPriorityEnum priority;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      alertType: alertTypeFromDb(json['alert_type'] as String?),
      priority: alertPriorityFromDb(json['priority'] as String?),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, isActive, priority];
}

// ── Notification Model ────────────────────────────────────────
enum NotificationStatusEnum { pending, sent, delivered, failed }

class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    this.profileId,
    this.alertId,
    required this.title,
    required this.body,
    required this.status,
    required this.isRead,
    this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String? profileId;
  final String? alertId;
  final String title;
  final String body;
  final NotificationStatusEnum status;
  final bool isRead;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?,
      alertId: json['alert_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      status: NotificationStatusEnum.values
              .where((e) => e.name == (json['status'] as String?))
              .firstOrNull ?? NotificationStatusEnum.pending,
      isRead: (json['is_read'] as bool?) ?? false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, isRead, status];
}

// ── Device Token Model ────────────────────────────────────────
enum DevicePlatformEnum { android, ios, web }

class DeviceTokenModel extends Equatable {
  const DeviceTokenModel({
    required this.id,
    required this.profileId,
    required this.platform,
    this.deviceName,
    this.deviceId,
    required this.fcmToken,
    this.appVersion,
    this.osVersion,
    required this.isActive,
  });

  final String id;
  final String profileId;
  final DevicePlatformEnum platform;
  final String? deviceName;
  final String? deviceId;
  final String fcmToken;
  final String? appVersion;
  final String? osVersion;
  final bool isActive;

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      platform: DevicePlatformEnum.values
              .where((e) => e.name == (json['platform'] as String?))
              .firstOrNull ?? DevicePlatformEnum.android,
      deviceName: json['device_name'] as String?,
      deviceId: json['device_id'] as String?,
      fcmToken: json['fcm_token'] as String,
      appVersion: json['app_version'] as String?,
      osVersion: json['os_version'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  @override
  List<Object?> get props => [id, fcmToken, isActive];
}
