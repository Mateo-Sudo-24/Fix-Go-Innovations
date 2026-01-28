import 'package:flutter/material.dart';
import '../../models/work_and_chat_models.dart' as wc;
import '../../models/accepted_work_model.dart' as aw;
import 'enhanced_payment_screen.dart';

/// Pantalla de pago - Redirige a EnhancedPaymentScreen
class PaymentScreen extends StatelessWidget {
  final wc.AcceptedWork work;

  const PaymentScreen({
    Key? key,
    required this.work,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convertir y redirigir a la nueva pantalla de pago mejorada
    final convertedWork = aw.AcceptedWork(
      id: work.id,
      requestId: work.id, // Usar id como requestId
      clientId: work.clientId,
      technicianId: work.technicianId,
      quotationId: work.quotationId,
      status: 'pending_payment',
      paymentAmount: work.paymentAmount,
      createdAt: work.createdAt,
      updatedAt: DateTime.now(),
    );
    
    return EnhancedPaymentScreen(work: convertedWork);
  }
}

