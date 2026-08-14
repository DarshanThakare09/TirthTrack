import 'package:equatable/equatable.dart';

enum LoginCodeStatusEnum { active, used, expired, revoked }

extension LoginCodeStatusEnumX on LoginCodeStatusEnum {
  String get dbValue => name;
  String get displayLabel {
    switch (this) {
      case LoginCodeStatusEnum.active:
        return 'Active';
      case LoginCodeStatusEnum.used:
        return 'Used';
      case LoginCodeStatusEnum.expired:
        return 'Expired';
      case LoginCodeStatusEnum.revoked:
        return 'Revoked';
    }
  }
}

LoginCodeStatusEnum loginCodeStatusFromDb(String? value) {
  if (value == null) return LoginCodeStatusEnum.active;
  return LoginCodeStatusEnum.values.where((e) => e.name == value).firstOrNull ??
      LoginCodeStatusEnum.active;
}

class PoliceLoginCodeModel extends Equatable {
  const PoliceLoginCodeModel({
    required this.id,
    required this.policeId,
    required this.loginCode,
    required this.expiresAt,
    required this.status,
    this.usedAt,
    this.createdBy,
    required this.createdAt,
    this.officerName,
    this.badgeNumber,
    this.policeStation,
  });

  final String id;
  final String policeId;
  final String loginCode;
  final DateTime expiresAt;
  final LoginCodeStatusEnum status;
  final DateTime? usedAt;
  final String? createdBy;
  final DateTime createdAt;
  final String? officerName;
  final String? badgeNumber;
  final String? policeStation;

  bool get isExpiredByDate => expiresAt.isBefore(DateTime.now());

  bool get isEffectiveActive =>
      status == LoginCodeStatusEnum.active && !isExpiredByDate;

  LoginCodeStatusEnum get effectiveStatus {
    if (status == LoginCodeStatusEnum.active && isExpiredByDate) {
      return LoginCodeStatusEnum.expired;
    }
    return status;
  }

  factory PoliceLoginCodeModel.fromJson(Map<String, dynamic> json) {
    String? officerName;
    String? badgeNumber;
    String? policeStation;

    final policeDetails = json['police_details'] as Map<String, dynamic>?;
    if (policeDetails != null) {
      badgeNumber = policeDetails['badge_number'] as String?;
      policeStation = policeDetails['police_station'] as String?;
      final profile = policeDetails['profiles'] as Map<String, dynamic>?;
      if (profile != null) {
        officerName = profile['full_name'] as String?;
      }
    }

    return PoliceLoginCodeModel(
      id: json['id'] as String,
      policeId: json['police_id'] as String,
      loginCode: json['login_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      status: loginCodeStatusFromDb(json['status'] as String?),
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'] as String)?.toLocal()
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      officerName: officerName,
      badgeNumber: badgeNumber,
      policeStation: policeStation,
    );
  }

  @override
  List<Object?> get props =>
      [id, policeId, loginCode, expiresAt, status, usedAt, officerName, badgeNumber];
}
