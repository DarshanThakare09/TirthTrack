import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/route_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'route_providers.dart';

class RouteFormScreen extends ConsumerStatefulWidget {
  const RouteFormScreen({
    super.key,
    this.routeId,
  });

  final String? routeId;

  @override
  ConsumerState<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends ConsumerState<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  final _distanceController = TextEditingController();
  final _timeController = TextEditingController();
  bool _isActive = true;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _distanceController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _populateData(RouteModel route) {
    if (_isInitialized) return;
    _nameController.text = route.routeName;
    _codeController.text = route.routeCode ?? '';
    _descController.text = route.description ?? '';
    _distanceController.text = route.totalDistanceKm?.toString() ?? '';
    _timeController.text = route.estimatedTimeMinutes?.toString() ?? '';
    _isActive = route.isActive;
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final distance = double.tryParse(_distanceController.text.trim());
    final timeMinutes = int.tryParse(_timeController.text.trim());

    final route = RouteModel(
      id: widget.routeId ?? '',
      routeName: _nameController.text.trim(),
      routeCode: _codeController.text.trim().isNotEmpty
          ? _codeController.text.trim()
          : null,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      totalDistanceKm: distance,
      estimatedTimeMinutes: timeMinutes,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(routeActionControllerProvider.notifier)
        .saveRoute(id: widget.routeId, route: route);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            widget.routeId == null
                ? 'Route created successfully.'
                : 'Route updated successfully.',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.routeId != null;
    final actionState = ref.watch(routeActionControllerProvider);

    if (isEditing) {
      final routeAsync = ref.watch(routeDetailProvider(widget.routeId!));
      return routeAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Route')),
          body: const LoadingWidget(message: 'Loading route details...'),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Route')),
          body: ErrorStateWidget(message: err.toString()),
        ),
        data: (route) {
          _populateData(route);
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
        title: Text(isEditing ? 'Edit Route' : 'Create New Route'),
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
                        'Route Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Route Name
                      AppTextField(
                        controller: _nameController,
                        label: 'Route Name',
                        hint: 'e.g. Ramkund Parikrama Marg',
                        prefixIcon: Icons.alt_route_rounded,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Route name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Route Code
                      AppTextField(
                        controller: _codeController,
                        label: 'Route Code (Unique Identifier)',
                        hint: 'e.g. RT-RAMKUND-01',
                        prefixIcon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      AppTextField(
                        controller: _descController,
                        label: 'Route Description',
                        hint: 'Provide landmarks, walking surface notes, or access restrictions...',
                        maxLines: 3,
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Distance & Time
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _distanceController,
                              label: 'Total Distance (km)',
                              hint: 'e.g. 4.5',
                              prefixIcon: Icons.straighten_rounded,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AppTextField(
                              controller: _timeController,
                              label: 'Estimated Time (Mins)',
                              hint: 'e.g. 60',
                              prefixIcon: Icons.timer_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Active Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Route Active Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Active routes are publicly visible to pilgrims for navigation.',
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

              // Submit Button
              AppButton(
                text: isEditing ? 'Update Route' : 'Save Route',
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
