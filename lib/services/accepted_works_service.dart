import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/accepted_work_model.dart';

/// 🎯 Servicio de Trabajos Aceptados
class AcceptedWorksService {
  final _supabase = Supabase.instance.client;

  // ==================== CREAR TRABAJO ACEPTADO ====================
  Future<Map<String, dynamic>> createAcceptedWork({
    required String requestId,
    required String quotationId,
    required String clientId,
    required String technicianId,
    required double paymentAmount,
    double? platformFee,
    required String status,
  }) async {
    try {
      final technicianAmount = (platformFee != null)
          ? paymentAmount - platformFee
          : paymentAmount;

      final workData = {
        'request_id': requestId,
        'quotation_id': quotationId,
        'client_id': clientId,
        'technician_id': technicianId,
        'status': status,
        'payment_amount': paymentAmount,
        'platform_fee': platformFee ?? 0,
        'technician_amount': technicianAmount,
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('accepted_works')
          .insert(workData)
          .select()
          .single();

      print('✅ Trabajo aceptado creado: ${response['id']}');

      return {
        'success': true,
        'work': AcceptedWork.fromJson(response),
      };
    } catch (e) {
      print('❌ Error creando trabajo aceptado: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== OBTENER TRABAJO POR ID ====================
  Future<AcceptedWork?> getAcceptedWork(String workId) async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select('*')
          .eq('id', workId)
          .single();

      return AcceptedWork.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo trabajo: $e');
      return null;
    }
  }

  // ==================== OBTENER TRABAJOS DEL TÉCNICO ====================
  Future<List<AcceptedWork>> getTechnicianWorks(String technicianId) async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select('*')
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);

      return response.map((item) => AcceptedWork.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error obteniendo trabajos del técnico: $e');
      return [];
    }
  }

  // ==================== OBTENER TRABAJOS DEL CLIENTE ====================
  Future<List<AcceptedWork>> getClientWorks(String clientId) async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return response.map((item) => AcceptedWork.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error obteniendo trabajos del cliente: $e');
      return [];
    }
  }

  // ==================== ACTUALIZAR ESTADO DE PAGO ====================
  Future<bool> updatePaymentStatus({
    required String workId,
    required String paymentStatus,
    required String paymentReference,
    required double paymentAmount,
    Map<String, dynamic>? paymentMetadata,
    Map<String, dynamic>? deviceData,
  }) async {
    try {
      await _supabase.from('accepted_works').update({
        'payment_status': paymentStatus,
        'payment_reference': paymentReference,
        'payment_amount': paymentAmount,
        'paid_at': paymentStatus == 'completed' ? DateTime.now().toIso8601String() : null,
        'payment_metadata': paymentMetadata,
        'braintree_device_data': deviceData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workId);

      print('✅ Estado de pago actualizado: $workId -> $paymentStatus');
      return true;
    } catch (e) {
      print('❌ Error actualizando estado de pago: $e');
      return false;
    }
  }

  // ==================== INICIAR TRABAJO ====================
  Future<bool> startWork(String workId) async {
    try {
      await _supabase.from('accepted_works').update({
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workId);

      print('✅ Trabajo iniciado: $workId');
      return true;
    } catch (e) {
      print('❌ Error iniciando trabajo: $e');
      return false;
    }
  }

  // ==================== COMPLETAR TRABAJO ====================
  Future<bool> completeWork({
    required String workId,
    String? workNotes,
    List<String>? completionPhotos,
  }) async {
    try {
      await _supabase.from('accepted_works').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'work_notes': workNotes,
        'completion_photos': completionPhotos,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workId);

      print('✅ Trabajo completado: $workId');
      return true;
    } catch (e) {
      print('❌ Error completando trabajo: $e');
      return false;
    }
  }

  // ==================== AGREGAR CALIFICACIÓN ====================
  Future<bool> addClientRating({
    required String workId,
    required int rating,
    required String review,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        print('❌ Rating debe estar entre 1 y 5');
        return false;
      }

      await _supabase.from('accepted_works').update({
        'client_rating': rating,
        'client_review': review,
        'rated_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workId);

      print('✅ Calificación agregada: $workId -> $rating ⭐');
      return true;
    } catch (e) {
      print('❌ Error agregando calificación: $e');
      return false;
    }
  }

  // ==================== STREAM EN TIEMPO REAL ====================
  Stream<AcceptedWork?> streamAcceptedWork(String workId) {
    return _supabase
        .from('accepted_works')
        .stream(primaryKey: ['id'])
        .eq('id', workId)
        .map((List<Map<String, dynamic>> data) {
          if (data.isEmpty) return null;
          return AcceptedWork.fromJson(data[0]);
        })
        .handleError((error) {
          print('❌ Error en stream de trabajo: $error');
        });
  }

  // ==================== OBTENER TRABAJOS POR ESTADO ====================
  Future<List<AcceptedWork>> getWorksByStatus(String status) async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      return response.map((item) => AcceptedWork.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error obteniendo trabajos por estado: $e');
      return [];
    }
  }

  // ==================== OBTENER TRABAJOS SIN PAGAR ====================
  Future<List<AcceptedWork>> getPendingPaymentWorks(String clientId) async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select('*')
          .eq('client_id', clientId)
          .eq('status', 'pending_payment')
          .order('created_at', ascending: false);

      return response.map((item) => AcceptedWork.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error obteniendo trabajos pendientes: $e');
      return [];
    }
  }

  // ==================== OBTENER GANANCIAS DEL TÉCNICO ====================
  Future<Map<String, dynamic>> getTechnicianEarnings(String technicianId) async {
    try {
      final works = await getTechnicianWorks(technicianId);
      final completedWorks = works.where((w) => w.isCompleted && w.isPaid).toList();

      double totalEarnings = 0;
      double totalPlatformFee = 0;

      for (var work in completedWorks) {
        totalEarnings += work.technicianAmount ?? 0;
        totalPlatformFee += work.platformFee ?? 0;
      }

      return {
        'totalEarnings': totalEarnings,
        'totalPlatformFee': totalPlatformFee,
        'completedWorks': completedWorks.length,
        'averageRating': completedWorks.isEmpty
            ? 0
            : completedWorks
                    .where((w) => w.clientRating != null)
                    .fold<double>(0, (sum, w) => sum + (w.clientRating ?? 0)) /
                completedWorks.where((w) => w.clientRating != null).length,
      };
    } catch (e) {
      print('❌ Error obteniendo ganancias: $e');
      return {'error': e.toString()};
    }
  }

  // ==================== OBTENER INGRESOS DE LA PLATAFORMA ====================
  Future<Map<String, dynamic>> getPlatformIncome() async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select('platform_fee, payment_status')
          .eq('payment_status', 'completed');

      double totalIncome = 0;
      for (var item in response) {
        totalIncome += (item['platform_fee'] as num? ?? 0).toDouble();
      }

      return {
        'totalIncome': totalIncome,
        'completedTransactions': response.length,
        'averageTransactionFee': response.isEmpty ? 0 : totalIncome / response.length,
      };
    } catch (e) {
      print('❌ Error obteniendo ingresos: $e');
      return {'error': e.toString()};
    }
  }
}
