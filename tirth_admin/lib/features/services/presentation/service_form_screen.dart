import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/service_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/location_picker_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'service_providers.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({
    super.key,
    this.serviceId,
  });

  final String? serviceId;

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _hoursController = TextEditingController();
  ServiceTypeEnum _selectedType = ServiceTypeEnum.medical;
  bool _is24Hours = false;
  bool _isActive = true;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _populateData(ServiceModel service) {
    if (_isInitialized) return;
    _nameController.text = service.serviceName;
    _selectedType = service.serviceType;
    _descController.text = service.description ?? '';
    _latController.text = service.latitude.toString();
    _lngController.text = service.longitude.toString();
    _contactPersonController.text = service.contactPerson ?? '';
    _contactNumberController.text = service.contactNumber ?? '';
    _hoursController.text = service.operatingHours ?? '';
    _is24Hours = service.is24Hours;
    _isActive = service.isActive;
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
      title: 'Pick Facility Location',
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

    final service = ServiceModel(
      id: widget.serviceId ?? '',
      serviceName: _nameController.text.trim(),
      serviceType: _selectedType,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      latitude: lat,
      longitude: lng,
      contactPerson: _contactPersonController.text.trim().isNotEmpty
          ? _contactPersonController.text.trim()
          : null,
      contactNumber: _contactNumberController.text.trim().isNotEmpty
          ? _contactNumberController.text.trim()
          : null,
      operatingHours: _hoursController.text.trim().isNotEmpty
          ? _hoursController.text.trim()
          : null,
      is24Hours: _is24Hours,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(serviceActionControllerProvider.notifier)
        .saveService(id: widget.serviceId, service: service);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            widget.serviceId == null
                ? 'Facility added successfully.'
                : 'Facility details updated.',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.serviceId != null;
    final actionState = ref.watch(serviceActionControllerProvider);

    if (isEditing) {
      final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId!));
      return serviceAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Facility')),
          body: const LoadingWidget(message: 'Loading facility details...'),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Facility')),
          body: ErrorStateWidget(message: err.toString()),
        ),
        data: (service) {
          _populateData(service);
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
        title: Text(isEditing ? 'Edit Facility' : 'Add Facility / Service'),
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
                        'Facility Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Facility Name
                      AppTextField(
                        controller: _nameController,
                        label: 'Facility / Service Name',
                        hint: 'e.g. Civil Hospital Emergency Post #4',
                        prefixIcon: Icons.business_rounded,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Facility name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Service Type Dropdown
                      const Text(
                        'Service Category *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ServiceTypeEnum>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: ServiceTypeEnum.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon, color: t.color, size: 18),
                                const SizedBox(width: 10),
                                Text(t.displayLabel),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      AppTextField(
                        controller: _descController,
                        label: 'Description / Available Amenities',
                        hint: 'e.g. 10 emergency beds, oxygen cylinders, 2 ambulances stationed...',
                        maxLines: 3,
                        prefixIcon: Icons.description_outlined,
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

                      // Contact Person & Phone
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _contactPersonController,
                              label: 'Incharge Name',
                              hint: 'Dr. Sharma',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _contactNumberController,
                              label: 'Contact Number',
                              hint: '+91 9876543210',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Operating Hours
                      AppTextField(
                        controller: _hoursController,
                        label: 'Operating Hours',
                        hint: 'e.g. 06:00 AM – 10:00 PM',
                        prefixIcon: Icons.access_time_rounded,
                        enabled: !_is24Hours,
                      ),
                      const SizedBox(height: 12),

                      // 24 Hours Checkbox
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Open 24 Hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _is24Hours,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _is24Hours = val ?? false;
                            if (_is24Hours) {
                              _hoursController.text = '24 Hours';
                            }
                          });
                        },
                      ),

                      // Active Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Active services appear on the live pilgrim map.',
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
                text: isEditing ? 'Update Facility' : 'Save Facility',
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
