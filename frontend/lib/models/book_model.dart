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
