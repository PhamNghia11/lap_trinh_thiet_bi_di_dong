import '../core/api_client.dart';
import '../models/movie_model.dart';

class TmdbRepository {
  TmdbRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<List<Movie>> popular({int page = 1}) =>
      _movies('/movies/popular?page=$page');
  Future<List<Movie>> nowPlaying({int page = 1}) =>
      _movies('/movies/now-playing?page=$page');
  Future<List<Movie>> trending() => _movies('/movies/trending');
  Future<List<Movie>> refreshPopular() =>
      _movies('/movies/popular?page=1', forceRefresh: true);
  Future<List<Movie>> refreshNowPlaying() =>
      _movies('/movies/now-playing?page=1', forceRefresh: true);
  Future<List<Movie>> refreshTrending() =>
      _movies('/movies/trending', forceRefresh: true);
  Future<
      List<
          Movie>> search(String query, {int page = 1, int? year}) => _movies(
      '/movies/search?query=${Uri.encodeQueryComponent(query)}&page=$page${year == null ? '' : '&year=$year'}');

  Future<List<Movie>> discover({
    int page = 1,
    int? genreId,
    int? year,
    String sortBy = 'popularity.desc',
    double? minRating,
  }) {
    final query = <String, String>{
      'page': '$page',
      'sortBy': sortBy,
      if (genreId != null) 'genreId': '$genreId',
      if (year != null) 'year': '$year',
      if (minRating != null) 'minRating': '$minRating',
    };
    return _movies('/movies/discover?${Uri(queryParameters: query).query}');
  }

  Future<List<Movie>> refreshDiscover({
    int page = 1,
    int? genreId,
    String sortBy = 'popularity.desc',
  }) {
    final query = <String, String>{
      'page': '$page',
      'sortBy': sortBy,
      if (genreId != null) 'genreId': '$genreId',
    };
    return _movies(
      '/movies/discover?${Uri(queryParameters: query).query}',
      forceRefresh: true,
    );
  }

  Future<Movie> detail(String id) async {
    final data = Map<String, dynamic>.from(await _client.getCached(
      '/movies/$id',
      ttl: const Duration(minutes: 30),
    ));
    return Movie.fromTmdbJson(data);
  }

  Future<List<Movie>> _movies(String path, {bool forceRefresh = false}) async {
    final data = Map<String, dynamic>.from(
      await _client.getCached(path, forceRefresh: forceRefresh),
    );
    final results = data['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromTmdbJson)
        .toList();
  }
}
