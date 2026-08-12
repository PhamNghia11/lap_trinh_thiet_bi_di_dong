import 'package:flix_app/core/media_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rewrites TMDB image URLs only for Web', () {
    expect(
      resolveImageUrl(
        'https://image.tmdb.org/t/p/w500/poster.jpg',
        isWeb: true,
        apiBaseUrl: 'https://api.example.com/api/v1',
      ),
      'https://api.example.com/api/v1/movies/media/tmdb/w500/poster.jpg',
    );
    expect(
      resolveImageUrl(
        'https://image.tmdb.org/t/p/w500/poster.jpg',
        isWeb: false,
        apiBaseUrl: 'https://api.example.com/api/v1',
      ),
      'https://image.tmdb.org/t/p/w500/poster.jpg',
    );
  });

  test('leaves non-TMDB and malformed image URLs unchanged', () {
    expect(resolveImageUrl('https://example.com/poster.jpg', isWeb: true),
        'https://example.com/poster.jpg');
    expect(
        resolveImageUrl('https://image.tmdb.org/t/p/original/poster.jpg',
            isWeb: true),
        'https://image.tmdb.org/t/p/original/poster.jpg');
  });
}
