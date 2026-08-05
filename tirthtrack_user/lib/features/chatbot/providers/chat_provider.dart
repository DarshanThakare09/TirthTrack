// ============================================================
// features/chatbot/providers/chat_provider.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

// ── Repository ────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(supabaseClientProvider)),
);

// ── Active Session (auto-managed) ────────────────────────────
//
// Finds or creates an active session for the current user.
// Sessions are created automatically — the user never touches this.
final chatActiveSessionProvider =
    AsyncNotifierProvider<ChatActiveSessionNotifier, ChatSessionModel?>(
        ChatActiveSessionNotifier.new);

class ChatActiveSessionNotifier
    extends AsyncNotifier<ChatSessionModel?> {
  @override
  Future<ChatSessionModel?> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) {
      debugPrint('[CHATBOT] ChatActiveSessionNotifier: no user — skip');
      return null;
    }
    return _ensureActiveSession(uid);
  }

  /// Find an existing active session or create a new one.
  Future<ChatSessionModel> _ensureActiveSession(String uid) async {
    debugPrint('[CHATBOT] _ensureActiveSession: uid=$uid');
    final repo = ref.read(chatRepositoryProvider);
    final existing = await repo.findActiveSession(uid);
    if (existing != null) {
      debugPrint('[CHATBOT] _ensureActiveSession: resuming sessionId=${existing.id}');
      return existing;
    }
    debugPrint('[CHATBOT] _ensureActiveSession: no active session, creating new');
    final created = await repo.createSession(uid);
    // Refresh history list
    ref.invalidate(chatSessionsProvider);
    return created;
  }

  /// Called when the app goes to background — close current session.
  Future<void> closeCurrentSession() async {
    final session = state.valueOrNull;
    if (session == null) return;
    debugPrint('[CHATBOT] closeCurrentSession: closing sessionId=${session.id}');
    try {
      await ref.read(chatRepositoryProvider).closeSession(session.id);
      state = const AsyncData(null);
      ref.invalidate(chatSessionsProvider);
    } catch (e) {
      debugPrint('[CHATBOT] closeCurrentSession error: $e');
    }
  }

  /// Called when the app resumes — ensure an active session.
  Future<void> resumeSession() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    debugPrint('[CHATBOT] resumeSession: uid=$uid');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _ensureActiveSession(uid));
  }
}

// ── Session history list ──────────────────────────────────────
final chatSessionsProvider =
    AsyncNotifierProvider<ChatSessionsNotifier, List<ChatSessionModel>>(
        ChatSessionsNotifier.new);

class ChatSessionsNotifier
    extends AsyncNotifier<List<ChatSessionModel>> {
  @override
  Future<List<ChatSessionModel>> build() {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return Future.value([]);
    return ref.read(chatRepositoryProvider).fetchSessions(uid);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> archiveSession(String sessionId) async {
    await ref.read(chatRepositoryProvider).deleteSession(sessionId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != sessionId).toList());
  }
}

// ── Messages for a session ────────────────────────────────────
final chatMessagesProvider = StateNotifierProvider.family<
    ChatMessagesNotifier,
    AsyncValue<List<ChatMessageModel>>,
    String>((ref, sessionId) {
  return ChatMessagesNotifier(ref, sessionId);
});

