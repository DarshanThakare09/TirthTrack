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
    this.initialLat,
    this.initialLng,
  });

  final String? serviceId;
  final double? initialLat;
  final double? initialLng;

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
  void initState() {
    super.initState();
    if (widget.initialLat != null) {
      _latController.text = widget.initialLat!.toStringAsFixed(6);
    }
    if (widget.initialLng != null) {
      _lngController.text = widget.initialLng!.toStringAsFixed(6);
    }
  }

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

    final result = await LocationPickerDialog.showResult(
      context,
      initialLocation: initialPos,
      title: 'Pick Facility Location on Map',
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
        if (result.address != null && result.address!.isNotEmpty) {
          if (_descController.text.trim().isEmpty) {
            _descController.text = result.address!;
          }
        }
      });
      if (mounted && result.address != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location updated: ${result.address}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickOperatingHoursClock() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
      helpText: 'Select Opening Time',
    );
    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: 'Select Closing Time',
    );
    if (end == null || !mounted) return;

    final startStr = start.format(context);
    final endStr = end.format(context);

    setState(() {
      _is24Hours = false;
      _hoursController.text = '$startStr – $endStr';
    });
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
      operatingHours: _is24Hours
          ? '24 Hours'
          : (_hoursController.text.trim().isNotEmpty
              ? _hoursController.text.trim()
              : null),
      is24Hours: _is24Hours,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(serviceActionControllerProvider.notifier)
        .saveService(id: widget.serviceId, service: service);

    if (mounted && success) {
      ref.invalidate(serviceListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.serviceId != null
                ? 'Facility updated successfully'
                : 'New facility registered successfully',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
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
      final detailAsync = ref.watch(serviceDetailProvider(widget.serviceId!));
      return detailAsync.when(
        loading: () => const Scaffold(
          body: LoadingWidget(label: 'Loading facility details...'),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Facility')),
          body: ErrorStateWidget(
            message: err.toString(),
            onRetry: () => ref.refresh(serviceDetailProvider(widget.serviceId!)),
          ),
        ),
        data: (service) {
          _populateData(service);
          return _buildScaffold(context, isEditing, actionState);
        },
      );
    }

    return _buildScaffold(context, isEditing, actionState);
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isEditing,
    AsyncValue<void> actionState,
  ) {
    final isSaving = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Facility' : 'Register New Facility'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Card
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
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Service Name
                          AppTextField(
                            controller: _nameController,
                            label: 'Facility Name',
                            hint: 'e.g. Ram Kund First Aid Post #2',
                            prefixIcon: Icons.business_rounded,
                            isRequired: true,
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                    ? 'Facility name is required'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Service Type Dropdown
                          const Text(
                            'Facility Category *',
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
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

                          // Description / Address
                          AppTextField(
                            controller: _descController,
                            label: 'Location Description / Available Amenities',
                            hint: 'e.g. Near Ram Kund Ghat, Panchavati. Has 10 emergency beds...',
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
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (val) =>
                                      double.tryParse(val ?? '') == null
                                          ? 'Required'
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
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (val) =>
                                      double.tryParse(val ?? '') == null
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.map_rounded, size: 18),
                              label: const Text('Pick on Map (Auto-Detect Address)'),
                              onPressed: _handlePickLocation,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

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

                          // Operating Hours & Quick Presets
                          const Text(
                            'Operating Hours',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppTextField(
                            controller: _hoursController,
                            label: '',
                            hint: 'e.g. 06:00 AM – 10:00 PM',
                            prefixIcon: Icons.access_time_rounded,
                            enabled: !_is24Hours,
                          ),
                          const SizedBox(height: 8),

                          // Quick Time Presets
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.all_inclusive_rounded,
                                    size: 16),
                                label: const Text('24x7 Open'),
                                onPressed: () {
                                  setState(() {
                                    _is24Hours = true;
                                    _hoursController.text = '24 Hours';
                                  });
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.wb_sunny_outlined,
                                    size: 16),
                                label: const Text('06:00 AM – 10:00 PM'),
                                onPressed: () {
                                  setState(() {
                                    _is24Hours = false;
                                    _hoursController.text =
                                        '06:00 AM – 10:00 PM';
                                  });
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.access_time, size: 16),
                                label: const Text('Clock Picker 🕒'),
                                onPressed: _pickOperatingHoursClock,
                              ),
                            ],
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
                            onChanged: (val) =>
                                setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  AppButton(
                    text: isEditing ? 'Update Facility' : 'Create Facility',
                    icon: Icons.check_circle_rounded,
                    isLoading: isSaving,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
