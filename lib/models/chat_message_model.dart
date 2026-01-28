/// 💬 Modelo de Mensaje de Chat
class ChatMessage {
  final String id;
  final String workId;
  final String senderId;
  final String messageText;
  final String messageType; // 'text', 'image', 'document'
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.workId,
    required this.senderId,
    required this.messageText,
    this.messageType = 'text',
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  /// Convertir de JSON (Supabase)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      workId: json['work_id'] as String,
      senderId: json['sender_id'] as String,
      messageText: json['message_text'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() => {
    'id': id,
    'work_id': workId,
    'sender_id': senderId,
    'message_text': messageText,
    'message_type': messageType,
    'is_read': isRead,
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  /// copyWith para crear copias con cambios
  ChatMessage copyWith({
    String? id,
    String? workId,
    String? senderId,
    String? messageText,
    String? messageType,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      senderId: senderId ?? this.senderId,
      messageText: messageText ?? this.messageText,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ChatMessage(id: $id, workId: $workId, sender: $senderId, text: $messageText)';
}
