// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookReview _$BookReviewFromJson(Map<String, dynamic> json) => BookReview(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num).toInt(),
  bookId: (json['bookId'] as num).toInt(),
  reviewText: json['reviewText'] as String,
  rating: (json['rating'] as num).toDouble(),
);

Map<String, dynamic> _$BookReviewToJson(BookReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'bookId': instance.bookId,
      'reviewText': instance.reviewText,
      'rating': instance.rating,
    };
