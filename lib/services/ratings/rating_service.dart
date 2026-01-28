import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ratings/rating_model.dart';
import '../payment_service.dart';

class RatingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PaymentService _paymentService = PaymentService();
  static const String _tableName = 'ratings';

  // Crear una calificación
  Future<RatingModel> submitRating({
    required String workId,
    required String fromUserId,
    required String toUserId,
    required double rating,
    required String title,
    required String review,
    List<String>? tags,
    int? wouldRecommend,
    bool? isTechnician,
  }) async {
    try {
      // Validar rango de calificación
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final response = await _supabase.from(_tableName).insert({
        'work_id': workId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'rating': rating,
        'title': title,
        'review': review,
        'tags': tags ?? [],
        'would_recommend': wouldRecommend,
        'is_technician': isTechnician,
      }).select().single();

      final ratingModel = RatingModel.fromJson(response);

      // Si es una calificación baja (< 3 estrellas) y es del cliente, ofrecer reembolso parcial
      if (ratingModel.isLowRating() && isTechnician == true) {
        // Usar refundPayment() para procesar reembolso automático del 25%
        try {
          // Buscar el pago asociado a este trabajo
          final payments = await _supabase
              .from('payments')
              .select('id')
              .eq('work_id', workId)
              .eq('status', 'completed')
              .limit(1);
          
          if (payments.isNotEmpty) {
            await _paymentService.refundPayment(
              paymentId: payments.first['id'],
              reason: 'Low rating feedback - automatic 25% refund',
            );
          }
        } catch (e) {
          // Log pero no fallar - la calificación se creó exitosamente
          print('Warning: Could not process automatic refund: $e');
        }
      }

      return ratingModel;
    } catch (e) {
      throw Exception('Error submitting rating: $e');
    }
  }

  // Obtener calificaciones de un usuario (como técnico o cliente)
  Future<List<RatingModel>> getRatingsForUser(
    String userId, {
    bool? asTechnician,
  }) async {
    try {
      var query = _supabase.from(_tableName).select();

      query = query.eq('to_user_id', userId);
      if (asTechnician != null) {
        query = query.eq('is_technician', asTechnician);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((r) => RatingModel.fromJson(r))
          .toList();
    } catch (e) {
      throw Exception('Error fetching ratings for user: $e');
    }
  }

  // Obtener calificaciones de un trabajo específico
  Future<List<RatingModel>> getRatingsForWork(String workId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('work_id', workId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((r) => RatingModel.fromJson(r))
          .toList();
    } catch (e) {
      throw Exception('Error fetching ratings for work: $e');
    }
  }

  // Obtener calificación promedio de un usuario
  Future<double> getAverageRating(String userId) async {
    try {
      final ratings = await getRatingsForUser(userId);
      if (ratings.isEmpty) return 0.0;

      final sum = ratings.fold<double>(0, (acc, r) => acc + r.rating);
      return sum / ratings.length;
    } catch (e) {
      throw Exception('Error calculating average rating: $e');
    }
  }

  // Obtener conteo de calificaciones por rango (1-5)
  Future<Map<int, int>> getRatingDistribution(String userId) async {
    try {
      final ratings = await getRatingsForUser(userId);
      final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final rating in ratings) {
        final stars = rating.rating.toInt();
        distribution[stars] = (distribution[stars] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      throw Exception('Error calculating rating distribution: $e');
    }
  }

  // Obtener calificaciones con promedio mínimo
  Future<List<RatingModel>> getRatingsByMinimumRating(
    String userId,
    double minimumRating,
  ) async {
    try {
      final ratings = await getRatingsForUser(userId);
      return ratings.where((r) => r.rating >= minimumRating).toList();
    } catch (e) {
      throw Exception('Error fetching ratings by minimum rating: $e');
    }
  }

  // Actualizar una calificación (solo por quien la creó, dentro de 7 días)
  Future<RatingModel> updateRating(
    String ratingId, {
    double? rating,
    String? title,
    String? review,
    List<String>? tags,
    int? wouldRecommend,
  }) async {
    try {
      final existingRating = await _supabase
          .from(_tableName)
          .select()
          .eq('id', ratingId)
          .single();

      final ratingModel = RatingModel.fromJson(existingRating);

      // Validar que no haya pasado más de 7 días
      final daysSinceCreation =
          DateTime.now().difference(ratingModel.createdAt).inDays;
      if (daysSinceCreation > 7) {
        throw Exception('Ratings can only be edited within 7 days');
      }

      // Validar rango de calificación si se actualiza
      if (rating != null && (rating < 1 || rating > 5)) {
        throw Exception('Rating must be between 1 and 5');
      }

      final updateData = <String, dynamic>{};
      if (rating != null) updateData['rating'] = rating;
      if (title != null) updateData['title'] = title;
      if (review != null) updateData['review'] = review;
      if (tags != null) updateData['tags'] = tags;
      if (wouldRecommend != null)
        updateData['would_recommend'] = wouldRecommend;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', ratingId)
          .select()
          .single();

      return RatingModel.fromJson(response);
    } catch (e) {
      throw Exception('Error updating rating: $e');
    }
  }

  // Eliminar una calificación (solo por quien la creó)
  Future<void> deleteRating(String ratingId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', ratingId);
    } catch (e) {
      throw Exception('Error deleting rating: $e');
    }
  }

  // Obtener reseñas de un trabajo (todas las calificaciones de ambos lados)
  Future<Map<String, dynamic>> getWorkReviewsSummary(String workId) async {
    try {
      final ratings = await getRatingsForWork(workId);

      if (ratings.isEmpty) {
        return {
          'total': 0,
          'average': 0.0,
          'clientToTech': null,
          'techToClient': null,
        };
      }

      final clientToTech =
          ratings.firstWhere((r) => r.isTechnician == true, orElse: () => null as dynamic) as RatingModel?;
      final techToClient =
          ratings.firstWhere((r) => r.isTechnician == false, orElse: () => null as dynamic) as RatingModel?;

      final average =
          ratings.fold<double>(0, (acc, r) => acc + r.rating) / ratings.length;

      return {
        'total': ratings.length,
        'average': average,
        'clientToTech': clientToTech?.toJson(),
        'techToClient': techToClient?.toJson(),
      };
    } catch (e) {
      throw Exception('Error fetching work reviews summary: $e');
    }
  }

  // Buscar reseñas por palabra clave
  Future<List<RatingModel>> searchReviews(
    String userId,
    String keyword,
  ) async {
    try {
      final ratings = await getRatingsForUser(userId);
      return ratings
          .where((r) =>
              r.review.toLowerCase().contains(keyword.toLowerCase()) ||
              r.title.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Error searching reviews: $e');
    }
  }

  // Obtener calificaciones recientes
  Future<List<RatingModel>> getRecentRatings(
    String userId, {
    int days = 30,
  }) async {
    try {
      final ratings = await getRatingsForUser(userId);
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      return ratings
          .where((r) => r.createdAt.isAfter(cutoffDate))
          .toList();
    } catch (e) {
      throw Exception('Error fetching recent ratings: $e');
    }
  }

  // Obtener calificaciones con tags específicas
  Future<List<RatingModel>> getRatingsByTag(
    String userId,
    String tag,
  ) async {
    try {
      final ratings = await getRatingsForUser(userId);
      return ratings.where((r) => r.tags.contains(tag)).toList();
    } catch (e) {
      throw Exception('Error fetching ratings by tag: $e');
    }
  }

  // Obtener estadísticas de recomendaciones
  Future<Map<String, dynamic>> getRecommendationStats(String userId) async {
    try {
      final ratings = await getRatingsForUser(userId);
      final withRecommendation =
          ratings.where((r) => r.wouldRecommend != null).toList();

      if (withRecommendation.isEmpty) {
        return {
          'total': 0,
          'would_recommend': 0,
          'would_not_recommend': 0,
          'recommendation_rate': 0.0,
        };
      }

      final wouldRecommend =
          withRecommendation.where((r) => r.wouldRecommend == 1).length;
      final wouldNotRecommend =
          withRecommendation.where((r) => r.wouldRecommend == 0).length;

      return {
        'total': withRecommendation.length,
        'would_recommend': wouldRecommend,
        'would_not_recommend': wouldNotRecommend,
        'recommendation_rate': wouldRecommend / withRecommendation.length,
      };
    } catch (e) {
      throw Exception('Error calculating recommendation stats: $e');
    }
  }
}
