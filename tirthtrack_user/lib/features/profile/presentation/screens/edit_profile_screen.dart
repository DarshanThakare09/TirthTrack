// ============================================================
// features/profile/presentation/screens/edit_profile_screen.dart
// ============================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../models/profile_model.dart';
import '../../providers/profile_provider.dart';
import '../widgets/profile_avatar_widget.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();

  GenderEnum? _selectedGender;
  DateTime? _dateOfBirth;
  bool _isSubmitting = false;
  bool _initialised = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initFromProfile(ProfileModel profile) {
    if (_initialised) return;
    _initialised = true;
    _nameController.text = profile.fullName ?? '';
    _cityController.text = profile.city ?? '';
    _stateController.text = profile.state ?? '';
    _addressController.text = profile.address ?? '';
    _selectedGender = profile.gender;
    _dateOfBirth = profile.dateOfBirth;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only JPG, PNG, and WEBP are allowed.')),
        );
      }
      return;
    }

    await ref.read(profileProvider.notifier).uploadProfilePhoto(
          bytes: Uint8List.fromList(bytes),
          extension: ext == 'jpg' ? 'jpeg' : ext,
        );

    if (mounted) {
      final state = ref.read(profileProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo.')),
        );
      } else {
        ref.invalidate(profilePhotoUrlProvider);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final updates = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'gender': _selectedGender!.dbValue,
      'date_of_birth':
          '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'address': _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await ref.read(profileProvider.notifier).updateProfile(updates);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final pState = ref.read(profileProvider);

    pState.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        context.pop();
      },
      error: (e, _) {
        final msg = e is AppException ? e.message : 'Failed to update profile.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final photoUrlState = ref.watch(profilePhotoUrlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileState.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (profile) {
          _initFromProfile(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ─────────────────────────────────
                  Center(
                    child: ProfileAvatarWidget(
                      photoUrl: photoUrlState.valueOrNull,
                      name: profile.fullName,
                      radius: 52,
                      showEditBadge: true,
                      onTap: _pickAndUploadPhoto,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Full Name ───────────────────────────────
                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Gender ──────────────────────────────────
                  Text('Gender *', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: GenderEnum.values.map((g) {
                      final selected = _selectedGender == g;
                      return ChoiceChip(
                        label: Text(g.displayLabel),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedGender = g),
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.onSurfaceMuted,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Date of Birth ───────────────────────────
                  Text('Date of Birth *', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: AppColors.onSurfaceMuted, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _dateOfBirth != null
                                ? DateFormat('dd MMMM yyyy')
                                    .format(_dateOfBirth!)
                                : 'Select date of birth',
                            style: _dateOfBirth != null
                                ? AppTextStyles.bodyMedium
                                : AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceDisabled),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── City ────────────────────────────────────
                  AppTextField(
                    controller: _cityController,
                    label: 'City *',
                    prefixIcon:
                        const Icon(Icons.location_city_outlined),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'City is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── State ───────────────────────────────────
                  AppTextField(
                    controller: _stateController,
                    label: 'State *',
                    prefixIcon: const Icon(Icons.map_outlined),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'State is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Address ─────────────────────────────────
                  AppTextField(
                    controller: _addressController,
                    label: 'Address',
                    prefixIcon: const Icon(Icons.home_outlined),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),

                  // ── Save ────────────────────────────────────
                  AppButton(
                    label: 'Save Changes',
                    icon: Icons.save_outlined,
                    onPressed: _isSubmitting ? null : _save,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
