import 'package:flutter/foundation.dart';

import 'api_client.dart';

String resolveImageUrl(
  String url, {
  bool? isWeb,
  String? apiBaseUrl,
}) {
  if (url.isEmpty || !(isWeb ?? kIsWeb)) return url;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'image.tmdb.org') return url;
  final parts = uri.pathSegments;
  if (parts.length != 4 || parts[0] != 't' || parts[1] != 'p') return url;
  final size = parts[2];
  final file = parts[3];
  if (file.isEmpty ||
      !RegExp(r'^w(?:45|92|154|185|300|342|500|780|1280)$').hasMatch(size)) {
    return url;
  }
  final base = apiBaseUrl ?? ApiClient.instance.baseUrl;
  return '$base/movies/media/tmdb/$size/$file';
}
