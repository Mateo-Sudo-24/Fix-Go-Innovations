import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/reports/user_report_block_models.dart';

class UserReportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'user_reports';

  // Reportar un usuario
  Future<UserReportModel> reportUser({
    required String reportedByUserId,
    required String reportedUserId,
    required ReportReason reason,
    required String description,
    String? workId,
  }) async {
    try {
      if (reportedByUserId == reportedUserId) {
        throw Exception('No puedes reportarte a ti mismo');
      }

      final response = await _supabase.from(_tableName).insert({
        'reported_by_user_id': reportedByUserId,
        'reported_user_id': reportedUserId,
        'reason': reason.name,
        'description': description,
        'work_id': workId,
        'status': 'pending',
      }).select().single();

      return UserReportModel.fromJson(response);
    } catch (e) {
      throw Exception('Error reporting user: $e');
    }
  }

  // Obtener reportes de un usuario (como reportero)
  Future<List<UserReportModel>> getReportsBy(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('reported_by_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((r) => UserReportModel.fromJson(r))
          .toList();
    } catch (e) {
      throw Exception('Error fetching reports by user: $e');
    }
  }

  // Obtener reportes en contra de un usuario
  Future<List<UserReportModel>> getReportsAgainst(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('reported_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((r) => UserReportModel.fromJson(r))
          .toList();
    } catch (e) {
      throw Exception('Error fetching reports against user: $e');
    }
  }

  // Obtener todos los reportes pendientes (para admins)
  Future<List<UserReportModel>> getPendingReports() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return (response as List)
          .map((r) => UserReportModel.fromJson(r))
          .toList();
    } catch (e) {
      throw Exception('Error fetching pending reports: $e');
    }
  }

  // Obtener conteo de reportes pendientes
  Future<int> getPendingReportsCount() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      throw Exception('Error getting pending reports count: $e');
    }
  }

  // Marcar reporte como revisado (para admins)
  Future<void> markAsReviewed(String reportId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'status': 'reviewed'}).eq('id', reportId);
    } catch (e) {
      throw Exception('Error marking report as reviewed: $e');
    }
  }

  // Resolver reporte (para admins)
  Future<void> resolveReport(
    String reportId, {
    required String status, // 'resolved' o 'dismissed'
    String? adminNotes,
  }) async {
    try {
      if (status != 'resolved' && status != 'dismissed') {
        throw Exception('Invalid status. Must be "resolved" or "dismissed"');
      }

      await _supabase.from(_tableName).update({
        'status': status,
        'admin_notes': adminNotes,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
    } catch (e) {
      throw Exception('Error resolving report: $e');
    }
  }

  // Obtener reportes por razón
  Future<List<UserReportModel>> getReportsByReason(ReportReason reason) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('reason', reason.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((r) => UserReportModel.fromJson(r))
          .toList();
    } catch (e) {
      throw Exception('Error fetching reports by reason: $e');
    }
  }

  // Obtener estadísticas de reportes
  Future<Map<String, dynamic>> getReportStats() async {
    try {
      final allReports = await _supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      final reports = (allReports as List)
          .map((r) => UserReportModel.fromJson(r))
          .toList();

      final pending = reports.where((r) => r.status == 'pending').length;
      final reviewed = reports.where((r) => r.status == 'reviewed').length;
      final resolved = reports.where((r) => r.status == 'resolved').length;
      final dismissed = reports.where((r) => r.status == 'dismissed').length;

      return {
        'total': reports.length,
        'pending': pending,
        'reviewed': reviewed,
        'resolved': resolved,
        'dismissed': dismissed,
      };
    } catch (e) {
      throw Exception('Error getting report stats: $e');
    }
  }

  // Verificar si un usuario ya ha reportado a otro
  Future<bool> hasAlreadyReported(
    String reporterUserId,
    String reportedUserId,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('reported_by_user_id', reporterUserId)
          .eq('reported_user_id', reportedUserId);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Error checking if already reported: $e');
    }
  }
}

class UserBlockService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'user_blocks';

  // Bloquear usuario
  Future<UserBlockModel> blockUser({
    required String blockingUserId,
    required String blockedUserId,
    String? reason,
  }) async {
    try {
      if (blockingUserId == blockedUserId) {
        throw Exception('No puedes bloquearte a ti mismo');
      }

      // Verificar si ya existe el bloqueo
      final existing = await _supabase
          .from(_tableName)
          .select('id')
          .eq('blocking_user_id', blockingUserId)
          .eq('blocked_user_id', blockedUserId);

      if ((existing as List).isNotEmpty) {
        throw Exception('Este usuario ya está bloqueado');
      }

      final response = await _supabase.from(_tableName).insert({
        'blocking_user_id': blockingUserId,
        'blocked_user_id': blockedUserId,
        'reason': reason,
      }).select().single();

      return UserBlockModel.fromJson(response);
    } catch (e) {
      throw Exception('Error blocking user: $e');
    }
  }

  // Desbloquear usuario
  Future<void> unblockUser({
    required String blockingUserId,
    required String blockedUserId,
  }) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('blocking_user_id', blockingUserId)
          .eq('blocked_user_id', blockedUserId);
    } catch (e) {
      throw Exception('Error unblocking user: $e');
    }
  }

  // Obtener usuarios bloqueados
  Future<List<UserBlockModel>> getBlockedUsers(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('blocking_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((b) => UserBlockModel.fromJson(b))
          .toList();
    } catch (e) {
      throw Exception('Error fetching blocked users: $e');
    }
  }

  // Obtener usuarios que bloquearon a este usuario
  Future<List<UserBlockModel>> getBlockedBy(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('blocked_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((b) => UserBlockModel.fromJson(b))
          .toList();
    } catch (e) {
      throw Exception('Error fetching users blocking this user: $e');
    }
  }

  // Verificar si un usuario está bloqueado
  Future<bool> isUserBlocked(String blockingUserId, String blockedUserId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('blocking_user_id', blockingUserId)
          .eq('blocked_user_id', blockedUserId);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Error checking if user is blocked: $e');
    }
  }

  // Obtener conteo de usuarios bloqueados
  Future<int> getBlockedCount(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('blocking_user_id', userId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Error getting blocked count: $e');
    }
  }

  // Obtener conteo de usuarios que bloquearon
  Future<int> getBlockedByCount(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('blocked_user_id', userId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Error getting blocked by count: $e');
    }
  }
}
