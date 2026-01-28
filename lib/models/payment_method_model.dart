enum PaymentMethodType {
  braintree,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get displayName {
    switch (this) {
      case PaymentMethodType.braintree:
        return 'Tarjeta de Crédito/Débito';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethodType.braintree:
        return 'Pago inmediato con tarjeta';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethodType.braintree:
        return '💳';
    }
  }
}

class PaymentMethod {
  final String id;
  final String workId;
  final PaymentMethodType type;
  final double amount;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;
  final String? routingNumber;
  final String? referenceCode;
  final String? paymentNonce; // Para Braintree
  final String? deviceData; // Para Braintree
  final String status; // pending, completed, failed
  final String? paymentReference; // ID de transacción
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  PaymentMethod({
    required this.id,
    required this.workId,
    required this.type,
    required this.amount,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.routingNumber,
    this.referenceCode,
    this.paymentNonce,
    this.deviceData,
    this.status = 'pending',
    this.paymentReference,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      workId: json['work_id'] as String,
      type: PaymentMethodType.values[json['type'] as int],
      amount: (json['amount'] as num).toDouble(),
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      accountHolder: json['account_holder'] as String?,
      routingNumber: json['routing_number'] as String?,
      referenceCode: json['reference_code'] as String?,
      paymentNonce: json['payment_nonce'] as String?,
      deviceData: json['device_data'] as String?,
      status: json['status'] as String? ?? 'pending',
      paymentReference: json['payment_reference'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'status': status,
      'payment_reference': paymentReference,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? workId,
    PaymentMethodType? type,
    double? amount,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    String? routingNumber,
    String? referenceCode,
    String? paymentNonce,
    String? deviceData,
    String? status,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      routingNumber: routingNumber ?? this.routingNumber,
      referenceCode: referenceCode ?? this.referenceCode,
      paymentNonce: paymentNonce ?? this.paymentNonce,
      deviceData: deviceData ?? this.deviceData,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Configuración de bancos por país (ejemplo para Perú)
class BankConfig {
  static const Map<String, Map<String, String>> bankAccounts = {
    'BCP': {
      'name': 'Banco de Crédito del Perú',
      'accountNumber': '191-2345678-0-12',
      'accountHolder': 'Fix & Go Innovations SAC',
      'currency': 'USD',
    },
    'Interbank': {
      'name': 'Interbank',
      'accountNumber': '0021-0123456-0-89',
      'accountHolder': 'Fix & Go Innovations SAC',
      'currency': 'USD',
    },
    'Scotiabank': {
      'name': 'Scotiabank Perú',
      'accountNumber': '000-3456789-12',
      'accountHolder': 'Fix & Go Innovations SAC',
      'currency': 'USD',
    },
  };

  static Map<String, String>? getBankConfig(String bankCode) {
    return bankAccounts[bankCode];
  }

  static List<String> get availableBanks => bankAccounts.keys.toList();
}
