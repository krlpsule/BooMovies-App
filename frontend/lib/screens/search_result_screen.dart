import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../services/google_books_service.dart';
import '../services/tmdb_service.dart';
import '../services/internal_api_service.dart';
import '../services/user_manager.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  final String searchType;

  SearchResultsScreen({
    super.key,
    required this.query,
    required this.searchType,
  });

  final InternalApiService _apiService = InternalApiService();
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

                // Alt başlıkta yazar veya yönetmen bilgisini gösteriyoruz
                subtitle: Text(
                  searchType == 'book'
                      ? (item.author ?? 'Bilinmeyen Yazar')
                      : (item.director ?? 'Bilinmeyen Yönetmen'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                trailing: const Icon(Icons.add_circle_outline),

                onTap: () async {
                  final int? currentUserId = context.read<UserManager>().userId;

                  if (currentUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Oturum bulunamadı. Lütfen giriş yapın."),
                      ),
                    );
                    return;
                  }

                  // 1. Veri Hazırlama (Nesne özelliklerine nokta ile erişim sağlandı)
final Map<String, dynamic> dataToSend = searchType == 'book'
    ? {
        "Title": item.title ?? "Başlıksız",
        "Author": item.author ?? "Bilinmiyor",
        "Genre": "Genel",
        "Summary": "Özet yok.",
        "CoverUrl": item.coverUrl,
      }
    : {
        "Title": item.title ?? "Başlıksız",
        "Director": item.director ?? "Bilinmiyor",
        "Genre": item.genre ?? "Film",
        "Plot": item.plot ?? "Özet yok.",
        "PosterUrl": item.posterUrl, 
      };

                  try {
                    // 2. Aşama: Veritabanına Ekle
                    final result = searchType == 'book'
                        ? await _apiService.addOrGetBook(dataToSend)
                        : await _apiService.addOrGetMovie(dataToSend);

                    if (result != null) {
                      bool isAddedToList = false;

                      // 3. Aşama: Kullanıcı Listesine Ekle
                      if (searchType == 'book') {
                        isAddedToList = await _apiService.addToLibrary(
                          currentUserId,
                          result['BookID'],
                        );
                      } else {
                        isAddedToList = await _apiService.addToWatchlist(
                          currentUserId,
                          result['MovieID'],
                        );
                      }

                      // 4. Aşama: Başarılıysa Yönlendir
                      if (isAddedToList && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$title listenize eklendi!")),
                        );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                              initialIndex: searchType == 'book' ? 0 : 1,
                            ),
                          ),
                          (route) => false,
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Bu içerik zaten listenizde."),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Kaydederken bir hata oluştu!"),
                        ),
                      );
                    }
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
