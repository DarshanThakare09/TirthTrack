import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String? profileId;
  final String? alertId;
  final String title;
  final String body;
  final String status;
  final bool isRead;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.profileId,
    this.alertId,
    required this.title,
    required this.body,
    this.status = 'sent',
    this.isRead = false,
    this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?,
      alertId: json['alert_id'] as String?,
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'sent',
      isRead: json['is_read'] as bool? ?? false,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'alert_id': alertId,
      'title': title,
      'body': body,
      'status': status,
      'is_read': isRead,
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, profileId, alertId, title, body, status, isRead];
}
