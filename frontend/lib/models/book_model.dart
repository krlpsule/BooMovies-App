import 'package:json_annotation/json_annotation.dart';

part 'book_model.g.dart';

@JsonSerializable()
class Book {
  final int? id;
  final String title;
  final String author;
  final String genre;
  final String summary;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.summary,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String coverUrl;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
  });

  // Open Library JSON formatına uygun factory metodu
  factory BookModel.fromJson(Map<String, dynamic> json) {
    // Kapak görseli ID'sini alıp Open Library Covers API URL'sine çeviriyoruz
    // Sonundaki '-L' büyük boy (Large) kapak içindir. İhtiyacına göre '-M' (Medium) yapabilirsin.
    final coverId = json['cover_i'];
    final String cover = coverId != null 
        ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg' 
        : 'https://via.placeholder.com/150'; // Kapak yoksa gösterilecek varsayılan görsel

    return BookModel(
      id: json['key'] ?? '',
      title: json['title'] ?? 'Bilinmeyen Kitap',
      // Open Library'de yazar isimleri bir liste (Array) olarak döner, ilkini alıyoruz
      author: (json['author_name'] as List?)?.first ?? 'Bilinmeyen Yazar', 
      coverUrl: cover,
    );
  }
}