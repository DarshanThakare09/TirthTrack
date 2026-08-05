// ============================================================
// features/chatbot/models/chat_models.dart
// ============================================================

import 'package:equatable/equatable.dart';

// ── Enums ─────────────────────────────────────────────────────
enum ChatMessageRole { system, user, assistant }
enum ChatSessionStatus { active, closed, archived }

extension ChatMessageRoleX on ChatMessageRole {
  String get dbValue => name;
}

extension ChatSessionStatusX on ChatSessionStatus {
  String get dbValue => name;
}

ChatMessageRole roleFromDb(String? v) {
  if (v == null) return ChatMessageRole.user;
  return ChatMessageRole.values
      .where((e) => e.name == v)
      .firstOrNull ?? ChatMessageRole.user;
}

ChatSessionStatus statusFromDb(String? v) {
  if (v == null) return ChatSessionStatus.active;
  return ChatSessionStatus.values
      .where((e) => e.name == v)
      .firstOrNull ?? ChatSessionStatus.active;
}

// ── Chat Session ──────────────────────────────────────────────
class ChatSessionModel extends Equatable {
  const ChatSessionModel({
    required this.id,
    required this.profileId,
    this.sessionTitle,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String? sessionTitle;
  final ChatSessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle => sessionTitle ?? 'New Chat';

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      sessionTitle: json['session_title'] as String?,
      status: statusFromDb(json['status'] as String?),
      startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, sessionTitle, status, updatedAt];
}

// ── Chat Message ──────────────────────────────────────────────
class ChatMessageModel extends Equatable {
  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.message,
    this.metadata,
    required this.createdAt,
    this.isStreaming = false,
  });

  final String id;
  final String sessionId;
  final ChatMessageRole sender;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  /// True while assistant is typing (local-only, not persisted).
  final bool isStreaming;

  bool get isUser => sender == ChatMessageRole.user;
  bool get isAssistant => sender == ChatMessageRole.assistant;
  bool get isSystem => sender == ChatMessageRole.system;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      sender: roleFromDb(json['sender'] as String?),
      message: json['message'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  ChatMessageModel copyWith({String? message, bool? isStreaming}) {
    return ChatMessageModel(
      id: id,
      sessionId: sessionId,
      sender: sender,
      message: message ?? this.message,
      metadata: metadata,
      createdAt: createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [id, message, sender, createdAt];
}

// ── Backend API Response Models ───────────────────────────────
class ChatSourceModel extends Equatable {
  const ChatSourceModel({
    required this.document,
    required this.page,
    required this.chunkId,
  });

  final String document;
  final String page;
  final String chunkId;

  factory ChatSourceModel.fromJson(Map<String, dynamic> json) {
    return ChatSourceModel(
      document: json['document']?.toString() ?? '',
      page: json['page']?.toString() ?? '',
      chunkId: (json['chunk_id'] ?? json['chunkId'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'document': document,
        'page': page,
        'chunk_id': chunkId,
      };

  @override
  List<Object?> get props => [document, page, chunkId];
}

class ChatbotResponseModel extends Equatable {
  const ChatbotResponseModel({
    required this.status,
    required this.answer,
    required this.sources,
    required this.confidence,
    required this.retrievedChunks,
    required this.needsHumanSupport,
    this.sessionId,
    this.timestamp,
    this.metadata,
  });

  final String status;
  final String answer;
  final List<ChatSourceModel> sources;
  final String confidence;
  final int retrievedChunks;
  final bool needsHumanSupport;
  final String? sessionId;
  final String? timestamp;
  final Map<String, dynamic>? metadata;

  factory ChatbotResponseModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as List? ?? [];
    return ChatbotResponseModel(
      status: json['status'] as String? ?? 'success',
      answer: json['answer'] as String? ?? '',
      sources: rawSources
          .map((s) => ChatSourceModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      confidence: json['confidence'] as String? ?? 'low',
      retrievedChunks: (json['retrieved_chunks'] ?? json['retrievedChunks']) as int? ?? 0,
      needsHumanSupport: (json['needs_human_support'] ?? json['needsHumanSupport']) as bool? ?? false,
      sessionId: json['session_id'] as String?,
      timestamp: json['timestamp'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'answer': answer,
        'sources': sources.map((s) => s.toJson()).toList(),
        'confidence': confidence,
        'retrieved_chunks': retrievedChunks,
        'needs_human_support': needsHumanSupport,
        if (sessionId != null) 'session_id': sessionId,
        if (timestamp != null) 'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
      };

  @override
  List<Object?> get props => [
        status,
        answer,
        sources,
        confidence,
        retrievedChunks,
        needsHumanSupport,
        sessionId,
      ];
}

