import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/internal_api_service.dart';
import '../services/user_manager.dart';
import 'movie_review_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final InternalApiService _apiService = InternalApiService();
  late Future<List<dynamic>> _watchlistFuture;
  int? _currentUserId;

  void _loadWatchlist(int userId) {
    _currentUserId = userId;
    _watchlistFuture = _apiService.getUserWatchlist(userId);
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    Map movie,
    int userId,
  ) async {
    final bool alreadyReviewed = movie['UserRating'] != null;
    final reviewController = TextEditingController(
      text: movie['UserReviewText']?.toString() ?? '',
    );
    int selectedRating = alreadyReviewed
        ? (movie['UserRating'] as num).round()
        : 0;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                alreadyReviewed
                    ? "${movie['Title'] ?? 'Film'} - Yorumu Düzenle"
                    : (movie['Title'] ?? 'Film Yorumu'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Puanınız:"),
                    Row(
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          icon: Icon(
                            starIndex <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setDialogState(() => selectedRating = starIndex);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Yorumunuzu yazın...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedRating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lütfen bir puan seçin.")),
                      );
                      return;
                    }
                    try {
                      await _apiService.postMovieReview(
                        userId,
                        movie['MovieID'],
                        selectedRating,
                        reviewController.text,
                      );
                      Navigator.pop(dialogContext);
                      setState(() => _loadWatchlist(userId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yorumunuz kaydedildi.")),
                      );
                    } catch (e) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                    }
                  },
                  child: Text(alreadyReviewed ? "Güncelle" : "Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReviewsListDialog(BuildContext context, Map movie) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("${movie['Title'] ?? 'Film'} - Yorumlar"),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _apiService.getMovieDetails(movie['MovieID']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final reviews =
                    (snapshot.data?['Reviews'] as List<dynamic>? ?? []);
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("Bu film için henüz yorum yapılmamış."),
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: reviews.map((review) {
                      final rating = review['Rating'] ?? 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(review['Username'] ?? 'Kullanıcı'),
                        subtitle:
                            (review['ReviewText'] != null &&
                                review['ReviewText'].toString().isNotEmpty)
                            ? Text(review['ReviewText'])
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            return Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Filmi Kaldır"),
        content: Text(
          "\"$title\" filmini listenizden kaldırmak istediğinize emin misiniz? Bu filme yaptığınız yorumlar da silinecek.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Kaldır", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final userManager = context.watch<UserManager>();
    final userId = userManager.userId;

    if (userId == null) {
      return const Center(child: Text("Giriş yapmalısınız."));
    }

    if (_currentUserId != userId) {
      _loadWatchlist(userId);
    }

    return FutureBuilder<List<dynamic>>(
      future: _watchlistFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Henüz film eklemediniz."));
        }

        final movies = snapshot.data!;
        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];

            // Veritabanından gelen görsel URL'si (Backend'de 'PosterUrl' olarak tutulduğunu varsayıyoruz)
            final String? posterUrl = movie['PosterUrl'];

            return Dismissible(
              key: ValueKey(movie['MovieID']),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return _confirmDelete(context, movie['Title'] ?? 'Bu film');
              },
              onDismissed: (direction) async {
                final success = await _apiService.removeFromWatchlist(
                  userId,
                  movie['MovieID'],
                );
                if (!context.mounted) return;
                setState(() => _loadWatchlist(userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "\"${movie['Title']}\" listeden kaldırıldı."
                          : "Kaldırırken bir hata oluştu.",
                    ),
                  ),
                );
              },
              child: ListTile(
                // Film afişini buraya ekliyoruz
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 50,
                    height: 75,
                    child: (posterUrl != null && posterUrl.isNotEmpty)
                        ? Image.network(
                            posterUrl,
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.movie,
                                  size: 40,
                                  color: Colors.blueGrey,
                                ),
                          )
                        : const Icon(
                            Icons.movie,
                            size: 40,
                            color: Colors.blueGrey,
                          ),
                  ),
                ),
                title: Text(movie['Title'] ?? 'Bilinmiyor'),
                subtitle: Text(
                  movie['AverageRating'] != null
                      ? "Ortalama Puan: ${movie['AverageRating']} ⭐"
                      : "Puan yok",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      onPressed: () =>
                          _showReviewDialog(context, movie, userId),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.comment_outlined,
                        color: Colors.teal,
                      ),
                      onPressed: () => _showReviewsListDialog(context, movie),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieReviewScreen(
                              movieId: movie['MovieID'],
                              title: movie['Title'],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieReviewScreen(
                        movieId: movie['MovieID'],
                        title: movie['Title'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
