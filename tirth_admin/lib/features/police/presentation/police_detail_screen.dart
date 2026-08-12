import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/police_officer_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'police_providers.dart';

class PoliceDetailScreen extends ConsumerStatefulWidget {
  const PoliceDetailScreen({
    super.key,
    required this.policeId,
  });

  final String policeId;

  @override
  ConsumerState<PoliceDetailScreen> createState() => _PoliceDetailScreenState();
}

class _PoliceDetailScreenState extends ConsumerState<PoliceDetailScreen> {
  Future<void> _handleVerify(PoliceOfficerModel officer) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Verify Police Officer?',
      message:
          'Are you sure you want to verify Officer ${officer.officerDisplayName} (Badge: ${officer.badgeNumber})? Once verified, the officer will be authorized to log into the Police App.',
      confirmLabel: 'Verify Officer',
      icon: Icons.verified_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(policeActionControllerProvider.notifier)
          .verifyOfficer(officer.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('${officer.officerDisplayName} verified successfully.'),
          ),
        );
      }
    }
  }

  Future<void> _handleReject(PoliceOfficerModel officer) async {
    final remarksController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text(
              'Reject Verification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provide a reason or remarks for rejecting Officer ${officer.officerDisplayName}:',
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: remarksController,
              label: 'Rejection Remarks',
              hint: 'e.g. ID card photo is blurry, badge number does not match record...',
              maxLines: 3,
              isRequired: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (remarksController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter rejection remarks.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.of(dialogCtx).pop(true);
            },
            child: const Text('Reject Officer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(policeActionControllerProvider.notifier)
          .rejectOfficer(
            policeId: officer.id,
            remarks: remarksController.text.trim(),
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Police officer verification marked as rejected.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final officerAsync = ref.watch(policeDetailProvider(widget.policeId));
    final actionState = ref.watch(policeActionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Police Officer Profile'),
      ),
      body: officerAsync.when(
        loading: () => const LoadingWidget(message: 'Loading officer profile...'),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(policeDetailProvider(widget.policeId)),
        ),
        data: (officer) {
          final isPending =
              officer.verificationStatus == PoliceStatusEnum.pending;
          final isVerified =
              officer.verificationStatus == PoliceStatusEnum.verified;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            officer.officerDisplayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          officer.officerDisplayName,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Badge No: ${officer.badgeNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StatusBadge.police(officer.verificationStatus.dbValue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Official Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Official Deployment Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Police Station',
                          value: officer.policeStation,
                          icon: Icons.local_police_outlined,
                        ),
                        _InfoRow(
                          label: 'District & State',
                          value: '${officer.district}, ${officer.state}',
                          icon: Icons.location_city_rounded,
                        ),
                        if (officer.designation != null)
                          _InfoRow(
                            label: 'Designation',
                            value: officer.designation!,
                            icon: Icons.badge_outlined,
                          ),
                        if (officer.department != null)
                          _InfoRow(
                            label: 'Department',
                            value: officer.department!,
                            icon: Icons.apartment_rounded,
                          ),
                        if (officer.mobile != null)
                          _InfoRow(
                            label: 'Contact Phone',
                            value: officer.mobile!,
                            icon: Icons.phone_outlined,
                          ),
                        if (officer.email != null)
                          _InfoRow(
                            label: 'Email',
                            value: officer.email!,
                            icon: Icons.email_outlined,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ID Card Document Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Police ID Card Document',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (officer.idCardPhoto != null &&
                            officer.idCardPhoto!.trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.document_scanner_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Official ID Document Attached',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onBackground,
                                        ),
                                      ),
                                      Text(
                                        officer.idCardPhoto!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppButton(
                                  text: 'View ID',
                                  variant: AppButtonVariant.primary,
                                  height: 38,
                                  width: 90,
                                  onPressed: () {
                                    context.push(
                                      '/police/${officer.id}/id-card',
                                      extra: {
                                        'storagePath': officer.idCardPhoto!,
                                        'officerName':
                                            officer.officerDisplayName,
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.onSurfaceMuted,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No ID card photo has been uploaded for this officer yet.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Verification Audit Log
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verification Audit Info',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          label: 'Registration Date',
                          value: DateFormatter.formatDateTime(officer.createdAt),
                        ),
                        if (officer.verifiedAt != null)
                          _InfoRow(
                            label: 'Verification Timestamp',
                            value: DateFormatter.formatDateTime(
                                officer.verifiedAt),
                          ),
                        if (officer.remarks != null &&
                            officer.remarks!.isNotEmpty)
                          _InfoRow(
                            label: 'Admin Remarks',
                            value: officer.remarks!,
                            isHighlighted: true,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                if (isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Reject',
                          variant: AppButtonVariant.danger,
                          icon: Icons.cancel_outlined,
                          isLoading: actionState.isLoading,
                          onPressed: () => _handleReject(officer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Verify Officer',
                          variant: AppButtonVariant.primary,
                          icon: Icons.verified_rounded,
                          isLoading: actionState.isLoading,
                          onPressed: () => _handleVerify(officer),
                        ),
                      ),
                    ],
                  ),
                ],

                if (isVerified) ...[
                  AppButton(
                    text: 'Manage Police Login Codes',
                    variant: AppButtonVariant.primary,
                    icon: Icons.vpn_key_rounded,
                    onPressed: () {
                      context.push(
                        '/police/${officer.id}/login-codes',
                        extra: officer,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.onSurfaceMuted),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isHighlighted ? AppColors.error : AppColors.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
