import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

/// 💬 Servicio de Chat en Tiempo Real
class ChatService {
  final _supabase = Supabase.instance.client;

  // ==================== ENVIAR MENSAJE ====================
  Future<Map<String, dynamic>> sendMessage({
    required String workId,
    required String messageText,
    String messageType = 'text',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      final messageData = {
        'work_id': workId,
        'sender_id': userId,
        'message_text': messageText,
        'message_type': messageType,
        'is_read': false,
      };

      final response = await _supabase
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      print('✅ Mensaje enviado: ${response['id']}');
      return {
        'success': true,
        'message': response,
      };
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== OBTENER MENSAJES DEL CHAT ====================
  Future<List<ChatMessage>> getChatMessages(String workId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('work_id', workId)
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = response.map((item) => ChatMessage.fromJson(item)).toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return messages;
    } catch (e) {
      print('❌ Error obteniendo mensajes: $e');
      return [];
    }
  }

  // ==================== STREAM EN TIEMPO REAL ====================
  Stream<List<ChatMessage>> streamChatMessages(String workId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('work_id', workId)
        .order('created_at')
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) => ChatMessage.fromJson(item)).toList();
        })
        .handleError((error) {
          print('❌ Error en stream de chat: $error');
        });
  }

  // ==================== MARCAR MENSAJE COMO LEÍDO ====================
  Future<bool> markAsRead(String messageId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      print('✅ Mensaje marcado como leído: $messageId');
      return true;
    } catch (e) {
      print('❌ Error marcando mensaje como leído: $e');
      return false;
    }
  }

  // ==================== MARCAR TODOS COMO LEÍDOS ====================
  Future<bool> markAllAsRead(String workId, String userId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('work_id', workId)
          .neq('sender_id', userId);

      print('✅ Todos los mensajes de $workId marcados como leídos');
      return true;
    } catch (e) {
      print('❌ Error marcando todos como leídos: $e');
      return false;
    }
  }

  // ==================== OBTENER MENSAJES NO LEÍDOS ====================
  Future<int> getUnreadCount(String workId, String userId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('work_id', workId)
          .eq('is_read', false)
          .neq('sender_id', userId);

      return response.length;
    } catch (e) {
      print('❌ Error obteniendo no leídos: $e');
      return 0;
    }
  }

  // ==================== ELIMINAR MENSAJE ====================
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('id', messageId);

      print('✅ Mensaje eliminado: $messageId');
      return true;
    } catch (e) {
      print('❌ Error eliminando mensaje: $e');
      return false;
    }
  }

  // ==================== OBTENER ÚLTIMO MENSAJE DEL CHAT ====================
  Future<ChatMessage?> getLastMessage(String workId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('work_id', workId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      print('⚠️ No hay mensajes aún: $e');
      return null;
    }
  }

  // ==================== CREAR CHAT INICIAL (post-pago) ====================
  Future<Map<String, dynamic>> initializeChatAfterPayment({
    required String workId,
    required String technicianName,
    required String clientName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      // Mensaje de bienvenida automático
      final welcomeMessage = '''¡Hola $clientName!

El trabajo ha sido confirmado y el pago fue procesado exitosamente. 

El técnico $technicianName está listo para iniciar.

💬 Puedes comunicarte aquí para cualquier duda o detalle del trabajo.''';

      final messageData = {
        'work_id': workId,
        'sender_id': userId,
        'message_text': welcomeMessage,
        'message_type': 'system',
        'is_read': false,
      };

      await _supabase.from('chat_messages').insert(messageData);

      print('✅ Chat inicializado con mensaje de bienvenida');

      return {
        'success': true,
        'message': 'Chat inicializado exitosamente',
      };
    } catch (e) {
      print('❌ Error inicializando chat: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== SEARCH EN MENSAJES ====================
  Future<List<ChatMessage>> searchMessages(String workId, String query) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('work_id', workId)
          .ilike('message_text', '%$query%')
          .order('created_at', ascending: false);

      return response.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error buscando mensajes: $e');
      return [];
    }
  }

  // ==================== OBTENER RESUMEN DEL CHAT ====================
  Future<Map<String, dynamic>> getChatSummary(String workId) async {
    try {
      final allMessages = await getChatMessages(workId, limit: 1000);

      if (allMessages.isEmpty) {
        return {
          'totalMessages': 0,
          'unreadCount': 0,
          'lastMessage': null,
          'firstMessage': null,
        };
      }

      final unreadCount = allMessages.where((m) => !m.isRead).length;

      return {
        'totalMessages': allMessages.length,
        'unreadCount': unreadCount,
        'lastMessage': allMessages.last,
        'firstMessage': allMessages.first,
        'duration': allMessages.last.createdAt.difference(allMessages.first.createdAt),
      };
    } catch (e) {
      print('❌ Error obteniendo resumen: $e');
      return {'error': e.toString()};
    }
  }
}
