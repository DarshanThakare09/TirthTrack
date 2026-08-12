import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum AlertTypeEnum {
  general,
  emergency,
  weather,
  traffic,
  security,
  medical,
  announcement,
}

enum AlertPriorityEnum { low, medium, high, critical }

extension AlertTypeEnumX on AlertTypeEnum {
  String get dbValue => name;

  String get displayLabel {
    switch (this) {
      case AlertTypeEnum.general:
        return 'General Announcement';
      case AlertTypeEnum.emergency:
        return 'Emergency / Disaster';
      case AlertTypeEnum.weather:
        return 'Weather Alert';
      case AlertTypeEnum.traffic:
        return 'Traffic & Crowd';
      case AlertTypeEnum.security:
        return 'Security Alert';
      case AlertTypeEnum.medical:
        return 'Medical Advisory';
      case AlertTypeEnum.announcement:
        return 'Official Announcement';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertTypeEnum.general:
        return Icons.campaign_rounded;
      case AlertTypeEnum.emergency:
        return Icons.warning_amber_rounded;
      case AlertTypeEnum.weather:
        return Icons.thunderstorm_rounded;
      case AlertTypeEnum.traffic:
        return Icons.traffic_rounded;
      case AlertTypeEnum.security:
        return Icons.security_rounded;
      case AlertTypeEnum.medical:
        return Icons.medical_services_rounded;
      case AlertTypeEnum.announcement:
        return Icons.announcement_rounded;
    }
  }
}

extension AlertPriorityEnumX on AlertPriorityEnum {
  String get dbValue => name;

  String get displayLabel {
    switch (this) {
      case AlertPriorityEnum.low:
        return 'Low';
      case AlertPriorityEnum.medium:
        return 'Medium';
      case AlertPriorityEnum.high:
        return 'High';
      case AlertPriorityEnum.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case AlertPriorityEnum.low:
        return AppColors.priorityLow;
      case AlertPriorityEnum.medium:
        return AppColors.priorityMedium;
      case AlertPriorityEnum.high:
        return AppColors.priorityHigh;
      case AlertPriorityEnum.critical:
        return AppColors.priorityCritical;
    }
  }
}

AlertTypeEnum alertTypeFromDb(String? value) {
  if (value == null) return AlertTypeEnum.general;
  return AlertTypeEnum.values.where((e) => e.name == value).firstOrNull ??
      AlertTypeEnum.general;
}

AlertPriorityEnum alertPriorityFromDb(String? value) {
  if (value == null) return AlertPriorityEnum.medium;
  return AlertPriorityEnum.values.where((e) => e.name == value).firstOrNull ??
      AlertPriorityEnum.medium;
}

class AlertModel extends Equatable {
  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.alertType,
    required this.priority,
    this.createdBy,
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
  final String? createdBy;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isEffectiveActive => isActive && !isExpired;

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      alertType: alertTypeFromDb(json['alert_type'] as String?),
      priority: alertPriorityFromDb(json['priority'] as String?),
      createdBy: json['created_by'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpsertJson({String? currentAdminId}) {
    return {
      'title': title.trim(),
      'message': message.trim(),
      'alert_type': alertType.dbValue,
      'priority': priority.dbValue,
      if (createdBy != null || currentAdminId != null)
        'created_by': createdBy ?? currentAdminId,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  AlertModel copyWith({
    String? title,
    String? message,
    AlertTypeEnum? alertType,
    AlertPriorityEnum? priority,
    String? createdBy,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return AlertModel(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      alertType: alertType ?? this.alertType,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        alertType,
        priority,
        createdBy,
        expiresAt,
        isActive,
      ];
}
