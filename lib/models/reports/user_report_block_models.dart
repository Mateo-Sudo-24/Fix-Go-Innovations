enum ReportReason {
  harassment,
  fraud,
  inappropriateContent,
  unsafeService,
  fraudulentPayment,
  misrepresentation,
  nonPayment,
  rude,
  other,
}

class UserReportModel {
  final String id;
  final String reportedByUserId;
  final String reportedUserId;
  final ReportReason reason;
  final String description;
  final String? workId; // Trabajo relacionado si aplica
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  UserReportModel({
    required this.id,
    required this.reportedByUserId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    this.workId,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  factory UserReportModel.fromJson(Map<String, dynamic> json) {
    return UserReportModel(
      id: json['id'],
      reportedByUserId: json['reported_by_user_id'],
      reportedUserId: json['reported_user_id'],
      reason: ReportReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => ReportReason.other,
      ),
      description: json['description'],
      workId: json['work_id'],
      status: json['status'],
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reported_by_user_id': reportedByUserId,
      'reported_user_id': reportedUserId,
      'reason': reason.name,
      'description': description,
      'work_id': workId,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}

class UserBlockModel {
  final String id;
  final String blockingUserId;
  final String blockedUserId;
  final String? reason;
  final DateTime createdAt;
  final DateTime? unblockDate;

  UserBlockModel({
    required this.id,
    required this.blockingUserId,
    required this.blockedUserId,
    this.reason,
    required this.createdAt,
    this.unblockDate,
  });

  factory UserBlockModel.fromJson(Map<String, dynamic> json) {
    return UserBlockModel(
      id: json['id'],
      blockingUserId: json['blocking_user_id'],
      blockedUserId: json['blocked_user_id'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
      unblockDate: json['unblock_date'] != null
          ? DateTime.parse(json['unblock_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocking_user_id': blockingUserId,
      'blocked_user_id': blockedUserId,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'unblock_date': unblockDate?.toIso8601String(),
    };
  }
}
