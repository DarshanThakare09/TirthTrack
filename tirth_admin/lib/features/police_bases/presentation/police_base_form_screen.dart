import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/police_base_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/location_picker_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'police_base_providers.dart';

class PoliceBaseFormScreen extends ConsumerStatefulWidget {
  const PoliceBaseFormScreen({
    super.key,
    this.baseId,
  });

  final String? baseId;

  @override
  ConsumerState<PoliceBaseFormScreen> createState() =>
      _PoliceBaseFormScreenState();
}

class _PoliceBaseFormScreenState extends ConsumerState<PoliceBaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stationController = TextEditingController();
  final _sectorController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _inchargeController = TextEditingController();
  final _contactController = TextEditingController();
  final _staffController = TextEditingController(text: '0');
  bool _isActive = true;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _stationController.dispose();
    _sectorController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _inchargeController.dispose();
    _contactController.dispose();
    _staffController.dispose();
    super.dispose();
  }

  void _populateData(PoliceBaseModel base) {
    if (_isInitialized) return;
    _nameController.text = base.baseName;
    _stationController.text = base.stationName ?? '';
    _sectorController.text = base.sectorName ?? '';
    _latController.text = base.latitude.toString();
    _lngController.text = base.longitude.toString();
    _inchargeController.text = base.inchargeName ?? '';
    _contactController.text = base.contactNumber ?? '';
    _staffController.text = base.totalStaff.toString();
    _isActive = base.isActive;
    _isInitialized = true;
  }

  Future<void> _handlePickLocation() async {
    final currentLat = double.tryParse(_latController.text.trim());
    final currentLng = double.tryParse(_lngController.text.trim());
    final initialPos = (currentLat != null && currentLng != null)
        ? LatLng(currentLat, currentLng)
        : null;

    final picked = await LocationPickerDialog.show(
      context,
      initialLocation: initialPos,
      title: 'Pick Police Base Location',
    );

    if (picked != null) {
      setState(() {
        _latController.text = picked.latitude.toStringAsFixed(6);
        _lngController.text = picked.longitude.toStringAsFixed(6);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.parse(_latController.text.trim());
    final lng = double.parse(_lngController.text.trim());
    final staff = int.tryParse(_staffController.text.trim()) ?? 0;

    final base = PoliceBaseModel(
      id: widget.baseId ?? '',
      baseName: _nameController.text.trim(),
      stationName: _stationController.text.trim().isNotEmpty
          ? _stationController.text.trim()
          : null,
      sectorName: _sectorController.text.trim().isNotEmpty
          ? _sectorController.text.trim()
          : null,
      latitude: lat,
      longitude: lng,
      inchargeName: _inchargeController.text.trim().isNotEmpty
          ? _inchargeController.text.trim()
          : null,
      contactNumber: _contactController.text.trim().isNotEmpty
          ? _contactController.text.trim()
          : null,
      totalStaff: staff,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(policeBaseActionControllerProvider.notifier)
        .saveBase(id: widget.baseId, base: base);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            widget.baseId == null
                ? 'Police Base created successfully.'
                : 'Police Base updated successfully.',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.baseId != null;
    final actionState = ref.watch(policeBaseActionControllerProvider);

    if (isEditing) {
      final baseAsync = ref.watch(policeBaseDetailProvider(widget.baseId!));
      return baseAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Police Base')),
          body: const LoadingWidget(message: 'Loading base details...'),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Police Base')),
          body: ErrorStateWidget(message: err.toString()),
        ),
        data: (base) {
          _populateData(base);
          return _buildForm(isEditing: true, isLoading: actionState.isLoading);
        },
      );
    }

    return _buildForm(isEditing: false, isLoading: actionState.isLoading);
  }

  Widget _buildForm({required bool isEditing, required bool isLoading}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Police Base' : 'Add Police Base'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Base Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Base Name
                      AppTextField(
                        controller: _nameController,
                        label: 'Police Base Name',
                        hint: 'e.g. Sector-3 Main Police Post (Panchavati)',
                        prefixIcon: Icons.shield_rounded,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Base name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Station & Sector
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _stationController,
                              label: 'Police Station',
                              hint: 'Panchavati PS',
                              prefixIcon: Icons.local_police_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _sectorController,
                              label: 'Sector Assignment',
                              hint: 'Sector-3 (Ramkund)',
                              prefixIcon: Icons.map_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Coordinates
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _latController,
                              label: 'Latitude',
                              hint: '19.9975',
                              prefixIcon: Icons.pin_drop_outlined,
                              isRequired: true,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (val) =>
                                  double.tryParse(val ?? '') == null
                                      ? 'Latitude required'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _lngController,
                              label: 'Longitude',
                              hint: '73.7898',
                              prefixIcon: Icons.pin_drop_outlined,
                              isRequired: true,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (val) =>
                                  double.tryParse(val ?? '') == null
                                      ? 'Longitude required'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text('Pick on Map'),
                          onPressed: _handlePickLocation,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Incharge & Contact
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _inchargeController,
                              label: 'Incharge Officer Name',
                              hint: 'Inspector Patil',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _contactController,
                              label: 'Control Room / Phone',
                              hint: '+91 253 2570000',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Staff Count
                      AppTextField(
                        controller: _staffController,
                        label: 'Total Stationed Staff',
                        hint: '0',
                        prefixIcon: Icons.people_outline_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Active Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active Base Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Active police bases appear on public maps and can be assigned to sectors.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                        value: _isActive,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              AppButton(
                text: isEditing ? 'Update Base' : 'Save Police Base',
                icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
                isLoading: isLoading,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
