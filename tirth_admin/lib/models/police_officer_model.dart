import 'package:equatable/equatable.dart';

enum PoliceStatusEnum { pending, verified, rejected }

extension PoliceStatusEnumX on PoliceStatusEnum {
  String get dbValue => name;
  String get displayLabel {
    switch (this) {
      case PoliceStatusEnum.pending:
        return 'Pending';
      case PoliceStatusEnum.verified:
        return 'Verified';
      case PoliceStatusEnum.rejected:
        return 'Rejected';
    }
  }
}

PoliceStatusEnum policeStatusFromDb(String? value) {
  if (value == null) return PoliceStatusEnum.pending;
  return PoliceStatusEnum.values.where((e) => e.name == value).firstOrNull ??
      PoliceStatusEnum.pending;
}

class PoliceOfficerModel extends Equatable {
  const PoliceOfficerModel({
    required this.id,
    required this.profileId,
    required this.badgeNumber,
    required this.policeStation,
    required this.district,
    required this.state,
    this.designation,
    this.department,
    this.idCardPhoto,
    required this.verificationStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    // Joined Profile Details
    this.fullName,
    this.mobile,
    this.email,
    this.profilePhoto,
  });

  final String id;
  final String profileId;
  final String badgeNumber;
  final String policeStation;
  final String district;
  final String state;
  final String? designation;
  final String? department;
  final String? idCardPhoto;
  final PoliceStatusEnum verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Profile data
  final String? fullName;
  final String? mobile;
  final String? email;
  final String? profilePhoto;

  bool get isVerified => verificationStatus == PoliceStatusEnum.verified;
  bool get isPending => verificationStatus == PoliceStatusEnum.pending;
  bool get isRejected => verificationStatus == PoliceStatusEnum.rejected;

  String get officerDisplayName => fullName?.trim().isNotEmpty == true
      ? fullName!
      : 'Officer ($badgeNumber)';

  factory PoliceOfficerModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return PoliceOfficerModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      badgeNumber: json['badge_number'] as String,
      policeStation: json['police_station'] as String,
      district: json['district'] as String,
      state: json['state'] as String,
      designation: json['designation'] as String?,
      department: json['department'] as String?,
      idCardPhoto: json['id_card_photo'] as String?,
      verificationStatus:
          policeStatusFromDb(json['verification_status'] as String?),
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fullName: profile?['full_name'] as String?,
      mobile: profile?['mobile'] as String?,
      email: profile?['email'] as String?,
      profilePhoto: profile?['profile_photo'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        badgeNumber,
        policeStation,
        verificationStatus,
        verifiedBy,
        verifiedAt,
        fullName,
      ];
}
