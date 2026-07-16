import 'dart:convert';
import 'package:http/http.dart' as http;
//import '../models/book.dart';

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
    } else {
      return null; // Hatalı giriş
    }
  }

  //--- KULLANICI KAYIT İŞLEMLERİ ---
  Future<void> addUser(
    String name,
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_user'), // FastAPI'deki endpoint
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "NameSurname": name,
        "Username": username,
        "Email": email,
        "Password_": password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Kayıt oluşturulamadı!');
    }
  }

  // --- KİTAP İŞLEMLERİ ---
  // Kitabı veritabanına ekle veya zaten varsa mevcut olanı getir
  Future<Map<String, dynamic>> addOrGetBook(
    Map<String, dynamic> bookData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_book_if_not_exists'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(bookData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Veritabanına kayıt yapılamadı!');
    }
  }

  // ---KİTAP  YORUMU İŞLEMLERİ ---
  Future<void> postBookReview(
    int userId,
    int bookId,
    int rating,
    String reviewText,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/book-reviews'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "UserID": userId,
        "BookID": bookId,
        "Rating": rating,
        "ReviewText": reviewText,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Yorum eklenirken bir hata oluştu!');
    }
  }

  // ---KİTAP  YORUMU LİSTELEME İŞLEMLERİ ---
  Future<List<dynamic>> getReviewsForBook(int bookId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/books/$bookId/reviews'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Yorumlar yüklenemedi!');
    }
  }
}
