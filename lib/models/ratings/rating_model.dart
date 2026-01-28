class RatingModel {
  final String id;
  final String workId;
  final String fromUserId;
  final String toUserId;
  final double rating; // 1-5 estrellas
  final String title;
  final String review;
  final List<String> tags; // ej: ['puntual', 'profesional', 'limpió']
  final int? wouldRecommend; // 1 = sí, 0 = no
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool? isTechnician; // True si es del cliente al técnico, False al revés

  RatingModel({
    required this.id,
    required this.workId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    required this.title,
    required this.review,
    this.tags = const [],
    this.wouldRecommend,
    required this.createdAt,
    this.updatedAt,
    this.isTechnician,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'],
      workId: json['work_id'],
      fromUserId: json['from_user_id'],
      toUserId: json['to_user_id'],
      rating: (json['rating'] as num).toDouble(),
      title: json['title'],
      review: json['review'],
      tags: List<String>.from(json['tags'] ?? []),
      wouldRecommend: json['would_recommend'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      isTechnician: json['is_technician'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_id': workId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'rating': rating,
      'title': title,
      'review': review,
      'tags': tags,
      'would_recommend': wouldRecommend,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_technician': isTechnician,
    };
  }

  RatingModel copyWith({
    String? id,
    String? workId,
    String? fromUserId,
    String? toUserId,
    double? rating,
    String? title,
    String? review,
    List<String>? tags,
    int? wouldRecommend,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isTechnician,
  }) {
    return RatingModel(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      review: review ?? this.review,
      tags: tags ?? this.tags,
      wouldRecommend: wouldRecommend ?? this.wouldRecommend,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isTechnician: isTechnician ?? this.isTechnician,
    );
  }

  // Calcular si es una calificación baja (< 3 estrellas)
  bool isLowRating() => rating < 3.0;

  // Calcular si es una calificación alta (>= 4 estrellas)
  bool isHighRating() => rating >= 4.0;
}
