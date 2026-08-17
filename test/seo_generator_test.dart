import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flix_app/core/seo_url.dart';

import '../tool/seo_generator.dart';

void main() {
  const movie = SeoMovie(
    id: 550,
    title: 'Sàn Đấu Sinh Tử',
    originalTitle: 'Fight Club',
    overview: 'Một câu chuyện về câu lạc bộ chiến đấu & những bí mật.',
    posterPath: '/poster.jpg',
    backdropPath: '/backdrop.jpg',
    releaseDate: '1999-10-15',
    rating: 8.4,
    ratingCount: 32000,
    genreIds: [18, 53],
  );

  test('tạo URL phim không dấu, ổn định và có ID', () {
    expect(movieSeoSlug('Người Nhện: Khởi Đầu Mới'), 'nguoi-nhen-khoi-dau-moi');
    expect(movieSeoSlug('Ngôi nhà cuối cùng'), 'ngoi-nha-cuoi-cung');
    expect(
        movieSeoPath(movie.title, '${movie.id}'), '/phim/san-dau-sinh-tu-550/');
  });

  test('trang phim có canonical, social metadata và Movie JSON-LD', () {
    final html = generateMoviePage(movie, siteUrl: flixSiteBaseUrl);

    expect(html, contains('<html lang="vi">'));
    expect(
        html, contains('rel="canonical" href="$flixSiteBaseUrl${movie.path}"'));
    expect(html, contains('property="og:type" content="video.movie"'));
    expect(html, contains('"@type":"Movie"'));
    expect(html, contains('Một câu chuyện về câu lạc bộ chiến đấu &amp;'));
    expect(html, isNot(contains('<script>alert(')));
  });

  test('dữ liệu JSON-LD không thể đóng thẻ script', () {
    const unsafe = SeoMovie(
      id: 1,
      title: '</script><script>alert(1)</script>',
      originalTitle: '',
      overview: '</script><script>alert(1)</script>',
      posterPath: '',
      backdropPath: '',
      releaseDate: '',
      rating: 0,
      ratingCount: 0,
      genreIds: [],
    );
    final html = generateMoviePage(unsafe, siteUrl: flixSiteBaseUrl);
    expect(html, contains(r'\u003c/script>'));
    expect(RegExp(r'<script>alert\(1\)</script>').hasMatch(html), isFalse);
  });

  test('catalog tạo ItemList hợp lệ và sitemap dùng URL tuyệt đối', () {
    final catalog = generateCatalogPage([movie], siteUrl: flixSiteBaseUrl);
    final sitemap = generateSitemap(
      [movie],
      siteUrl: flixSiteBaseUrl,
      generatedAt: DateTime.utc(2026, 8, 17),
    );

    expect(catalog, contains('"@type":"ItemList"'));
    expect(catalog, contains(movie.path));
    expect(sitemap, contains('$flixSiteBaseUrl${movie.path}'));
    expect(sitemap, contains('<lastmod>2026-08-17</lastmod>'));
    expect(() => jsonDecode(_jsonLd(catalog)), returnsNormally);
  });
}

String _jsonLd(String html) {
  final match = RegExp(
    r'<script type="application/ld\+json">(.*?)</script>',
    dotAll: true,
  ).firstMatch(html);
  return match!.group(1)!;
}
