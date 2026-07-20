import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class OpenLibraryService {
  Future<List<BookModel>> searchBooks(String query) async {
    // Kitap adı ile arama yapan endpoint
    final url = Uri.parse('https://openlibrary.org/search.json?q=$query');

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'BooMoviesApp (eminesulekaraalp@gmail.com)', // Projene özel tanımlama
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Open Library arama sonuçlarını 'docs' dizisi içinde döndürür
        final List docs = data['docs'] ?? [];

        return docs.map((bookJson) => BookModel.fromJson(bookJson)).toList();
      } else {
        throw Exception('Kitaplar yüklenirken bir hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
}
