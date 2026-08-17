import 'dart:convert';

import 'package:flix_app/core/seo_url.dart';
export 'package:flix_app/core/seo_url.dart' show flixSiteBaseUrl;

const tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

const _genreNames = <int, String>{
  12: 'Phiêu lưu',
  14: 'Giả tưởng',
  16: 'Hoạt hình',
  18: 'Chính kịch',
  27: 'Kinh dị',
  28: 'Hành động',
  35: 'Hài',
  36: 'Lịch sử',
  37: 'Miền Tây',
  53: 'Gây cấn',
  80: 'Tội phạm',
  99: 'Tài liệu',
  878: 'Khoa học viễn tưởng',
  9648: 'Bí ẩn',
  10402: 'Âm nhạc',
  10749: 'Lãng mạn',
  10751: 'Gia đình',
  10752: 'Chiến tranh',
  10770: 'Phim truyền hình',
};

class SeoMovie {
  const SeoMovie({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.rating,
    required this.ratingCount,
    required this.genreIds,
  });

  factory SeoMovie.fromTmdb(Map<String, dynamic> json) {
    return SeoMovie(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String? ?? '').trim(),
      originalTitle: (json['original_title'] as String? ?? '').trim(),
      overview: (json['overview'] as String? ?? '').trim(),
      posterPath: (json['poster_path'] as String? ?? '').trim(),
      backdropPath: (json['backdrop_path'] as String? ?? '').trim(),
      releaseDate: (json['release_date'] as String? ?? '').trim(),
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      genreIds: (json['genre_ids'] as List? ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(),
    );
  }

  final int id;
  final String title;
  final String originalTitle;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final String releaseDate;
  final double rating;
  final int ratingCount;
  final List<int> genreIds;

  String get path => movieSeoPath(title, '$id');
  String canonical(String siteUrl) => '$siteUrl$path';
  String get posterUrl =>
      posterPath.isEmpty ? '' : '$tmdbImageBaseUrl/w500$posterPath';
  String get socialImageUrl {
    final path = backdropPath.isNotEmpty ? backdropPath : posterPath;
    return path.isEmpty ? '' : '$tmdbImageBaseUrl/w1280$path';
  }

  String get description {
    final fallback =
        'Xem thông tin, trailer và đánh giá phim $title trên FLIX.';
    final normalized = (overview.isEmpty ? fallback : overview)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized.length <= 158
        ? normalized
        : '${normalized.substring(0, 155)}...';
  }

  List<String> get genres => genreIds
      .map((id) => _genreNames[id])
      .whereType<String>()
      .toList(growable: false);
}

