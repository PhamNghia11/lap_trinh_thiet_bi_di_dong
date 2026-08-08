import '../core/api_client.dart';
import '../models/movie_model.dart';
import 'tmdb_repository.dart';

class UserDataRepository {
  UserDataRepository({ApiClient? client, TmdbRepository? movies})
      : _client = client ?? ApiClient.instance,
        _movies = movies ?? TmdbRepository();

  final ApiClient _client;
  final TmdbRepository _movies;

  Future<List<Movie>> favorites() async {
    final rows = await _client.get('/me/favorites', authenticated: true) as List;
    return Future.wait(rows.map((row) async {
      final movieId = (row as Map)['tmdbMovieId'];
      return (await _movies.detail('$movieId')).copyWith(isFavorite: true);
    }));
  }

  Future<void> addFavorite(String movieId) async {
    await _client.post('/me/favorites/$movieId', authenticated: true);
  }

  Future<void> removeFavorite(String movieId) async {
    await _client.delete('/me/favorites/$movieId', authenticated: true);
  }

  Future<List<Map<String, dynamic>>> history() async {
    final rows = await _client.get('/me/history', authenticated: true) as List;
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> saveHistory(
    String movieId, {
    double progress = 0,
    int watchedSeconds = 0,
    int? durationSeconds,
  }) async {
    await _client.put('/me/history/$movieId', authenticated: true, body: {
      'progress': progress,
      'watchedSeconds': watchedSeconds,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    });
  }

  Future<void> removeHistory(String movieId) async {
    await _client.delete('/me/history/$movieId', authenticated: true);
  }

  Future<void> clearHistory() async {
    await _client.delete('/me/history', authenticated: true);
  }

  Future<List<Map<String, dynamic>>> reviews(String movieId) async {
    final rows = await _client.get('/movies/$movieId/reviews') as List;
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> saveReview(
    String movieId,
    int rating,
    String comment,
    bool hasSpoiler,
  ) async {
    await _client.post('/movies/$movieId/reviews', authenticated: true, body: {
      'rating': rating,
      'comment': comment,
      'hasSpoiler': hasSpoiler,
    });
  }
}
