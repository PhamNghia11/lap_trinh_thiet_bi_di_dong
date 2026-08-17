import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'seo_generator.dart';

Future<void> main(List<String> arguments) async {
  final output = Directory(_argument(arguments, '--output') ?? 'build/web');
  final apiUrl = (_argument(arguments, '--api-url') ??
          Platform.environment['FLIX_API_URL'] ??
          'https://lap-trinh-thiet-bi-di-dong.onrender.com/api/v1')
      .replaceAll(RegExp(r'/+$'), '');
  final siteUrl = (_argument(arguments, '--site-url') ?? flixSiteBaseUrl)
      .replaceAll(RegExp(r'/+$'), '');
  if (!await output.exists()) {
    stderr.writeln('Không tìm thấy thư mục web đã build: ${output.path}');
    exitCode = 2;
    return;
  }

  final payloads = await Future.wait([
    _getJson('$apiUrl/movies/trending'),
    _getJson('$apiUrl/movies/popular?page=1'),
    _getJson('$apiUrl/movies/now-playing?page=1'),
  ]);
  final moviesById = <int, SeoMovie>{};
  for (final payload in payloads) {
    final data = payload['data'] as Map<String, dynamic>? ?? payload;
    final rows = data['results'] as List? ?? const [];
    for (final row in rows.whereType<Map>()) {
      final movie = SeoMovie.fromTmdb(Map<String, dynamic>.from(row));
      if (movie.title.isNotEmpty) {
        moviesById.putIfAbsent(movie.id, () => movie);
      }
    }
  }
  final movies = moviesById.values.take(60).toList(growable: false);
  if (movies.isEmpty) {
    stderr.writeln('API không trả về phim để tạo trang SEO.');
    exitCode = 3;
    return;
  }

  final movieDirectory = Directory('${output.path}/phim');
  if (await movieDirectory.exists()) {
    await movieDirectory.delete(recursive: true);
  }
  await movieDirectory.create(recursive: true);
  await File('${movieDirectory.path}/index.html').writeAsString(
    generateCatalogPage(movies, siteUrl: siteUrl),
  );
  for (final movie in movies) {
    final directory = Directory('${output.path}${movie.path}');
    await directory.create(recursive: true);
    await File('${directory.path}/index.html').writeAsString(
      generateMoviePage(movie, siteUrl: siteUrl),
    );
  }
  await File('${output.path}/sitemap.xml').writeAsString(
    generateSitemap(movies, siteUrl: siteUrl, generatedAt: DateTime.now()),
  );
  stdout
      .writeln('Đã tạo ${movies.length} trang phim SEO trong ${output.path}.');
}

String? _argument(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  return index >= 0 && index + 1 < arguments.length
      ? arguments[index + 1]
      : null;
}

Future<Map<String, dynamic>> _getJson(String url) async {
  Object? lastError;
  for (var attempt = 1; attempt <= 3; attempt++) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers
          .set(HttpHeaders.userAgentHeader, 'FLIX-SEO-Generator/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 45));
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $body',
            uri: Uri.parse(url));
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('JSON không phải object');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      lastError = error;
      if (attempt < 3) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    } finally {
      client.close(force: true);
    }
  }
  throw StateError('Không tải được $url sau 3 lần: $lastError');
}
