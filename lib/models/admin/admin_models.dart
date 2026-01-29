// ==================== ESTADÍSTICAS DE LA PLATAFORMA ====================
class PlatformStats {
  final int totalUsers;
  final int totalClients;
  final int totalTechnicians;
  final int totalRequests;
  final int totalQuotations;
  final int totalWorks;
  final int totalCompletedWorks;
  final double totalRevenue;
  final double platformEarnings;
  final double technicianEarnings;

  PlatformStats({
    required this.totalUsers,
    required this.totalClients,
    required this.totalTechnicians,
    required this.totalRequests,
    required this.totalQuotations,
    required this.totalWorks,
    required this.totalCompletedWorks,
    required this.totalRevenue,
    required this.platformEarnings,
    required this.technicianEarnings,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalUsers: json['total_users'] ?? 0,
      totalClients: json['total_clients'] ?? 0,
      totalTechnicians: json['total_technicians'] ?? 0,
      totalRequests: json['total_requests'] ?? 0,
      totalQuotations: json['total_quotations'] ?? 0,
      totalWorks: json['total_works'] ?? 0,
      totalCompletedWorks: json['total_completed_works'] ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      platformEarnings: (json['platform_earnings'] as num?)?.toDouble() ?? 0.0,
      technicianEarnings: (json['technician_earnings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ==================== TRANSACCIÓN DE PAGO ====================
class PaymentTransaction {
  final String id;
  final String workId;
  final String clientId;
  final String technicianId;
  final String? braintreeTransactionId;
  final String? braintreeStatus;
  final double totalAmount;
  final double platformFee;
  final double technicianAmount;
  final String paymentMethod;
  final Map<String, dynamic>? paymentMethodDetails;
  final String status;
  final String? errorMessage;
  final DateTime transactionDate;
  final DateTime? settledDate;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.workId,
    required this.clientId,
    required this.technicianId,
    this.braintreeTransactionId,
    this.braintreeStatus,
    required this.totalAmount,
    required this.platformFee,
    required this.technicianAmount,
    required this.paymentMethod,
    this.paymentMethodDetails,
    required this.status,
    this.errorMessage,
    required this.transactionDate,
    this.settledDate,
    this.metadata,
    required this.createdAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      workId: json['work_id'],
      clientId: json['client_id'],
      technicianId: json['technician_id'],
      braintreeTransactionId: json['braintree_transaction_id'],
      braintreeStatus: json['braintree_status'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      technicianAmount: (json['technician_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      paymentMethodDetails: json['payment_method_details'],
      status: json['status'],
      errorMessage: json['error_message'],
      transactionDate: DateTime.parse(json['transaction_date']),
      settledDate: json['settled_date'] != null
          ? DateTime.parse(json['settled_date'])
          : null,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// ==================== LOG DE ACTIVIDAD ====================
class ActivityLog {
  final String id;
  final String? userId;
  final String? userEmail;
  final String? userRole;
  final String actionType;
  final String? entityType;
  final String? entityId;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    this.userId,
    this.userEmail,
    this.userRole,
    required this.actionType,
    this.entityType,
    this.entityId,
    required this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      userId: json['user_id'],
      userEmail: json['user_email'],
      userRole: json['user_role'],
      actionType: json['action_type'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      description: json['description'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get actionIcon {
    switch (actionType) {
      case 'user_registered':
        return '👤';
      case 'request_created':
        return '📝';
      case 'quotation_sent':
        return '📋';
      case 'quotation_accepted':
        return '✅';
      case 'payment_completed':
        return '💳';
      case 'work_started':
        return '🔧';
      case 'work_completed':
        return '✔️';
      case 'rating_submitted':
        return '⭐';
      default:
        return '📌';
    }
  }
}

// ==================== INGRESOS POR PERÍODO ====================
class RevenueByPeriod {
  final DateTime date;
  final double totalRevenue;
  final double platformFee;
  final int transactionCount;

  RevenueByPeriod({
    required this.date,
    required this.totalRevenue,
    required this.platformFee,
    required this.transactionCount,
  });

  factory RevenueByPeriod.fromJson(Map<String, dynamic> json) {
    return RevenueByPeriod(
      date: DateTime.parse(json['date']),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      transactionCount: json['transaction_count'] ?? 0,
    );
  }
}

// ==================== TOP TÉCNICO ====================
class TopTechnician {
  final String technicianId;
  final String technicianName;
  final int totalWorks;
  final int completedWorks;
  final double? averageRating;
  final double totalEarned;

  TopTechnician({
    required this.technicianId,
    required this.technicianName,
    required this.totalWorks,
    required this.completedWorks,
    this.averageRating,
    required this.totalEarned,
  });

  factory TopTechnician.fromJson(Map<String, dynamic> json) {
    return TopTechnician(
      technicianId: json['technician_id'],
      technicianName: json['technician_name'],
      totalWorks: json['total_works'] ?? 0,
      completedWorks: json['completed_works'] ?? 0,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
    );
  }
}