import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../services/internal_api_service.dart';
import '../services/user_manager.dart';

final InternalApiService _apiService = InternalApiService();

/// Bir arama sonucunu (Book veya Movie nesnesi) kullanıcının
/// kütüphanesine/izleme listesine ekler. search_result_screen.dart ve
/// home_screen.dart'taki canlı öneri (autocomplete) dropdown'u tarafından
/// ortak olarak kullanılır.
Future<void> addItemToUserList({
  required BuildContext context,
  required dynamic item,
  required String searchType, // 'book' ya da 'movie'
}) async {
  final int? currentUserId = context.read<UserManager>().userId;
  final String title = item.title ?? "Başlıksız";

  if (currentUserId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Oturum bulunamadı. Lütfen giriş yapın.")),
    );
    return;
  }

  final Map<String, dynamic> dataToSend = searchType == 'book'
      ? {
          "Title": title,
          "Author": item.author,
          "Genre": item.genre,
          "Summary": item.summary,
          "CoverUrl": item.coverUrl,
        }
      : {
          "Title": title,
          "Director": item.director,
          "Genre": item.genre,
          "Plot": item.plot,
          "PosterUrl": item.posterUrl,
        };

  try {
    final result = searchType == 'book'
        ? await _apiService.addOrGetBook(dataToSend)
        : await _apiService.addOrGetMovie(dataToSend);

    if (result != null) {
      bool isAddedToList = false;

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

      if (!context.mounted) return;

      if (isAddedToList) {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu içerik zaten listenizde.")),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kaydederken bir hata oluştu!")),
      );
    }
  }
}