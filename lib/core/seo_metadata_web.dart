import 'dart:convert';

import 'package:web/web.dart' as web;

import 'seo_url.dart';

const _baseTitle = 'FLIX - Khám phá phim, trailer và đánh giá';
const _baseDescription =
    'Khám phá phim đang chiếu, trailer, đánh giá và quản lý danh sách yêu thích cùng FLIX.';
const _baseImage = '$flixSiteBaseUrl/icons/Icon-512.png';

void updateMovieSeoMetadata({
  required String id,
  required String title,
  required String description,
  required String imageUrl,
  required String releaseDate,
  required double rating,
  required int ratingCount,
}) {
  final canonical = movieSeoUrl(title, id);
  final summary = _summary(description, title);
  web.document.title = '$title | FLIX';
  _setMeta('name', 'description', summary);
  _setMeta('name', 'robots', 'index,follow,max-image-preview:large');
  _setMeta('property', 'og:type', 'video.movie');
  _setMeta('property', 'og:site_name', 'FLIX');
  _setMeta('property', 'og:locale', 'vi_VN');
  _setMeta('property', 'og:title', '$title | FLIX');
  _setMeta('property', 'og:description', summary);
  _setMeta('property', 'og:url', canonical);
  _setMeta('property', 'og:image', imageUrl.isEmpty ? _baseImage : imageUrl);
  _setMeta('name', 'twitter:card', 'summary_large_image');
  _setMeta('name', 'twitter:title', '$title | FLIX');
  _setMeta('name', 'twitter:description', summary);
  _setMeta('name', 'twitter:image', imageUrl.isEmpty ? _baseImage : imageUrl);
  _setCanonical(canonical);

  final schema = <String, Object?>{
    '@context': 'https://schema.org',
    '@type': 'Movie',
    'name': title,
    'description': summary,
    'url': canonical,
    if (imageUrl.isNotEmpty) 'image': imageUrl,
    if (releaseDate.isNotEmpty) 'dateCreated': releaseDate,
    if (ratingCount > 0)
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': rating,
        'bestRating': 10,
        'worstRating': 0,
        'ratingCount': ratingCount,
      },
  };
  _setStructuredData(schema);
}

void resetSeoMetadata() {
  web.document.title = _baseTitle;
  _setMeta('name', 'description', _baseDescription);
  _setMeta('name', 'robots', 'index,follow,max-image-preview:large');
  _setMeta('property', 'og:type', 'website');
  _setMeta('property', 'og:title', _baseTitle);
  _setMeta('property', 'og:description', _baseDescription);
  _setMeta('property', 'og:url', '$flixSiteBaseUrl/');
  _setMeta('property', 'og:image', _baseImage);
  _setMeta('name', 'twitter:card', 'summary_large_image');
  _setMeta('name', 'twitter:title', _baseTitle);
  _setMeta('name', 'twitter:description', _baseDescription);
  _setMeta('name', 'twitter:image', _baseImage);
  _setCanonical('$flixSiteBaseUrl/');
  web.document.querySelector('#flix-dynamic-structured-data')?.remove();
}

String _summary(String description, String title) {
  final normalized = description.trim().replaceAll(RegExp(r'\s+'), ' ');
  final value = normalized.isEmpty
      ? 'Xem thông tin, trailer và đánh giá phim $title trên FLIX.'
      : normalized;
  return value.length <= 158 ? value : '${value.substring(0, 155)}...';
}

void _setMeta(String attribute, String key, String content) {
  final selector = 'meta[$attribute="$key"]';
  final element = web.document.querySelector(selector) ?? web.HTMLMetaElement();
  element
    ..setAttribute(attribute, key)
    ..setAttribute('content', content);
  if (element.parentNode == null) web.document.head?.append(element);
}

void _setCanonical(String href) {
  final element = web.document.querySelector('link[rel="canonical"]') ??
      web.HTMLLinkElement();
  element
    ..setAttribute('rel', 'canonical')
    ..setAttribute('href', href);
  if (element.parentNode == null) web.document.head?.append(element);
}

void _setStructuredData(Map<String, Object?> value) {
  final element = web.document.querySelector('#flix-dynamic-structured-data') ??
      web.HTMLScriptElement();
  element
    ..id = 'flix-dynamic-structured-data'
    ..setAttribute('type', 'application/ld+json')
    ..textContent = jsonEncode(value).replaceAll('<', r'\u003c');
  if (element.parentNode == null) web.document.head?.append(element);
}
