import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleBooksService {
  final String _apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? "";
  final String _baseUrl = "https://www.googleapis.com/books/v1/volumes";

  Future<List<dynamic>> searchBooks(String query) async {
    
    final String url =
        "$_baseUrl?q=${Uri.encodeQueryComponent(query)}&key=$_apiKey&maxResults=10";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? [];
      } else if (response.statusCode == 503) {
        print("Google sunucuları şu an yoğun (503). Lütfen tekrar deneyin.");
        return [];
      } else {
        print("Hata kodu: ${response.statusCode}, Mesaj: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
      return [];
    }
  }
}
