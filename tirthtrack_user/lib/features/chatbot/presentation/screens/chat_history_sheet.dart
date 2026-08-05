// ============================================================
// features/chatbot/presentation/screens/chat_history_sheet.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';

/// Bottom sheet showing the user's chat history.
/// Accessible via the history icon in the ChatbotScreen AppBar.
class ChatHistorySheet extends ConsumerWidget {
  const ChatHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChatHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(chatSessionsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ──────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text('Chat History', style: AppTextStyles.labelLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          ref.read(chatSessionsProvider.notifier).refresh(),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Sessions list ────────────────────────────────
              Expanded(
                child: sessionsState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load history',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              ref.read(chatSessionsProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 48, color: AppColors.onSurfaceMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No past conversations',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.onSurfaceMuted),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sessions.length,
                      itemBuilder: (_, i) =>
                          _HistoryTile(session: sessions[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Session tile ──────────────────────────────────────────────
class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.session});

  final ChatSessionModel session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = session.status == ChatSessionStatus.active;

    return Dismissible(
      key: Key('history_${session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorContainer,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete conversation?'),
            content: const Text(
                'This conversation will be removed from history.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(chatSessionsProvider.notifier).archiveSession(session.id),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary])
                : null,
            color: isActive ? null : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isActive
                ? Icons.smart_toy_rounded
                : Icons.chat_bubble_outline_rounded,
            color: isActive ? Colors.white : AppColors.onSurfaceMuted,
            size: 22,
          ),
        ),
        title: Text(
          session.displayTitle,
          style: AppTextStyles.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (isActive)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Current',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary, fontSize: 10),
                ),
              ),
            Text(
              DateFormat('dd MMM • hh:mm a').format(session.updatedAt),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.onSurfaceMuted, size: 20),
        onTap: () {
          Navigator.pop(context); // close sheet
          context.push(
            '${AppRoutes.chatbot}/session/${session.id}',
            extra: session.sessionTitle,
          );
        },
      ),
    );
  }
}
