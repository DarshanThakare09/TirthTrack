import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sector_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../police_bases/presentation/police_base_providers.dart';
import 'sector_providers.dart';

class SectorFormScreen extends ConsumerStatefulWidget {
  const SectorFormScreen({
    super.key,
    this.sectorId,
  });

  final String? sectorId;

  @override
  ConsumerState<SectorFormScreen> createState() => _SectorFormScreenState();
}

class _SectorFormScreenState extends ConsumerState<SectorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedPoliceBaseId;
  String _selectedColorHex = '#FF7722';
  bool _isInitialized = false;

  final List<String> _presetColors = [
    '#FF7722', // Brand Saffron
    '#3B82F6', // Blue
    '#10B981', // Emerald Green
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#06B6D4', // Cyan
    '#EF4444', // Red
    '#64748B', // Slate
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _populateData(SectorModel sector) {
    if (_isInitialized) return;
    _nameController.text = sector.sectorName;
    _codeController.text = sector.sectorCode ?? '';
    _descController.text = sector.description ?? '';
    _selectedPoliceBaseId = sector.policeBaseId;
    _selectedColorHex = sector.colorHex ?? '#FF7722';
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final sector = SectorModel(
      id: widget.sectorId ?? '',
      sectorName: _nameController.text.trim(),
      sectorCode: _codeController.text.trim().isNotEmpty
          ? _codeController.text.trim()
          : null,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      policeBaseId: _selectedPoliceBaseId,
      colorHex: _selectedColorHex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(sectorActionControllerProvider.notifier)
        .saveSector(id: widget.sectorId, sector: sector);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            widget.sectorId == null
                ? 'Sector created successfully.'
                : 'Sector updated successfully.',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sectorId != null;
    final actionState = ref.watch(sectorActionControllerProvider);
    final basesAsync = ref.watch(policeBaseListProvider);

    if (isEditing) {
      final sectorAsync = ref.watch(sectorDetailProvider(widget.sectorId!));
      return sectorAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Sector')),
          body: const LoadingWidget(message: 'Loading sector details...'),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Sector')),
          body: ErrorStateWidget(message: err.toString()),
        ),
        data: (sector) {
          _populateData(sector);
          return _buildForm(
            isEditing: true,
            isLoading: actionState.isLoading,
            bases: basesAsync.valueOrNull ?? [],
          );
        },
      );
    }

    return _buildForm(
      isEditing: false,
      isLoading: actionState.isLoading,
      bases: basesAsync.valueOrNull ?? [],
    );
  }

  Widget _buildForm({
    required bool isEditing,
    required bool isLoading,
    required List bases,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Sector' : 'Add Zonal Sector'),
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
                        'Sector Definition',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Sector Name
                      AppTextField(
                        controller: _nameController,
                        label: 'Sector Name',
                        hint: 'e.g. Sector 1 (Ramkund Central Ghats)',
                        prefixIcon: Icons.map_rounded,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Sector name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sector Code
                      AppTextField(
                        controller: _codeController,
                        label: 'Sector Code (Unique)',
                        hint: 'e.g. SEC-01-RAMKUND',
                        prefixIcon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      AppTextField(
                        controller: _descController,
                        label: 'Description / Geographic Scope',
                        hint: 'e.g. Covers the sacred bathing ghats from Gandhi Smarak to Talkuteshwar Temple...',
                        maxLines: 3,
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Police Base Assignment Dropdown
                      const Text(
                        'Assigned Police Base / Station',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedPoliceBaseId,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        hint: const Text('None (Optional)'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None (Unassigned)'),
                          ),
                          ...bases.map((b) {
                            return DropdownMenuItem<String?>(
                              value: b.id,
                              child: Text(b.baseName),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedPoliceBaseId = val);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Color Identifier
                      const Text(
                        'Sector Visual Color Theme',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _presetColors.map((hex) {
                          final color = Color(int.parse('0xFF${hex.substring(1)}'));
                          final isSelected = _selectedColorHex == hex;

                          return InkWell(
                            onTap: () => setState(() => _selectedColorHex = hex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: isSelected ? 3 : 0,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              AppButton(
                text: isEditing ? 'Update Sector' : 'Save Sector',
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
