// ============================================================
// features/chatbot/presentation/screens/chatbot_screen.dart
// ============================================================
//
// Single unified chat interface.
// Session is auto-created/resumed — user never sees a session list.
// History is accessible via the History icon in the AppBar.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';
import 'chat_history_sheet.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  late ChatLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = ChatLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String sessionId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await ref
          .read(chatMessagesProvider(sessionId).notifier)
          .sendMessage(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(chatActiveSessionProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Chat History',
            onPressed: () => ChatHistorySheet.show(context),
          ),
        ],
      ),
      body: sessionState.when(
        loading: () => const LoadingWidget(label: 'Preparing assistant…'),
        error: (e, _) => AppErrorWidget(
          message: 'Could not start assistant.\n${e.toString()}',
          onRetry: () => ref.invalidate(chatActiveSessionProvider),
        ),
        data: (session) {
          if (session == null) {
            // Not authenticated — shouldn't normally be visible
            return const Center(
              child: Text('Please log in to use the assistant.'),
            );
          }
          return _ChatInterface(
            sessionId: session.id,
            isSending: _isSending,
            controller: _messageController,
            scrollController: _scrollController,
            onSend: () => _send(session.id),
            onScrollToBottom: _scrollToBottom,
          );
        },
      ),
    );
  }
}

// ── Chat Interface ─────────────────────────────────────────────
class _ChatInterface extends ConsumerWidget {
  const _ChatInterface({
    required this.sessionId,
    required this.isSending,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onScrollToBottom,
  });

  final String sessionId;
  final bool isSending;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final VoidCallback onScrollToBottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesState = ref.watch(chatMessagesProvider(sessionId));

    ref.listen(chatMessagesProvider(sessionId), (_, __) {
      onScrollToBottom();
    });

    return Column(
      children: [
        // ── Messages ───────────────────────────────────────────
        Expanded(
          child: messagesState.when(
            loading: () => const LoadingWidget(label: 'Loading messages…'),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () =>
                  ref.read(chatMessagesProvider(sessionId).notifier).refresh(),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return _WelcomeState(
                  controller: controller,
                  onSend: onSend,
                );
              }
              final reversedMessages = messages.reversed.toList();
              return ListView.builder(
                controller: scrollController,
                reverse: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: reversedMessages.length,
                itemBuilder: (_, i) => _ChatBubble(
                  message: reversedMessages[i],
                  showTime: true,
                ),
              );
            },
          ),
        ),

        // ── Input bar ──────────────────────────────────────────
        _InputBar(
          controller: controller,
          isSending: isSending,
          onSend: onSend,
        ),
      ],
    );
  }
}

// ── Welcome empty state ────────────────────────────────────────
class _WelcomeState extends StatelessWidget {
  const _WelcomeState({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'What are the pilgrimage routes?',
      'Where is the nearest hospital?',
      'Find food and water points',
      'How to reach the main ghat?',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/app_logo.png',
            height: 64,
            color: AppColors.primary,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text('Tirth Assistant', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about the\nNashik Kumbh Mela pilgrimage.',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Try asking',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (s) => _SuggestionChip(
              label: s,
              onTap: () {
                controller.text = s;
                onSend();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.onSurface)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

// ── Chat bubble ────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.showTime});

  final ChatMessageModel message;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final meta = message.metadata;
    final isErrorBubble = meta?['error'] == true;
    final needsHumanSupport = meta?['needs_human_support'] == true;
    final confidence = meta?['confidence'] as String?;
    final rawSources = meta?['sources'] as List?;
    final sources = rawSources != null && rawSources.isNotEmpty
        ? rawSources.whereType<Map>().toList()
        : const [];

    if (message.isStreaming) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            _AssistantAvatar(),
            SizedBox(width: 8),
            _TypingIndicator(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const _AssistantAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : isErrorBubble
                            ? Colors.orange.shade50
                            : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isErrorBubble
                        ? Border.all(color: Colors.orange.shade200)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Error icon for error bubbles
                      if (!isUser && isErrorBubble) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Connection error',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        message.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isUser
                              ? Colors.white
                              : isErrorBubble
                                  ? Colors.orange.shade900
                                  : AppColors.onSurface,
                        ),
                      ),
                      // Sources
                      if (!isUser && sources.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: sources.map((s) {
                            final doc =
                                s['document']?.toString() ?? '';
                            final page = s['page']?.toString() ?? '';
                            final label = doc.isNotEmpty
                                ? (page.isNotEmpty
                                    ? '$doc (p. $page)'
                                    : doc)
                                : 'Source ${s['chunk_id'] ?? ''}';
                            if (label.trim().isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                      Icons.description_outlined,
                                      size: 12,
                                      color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      // Human support banner
                      if (!isUser && needsHumanSupport) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.support_agent_rounded,
                                  size: 16, color: Colors.amber.shade800),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Support available: Tap for pilgrim helpdesk',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Confidence
                      if (!isUser &&
                          confidence != null &&
                          confidence.isNotEmpty &&
                          !isErrorBubble) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Confidence: $confidence',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          if (showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isUser ? 0 : 44,
                right: isUser ? 8 : 0,
              ),
              child: Text(
                DateFormat('hh:mm a').format(message.createdAt.toLocal()),
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Assistant Avatar ───────────────────────────────────────────
class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/app_logo.png',
      height: 28,
      color: AppColors.primary,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.smart_toy_rounded,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }
}

// ── Typing Indicator ───────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true),
    );
    _animations = _controllers.asMap().entries.map((e) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: e.value, curve: Curves.easeInOut),
      );
    }).toList();
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.onSurfaceMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Ask about Nashik Kumbh Mela…',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: isSending
                    ? Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        child: InkWell(
                          onTap: onSend,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.arrow_upward_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
