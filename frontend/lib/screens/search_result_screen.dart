import 'package:flutter/material.dart';
import '../services/google_books_service.dart';
import '../services/tmdb_service.dart';
import '../utils/content_actions.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  final String searchType;

  SearchResultsScreen({
    super.key,
    required this.query,
    required this.searchType,
  });

  final OpenLibraryService _bookService = OpenLibraryService();
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

              final title = item.title ?? "Başlıksız";

              final imageUrl = searchType == 'book'
                  ? item.coverUrl
                  : item.posterUrl;

              return ListTile(
                leading: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          imageUrl,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                        ),
                      )
                    : const Icon(Icons.image, size: 50),

                title: Text(title),

                subtitle: Text(
                  searchType == 'book'
                      ? (item.author ?? 'Bilinmeyen Yazar')
                      : (item.director ?? 'Bilinmeyen Yönetmen'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                trailing: const Icon(Icons.add_circle_outline),

                onTap: () => addItemToUserList(
                  context: context,
                  item: item,
                  searchType: searchType,
                ),
              );
            },
          );
        },
      ),
    );
  }
}