// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  author: json['author'] as String,
  genre: json['genre'] as String,
  summary: json['summary'] as String,
  coverUrl: json['coverUrl'] as String?,
);

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'author': instance.author,
  'genre': instance.genre,
  'summary': instance.summary,
  'coverUrl': instance.coverUrl,
};
