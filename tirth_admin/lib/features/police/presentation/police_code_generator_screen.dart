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

class PoliceCodeGeneratorScreen extends ConsumerStatefulWidget {
  const PoliceCodeGeneratorScreen({super.key});

  @override
  ConsumerState<PoliceCodeGeneratorScreen> createState() =>
      _PoliceCodeGeneratorScreenState();
}

class _PoliceCodeGeneratorScreenState
    extends ConsumerState<PoliceCodeGeneratorScreen> {
  PoliceOfficerModel? _selectedOfficer;
  Duration _selectedDuration = const Duration(hours: 24);
  PoliceLoginCodeModel? _lastGeneratedCode;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateCode() async {
    if (_selectedOfficer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please select a verified police officer first.'),
        ),
      );
      return;
    }

    final code = await ref
        .read(policeActionControllerProvider.notifier)
        .generateLoginCode(
          policeId: _selectedOfficer!.id,
          validityDuration: _selectedDuration,
        );

    if (code != null && mounted) {
      setState(() {
        _lastGeneratedCode = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Generated Code: ${code.loginCode} for ${_selectedOfficer!.officerDisplayName}',
          ),
        ),
      );
    }
  }

  Future<void> _handleRevokeCode(PoliceLoginCodeModel code) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revoke Police Login Code?',
      message:
          'Are you sure you want to invalidate login code "${code.loginCode}"? The officer will no longer be able to use this code to sign in.',
      confirmLabel: 'Revoke Code',
      isDestructive: true,
      icon: Icons.block_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(policeActionControllerProvider.notifier)
          .revokeLoginCode(policeId: code.policeId, codeId: code.id);

      if (success && mounted) {
        if (_lastGeneratedCode?.id == code.id) {
          setState(() {
            _lastGeneratedCode = null;
          });
        }
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
    final verifiedOfficersAsync = ref.watch(verifiedPoliceListProvider);
    final codesAsync = ref.watch(allPoliceLoginCodesProvider);
    final actionState = ref.watch(policeActionControllerProvider);
    final selectedFilter = ref.watch(loginCodeStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(verifiedPoliceListProvider);
          return ref.refresh(allPoliceLoginCodesProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            // Top Section: Code Generator Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.vpn_key_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Generate Police Login Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  Text(
                                    'Create a temporary 6-digit access code for police officers',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Officer Selector
                        const Text(
                          'Select Police Officer *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        verifiedOfficersAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text(
                            'Failed to load officers: $e',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                          data: (officers) {
                            if (officers.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'No verified police officers found. Please verify officers in Police section first.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                ),
                              );
                            }

                            return DropdownButtonFormField<PoliceOfficerModel>(
                              initialValue: _selectedOfficer,
                              hint: const Text('Choose a verified officer...'),
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                prefixIcon: const Icon(
                                  Icons.badge_rounded,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: officers.map((officer) {
                                return DropdownMenuItem(
                                  value: officer,
                                  child: Text(
                                    '${officer.officerDisplayName} • Badge ${officer.badgeNumber} (${officer.policeStation})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedOfficer = val);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Duration Selector
                        const Text(
                          'Code Validity Duration',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Duration>(
                          initialValue: _selectedDuration,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.timer_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: Duration(hours: 1),
                              child: Text('1 Hour (Temporary Access)'),
                            ),
                            DropdownMenuItem(
                              value: Duration(hours: 24),
                              child: Text('24 Hours (Standard Shift - 1 Day)'),
                            ),
                            DropdownMenuItem(
                              value: Duration(days: 7),
                              child: Text('7 Days (Weekly Deployment)'),
                            ),
                            DropdownMenuItem(
                              value: Duration(days: 30),
                              child: Text('30 Days (Full Mela Duration)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDuration = val);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Generate Button
                        AppButton(
                          text: 'Generate 6-Digit Code',
                          icon: Icons.key_rounded,
                          isLoading: actionState.isLoading,
                          onPressed: _selectedOfficer != null
                              ? _handleGenerateCode
                              : null,
                        ),

                        // Display Last Generated Code Box
                        if (_lastGeneratedCode != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ACTIVE LOGIN CODE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'READY FOR USE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        _lastGeneratedCode!.loginCode,
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 6,
                                          color: AppColors.primary,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      icon: const Icon(Icons.copy_rounded),
                                      tooltip: 'Copy Code',
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: _lastGeneratedCode!.loginCode,
                                          ),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            backgroundColor:
                                                AppColors.onBackground,
                                            content: Text(
                                              'Login code copied to clipboard.',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Officer: ${_selectedOfficer?.officerDisplayName ?? "Police Officer"} • Badge: ${_selectedOfficer?.badgeNumber ?? ""}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                Text(
                                  'Expires: ${DateFormatter.formatDateTime(_lastGeneratedCode!.expiresAt)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceMuted,
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
              ),
            ),

            // Header for Recent Login Codes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Generated Login Codes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All Codes',
                            isSelected: selectedFilter == null,
                            onTap: () {
                              ref
                                  .read(
                                      loginCodeStatusFilterProvider.notifier)
                                  .state = null;
                            },
                          ),
                          ...LoginCodeStatusEnum.values.map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: _FilterChip(
                                label: s.displayLabel,
                                isSelected: selectedFilter == s,
                                onTap: () {
                                  ref
                                      .read(
                                          loginCodeStatusFilterProvider
                                              .notifier)
                                      .state = selectedFilter == s ? null : s;
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Code List
            codesAsync.when(
              loading: () => const SliverFillRemaining(
                child: LoadingWidget(message: 'Loading police login codes...'),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref.refresh(allPoliceLoginCodesProvider),
                ),
              ),
              data: (codes) {
                if (codes.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.key_off_rounded,
                      title: 'No Login Codes',
                      subtitle:
                          'No police login codes match the selected filter. Generate a code above.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final code = codes[index];
                        final isEffectiveActive = code.isEffectiveActive;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEffectiveActive
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : AppColors.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isEffectiveActive
                                        ? AppColors.primaryContainer
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isEffectiveActive
                                        ? Icons.vpn_key_rounded
                                        : Icons.key_off_rounded,
                                    color: isEffectiveActive
                                        ? AppColors.primary
                                        : AppColors.onSurfaceMuted,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            code.loginCode,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                              fontFamily: 'monospace',
                                              color: AppColors.onBackground,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge.loginCode(
                                            code.effectiveStatus.dbValue,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        code.officerName != null
                                            ? '${code.officerName} • Badge ${code.badgeNumber ?? ""}'
                                            : 'Officer ID: ${code.policeId}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onBackground,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Created: ${DateFormatter.formatDateTime(code.createdAt)} • Exp: ${DateFormatter.formatDateTime(code.expiresAt)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isEffectiveActive) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'Copy Code',
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: code.loginCode),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          backgroundColor:
                                              AppColors.onBackground,
                                          content: Text('Code copied.'),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.block_rounded,
                                      size: 20,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Revoke Code',
                                    onPressed: () => _handleRevokeCode(code),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: codes.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}
