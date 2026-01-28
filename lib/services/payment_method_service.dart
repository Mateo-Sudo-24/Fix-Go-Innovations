import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_method_model.dart';

class PaymentMethodService {
  final _supabase = Supabase.instance.client;
  static const uuid = Uuid();

  // ==================== CREAR MÉTODO DE PAGO ====================
  Future<Map<String, dynamic>> createPaymentMethod({
    required String workId,
    required PaymentMethodType type,
    required double amount,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    String? routingNumber,
    String? referenceCode,
    String? paymentNonce,
    String? deviceData,
  }) async {
    try {
      final paymentMethodId = uuid.v4();
      final now = DateTime.now();

      final paymentMethodData = {
        'id': paymentMethodId,
        'work_id': workId,
        'type': type.index,
        'amount': amount,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder': accountHolder,
        'routing_number': routingNumber,
        'reference_code': referenceCode,
        'payment_nonce': paymentNonce,
        'device_data': deviceData,
        'status': 'pending',
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('payment_methods').insert(paymentMethodData);

      print('✅ Método de pago creado: $paymentMethodId (${type.displayName})');

      return {
        'success': true,
        'payment_method_id': paymentMethodId,
        'type': type.displayName,
      };
    } catch (e) {
      print('❌ Error al crear método de pago: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== OBTENER MÉTODO DE PAGO ====================
  Future<PaymentMethod?> getPaymentMethod(String paymentMethodId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select('*')
          .eq('id', paymentMethodId)
          .maybeSingle();

      if (response == null) return null;

      return PaymentMethod.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener método de pago: $e');
      return null;
    }
  }

  // ==================== OBTENER MÉTODOS DE PAGO DEL TRABAJO ====================
  Future<List<PaymentMethod>> getPaymentMethodsForWork(String workId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select('*')
          .eq('work_id', workId)
          .order('created_at', ascending: false);

      return response.map((item) => PaymentMethod.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error al obtener métodos de pago: $e');
      return [];
    }
  }

  // ==================== ACTUALIZAR ESTADO DE PAGO ====================
  Future<bool> updatePaymentStatus({
    required String paymentMethodId,
    required String status,
    String? paymentReference,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = {
        'status': status,
        if (paymentReference != null) 'payment_reference': paymentReference,
        if (metadata != null) 'metadata': metadata,
        if (status == 'completed') 'completed_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('payment_methods')
          .update(updateData)
          .eq('id', paymentMethodId);

      print(
          '✅ Estado de pago actualizado: $paymentMethodId -> $status');

      return true;
    } catch (e) {
      print('❌ Error al actualizar estado de pago: $e');
      return false;
    }
  }

  // ==================== GENERAR CÓDIGO DE REFERENCIA PARA TRANSFERENCIA ====================
  Future<String> generateTransferenceCode(String workId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final referenceCode = 'FIXGO-${workId.substring(0, 8).toUpperCase()}-$timestamp';
      return referenceCode;
    } catch (e) {
      print('❌ Error al generar código de referencia: $e');
      return 'ERROR';
    }
  }

  // ==================== VALIDAR TRANSFERENCIA (SIMULADO) ====================
  Future<Map<String, dynamic>> validateTransferencePayment({
    required String workId,
    required String referenceCode,
  }) async {
    try {
      print('🔍 Verificando transferencia con código: $referenceCode');

      // Aquí se integraría con el banco para verificar si la transferencia fue recibida
      // Por ahora, simulamos una verificación

      final response = await _supabase
          .from('payment_methods')
          .select('*')
          .eq('work_id', workId)
          .eq('reference_code', referenceCode)
          .eq('status', 'pending')
          .maybeSingle();

      if (response == null) {
        return {
          'verified': false,
          'message': 'No se encontró transferencia pendiente con ese código',
        };
      }

      // Actualizar a verificado
      await updatePaymentStatus(
        paymentMethodId: response['id'],
        status: 'completed',
        metadata: {'verified_at': DateTime.now().toIso8601String()},
      );

      return {
        'verified': true,
        'message': 'Transferencia verificada correctamente',
        'payment_method_id': response['id'],
      };
    } catch (e) {
      print('❌ Error al validar transferencia: $e');
      return {
        'verified': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== REGISTRAR PAGO EN EFECTIVO ====================
  Future<Map<String, dynamic>> registerCashPayment({
    required String workId,
    required double amount,
  }) async {
    try {
      final paymentMethodId = uuid.v4();
      final now = DateTime.now();

      final cashPaymentData = {
        'id': paymentMethodId,
        'work_id': workId,
        'type': PaymentMethodType.braintree.index,
        'amount': amount,
        'status': 'pending_confirmation', // Requiere confirmación física
        'created_at': now.toIso8601String(),
        'metadata': {
          'cash_recorded_at': now.toIso8601String(),
          'note': 'Pago en efectivo pendiente de confirmación en sitio',
        },
      };

      await _supabase.from('payment_methods').insert(cashPaymentData);

      print('✅ Pago en efectivo registrado: $paymentMethodId');

      return {
        'success': true,
        'payment_method_id': paymentMethodId,
        'status': 'pending_confirmation',
      };
    } catch (e) {
      print('❌ Error al registrar pago en efectivo: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== CONFIRMAR PAGO EN EFECTIVO (TÉCNICO CONFIRMA EN SITIO) ====================
  Future<bool> confirmCashPayment(String paymentMethodId) async {
    try {
      await updatePaymentStatus(
        paymentMethodId: paymentMethodId,
        status: 'completed',
        metadata: {
          'confirmed_at': DateTime.now().toIso8601String(),
          'confirmed_on_site': true,
        },
      );

      print('✅ Pago en efectivo confirmado: $paymentMethodId');

      return true;
    } catch (e) {
      print('❌ Error al confirmar pago en efectivo: $e');
      return false;
    }
  }

  // ==================== STREAM DE PAGOS PARA UN TRABAJO ====================
  Stream<List<PaymentMethod>> streamPaymentsForWork(String workId) {
    try {
      return _supabase
          .from('payment_methods')
          .stream(primaryKey: ['id'])
          .eq('work_id', workId)
          .order('created_at', ascending: false)
          .map((data) {
            return data.map((item) => PaymentMethod.fromJson(item)).toList();
          });
    } catch (e) {
      print('❌ Error al hacer stream de pagos: $e');
      return Stream.value([]);
    }
  }

  // ==================== OBTENER RESUMEN DE PAGOS ====================
  Future<Map<String, dynamic>> getPaymentSummary(String workId) async {
    try {
      final payments = await getPaymentMethodsForWork(workId);

      final summary = {
        'total_attempted': 0.0,
        'total_completed': 0.0,
        'total_pending': 0.0,
        'methods': <String, dynamic>{},
        'payment_count': payments.length,
      };

      for (var payment in payments) {
        final totalAttempted = (summary['total_attempted'] as num?) ?? 0.0;
        summary['total_attempted'] = totalAttempted + payment.amount;

        if (payment.status == 'completed') {
          final totalCompleted = (summary['total_completed'] as num?) ?? 0.0;
          summary['total_completed'] = totalCompleted + payment.amount;
        } else {
          final totalPending = (summary['total_pending'] as num?) ?? 0.0;
          summary['total_pending'] = totalPending + payment.amount;
        }

        // Contar por tipo
        final typeName = payment.type.displayName;
        final methodsMap = summary['methods'] as Map<String, dynamic>;
        
        if (!methodsMap.containsKey(typeName)) {
          methodsMap[typeName] = {
            'count': 0,
            'total': 0.0,
          };
        }
        
        final method = methodsMap[typeName] as Map<String, dynamic>?;
        if (method != null) {
          method['count'] = ((method['count'] as int?) ?? 0) + 1;
          method['total'] = ((method['total'] as num?) ?? 0.0) + payment.amount;
        }
      }

      return summary;
    } catch (e) {
      print('❌ Error al obtener resumen de pagos: $e');
      return {};
    }
  }
}