String generateMoviePage(SeoMovie movie, {required String siteUrl}) {
  final canonical = movie.canonical(siteUrl);
  final title = '${movie.title} | FLIX';
  final image = movie.socialImageUrl.isEmpty
      ? '$siteUrl/icons/Icon-512.png'
      : movie.socialImageUrl;
  final year = movie.releaseDate.length >= 4
      ? movie.releaseDate.substring(0, 4)
      : 'Đang cập nhật';
  final genres = movie.genres;
  final schema = <String, Object?>{
    '@context': 'https://schema.org',
    '@type': 'Movie',
    'name': movie.title,
    'url': canonical,
    'description': movie.description,
    'image': image,
    if (movie.releaseDate.isNotEmpty) 'dateCreated': movie.releaseDate,
    if (genres.isNotEmpty) 'genre': genres,
    if (movie.ratingCount > 0)
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': movie.rating,
        'bestRating': 10,
        'worstRating': 0,
        'ratingCount': movie.ratingCount,
      },
  };
  final jsonLd = _safeJson(schema);
  final openAppUrl = '$siteUrl/?movie=${movie.id}';
  final poster = movie.posterUrl.isEmpty
      ? '<div class="poster placeholder">FLIX</div>'
      : '<img class="poster" src="${_html(movie.posterUrl)}" '
          'alt="Poster phim ${_html(movie.title)}" width="500" height="750">';
  final originalTitle = movie.originalTitle.isNotEmpty &&
          movie.originalTitle.toLowerCase() != movie.title.toLowerCase()
      ? '<p class="original">${_html(movie.originalTitle)}</p>'
      : '';
  final genreMarkup = genres.isEmpty
      ? ''
      : '<p class="genres">${genres.map(_html).join(' · ')}</p>';
  final rating = movie.ratingCount == 0
      ? 'Chưa có đánh giá'
      : '${movie.rating.toStringAsFixed(1)}/10 · ${movie.ratingCount} lượt đánh giá';

  return '''<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="${_html(movie.description)}">
  <meta name="robots" content="index,follow,max-image-preview:large">
  <meta name="theme-color" content="#080506">
  <link rel="canonical" href="${_html(canonical)}">
  <link rel="icon" type="image/png" href="/favicon.png">
  <meta property="og:type" content="video.movie">
  <meta property="og:site_name" content="FLIX">
  <meta property="og:locale" content="vi_VN">
  <meta property="og:title" content="${_html(title)}">
  <meta property="og:description" content="${_html(movie.description)}">
  <meta property="og:url" content="${_html(canonical)}">
  <meta property="og:image" content="${_html(image)}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${_html(title)}">
  <meta name="twitter:description" content="${_html(movie.description)}">
  <meta name="twitter:image" content="${_html(image)}">
  <title>${_html(title)}</title>
  <script type="application/ld+json">$jsonLd</script>
  ${_styles()}
</head>
<body>
  <header><a class="brand" href="/">FLIX</a><a href="/phim/">Danh mục phim</a></header>
  <main class="movie">
    $poster
    <article>
      <p class="eyebrow">PHIM · ${_html(year)}</p>
      <h1>${_html(movie.title)}</h1>
      $originalTitle
      $genreMarkup
      <p class="rating">★ ${_html(rating)}</p>
      <p class="overview">${_html(movie.overview.isEmpty ? movie.description : movie.overview)}</p>
      <a class="cta" href="${_html(openAppUrl)}">Mở phim trong ứng dụng FLIX</a>
      <p class="attribution">Dữ liệu phim do <a href="https://www.themoviedb.org/movie/${movie.id}" rel="nofollow noopener">TMDB</a> cung cấp.</p>
    </article>
  </main>
</body>
</html>
''';
}

String generateCatalogPage(List<SeoMovie> movies, {required String siteUrl}) {
  final canonical = '$siteUrl/phim/';
  final schema = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    'name': 'Phim nổi bật trên FLIX',
    'itemListElement': [
      for (final entry in movies.indexed)
        {
          '@type': 'ListItem',
          'position': entry.$1 + 1,
          'item': {
            '@type': 'Movie',
            'name': entry.$2.title,
            'url': entry.$2.canonical(siteUrl),
            if (entry.$2.posterUrl.isNotEmpty) 'image': entry.$2.posterUrl,
            if (entry.$2.releaseDate.isNotEmpty)
              'dateCreated': entry.$2.releaseDate,
          },
        },
    ],
  };
  final cards = movies.map((movie) {
    final poster = movie.posterUrl.isEmpty
        ? '<div class="card-poster placeholder">FLIX</div>'
        : '<img class="card-poster" src="${_html(movie.posterUrl)}" '
            'alt="Poster phim ${_html(movie.title)}" width="300" height="450" loading="lazy">';
    return '''<article class="card">
      <a href="${_html(movie.path)}">$poster</a>
      <div><h2><a href="${_html(movie.path)}">${_html(movie.title)}</a></h2>
      <p>${_html(movie.description)}</p></div>
    </article>''';
  }).join('\n');

  return '''<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="Danh sách phim đang chiếu, thịnh hành và phổ biến được cập nhật trên FLIX.">
  <meta name="robots" content="index,follow,max-image-preview:large">
  <meta name="theme-color" content="#080506">
  <link rel="canonical" href="$canonical">
  <link rel="icon" type="image/png" href="/favicon.png">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="FLIX">
  <meta property="og:title" content="Danh mục phim | FLIX">
  <meta property="og:description" content="Danh sách phim đang chiếu, thịnh hành và phổ biến được cập nhật trên FLIX.">
  <meta property="og:url" content="$canonical">
  <meta property="og:image" content="$siteUrl/icons/Icon-512.png">
  <title>Danh mục phim | FLIX</title>
  <script type="application/ld+json">${_safeJson(schema)}</script>
  ${_styles()}
</head>
<body>
  <header><a class="brand" href="/">FLIX</a><a href="/">Mở ứng dụng</a></header>
  <main class="catalog"><p class="eyebrow">DANH MỤC CÓ THỂ LẬP CHỈ MỤC</p><h1>Phim nổi bật trên FLIX</h1><div class="grid">$cards</div></main>
</body>
</html>
''';
}

