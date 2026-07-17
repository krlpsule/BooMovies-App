// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovieReview _$MovieReviewFromJson(Map<String, dynamic> json) => MovieReview(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num).toInt(),
  movieId: (json['movieId'] as num).toInt(),
  reviewText: json['reviewText'] as String,
  rating: (json['rating'] as num).toDouble(),
);

Map<String, dynamic> _$MovieReviewToJson(MovieReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'movieId': instance.movieId,
      'reviewText': instance.reviewText,
      'rating': instance.rating,
    };
