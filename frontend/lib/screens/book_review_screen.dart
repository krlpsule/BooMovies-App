import 'package:flutter/material.dart';
import '../services/internal_api_service.dart';

class BookReviewScreen extends StatefulWidget {
  final int bookId;
  final String? title;

  const BookReviewScreen({super.key, required this.bookId, this.title});

  @override
  State<BookReviewScreen> createState() => _BookReviewScreenState();
}

class _BookReviewScreenState extends State<BookReviewScreen> {
  final InternalApiService _apiService = InternalApiService();
  late Future<Map<String, dynamic>?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _apiService.getBookDetails(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? "Kitap Detayı")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Kitap bilgisi bulunamadı."));
          }

          final book = snapshot.data!;
          final reviews = (book['Reviews'] as List<dynamic>? ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                book['Title'] ?? 'Başlıksız Kitap',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(book['Author'] ?? 'Bilinmeyen Yazar'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.category, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(book['Genre'] ?? 'Tür belirtilmemiş'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Özet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                (book['Summary'] == null || book['Summary'].toString().isEmpty)
                    ? "Özet bulunmuyor."
                    : book['Summary'],
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
                  child: Text("Bu kitap için henüz yorum yapılmamış."),
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