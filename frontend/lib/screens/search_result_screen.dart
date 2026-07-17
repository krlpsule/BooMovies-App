import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/google_books_service.dart';
import '../services/tmdb_service.dart';
import '../services/internal_api_service.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  final String searchType;

  SearchResultsScreen({
    super.key,
    required this.query,
    required this.searchType,
  });

  final InternalApiService _apiService = InternalApiService();
  final GoogleBooksService _bookService = GoogleBooksService();
  final TmdbService _movieService = TmdbService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${searchType == 'book' ? 'Kitap' : 'Film'} Sonuçları"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: searchType == 'book'
            ? _bookService.searchBooks(query)
            : _movieService.searchMovies(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text("Sonuç bulunamadı."));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final title = searchType == 'book'
                  ? item['volumeInfo']['title']
                  : item['title'];

              return ListTile(
                title: Text(title),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () async {
                  // 1. Veri Hazırlama
                  final Map<String, dynamic> dataToSend = searchType == 'book'
                      ? {
                          "Title": item['volumeInfo']['title'] ?? "Başlıksız",
                          "Author":
                              (item['volumeInfo']['authors'] ??
                              ['Bilinmiyor'])[0],
                          "Genre":
                              (item['volumeInfo']['categories'] ??
                              ['Genel'])[0],
                          "Summary":
                              item['volumeInfo']['description'] ?? "Özet yok.",
                        }
                      : {
                          "Title": item['title'] ?? "Başlıksız",
                          "Director": "Bilinmiyor",
                          "Genre": "Film",
                          "Plot": item['overview'] ?? "Özet yok.",
                        };

                  // 2. Servis Çağrısı ve Yönlendirme
                  try {
                    final result = searchType == 'book'
                        ? await _apiService.addOrGetBook(dataToSend)
                        : await _apiService.addOrGetMovie(dataToSend);

                    if (result != null && context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            initialIndex: searchType == 'book' ? 0 : 1,
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    print("Hata: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kaydederken bir hata oluştu!"),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
