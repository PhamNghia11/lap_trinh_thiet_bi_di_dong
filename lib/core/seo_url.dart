const flixSiteBaseUrl = 'https://flix-da-movie-m-app.web.app';

String movieSeoSlug(String title) {
  const source =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const target =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  var value = title.toLowerCase();
  for (var index = 0; index < source.length; index++) {
    value = value.replaceAll(source[index], target[index]);
  }
  return value
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String movieSeoPath(String title, String id) {
  final slug = movieSeoSlug(title);
  return '/phim/${slug.isEmpty ? 'phim' : slug}-$id/';
}

String movieSeoUrl(String title, String id) =>
    '$flixSiteBaseUrl${movieSeoPath(title, id)}';
