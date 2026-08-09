import '../core/api_client.dart';
import '../models/movie_model.dart';

class TmdbRepository {
  TmdbRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<List<Movie>> popular({int page = 1}) =>
      _movies('/movies/popular?page=$page');
  Future<List<Movie>> trending() => _movies('/movies/trending');
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

  Future<Movie> detail(String id) async {
    final data = Map<String, dynamic>.from(await _client.getCached(
      '/movies/$id',
      ttl: const Duration(minutes: 30),
    ));
    return Movie.fromTmdbJson(data);
  }

  Future<List<Movie>> _movies(String path) async {
    final data = Map<String, dynamic>.from(await _client.getCached(path));
    final results = data['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromTmdbJson)
        .toList();
  }
}
