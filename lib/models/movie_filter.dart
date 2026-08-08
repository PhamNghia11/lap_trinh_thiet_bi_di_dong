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

  bool get isActive => genreId != null || year != null || minRating > 0 || sortBy != 'popularity.desc';
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
