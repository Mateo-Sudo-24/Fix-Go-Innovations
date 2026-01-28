enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

enum PaymentMethodType {
  creditCard,
  paypal,
  applePay,
  googlePay,
}

class Payment {
  final String id;
  final String workId;
  final double amount;
  final double platformFee;
  final double technicianAmount;
  final PaymentStatus status;
  final String? braintreeTransactionId;
  final String? braintreeNonce;
  final PaymentMethodType paymentMethod;
  final String clientId;
  final String technicianId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? deviceData;

  Payment({
    required this.id,
    required this.workId,
    required this.amount,
    required this.platformFee,
    required this.technicianAmount,
    required this.status,
    this.braintreeTransactionId,
    this.braintreeNonce,
    required this.paymentMethod,
    required this.clientId,
    required this.technicianId,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.deviceData,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      workId: json['work_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      technicianAmount: (json['technician_amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      braintreeTransactionId: json['braintree_transaction_id'] as String?,
      braintreeNonce: json['braintree_nonce'] as String?,
      paymentMethod: PaymentMethodType.values.firstWhere(
        (e) => e.toString() == 'PaymentMethodType.${json['payment_method']}',
        orElse: () => PaymentMethodType.creditCard,
      ),
      clientId: json['client_id'] as String,
      technicianId: json['technician_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      failureReason: json['failure_reason'] as String?,
      deviceData: json['device_data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_id': workId,
      'amount': amount,
      'platform_fee': platformFee,
      'technician_amount': technicianAmount,
      'status': status.toString().split('.').last,
      'braintree_transaction_id': braintreeTransactionId,
      'braintree_nonce': braintreeNonce,
      'payment_method': paymentMethod.toString().split('.').last,
      'client_id': clientId,
      'technician_id': technicianId,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failure_reason': failureReason,
      'device_data': deviceData,
    };
  }

  Payment copyWith({
    String? id,
    String? workId,
    double? amount,
    double? platformFee,
    double? technicianAmount,
    PaymentStatus? status,
    String? braintreeTransactionId,
    String? braintreeNonce,
    PaymentMethodType? paymentMethod,
    String? clientId,
    String? technicianId,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
    String? deviceData,
  }) {
    return Payment(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      amount: amount ?? this.amount,
      platformFee: platformFee ?? this.platformFee,
      technicianAmount: technicianAmount ?? this.technicianAmount,
      status: status ?? this.status,
      braintreeTransactionId: braintreeTransactionId ?? this.braintreeTransactionId,
      braintreeNonce: braintreeNonce ?? this.braintreeNonce,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      clientId: clientId ?? this.clientId,
      technicianId: technicianId ?? this.technicianId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      deviceData: deviceData ?? this.deviceData,
    );
  }
}

class PaymentResponse {
  final String id;
  final String status;
  final String? message;
  final Map<String, dynamic>? data;

  PaymentResponse({
    required this.id,
    required this.status,
    this.message,
    this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      id: json['id'] as String? ?? '',
      status: json['status'] as String,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
