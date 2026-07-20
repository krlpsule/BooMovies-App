import 'package:json_annotation/json_annotation.dart';

part 'movie_model.g.dart';

@JsonSerializable()
class Movie {
  final int? id;
  final String title;
  final String director;
  final String genre;
  final String plot;

  // Arayüzde göstereceğimiz afiş görseli için eklendi
  final String? posterUrl;

  Movie({
    this.id,
    required this.title,
    required this.director,
    required this.genre,
    required this.plot,
    this.posterUrl,
  });

  // 1. MEVCUT MİMARİ: Kendi backend/veritabanından dönen veriler için
  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
  Map<String, dynamic> toJson() => _$MovieToJson(this);

  // 2. DIŞ API MİMARİSİ: TMDB'den gelen veriyi Movie nesnesine çevirmek için
  factory Movie.fromTmdb(Map<String, dynamic> json) {
    final String? posterPath = json['poster_path'];
    final String poster = posterPath != null
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : 'https://via.placeholder.com/500x750.png?text=Afis+Yok';

    return Movie(
      id: null,
      title: json['title'] ?? 'Bilinmeyen Film',
      director:
          'Bilinmeyen Yönetmen', // TMDB araması yönetmeni ana objede dönmez
      genre: 'Film',
      plot: json['overview'] ?? 'Özet yok.',
      posterUrl: poster,
    );
  }
}