class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  ChatMessagesNotifier(this._ref, this._sessionId)
      : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;
  final String _sessionId;

  Future<void> _load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _ref.read(chatRepositoryProvider).fetchMessages(_sessionId),
    );
  }

  Future<void> refresh() => _load();

  /// Send a user message, call the AI backend, and persist both to Supabase.
  /// On backend failure: persists an error-indicator assistant message to DB.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final repo = _ref.read(chatRepositoryProvider);

    // 1. Optimistic: add user message locally while DB write is in flight
    final tempId = 'temp_user_${DateTime.now().millisecondsSinceEpoch}';
    final tempUserMsg = ChatMessageModel(
      id: tempId,
      sessionId: _sessionId,
      sender: ChatMessageRole.user,
      message: trimmed,
      createdAt: DateTime.now(),
    );
    final current = state.valueOrNull ?? <ChatMessageModel>[];
    state = AsyncData([...current, tempUserMsg]);

    // 2. Persist user message to Supabase
    ChatMessageModel savedUser;
    try {
      savedUser = await repo.insertMessage(
        sessionId: _sessionId,
        sender: ChatMessageRole.user,
        message: trimmed,
      );
      // Replace temp with real DB record
      final updated = <ChatMessageModel>[...(state.valueOrNull ?? [])];
      final idx = updated.indexWhere((m) => m.id == tempId);
      if (idx != -1) updated[idx] = savedUser;
      state = AsyncData(updated);
    } catch (e) {
      // Remove temp message and re-throw so the UI shows a snack bar
      state = AsyncData(
          (state.valueOrNull ?? <ChatMessageModel>[])
              .where((m) => m.id != tempId)
              .toList());
      rethrow;
    }

    // 3. Show typing indicator
    const typingId = 'temp_typing';
    final typingMsg = ChatMessageModel(
      id: typingId,
      sessionId: _sessionId,
      sender: ChatMessageRole.assistant,
      message: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );
    state = AsyncData([...(state.valueOrNull ?? <ChatMessageModel>[]), typingMsg]);

    // 4. Call AI backend — NO local fallback
    String assistantText;
    Map<String, dynamic> assistantMetadata;
    bool isError = false;

    try {
      debugPrint('[CHATBOT] sendMessage: calling AI backend for "$trimmed"');
      final responseModel = await repo.queryChatbot(query: trimmed);
      assistantText = responseModel.answer.trim().isNotEmpty
          ? responseModel.answer
          : 'I received your question but the assistant returned an empty response. Please try again.';
      assistantMetadata = responseModel.toJson();
    } catch (e) {
      debugPrint('[CHATBOT] sendMessage: AI backend failed → $e');
      assistantText =
          'Sorry, I couldn\'t reach the assistant right now. Please check your connection and try again.';
      assistantMetadata = {'error': true, 'errorDetail': e.toString()};
      isError = true;
    }

    // 5. Remove typing indicator
    final withoutTyping = (state.valueOrNull ?? <ChatMessageModel>[])
        .where((m) => m.id != typingId)
        .toList();
    state = AsyncData(withoutTyping);

    // 6. Persist assistant response (or error message) to Supabase
    try {
      final savedAssistant = await repo.insertMessage(
        sessionId: _sessionId,
        sender: ChatMessageRole.assistant,
        message: assistantText,
        metadata: assistantMetadata,
      );
      state =
          AsyncData([...(state.valueOrNull ?? <ChatMessageModel>[]), savedAssistant]);
    } catch (e) {
      // Can't persist — still show in UI as a local-only message
      debugPrint('[CHATBOT] sendMessage: failed to persist assistant message → $e');
      final localMsg = ChatMessageModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId,
        sender: ChatMessageRole.assistant,
        message: assistantText,
        metadata: assistantMetadata,
        createdAt: DateTime.now(),
      );
      state = AsyncData(
          [...(state.valueOrNull ?? <ChatMessageModel>[]), localMsg]);
    }

    // 7. Auto-title the session from the first user message
    if (!isError) {
      final allMessages = state.valueOrNull ?? <ChatMessageModel>[];
      if (allMessages.where((m) => m.isUser).length == 1) {
        final title =
            trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed;
        try {
          await repo.updateSessionTitle(_sessionId, title);
          _ref.invalidate(chatSessionsProvider);
        } catch (_) {}
      }
    }
  }
}

// ── App Lifecycle Observer ─────────────────────────────────────
// Attach to the widget tree to auto-close/reopen sessions.
class ChatLifecycleObserver extends WidgetsBindingObserver {
  ChatLifecycleObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        debugPrint('[CHATBOT] App backgrounded — closing active session');
        _ref.read(chatActiveSessionProvider.notifier).closeCurrentSession();
        break;
      case AppLifecycleState.resumed:
        debugPrint('[CHATBOT] App resumed — ensuring active session');
        _ref.read(chatActiveSessionProvider.notifier).resumeSession();
        break;
      default:
        break;
    }
  }
}
