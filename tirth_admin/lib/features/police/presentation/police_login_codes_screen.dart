import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/police_login_code_model.dart';
import '../../../models/police_officer_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'police_providers.dart';

class PoliceLoginCodesScreen extends ConsumerStatefulWidget {
  const PoliceLoginCodesScreen({
    super.key,
    required this.officer,
  });

  final PoliceOfficerModel officer;

  @override
  ConsumerState<PoliceLoginCodesScreen> createState() =>
      _PoliceLoginCodesScreenState();
}

class _PoliceLoginCodesScreenState extends ConsumerState<PoliceLoginCodesScreen> {
  Future<void> _showGenerateCodeDialog() async {
    Duration selectedDuration = const Duration(days: 7);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text(
                'Generate Login Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate a secure 6-digit numeric login code for Officer ${widget.officer.officerDisplayName} (Badge: ${widget.officer.badgeNumber}).',
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 18),
              const Text(
                'Code Validity Duration',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Duration>(
                initialValue: selectedDuration,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                    value: Duration(hours: 24),
                    child: Text('24 Hours (1 Day)'),
                  ),
                  DropdownMenuItem(
                    value: Duration(days: 7),
                    child: Text('7 Days (Recommended)'),
                  ),
                  DropdownMenuItem(
                    value: Duration(days: 30),
                    child: Text('30 Days (Full Mela Duration)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedDuration = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Generate Code'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final code = await ref
          .read(policeActionControllerProvider.notifier)
          .generateLoginCode(
            policeId: widget.officer.id,
            validityDuration: selectedDuration,
          );

      if (code != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Generated Login Code: ${code.loginCode}'),
          ),
        );
      }
    }
  }

  Future<void> _handleRevokeCode(String codeId, String loginCode) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revoke Login Code?',
      message:
          'Are you sure you want to invalidate login code $loginCode? The police officer will no longer be able to use this code to sign into the Police App.',
      confirmLabel: 'Revoke Code',
      isDestructive: true,
      icon: Icons.block_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(policeActionControllerProvider.notifier)
          .revokeLoginCode(policeId: widget.officer.id, codeId: codeId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Login code has been revoked.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final codesAsync = ref.watch(policeLoginCodesProvider(widget.officer.id));
    final actionState = ref.watch(policeActionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Login Codes • ${widget.officer.officerDisplayName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async =>
            ref.refresh(policeLoginCodesProvider(widget.officer.id).future),
        child: Column(
          children: [
            // Officer Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      widget.officer.officerDisplayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.officer.officerDisplayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Text(
                          'Badge: ${widget.officer.badgeNumber} • ${widget.officer.policeStation}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    text: 'New Code',
                    icon: Icons.add_rounded,
                    height: 40,
                    width: 120,
                    isLoading: actionState.isLoading,
                    onPressed: _showGenerateCodeDialog,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Codes List
            Expanded(
              child: codesAsync.when(
                loading: () => const LoadingWidget(message: 'Loading login codes...'),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref
                      .refresh(policeLoginCodesProvider(widget.officer.id)),
                ),
                data: (codes) {
                  if (codes.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.vpn_key_off_outlined,
                      title: 'No Login Codes Generated',
                      message:
                          'Generate a code so the verified officer can log into the TirthTrack Police Application.',
                      actionLabel: 'Generate First Code',
                      onAction: _showGenerateCodeDialog,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: codes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final code = codes[index];
                      final effectiveStatus = code.effectiveStatus;
                      final isActive =
                          effectiveStatus == LoginCodeStatusEnum.active;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: AppColors.border),
                                        ),
                                        child: Text(
                                          code.loginCode,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 3,
                                            fontFamily: 'monospace',
                                            color: AppColors.onBackground,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy_rounded,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: 'Copy Code',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: code.loginCode));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Login code copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  StatusBadge.loginCode(effectiveStatus.name),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CodeInfoColumn(
                                      label: 'Expires At',
                                      value: DateFormatter.formatDateTime(
                                          code.expiresAt),
                                      isUrgent: isActive &&
                                          code.expiresAt.difference(DateTime.now()).inHours < 24,
                                    ),
                                  ),
                                  Expanded(
                                    child: _CodeInfoColumn(
                                      label: 'Created At',
                                      value: DateFormatter.formatDateTime(
                                          code.createdAt),
                                    ),
                                  ),
                                ],
                              ),
                              if (code.usedAt != null) ...[
                                const SizedBox(height: 8),
                                _CodeInfoColumn(
                                  label: 'Used At',
                                  value: DateFormatter.formatDateTime(code.usedAt),
                                ),
                              ],
                              if (isActive) ...[
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.block_rounded,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      label: const Text(
                                        'Revoke Code',
                                        style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(120, 36),
                                        side: const BorderSide(
                                            color: AppColors.error),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => _handleRevokeCode(
                                        code.id,
                                        code.loginCode,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeInfoColumn extends StatelessWidget {
  const _CodeInfoColumn({
    required this.label,
    required this.value,
    this.isUrgent = false,
  });

  final String label;
  final String value;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isUrgent ? AppColors.error : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
