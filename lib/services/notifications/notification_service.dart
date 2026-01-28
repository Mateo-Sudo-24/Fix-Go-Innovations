import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notifications/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'notifications';

  // Crear notificación
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from(_tableName).insert({
        'user_id': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'related_id': relatedId,
        'is_read': false,
        'metadata': metadata,
      });
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  // Obtener notificaciones del usuario
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Escuchar notificaciones en tiempo real
  Stream<List<NotificationModel>> listenToNotifications(String userId) {
    try {
      return _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at')
          .map((event) {
            return (event)
                .map((n) => NotificationModel.fromJson(n))
                .toList();
          });
    } catch (e) {
      throw Exception('Error listening to notifications: $e');
    }
  }

  // Marcar como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // Marcar todas como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_read': true}).eq('user_id', userId);
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  // Obtener conteo de no leídas
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  // Escuchar cambios en notificaciones no leídas (en tiempo real)
  Stream<int> listenToUnreadCount(String userId) {
    return listenToNotifications(userId).map((notifications) {
      return notifications.where((n) => !n.isRead).length;
    });
  }

  // Eliminar notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Eliminar todas las notificaciones de un usuario
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase.from(_tableName).delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Error deleting all notifications: $e');
    }
  }

  // Obtener notificaciones sin leer
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
    } catch (e) {
      throw Exception('Error fetching unread notifications: $e');
    }
  }

  // Obtener notificaciones por tipo
  Future<List<NotificationModel>> getNotificationsByType(
    String userId,
    NotificationType type,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('type', type.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
    } catch (e) {
      throw Exception('Error fetching notifications by type: $e');
    }
  }

  // Filtrar notificaciones por rango de fechas
  Future<List<NotificationModel>> getNotificationsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
    } catch (e) {
      throw Exception('Error fetching notifications by date range: $e');
    }
  }
}
