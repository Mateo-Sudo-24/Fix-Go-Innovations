import 'package:flutter/material.dart';
import '../../services/ratings/rating_service.dart';
import '../../models/ratings/rating_model.dart';
import '../../core/supabase_client.dart';

class RatingSubmissionScreen extends StatefulWidget {
  final String workId;
  final String toUserId;
  final String technicianName;
  final bool isTechnician;

  const RatingSubmissionScreen({
    Key? key,
    required this.workId,
    required this.toUserId,
    required this.technicianName,
    required this.isTechnician,
  }) : super(key: key);

  @override
  State<RatingSubmissionScreen> createState() => _RatingSubmissionScreenState();
}

class _RatingSubmissionScreenState extends State<RatingSubmissionScreen> {
  late RatingService _ratingService;
  double _rating = 5.0;
  final _titleController = TextEditingController();
  final _reviewController = TextEditingController();
  int? _wouldRecommend;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  static const List<String> _availableTags = [
    'puntual',
    'profesional',
    'limpio',
    'comunicativo',
    'rápido',
    'eficiente',
    'amable',
    'honesto',
    'calidad',
    'recomendable',
  ];

  @override
  void initState() {
    super.initState();
    _ratingService = RatingService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_titleController.text.isEmpty || _reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = supabaseClient.auth.currentUser!.id;
      await _ratingService.submitRating(
        workId: widget.workId,
        fromUserId: userId,
        toUserId: widget.toUserId,
        rating: _rating,
        title: _titleController.text,
        review: _reviewController.text,
        tags: _selectedTags,
        wouldRecommend: _wouldRecommend,
        isTechnician: widget.isTechnician,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Calificación enviada exitosamente!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificar'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con nombre
            Center(
              child: Column(
                children: [
                  const Icon(Icons.star, size: 48, color: Colors.amber),
                  const SizedBox(height: 12),
                  Text(
                    'Califica a ${widget.technicianName}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Selector de estrellas
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() => _rating = (index + 1).toDouble());
                        },
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: (index + 1) <= _rating.toInt()
                              ? Colors.amber
                              : Colors.grey[300],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_rating.toStringAsFixed(1)} de 5',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Título
            const Text(
              'Título',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ej: Excelente servicio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Reseña
            const Text(
              'Reseña',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText:
                    'Comparte tu experiencia (mínimo 20 caracteres)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Tags
            const Text(
              'Selecciona características',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ¿Lo recomendarías?
            const Text(
              '¿Lo recomendarías a otros?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _wouldRecommend = 1),
                    icon: const Icon(Icons.thumb_up),
                    label: const Text('Sí'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wouldRecommend == 1
                          ? Colors.green
                          : Colors.grey[300],
                      foregroundColor: _wouldRecommend == 1
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _wouldRecommend = 0),
                    icon: const Icon(Icons.thumb_down),
                    label: const Text('No'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wouldRecommend == 0
                          ? Colors.red
                          : Colors.grey[300],
                      foregroundColor: _wouldRecommend == 0
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botón de envío
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar Calificación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla para ver calificaciones
class RatingsViewScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const RatingsViewScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<RatingsViewScreen> createState() => _RatingsViewScreenState();
}

class _RatingsViewScreenState extends State<RatingsViewScreen> {
  late RatingService _ratingService;

  @override
  void initState() {
    super.initState();
    _ratingService = RatingService();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Calificaciones de ${widget.userName}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Todas'),
              Tab(text: 'Recomendaciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Todas las calificaciones
            FutureBuilder<List<RatingModel>>(
              future: _ratingService.getRatingsForUser(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final ratings = snapshot.data ?? [];

                if (ratings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Sin calificaciones aún'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    return _RatingCard(rating: ratings[index]);
                  },
                );
              },
            ),
            // Tab 2: Recomendaciones
            FutureBuilder<Map<String, dynamic>>(
              future: _ratingService.getRecommendationStats(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final stats = snapshot.data ?? {};
                final total = stats['total'] as int? ?? 0;
                final wouldRecommend = stats['would_recommend'] as int? ?? 0;
                final rate = (stats['recommendation_rate'] as double? ?? 0) * 100;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Tasa de Recomendación',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${rate.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '$wouldRecommend de $total personas lo recomendarían',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final RatingModel rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calificación y fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 16,
                      color: index < rating.rating.toInt()
                          ? Colors.amber
                          : Colors.grey[300],
                    );
                  }),
                ),
                Text(
                  _formatDate(rating.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Título
            Text(
              rating.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Reseña
            Text(rating.review),
            const SizedBox(height: 8),
            // Tags
            if (rating.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: rating.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            if (rating.wouldRecommend != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    rating.wouldRecommend == 1
                        ? Icons.thumb_up
                        : Icons.thumb_down,
                    size: 16,
                    color: rating.wouldRecommend == 1
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rating.wouldRecommend == 1
                        ? 'Recomendado'
                        : 'No recomendado',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
