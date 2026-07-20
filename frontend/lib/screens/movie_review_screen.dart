import 'package:flutter/material.dart';
import '../services/internal_api_service.dart';

class MovieReviewScreen extends StatefulWidget {
  final int movieId;
  final String? title;

  const MovieReviewScreen({super.key, required this.movieId, this.title});

  @override
  State<MovieReviewScreen> createState() => _MovieReviewScreenState();
}

class _MovieReviewScreenState extends State<MovieReviewScreen> {
  final InternalApiService _apiService = InternalApiService();
  late Future<Map<String, dynamic>?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _apiService.getMovieDetails(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? "Film Detayı")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Film bilgisi bulunamadı."));
          }

          final movie = snapshot.data!;
          final reviews = (movie['Reviews'] as List<dynamic>? ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                movie['Title'] ?? 'Bilinmeyen Film',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.movie_creation_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(movie['Director'] ?? 'Bilinmeyen Yönetmen'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.category, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(movie['Genre'] ?? 'Tür belirtilmemiş'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Konu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                (movie['Plot'] == null || movie['Plot'].toString().isEmpty)
                    ? "Konu özeti bulunmuyor."
                    : movie['Plot'],
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const Divider(height: 32),
              Text(
                "Yorumlar (${reviews.length})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("Bu film için henüz yorum yapılmamış."),
                )
              else
                ...reviews.map((review) {
                  final rating = review['Rating'] ?? 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                review['Username'] ?? 'Kullanıcı',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < rating ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (review['ReviewText'] != null &&
                              review['ReviewText'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(review['ReviewText']),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}