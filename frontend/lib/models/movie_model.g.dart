// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movie _$MovieFromJson(Map<String, dynamic> json) => Movie(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  director: json['director'] as String,
  genre: json['genre'] as String,
  plot: json['plot'] as String,
  posterUrl: json['posterUrl'] as String?,
);

Map<String, dynamic> _$MovieToJson(Movie instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'director': instance.director,
  'genre': instance.genre,
  'plot': instance.plot,
  'posterUrl': instance.posterUrl,
};
