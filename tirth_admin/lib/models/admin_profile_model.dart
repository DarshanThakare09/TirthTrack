import 'package:equatable/equatable.dart';

enum UserRoleEnum { user, police, admin }

class AdminProfileModel extends Equatable {
  const AdminProfileModel({
    required this.adminId,
    required this.profileId,
    required this.fullName,
    this.email,
    this.mobile,
    this.employeeCode,
    this.designation,
    this.profilePhoto,
    this.permissions = const {},
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String adminId;       // admin_details.id (Used for created_by / verified_by)
  final String profileId;     // profiles.id / auth.uid()
  final String fullName;
  final String? email;
  final String? mobile;
  final String? employeeCode;
  final String? designation;
  final String? profilePhoto;
  final Map<String, dynamic> permissions;
  final UserRoleEnum role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AdminProfileModel.fromSupabase({
    required Map<String, dynamic> profileJson,
    required Map<String, dynamic> adminDetailsJson,
  }) {
    return AdminProfileModel(
      adminId: adminDetailsJson['id'] as String,
      profileId: profileJson['id'] as String,
      fullName: (profileJson['full_name'] as String?) ?? 'Administrator',
      email: profileJson['email'] as String?,
      mobile: profileJson['mobile'] as String?,
      employeeCode: adminDetailsJson['employee_code'] as String?,
      designation: (adminDetailsJson['designation'] as String?) ?? 'Administrator',
      profilePhoto: profileJson['profile_photo'] as String?,
      permissions: (adminDetailsJson['permissions'] as Map<String, dynamic>?) ?? {},
      role: UserRoleEnum.admin,
      isActive: (profileJson['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(adminDetailsJson['created_at'] as String),
      updatedAt: DateTime.parse(adminDetailsJson['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [adminId, profileId, fullName, email, role, isActive];
}
