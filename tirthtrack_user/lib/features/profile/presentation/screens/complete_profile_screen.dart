// ============================================================
// features/profile/presentation/screens/complete_profile_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../models/profile_model.dart';
import '../../providers/profile_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  GenderEnum? _selectedGender;
  DateTime? _dateOfBirth;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      if (profile.fullName != null) _nameController.text = profile.fullName!;
      if (profile.city != null) _cityController.text = profile.city!;
      if (profile.state != null) _stateController.text = profile.state!;
      _selectedGender = profile.gender;
      _dateOfBirth = profile.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ??
          DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
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

    final updates = {
      'full_name': _nameController.text.trim(),
      'gender': _selectedGender!.dbValue,
      'date_of_birth':
          '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await ref.read(profileProvider.notifier).updateProfile(updates);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final profileState = ref.read(profileProvider);

    profileState.when(
      data: (_) => context.go(AppRoutes.locationPermission),
      error: (e, _) {
        final msg = e is AppException ? e.message : 'Failed to save profile.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us about yourself',
                  style: AppTextStyles.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill in your profile details to continue.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 32),

                // ── Full Name ────────────────────────────────
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'Darshan Thakare',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),

                // ── Gender ───────────────────────────────────
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
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Date of Birth ────────────────────────────
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

                // ── City ──────────────────────────────────────
                AppTextField(
                  controller: _cityController,
                  label: 'City *',
                  hint: 'Nashik',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'City'),
                ),
                const SizedBox(height: 16),

                // ── State ─────────────────────────────────────
                AppTextField(
                  controller: _stateController,
                  label: 'State *',
                  hint: 'Maharashtra',
                  prefixIcon: const Icon(Icons.map_outlined),
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.required(v, 'State'),
                ),
                const SizedBox(height: 40),

                // ── Save ──────────────────────────────────────
                AppButton(
                  label: 'Save & Continue',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _isSubmitting ? null : _save,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