String generateSitemap(
  List<SeoMovie> movies, {
  required String siteUrl,
  required DateTime generatedAt,
}) {
  final lastmod = generatedAt.toUtc().toIso8601String().split('T').first;
  final urls = <String>[
    '$siteUrl/',
    '$siteUrl/phim/',
    '$siteUrl/privacy.html',
    '$siteUrl/terms.html',
    '$siteUrl/account-deletion.html',
    ...movies.map((movie) => movie.canonical(siteUrl)),
  ];
  return '''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map((url) => '  <url><loc>${_xml(url)}</loc><lastmod>$lastmod</lastmod></url>').join('\n')}
</urlset>
''';
}

String _safeJson(Object? value) => jsonEncode(value).replaceAll('<', r'\u003c');

String _html(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

String _xml(String value) => _html(value).replaceAll('&#39;', '&apos;');

String _styles() => '''<style>
  :root { color-scheme: dark; font-family: Inter, Arial, sans-serif; background: #080506; color: #f8f5f6; }
  * { box-sizing: border-box; } body { margin: 0; background: #080506; }
  a { color: inherit; } header { height: 72px; padding: 0 max(24px, calc((100% - 1180px)/2)); display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #2c2527; }
  header a { text-decoration: none; } .brand { color: #ef101f; font-size: 28px; font-weight: 900; letter-spacing: 2px; }
  .movie, .catalog { width: min(1180px, calc(100% - 40px)); margin: 0 auto; padding: 56px 0 80px; }
  .movie { display: grid; grid-template-columns: minmax(220px, 340px) 1fr; gap: clamp(32px, 6vw, 76px); align-items: start; }
  .poster { width: 100%; aspect-ratio: 2/3; object-fit: cover; border-radius: 20px; background: #171214; box-shadow: 0 22px 70px #0009; }
  .placeholder { display: grid; place-items: center; color: #ef101f; font-size: 36px; font-weight: 900; }
  .eyebrow { color: #ef101f; font-weight: 800; letter-spacing: .12em; } h1 { font-size: clamp(38px, 6vw, 76px); line-height: 1.02; margin: 12px 0 14px; }
  .original, .genres, .attribution { color: #aaa0a3; } .rating { color: #ffd166; font-weight: 700; } .overview { max-width: 720px; color: #d5ced0; font-size: 18px; line-height: 1.75; }
  .cta { display: inline-block; margin-top: 22px; padding: 14px 22px; border-radius: 999px; background: #ef101f; color: white; text-decoration: none; font-weight: 800; }
  .attribution { margin-top: 32px; font-size: 13px; } .catalog > h1 { margin-bottom: 40px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 22px; }
  .card { overflow: hidden; border: 1px solid #2c2527; border-radius: 18px; background: #151113; }
  .card-poster { width: 100%; aspect-ratio: 2/3; object-fit: cover; display: block; } .card > div { padding: 18px; }
  .card h2 { margin: 0 0 9px; font-size: 19px; } .card h2 a { text-decoration: none; } .card p { color: #aaa0a3; line-height: 1.55; margin: 0; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
  @media (max-width: 720px) { .movie { grid-template-columns: 1fr; padding-top: 28px; } .poster { width: min(100%, 360px); margin: 0 auto; } h1 { font-size: 42px; } }
</style>''';
