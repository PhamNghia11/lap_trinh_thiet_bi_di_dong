import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie_model.dart';

class TmdbRepository {
  TmdbRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment(
          'FLIX_API_URL',
          defaultValue: 'http://10.0.2.2:3000/api/v1',
        );

  final http.Client _client;
  final String _baseUrl;

  Future<List<Movie>> popular({int page = 1}) => _movies('/movies/popular?page=$page');
  Future<List<Movie>> trending() => _movies('/movies/trending');

  Future<List<Movie>> _movies(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể tải dữ liệu phim (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    final results = data['results'] as List<dynamic>? ?? const [];
    return results.whereType<Map<String, dynamic>>().map(Movie.fromTmdbJson).toList();
  }
}
