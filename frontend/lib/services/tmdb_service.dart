import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie_model.dart'; // Film modelimizi ekliyoruz

class TmdbService {
  final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? "";
  final String _baseUrl = "https://api.themoviedb.org/3";

  // Dönüş tipini List<dynamic> yerine List<Movie> olarak güncelledik
  Future<List<Movie>> searchMovies(String query) async {
    if (_apiKey.isEmpty) {
      print("HATA: TMDB_API_KEY bulunamadı!");
      return [];
    }

    final url =
        "$_baseUrl/search/movie?api_key=$_apiKey&query=$query&language=tr-TR";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        
        return results.map((movieJson) => Movie.fromTmdb(movieJson)).toList();
      } else {
        print("API Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
      return [];
    }
  }
}
