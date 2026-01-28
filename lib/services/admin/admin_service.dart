import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener estadísticas generales del sistema
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      // Contar usuarios
      final usersCount = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('is_deleted', false);

      // Contar trabajos completados
      final completedWorks = await _supabase
          .from('accepted_works')
          .select('id')
          .eq('status', 'completed');

      // Contar ingresos totales
      final payments = await _supabase
          .from('payments')
          .select('amount')
          .eq('status', 'completed');

      double totalRevenue = 0;
      for (var payment in payments) {
        totalRevenue += (payment['amount'] as num).toDouble();
      }

      // Contar reportes pendientes
      final pendingReports = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'pending');

      return {
        'total_users': usersCount.length,
        'completed_works': completedWorks.length,
        'total_revenue': totalRevenue,
        'pending_reports': pendingReports.length,
      };
    } catch (e) {
      throw Exception('Error fetching system stats: $e');
    }
  }

  // Obtener usuarios activos (últimos 30 días)
  Future<List<Map<String, dynamic>>> getActiveUsers() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      final response = await _supabase
          .from('user_profiles')
          .select('id, full_name, email, role, created_at, is_deleted')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching active users: $e');
    }
  }

  // Obtener técnicos mejor calificados
  Future<List<Map<String, dynamic>>> getTopRatedTechnicians() async {
    try {
      // Obtener técnicos con su calificación promedio
      final response = await _supabase
          .from('user_profiles')
          .select(
              'id, full_name, role, specialty, email, profile_image_url, created_at')
          .eq('role', 'technician')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching top rated technicians: $e');
    }
  }

  // Obtener ingresos por período
  Future<List<Map<String, dynamic>>> getRevenueByPeriod(
    {int days = 30,}
  ) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('payments')
          .select('created_at, platform_fee, technician_amount')
          .gte('created_at', startDate.toIso8601String())
          .eq('status', 'completed')
          .order('created_at', ascending: true);

      // Agrupar por día
      final Map<String, Map<String, dynamic>> groupedData = {};

      for (var payment in response) {
        final date = DateTime.parse(payment['created_at']);
        final key = '${date.year}-${date.month}-${date.day}';

        if (!groupedData.containsKey(key)) {
          groupedData[key] = {
            'date': key,
            'revenue': 0.0,
            'transactions': 0,
          };
        }

        groupedData[key]!['revenue'] +=
            ((payment['platform_fee'] ?? 0) as num).toDouble();
        groupedData[key]!['transactions'] += 1;
      }

      return groupedData.values.toList();
    } catch (e) {
      throw Exception('Error fetching revenue by period: $e');
    }
  }

  // Obtener estadísticas de trabajos
  Future<Map<String, dynamic>> getWorkStats() async {
    try {
      final allWorks = await _supabase.from('accepted_works').select('status');

      final Map<String, int> stats = {
        'pending_payment': 0,
        'on_way': 0,
        'in_progress': 0,
        'completed': 0,
      };

      for (var work in allWorks) {
        final status = work['status'] as String?;
        if (status != null && stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Error fetching work stats: $e');
    }
  }

  // Bloquear usuario (moderación)
  Future<void> blockUserForViolation(
    String userId,
    String reason,
  ) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'is_blocked': true, 'block_reason': reason}).eq('id', userId);
    } catch (e) {
      throw Exception('Error blocking user: $e');
    }
  }

  // Desbloquear usuario
  Future<void> unblockUser(String userId) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'is_blocked': false, 'block_reason': null}).eq('id', userId);
    } catch (e) {
      throw Exception('Error unblocking user: $e');
    }
  }

  // Obtener usuarios bloqueados
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id, full_name, email, role, block_reason, created_at')
          .eq('is_blocked', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching blocked users: $e');
    }
  }

  // Obtener reportes por razón
  Future<Map<String, dynamic>> getReportsByReason() async {
    try {
      final response = await _supabase.from('user_reports').select('reason');

      final Map<String, int> stats = {};

      for (var report in response) {
        final reason = report['reason'] as String? ?? 'other';
        stats[reason] = (stats[reason] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Error fetching reports by reason: $e');
    }
  }

  // Obtener usuarios más reportados
  Future<List<Map<String, dynamic>>> getMostReportedUsers() async {
    try {
      final response = await _supabase
          .from('user_reports')
          .select('reported_user_id, user_profiles(full_name, email, role)')
          .order('created_at', ascending: false)
          .limit(10);

      final Map<String, Map<String, dynamic>> userStats = {};

      for (var report in response) {
        final userId = report['reported_user_id'];
        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'userId': userId,
            'count': 0,
            'user': report['user_profiles'],
          };
        }
        userStats[userId]!['count'] += 1;
      }

      return userStats.values
          .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    } catch (e) {
      throw Exception('Error fetching most reported users: $e');
    }
  }

  // Obtener analítica de pagos
  Future<Map<String, dynamic>> getPaymentAnalytics() async {
    try {
      final payments = await _supabase
          .from('payments')
          .select('amount, platform_fee, technician_amount, status');

      double totalProcessed = 0;
      double totalPlatformFee = 0;
      double totalTechnicianAmount = 0;
      int successfulPayments = 0;
      int failedPayments = 0;

      for (var payment in payments) {
        totalProcessed += ((payment['amount'] ?? 0) as num).toDouble();
        totalPlatformFee +=
            ((payment['platform_fee'] ?? 0) as num).toDouble();
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
      throw Exception('Error fetching payment analytics: $e');
    }
  }
}
