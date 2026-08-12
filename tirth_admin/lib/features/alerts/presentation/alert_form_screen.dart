import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/alert_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'alert_providers.dart';

class AlertFormScreen extends ConsumerStatefulWidget {
  const AlertFormScreen({
    super.key,
    this.alertId,
  });

  final String? alertId;

  @override
  ConsumerState<AlertFormScreen> createState() => _AlertFormScreenState();
}

class _AlertFormScreenState extends ConsumerState<AlertFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  AlertTypeEnum _selectedType = AlertTypeEnum.general;
  AlertPriorityEnum _selectedPriority = AlertPriorityEnum.medium;
  DateTime? _expiresAt;
  bool _isActive = true;
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _populateData(AlertModel alert) {
    if (_isInitialized) return;
    _titleController.text = alert.title;
    _messageController.text = alert.message;
    _selectedType = alert.alertType;
    _selectedPriority = alert.priority;
    _expiresAt = alert.expiresAt;
    _isActive = alert.isActive;
    _isInitialized = true;
  }

  Future<void> _pickExpiryDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _expiresAt ?? now.add(const Duration(hours: 4))),
      );

      if (pickedTime != null) {
        setState(() {
          _expiresAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final alert = AlertModel(
      id: widget.alertId ?? '',
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      alertType: _selectedType,
      priority: _selectedPriority,
      expiresAt: _expiresAt,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(alertActionControllerProvider.notifier)
        .saveAlert(id: widget.alertId, alert: alert);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            widget.alertId == null
                ? 'Alert broadcast published successfully.'
                : 'Alert broadcast updated.',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.alertId != null;
    final actionState = ref.watch(alertActionControllerProvider);

    if (isEditing) {
      final alertAsync = ref.watch(alertDetailProvider(widget.alertId!));
      return alertAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Alert')),
          body: const LoadingWidget(message: 'Loading alert data...'),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Alert')),
          body: ErrorStateWidget(message: err.toString()),
        ),
        data: (alert) {
          _populateData(alert);
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
        title: Text(isEditing ? 'Edit Alert Broadcast' : 'Publish Alert Broadcast'),
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
                        'Broadcast Parameters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      AppTextField(
                        controller: _titleController,
                        label: 'Broadcast Title',
                        hint: 'e.g. Heavy Crowd Surge at Ramkund Ghat No. 2',
                        prefixIcon: Icons.campaign_rounded,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Alert title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Alert Type & Priority Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<AlertTypeEnum>(
                                  initialValue: _selectedType,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                  items: AlertTypeEnum.values.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Row(
                                        children: [
                                          Icon(t.icon, size: 16),
                                          const SizedBox(width: 8),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Priority
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Priority Level *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<AlertPriorityEnum>(
                                  initialValue: _selectedPriority,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                  items: AlertPriorityEnum.values.map((p) {
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        p.displayLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: p.color,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedPriority = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Message Body
                      AppTextField(
                        controller: _messageController,
                        label: 'Broadcast Message Body',
                        hint: 'Provide clear actionable instructions, alternate route recommendations, or advisory information for pilgrims...',
                        maxLines: 4,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Message body is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Expiry Date/Time
                      const Text(
                        'Broadcast Expiration (Optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickExpiryDateTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _expiresAt != null
                                      ? DateFormatter.formatDateTime(_expiresAt)
                                      : 'No expiration set (Active until manual removal)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _expiresAt != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _expiresAt != null
                                        ? AppColors.onBackground
                                        : AppColors.onSurfaceMuted,
                                  ),
                                ),
                              ),
                              if (_expiresAt != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () =>
                                      setState(() => _expiresAt = null),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Active Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active Broadcast Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Active alerts immediately display on the pilgrim app banner and emergency feed.',
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
                text: isEditing ? 'Update Broadcast' : 'Publish Alert Broadcast',
                icon: isEditing ? Icons.save_rounded : Icons.send_rounded,
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
