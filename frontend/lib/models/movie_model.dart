import 'package:json_annotation/json_annotation.dart';

part 'movie_model.g.dart'; 

@JsonSerializable()
class Movie {
  final int? id;
  final String title;
  final String director;
  final String genre;
  final String plot;
 


  Movie({this.id, required this.title, required this.director, required this.genre, required this.plot});

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
  Map<String, dynamic> toJson() => _$MovieToJson(this);
}