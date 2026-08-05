// ============================================================
// features/profile/models/profile_model.dart
// ============================================================

import 'package:equatable/equatable.dart';

// ── Enums (match DB exactly) ──────────────────────────────────
enum GenderEnum { male, female, other }

enum UserRoleEnum { user, police, admin }

extension GenderEnumX on GenderEnum {
  String get dbValue => name; // 'male', 'female', 'other'
  String get displayLabel {
    switch (this) {
      case GenderEnum.male:
        return 'Male';
      case GenderEnum.female:
        return 'Female';
      case GenderEnum.other:
        return 'Other';
    }
  }
}

extension UserRoleEnumX on UserRoleEnum {
  String get dbValue => name;
}

GenderEnum? genderFromDb(String? value) {
  if (value == null) return null;
  return GenderEnum.values.where((e) => e.name == value).firstOrNull;
}

UserRoleEnum? roleFromDb(String? value) {
  if (value == null) return null;
  return UserRoleEnum.values.where((e) => e.name == value).firstOrNull;
}

// ── Profile Model ─────────────────────────────────────────────
class ProfileModel extends Equatable {
  const ProfileModel({
    required this.id,
    required this.fullName,
    this.mobile,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.profilePhoto,
    this.address,
    this.city,
    this.state,
    this.country = 'India',
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? fullName;      // Nullable — trigger inserts without full_name
  final String? mobile;
  final String? email;
  final GenderEnum? gender;
  final DateTime? dateOfBirth;
  final String? profilePhoto;  // Storage path, not full URL
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final UserRoleEnum role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// A profile is complete when all core profile fields are provided and non-null.
  bool get isComplete =>
      fullName != null &&
      fullName!.trim().isNotEmpty &&
      fullName != 'Pilgrim User' &&
      gender != null &&
      dateOfBirth != null &&
      city != null &&
      city!.trim().isNotEmpty &&
      state != null &&
      state!.trim().isNotEmpty;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      gender: genderFromDb(json['gender'] as String?),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      profilePhoto: json['profile_photo'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: (json['country'] as String?) ?? 'India',
      role: roleFromDb(json['role'] as String?) ?? UserRoleEnum.user,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (fullName != null) 'full_name': fullName,
      if (gender != null) 'gender': gender!.dbValue,
      if (dateOfBirth != null)
        'date_of_birth':
            '${dateOfBirth!.year}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}',
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (profilePhoto != null) 'profile_photo': profilePhoto,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? mobile,
    String? email,
    GenderEnum? gender,
    DateTime? dateOfBirth,
    String? profilePhoto,
    String? address,
    String? city,
    String? state,
    String? country,
    bool? isActive,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      role: role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        mobile,
        email,
        gender,
        dateOfBirth,
        profilePhoto,
        address,
        city,
        state,
        country,
        role,
        isActive,
        createdAt,
        updatedAt,
      ];
}
