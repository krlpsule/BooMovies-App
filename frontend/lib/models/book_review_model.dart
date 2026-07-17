import 'package:json_annotation/json_annotation.dart';

part 'book_review_model.g.dart';

@JsonSerializable()
class BookReview {
  final int? id;
  final int userId;
  final int bookId; 
  final String reviewText;
  final double rating;

  BookReview({this.id, required this.userId, required this.bookId, required this.reviewText, required this.rating});

  factory BookReview.fromJson(Map<String, dynamic> json) => _$BookReviewFromJson(json);
  Map<String, dynamic> toJson() => _$BookReviewToJson(this);
}