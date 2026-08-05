// ============================================================
// features/chatbot/repositories/chat_repository.dart
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../models/chat_models.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  // ── AI Backend Query ──────────────────────────────────────────
  Future<ChatbotResponseModel> queryChatbot({
    required String query,
    bool stream = false,
  }) async {
    final urlsToTry = {
      AppConfig.chatbotApiUrl,
      'https://tirthchat.vercel.app/api/v1/chat',
    }.toList();

    Object? lastError;

    for (final urlStr in urlsToTry) {
      try {
        final url = Uri.parse(urlStr);
        debugPrint('[CHATBOT] queryChatbot: trying POST → $url');
        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'query': query,
                'stream': stream,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint(
              '[CHATBOT] queryChatbot: response from $url (status: ${decoded['status']}, confidence: ${decoded['confidence']})');
          return ChatbotResponseModel.fromJson(decoded);
        } else {
          appLogger.w(
              '[CHATBOT] $url returned status ${response.statusCode}');
        }
      } catch (e) {
        lastError = e;
        appLogger.w('[CHATBOT] network/CORS error for $urlStr: $e');
      }
    }

    throw ServerException(
      lastError?.toString() ?? 'Unable to connect to the AI chatbot server.',
    );
  }

  // ── Sessions ──────────────────────────────────────────────────

  /// Find the most-recent active session for [profileId], or null if none.
  Future<ChatSessionModel?> findActiveSession(String profileId) async {
    try {
      debugPrint('[CHATBOT] findActiveSession: querying for profileId=$profileId');
      final data = await _client
          .from(SupabaseTable.chatbotSessions)
          .select()
          .eq('profile_id', profileId)
          .eq('status', ChatSessionStatus.active.dbValue)
          .order('updated_at', ascending: false)
          .limit(1);

      if ((data as List).isEmpty) {
        debugPrint('[CHATBOT] findActiveSession: no active session found');
        return null;
      }
      final session = ChatSessionModel.fromJson(data.first);
      debugPrint('[CHATBOT] findActiveSession: found sessionId=${session.id}');
      return session;
    } on PostgrestException catch (e) {
      appLogger.e('[CHATBOT] findActiveSession PostgrestException: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('[CHATBOT] findActiveSession unexpected: $e');
      throw const UnknownException();
    }
  }

  Future<List<ChatSessionModel>> fetchSessions(String profileId) async {
    try {
      debugPrint('[CHATBOT] fetchSessions: profileId=$profileId');
      final data = await _client
          .from(SupabaseTable.chatbotSessions)
          .select()
          .eq('profile_id', profileId)
          .neq('status', ChatSessionStatus.archived.dbValue)
          .order('updated_at', ascending: false);
      final sessions = (data as List)
          .map((j) => ChatSessionModel.fromJson(j as Map<String, dynamic>))
          .toList();
      debugPrint('[CHATBOT] fetchSessions: found ${sessions.length} sessions');
      return sessions;
    } on PostgrestException catch (e) {
      appLogger.e('[CHATBOT] fetchSessions: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('[CHATBOT] fetchSessions unexpected: $e');
      throw const UnknownException();
    }
  }

  Future<ChatSessionModel> createSession(String profileId) async {
    try {
      debugPrint('[CHATBOT] createSession: profileId=$profileId');
      final data = await _client
          .from(SupabaseTable.chatbotSessions)
          .insert({
            'profile_id': profileId,
            'status': ChatSessionStatus.active.dbValue,
          })
          .select()
          .single();
      final session = ChatSessionModel.fromJson(data);
      debugPrint('[CHATBOT] createSession: created sessionId=${session.id}');
      return session;
    } on PostgrestException catch (e) {
      appLogger.e('[CHATBOT] createSession: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('[CHATBOT] createSession unexpected: $e');
      throw const UnknownException();
    }
  }

  Future<void> closeSession(String sessionId) async {
    try {
      debugPrint('[CHATBOT] closeSession: sessionId=$sessionId');
      await _client
          .from(SupabaseTable.chatbotSessions)
          .update({
            'status': ChatSessionStatus.closed.dbValue,
            'ended_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
      debugPrint('[CHATBOT] closeSession: closed');
    } on PostgrestException catch (e) {
      appLogger.e('[CHATBOT] closeSession: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    try {
      await _client
          .from(SupabaseTable.chatbotSessions)
          .update({
            'session_title': title,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }

  // ── Messages ──────────────────────────────────────────────────

  Future<List<ChatMessageModel>> fetchMessages(String sessionId) async {
    try {
      debugPrint('[CHATBOT] fetchMessages: sessionId=$sessionId');
      final data = await _client
          .from(SupabaseTable.chatbotMessages)
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);
      final messages = (data as List)
          .map((j) => ChatMessageModel.fromJson(j as Map<String, dynamic>))
          .toList();
      debugPrint('[CHATBOT] fetchMessages: ${messages.length} messages');
      return messages;
    } on PostgrestException catch (e) {
      appLogger.e('[CHATBOT] fetchMessages: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('[CHATBOT] fetchMessages unexpected: $e');
      throw const UnknownException();
    }
  }

  Future<ChatMessageModel> insertMessage({
    required String sessionId,
    required ChatMessageRole sender,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = await _client
          .from(SupabaseTable.chatbotMessages)
          .insert({
            'session_id': sessionId,
            'sender': sender.dbValue,
            'message': message,
            'metadata': metadata ?? <String, dynamic>{},
          })
          .select()
          .single();
      // Keep session updated_at fresh
      await _client
          .from(SupabaseTable.chatbotSessions)
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);
      return ChatMessageModel.fromJson(data);
    } on PostgrestException catch (e) {
      appLogger.e('[CHATBOT] insertMessage: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('[CHATBOT] insertMessage unexpected: $e');
      throw const UnknownException();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _client
          .from(SupabaseTable.chatbotSessions)
          .update({'status': ChatSessionStatus.archived.dbValue})
          .eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }
}
