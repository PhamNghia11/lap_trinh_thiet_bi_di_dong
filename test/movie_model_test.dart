import 'package:flix_app/models/movie_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Movie ánh xạ đầy đủ dữ liệu chi tiết TMDB', () {
    final movie = Movie.fromTmdbJson({
      'id': 693134,
      'title': 'Dune: Part Two',
      'release_date': '2024-02-27',
      'vote_average': 8.2,
      'vote_count': 5000,
      'runtime': 166,
      'overview': 'Nội dung phim',
      'poster_path': '/poster.jpg',
      'genres': [
        {'name': 'Viễn Tưởng'},
      ],
      'production_countries': [
        {'name': 'United States of America'},
      ],
      'credits': {
        'cast': [
          {'name': 'Timothée Chalamet', 'character': 'Paul', 'profile_path': '/actor.jpg'},
        ],
        'crew': [
          {'name': 'Denis Villeneuve', 'job': 'Director'},
        ],
      },
      'videos': {
        'results': [
          {'site': 'YouTube', 'type': 'Trailer', 'key': 'abc123'},
        ],
      },
    });

    expect(movie.id, '693134');
    expect(movie.year, 2024);
    expect(movie.duration, '166 phút');
    expect(movie.director, 'Denis Villeneuve');
    expect(movie.castList.single.role, 'Paul');
    expect(movie.trailerKey, 'abc123');
  });

  test('Movie ánh xạ genre_ids cho dữ liệu danh sách', () {
    final movie = Movie.fromTmdbJson({
      'id': 1,
      'title': 'Movie',
      'genre_ids': [28, 878],
    });
    expect(movie.genres, containsAll(['Hành Động', 'Viễn Tưởng']));
  });
}
