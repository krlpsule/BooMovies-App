import 'dart:convert';
import 'package:http/http.dart' as http;

class InternalApiService {
  final String baseUrl = "http://10.0.2.2:8000";

  // --- KULLANICI İŞLEMLERİ ---
  Future<int?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"Username": username, "Password_": password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['UserID'];
    }
    return null;
  }

  Future<void> addUser(
    String name,
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_user'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "NameSurname": name,
        "Username": username,
        "Email": email,
        "Password_": password,
      }),
    );
    if (response.statusCode != 200) throw Exception('Kayıt oluşturulamadı!');
  }

  // --- KİTAP VE FİLM VERİ EKLEME ---
  Future<Map<String, dynamic>> addOrGetBook(
    Map<String, dynamic> bookData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_book_if_not_exists'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(bookData),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Kitap kaydedilemedi!');
  }

  Future<Map<String, dynamic>> addOrGetMovie(
    Map<String, dynamic> movieData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_movie_if_not_exists'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(movieData),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Film kaydedilemedi!');
  }

  // --- YORUM EKLEME ---
  Future<void> postBookReview(
    int userId,
    int bookId,
    int rating,
    String reviewText,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_book_review'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "UserID": userId,
        "BookID": bookId,
        "Rating": rating,
        "ReviewText": reviewText,
      }),
    );
    if (response.statusCode != 200) throw Exception('Kitap yorumu eklenemedi!');
  }

  Future<void> postMovieReview(
    int userId,
    int movieId,
    int rating,
    String reviewText,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_movie_review'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "UserID": userId,
        "MovieID": movieId,
        "Rating": rating,
        "ReviewText": reviewText,
      }),
    );
    if (response.statusCode != 200) throw Exception('Film yorumu eklenemedi!');
  }

  // --- KULLANICIYA ÖZEL YORUMLARI ÇEKME (Home Screen İçin) ---
  Future<List<dynamic>> getUserBookReviews(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/book_reviews'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getUserMovieReviews(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/movie_reviews'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }
  // --- KULLANICI LİSTELERİNE EKLEME İŞLEMLERİ ---

  // --- KULLANICI LİSTELERİNE EKLEME İŞLEMLERİ ---

  Future<bool> addToLibrary(int userId, int bookId) async {
    try {
      print("Kütüphaneye ekleniyor... UserID: $userId, BookID: $bookId");
      final response = await http.post(
        Uri.parse('$baseUrl/add_to_library'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'UserID': userId, 'BookID': bookId}),
      );

      // Hata ayıklama için Backend'den dönenleri yazdırıyoruz
      print("Backend Yanıt Kodu (Library): ${response.statusCode}");
      print("Backend Yanıt Mesajı (Library): ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Kütüphaneye eklerken ağ veya kod hatası: $e");
      return false;
    }
  }

  Future<bool> addToWatchlist(int userId, int movieId) async {
    try {
      print("İzleme listesine ekleniyor... UserID: $userId, MovieID: $movieId");
      final response = await http.post(
        Uri.parse('$baseUrl/add_to_watchlist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'UserID': userId, 'MovieID': movieId}),
      );

      // Hata ayıklama için Backend'den dönenleri yazdırıyoruz
      print("Backend Yanıt Kodu (Watchlist): ${response.statusCode}");
      print("Backend Yanıt Mesajı (Watchlist): ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("İzleme listesine eklerken ağ veya kod hatası: $e");
      return false;
    }
  }

  // --- KULLANICI LİSTELERİNİ ÇEKME İŞLEMLERİ ---

  Future<List<dynamic>> getUserLibrary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/library'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Kütüphaneyi çekerken hata: $e");
    }
    return [];
  }

  Future<List<dynamic>> getUserWatchlist(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/watchlist'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("İzleme listesini çekerken hata: $e");
    }
    return [];
  }
}
