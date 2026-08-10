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
      'backdrop_path': '/backdrop.jpg',
      'original_title': 'Dune: Part Two',
      'tagline': 'Long live the fighters.',
      'status': 'Released',
      'budget': 190000000,
      'revenue': 714000000,
      'popularity': 92.4,
      'imdb_id': 'tt15239678',
      'homepage': 'https://www.dunemovie.com',
      'spoken_languages': [
        {'name': 'English'},
      ],
      'production_companies': [
        {'name': 'Legendary Pictures'},
      ],
      'belongs_to_collection': {'name': 'Dune Collection'},
      'keywords': {
        'keywords': [
          {'name': 'desert'},
          {'name': 'prophecy'},
        ],
      },
      'watch/providers': {
        'results': {
          'VN': {
            'flatrate': [
              {'provider_name': 'Max', 'name': 'Max'},
            ],
          },
        },
      },
      'release_dates': {
        'results': [
          {
            'iso_3166_1': 'US',
            'release_dates': [
              {'certification': 'PG-13'},
            ],
          },
        ],
      },
      'genres': [
        {'name': 'Viễn Tưởng'},
      ],
      'production_countries': [
        {'name': 'United States of America'},
      ],
      'credits': {
        'cast': [
          {
            'name': 'Timothée Chalamet',
            'character': 'Paul',
            'profile_path': '/actor.jpg'
          },
        ],
        'crew': [
          {'name': 'Denis Villeneuve', 'job': 'Director'},
          {'name': 'Jon Spaihts', 'job': 'Screenplay', 'department': 'Writing'},
          {'name': 'Mary Parent', 'job': 'Producer'},
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
    expect(movie.backdropUrl, 'https://image.tmdb.org/t/p/w1280/backdrop.jpg');
    expect(movie.ageRating, 'PG-13');
    expect(movie.writers, contains('Jon Spaihts'));
    expect(movie.producers, contains('Mary Parent'));
    expect(movie.productionCompanies, ['Legendary Pictures']);
    expect(movie.watchProviders, ['Max']);
    expect(movie.keywords, containsAll(['desert', 'prophecy']));
    expect(Movie.fromJson(movie.toJson()).imdbId, 'tt15239678');
  });

  test('Movie ánh xạ genre_ids cho dữ liệu danh sách', () {
    final movie = Movie.fromTmdbJson({
      'id': 1,
      'title': 'Movie',
      'genre_ids': [28, 878],
    });
    expect(movie.genres, containsAll(['Hành Động', 'Viễn Tưởng']));
  });

  test('phân bố đánh giá dùng dữ liệu người xem thật', () {
    const reviews = [
      UserReview(
        userName: 'A',
        userAvatar: '',
        rating: 5,
        date: '',
        comment: '',
      ),
      UserReview(
        userName: 'B',
        userAvatar: '',
        rating: 4,
        date: '',
        comment: '',
      ),
      UserReview(
        userName: 'C',
        userAvatar: '',
        rating: 5,
        date: '',
        comment: '',
      ),
    ];

    expect(reviewRatingRatio(reviews, 5), closeTo(2 / 3, 0.0001));
    expect(reviewRatingRatio(reviews, 4), closeTo(1 / 3, 0.0001));
    expect(reviewRatingRatio(const [], 3), 0);
  });
}
