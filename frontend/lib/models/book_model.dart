import 'package:json_annotation/json_annotation.dart';

part 'book_model.g.dart';

@JsonSerializable()
class Book {
  final int? id;
  final String title;
  final String author;
  final String genre;
  final String summary;

  // Arayüzde göstereceğimiz kapak görseli için eklendi
  final String? coverUrl;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.summary,
    this.coverUrl,
  });

  // 1. MEVCUT MİMARİ: Kendi backend/veritabanından dönen veriler için
  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

  // 2. DIŞ API MİMARİSİ: Open Library'den gelen veriyi Book nesnesine çevirmek için
  factory Book.fromOpenLibrary(Map<String, dynamic> json) {
    final coverId = json['cover_i'];
    final String? cover = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
        : null; 

    return Book(
      id: null, 
      title: json['title'] ?? 'Bilinmeyen Kitap',
      author: (json['author_name'] as List?)?.isNotEmpty == true
          ? (json['author_name'] as List).first.toString()
          : '', 
      genre:
          '', 
      summary: '',
      coverUrl: cover,
    );
  }
}