class MovieFilter {
  const MovieFilter({
    this.genreId,
    this.genreLabel = 'Tất cả',
    this.year,
    this.sortBy = 'popularity.desc',
    this.sortLabel = 'Phổ biến nhất',
    this.minRating = 0,
  });

  final int? genreId;
  final String genreLabel;
  final int? year;
  final String sortBy;
  final String sortLabel;
  final double minRating;

  bool get isActive =>
      genreId != null ||
      year != null ||
      minRating > 0 ||
      sortBy != 'popularity.desc';

  Map<String, dynamic> toJson() => {
        'genreId': genreId,
        'genreLabel': genreLabel,
        'year': year,
        'sortBy': sortBy,
        'sortLabel': sortLabel,
        'minRating': minRating,
      };

  factory MovieFilter.fromJson(Map<String, dynamic> json) => MovieFilter(
        genreId: (json['genreId'] as num?)?.toInt(),
        genreLabel: json['genreLabel'] as String? ?? 'Táº¥t cáº£',
        year: (json['year'] as num?)?.toInt(),
        sortBy: json['sortBy'] as String? ?? 'popularity.desc',
        sortLabel: json['sortLabel'] as String? ?? 'Phá»• biáº¿n nháº¥t',
        minRating: (json['minRating'] as num?)?.toDouble() ?? 0,
      );
}

const movieGenreOptions = <String, int?>{
  'Tất cả': null,
  'Hành Động': 28,
  'Phiêu Lưu': 12,
  'Hoạt Hình': 16,
  'Hài Hước': 35,
  'Tội Phạm': 80,
  'Chính Kịch': 18,
  'Kỳ Ảo': 14,
  'Kinh Dị': 27,
  'Bí Ẩn': 9648,
  'Tình Cảm': 10749,
  'Viễn Tưởng': 878,
  'Giật Gân': 53,
};
