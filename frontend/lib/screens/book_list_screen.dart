import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/internal_api_service.dart';
import '../services/user_manager.dart';
import 'book_review_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final InternalApiService _apiService = InternalApiService();
  late Future<List<dynamic>> _libraryFuture;
  int? _currentUserId;

  void _loadLibrary(int userId) {
    _currentUserId = userId;
    _libraryFuture = _apiService.getUserLibrary(userId);
  }

  Future<void> _showReviewDialog(BuildContext context, Map book, int userId) async {
    final bool alreadyReviewed = book['UserRating'] != null;
    final reviewController = TextEditingController(
      text: book['UserReviewText']?.toString() ?? '',
    );
    int selectedRating = alreadyReviewed
        ? (book['UserRating'] as num).round()
        : 0;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                alreadyReviewed
                    ? "${book['Title'] ?? 'Kitap'} - Yorumu Düzenle"
                    : (book['Title'] ?? 'Kitap Yorumu'),
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
                      await _apiService.postBookReview(
                        userId,
                        book['BookID'],
                        selectedRating,
                        reviewController.text,
                      );
                      Navigator.pop(dialogContext);
                      setState(() => _loadLibrary(userId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yorumunuz kaydedildi.")),
                      );
                    } catch (e) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Hata: $e")),
                      );
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

  Future<void> _showReviewsListDialog(BuildContext context, Map book) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("${book['Title'] ?? 'Kitap'} - Yorumlar"),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _apiService.getBookDetails(book['BookID']),
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
                    child: Text("Bu kitap için henüz yorum yapılmamış."),
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
                        subtitle: (review['ReviewText'] != null &&
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
        title: const Text("Kitabı Kaldır"),
        content: Text("\"$title\" kitabını kütüphanenizden kaldırmak istediğinize emin misiniz? Bu kitaba yaptığınız yorumlar da silinecek."),
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
      _loadLibrary(userId);
    }

    return FutureBuilder<List<dynamic>>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Henüz kitap eklemediniz."));
        }

        final books = snapshot.data!;
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            
           
            final String? coverUrl = book['CoverUrl'];

            return Dismissible(
              key: ValueKey(book['BookID']),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return _confirmDelete(context, book['Title'] ?? 'Bu kitap');
              },
              onDismissed: (direction) async {
                final success = await _apiService.removeFromLibrary(
                  userId,
                  book['BookID'],
                );
                if (!context.mounted) return;
                setState(() => _loadLibrary(userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "\"${book['Title']}\" kütüphaneden kaldırıldı."
                          : "Kaldırırken bir hata oluştu.",
                    ),
                  ),
                );
              },
              child: ListTile(
              // Görseli buraya ekliyoruz
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 50,
                  height: 75,
                  child: (coverUrl != null && coverUrl.isNotEmpty)
                      ? Image.network(
                          coverUrl,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.book, size: 40, color: Colors.blueGrey),
                        )
                      : const Icon(Icons.book, size: 40, color: Colors.blueGrey),
                ),
              ),
              title: Text(book['Title'] ?? 'Başlıksız Kitap'),
              subtitle: Text(
                book['AverageRating'] != null
                    ? "Ortalama Puan: ${book['AverageRating']} ⭐"
                    : "Puan yok",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () => _showReviewDialog(context, book, userId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, color: Colors.teal),
                    onPressed: () => _showReviewsListDialog(context, book),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookReviewScreen(
                            bookId: book['BookID'],
                            title: book['Title'],
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
                    builder: (context) => BookReviewScreen(
                      bookId: book['BookID'],
                      title: book['Title'],
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