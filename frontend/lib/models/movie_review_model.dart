import 'package:json_annotation/json_annotation.dart';

part 'movie_review_model.g.dart';

@JsonSerializable()
class MovieReview {
  final int? id;
  final int userId;
  final int movieId; 
  final String reviewText;
  final double rating;

  MovieReview({this.id, required this.userId, required this.movieId, required this.reviewText, required this.rating});

  factory MovieReview.fromJson(Map<String, dynamic> json) => _$MovieReviewFromJson(json);
  Map<String, dynamic> toJson() => _$MovieReviewToJson(this);
}