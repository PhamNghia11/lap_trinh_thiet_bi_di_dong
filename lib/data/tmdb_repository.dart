import '../core/api_client.dart';
import '../models/movie_model.dart';

class TmdbRepository {
  TmdbRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<List<Movie>> popular({int page = 1}) => _movies('/movies/popular?page=$page');
  Future<List<Movie>> trending() => _movies('/movies/trending');
  Future<List<Movie>> search(String query, {int page = 1}) =>
      _movies('/movies/search?query=${Uri.encodeQueryComponent(query)}&page=$page');

  Future<Movie> detail(String id) async {
    final data = Map<String, dynamic>.from(await _client.get('/movies/$id'));
    return Movie.fromTmdbJson(data);
  }

  Future<List<Movie>> _movies(String path) async {
    final data = Map<String, dynamic>.from(await _client.get(path));
    final results = data['results'] as List<dynamic>? ?? const [];
    return results.whereType<Map<String, dynamic>>().map(Movie.fromTmdbJson).toList();
  }
}
