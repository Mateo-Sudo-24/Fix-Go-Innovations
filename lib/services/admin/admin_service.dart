import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== OBTENER ESTADÍSTICAS GENERALES ====================
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _supabase.rpc('get_platform_stats');

      return {
        'total_users': response['total_users'] ?? 0,
        'total_technicians': response['total_technicians'] ?? 0,
        'total_requests': response['total_requests'] ?? 0,
        'total_revenue': response['total_revenue'] ?? 0,
        'total_completed_works': response['total_completed_works'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching system stats: $e');
      return {
        'total_users': 0,
        'total_technicians': 0,
        'total_requests': 0,
        'total_revenue': 0,
        'total_completed_works': 0,
      };
    }
  }

  // ==================== OBTENER USUARIOS ACTIVOS ====================
  Future<List<Map<String, dynamic>>> getActiveUsers() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      final response = await _supabase
          .from('user_profiles')
          .select('id, email, full_name, role, created_at')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching active users: $e');
      return [];
    }
  }

  // ==================== OBTENER TÉCNICOS TOP ====================
  Future<List<Map<String, dynamic>>> getTopRatedTechnicians() async {
    try {
      final response = await _supabase.rpc(
        'get_top_technicians',
        params: {'p_limit': 10},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Error fetching top rated technicians: $e');

      // Fallback
      final response = await _supabase
          .from('user_profiles')
          .select('id, full_name, role, email, created_at')
          .eq('role', 'technician')
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    }
  }

  // ==================== OBTENER INGRESOS POR PERÍODO ====================
  Future<List<Map<String, dynamic>>> getRevenueByPeriod({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase.rpc(
        'get_revenue_by_period',
        params: {
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': DateTime.now().toIso8601String(),
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Error fetching revenue by period: $e');
      return [];
    }
  }

  // ==================== OBTENER ESTADÍSTICAS DE TRABAJOS ====================
  Future<Map<String, dynamic>> getWorkStats() async {
    try {
      final allWorks = await _supabase.from('accepted_works').select('status');

      final Map<String, int> stats = {
        'pending_payment': 0,
        'on_way': 0,
        'in_progress': 0,
        'completed': 0,
        'rated': 0,
      };

      for (var work in allWorks) {
        final status = work['status'] as String?;
        if (status != null && stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error fetching work stats: $e');
      return {
        'pending_payment': 0,
        'on_way': 0,
        'in_progress': 0,
        'completed': 0,
        'rated': 0,
      };
    }
  }

  // ==================== BLOQUEAR USUARIO ====================
  Future<void> blockUserForViolation(String userId, String reason) async {
    try {
      await _supabase.from('activity_logs').insert({
        'user_id': userId,
        'action_type': 'user_blocked',
        'entity_type': 'user',
        'entity_id': userId,
        'description': 'Usuario bloqueado por: $reason',
      });

      debugPrint('Usuario $userId bloqueado por: $reason');
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  // ==================== DESBLOQUEAR USUARIO ====================
  Future<void> unblockUser(String userId) async {
    try {
      await _supabase.from('activity_logs').insert({
        'user_id': userId,
        'action_type': 'user_unblocked',
        'entity_type': 'user',
        'entity_id': userId,
        'description': 'Usuario desbloqueado',
      });

      debugPrint('Usuario $userId desbloqueado');
    } catch (e) {
      debugPrint('Error unblocking user: $e');
    }
  }

  // ==================== OBTENER USUARIOS BLOQUEADOS ====================
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final response = await _supabase
          .from('activity_logs')
          .select('user_id, user_email, description, created_at')
          .eq('action_type', 'user_blocked')
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching blocked users: $e');
      return [];
    }
  }

  // ==================== OBTENER REPORTES POR RAZÓN ====================
  Future<Map<String, dynamic>> getReportsByReason() async {
    try {
      final response = await _supabase
          .from('activity_logs')
          .select('description')
          .eq('action_type', 'report_created');

      final Map<String, int> stats = {};

      for (var log in response) {
        final reason = (log['description'] as String?) ?? 'other';
        stats[reason] = (stats[reason] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error fetching reports by reason: $e');
      return {};
    }
  }

  // ==================== OBTENER USUARIOS MÁS REPORTADOS ====================
  Future<List<Map<String, dynamic>>> getMostReportedUsers() async {
    try {
      final response = await _supabase
          .from('activity_logs')
          .select('entity_id, entity_type, description')
          .eq('action_type', 'report_created')
          .eq('entity_type', 'user')
          .order('created_at', ascending: false)
          .limit(50);

      final Map<String, Map<String, dynamic>> userStats = {};

      for (var log in response) {
        final userId = log['entity_id'];
        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'user_id': userId,
            'count': 0,
          };
        }
        userStats[userId]!['count'] += 1;
      }

      final result = userStats.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return result;
    } catch (e) {
      debugPrint('Error fetching most reported users: $e');
      return [];
    }
  }

  // ==================== OBTENER ANALÍTICA DE PAGOS ====================
  Future<Map<String, dynamic>> getPaymentAnalytics() async {
    try {
      final payments = await _supabase
          .from('payment_transactions')
          .select('total_amount, platform_fee, technician_amount, status');

      double totalProcessed = 0;
      double totalPlatformFee = 0;
      double totalTechnicianAmount = 0;
      int successfulPayments = 0;
      int failedPayments = 0;

      for (var payment in payments) {
        totalProcessed += ((payment['total_amount'] ?? 0) as num).toDouble();
        totalPlatformFee += ((payment['platform_fee'] ?? 0) as num).toDouble();
        totalTechnicianAmount +=
            ((payment['technician_amount'] ?? 0) as num).toDouble();

        final status = (payment['status'] as String?);
        if (status == 'completed') {
          successfulPayments++;
        } else if (status == 'failed') {
          failedPayments++;
        }
      }

      final totalPayments = successfulPayments + failedPayments;
      final successRate =
          totalPayments > 0 ? (successfulPayments / totalPayments) * 100 : 0;

      return {
        'total_processed': totalProcessed,
        'total_platform_fee': totalPlatformFee,
        'total_technician_amount': totalTechnicianAmount,
        'successful_payments': successfulPayments,
        'failed_payments': failedPayments,
        'success_rate': successRate,
      };
    } catch (e) {
      debugPrint('Error fetching payment analytics: $e');
      return {
        'total_processed': 0.0,
        'total_platform_fee': 0.0,
        'total_technician_amount': 0.0,
        'successful_payments': 0,
        'failed_payments': 0,
        'success_rate': 0.0,
      };
    }
  }
}
