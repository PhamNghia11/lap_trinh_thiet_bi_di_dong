// lib/models/movie_model.dart

/// Class đại diện cho một diễn viên và vai diễn trong phim
class CastMember {
  final String name;
  final String role;
  final String avatarUrl;
  final String bio;

  const CastMember({
    required this.name,
    required this.role,
    required this.avatarUrl,
    this.bio =
        'Diễn viên điện ảnh nổi tiếng với nhiều vai diễn ấn tượng trong các phim bom tấn.',
  });
}

/// Class đại diện cho đánh giá của người xem
class UserReview {
  final String userName;
  final String userAvatar;
  final double rating;
  final String date;
  final String comment;

  const UserReview({
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.date,
    required this.comment,
  });
}

/// Model class đại diện cho một bộ phim trong ứng dụng FLIX.
class Movie {
  final String id;
  final String title;
  final List<String> genres;
  final int year;
  final double rating;
  final int ratingCount;
  final String duration;
  final String description;
  final String imageUrl;
  final bool isFavorite;
  final double watchProgress; // 0.0 -> 1.0, dùng cho History
  final String? badge; // "HD", "Mới", "Top 10"

  // Chi tiết nâng cao cho Movie Detail
  final String quality; // "4K Ultra HD", "HD"
  final String ageRating; // "T16", "T18", "P"
  final String languageInfo; // "Việt sub / Lồng tiếng"
  final String director;
  final String country;
  final String releaseDate;
  final List<CastMember> castList;
  final List<UserReview> reviews;
  final String? trailerKey;

  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.year,
    required this.rating,
    this.ratingCount = 0,
    required this.duration,
    required this.description,
    required this.imageUrl,
    this.isFavorite = false,
    this.watchProgress = 0.0,
    this.badge,
    this.quality = '4K Ultra HD',
    this.ageRating = 'T16',
    this.languageInfo = 'Việt sub / Lồng tiếng',
    this.director = 'Đang cập nhật',
    this.country = 'Đang cập nhật',
    this.releaseDate = 'Đang cập nhật',
    this.castList = const [],
    this.reviews = const [
      UserReview(
        userName: 'Trần Minh Đức',
        userAvatar: 'https://picsum.photos/id/1012/100/100',
        rating: 5.0,
        date: 'Hôm qua',
        comment:
            'Siêu phẩm điện ảnh của năm! Hình ảnh và âm thanh đỉnh cao, quay phim quá mãn nhãn.',
      ),
      UserReview(
        userName: 'Nguyễn Thảo Nhi',
        userAvatar: 'https://picsum.photos/id/1027/100/100',
        rating: 4.8,
        date: '3 ngày trước',
        comment:
            'Diễn xuất của Timothée Chalamet và Zendaya vô cùng xuất sắc. Rất đáng tiền ra rạp xem!',
      ),
    ],
    this.trailerKey,
  });

  /// Trả về chuỗi thể loại nối bằng dấu " • "
  factory Movie.fromTmdbJson(Map<String, dynamic> json) {
    final releaseDate = (json['release_date'] as String?) ?? '';
    final poster = json['poster_path'] as String?;
    final genreNames = (json['genres'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((genre) => genre['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        (json['genre_ids'] as List<dynamic>?)
            ?.whereType<num>()
            .map((id) => _tmdbGenreNames[id.toInt()])
            .whereType<String>()
            .toList() ??
        const <String>[];
    final credits = json['credits'] as Map<String, dynamic>?;
    final cast = (credits?['cast'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .take(12)
        .map((person) => CastMember(
              name: person['name'] as String? ?? 'Đang cập nhật',
              role: person['character'] as String? ?? '',
              avatarUrl: person['profile_path'] == null
                  ? ''
                  : 'https://image.tmdb.org/t/p/w185${person['profile_path']}',
            ))
        .toList();
    final crew = (credits?['crew'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final director = crew
        .where((person) => person['job'] == 'Director')
        .map((person) => person['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .firstOrNull;
    final videos =
        (json['videos'] as Map<String, dynamic>?)?['results'] as List<dynamic>? ??
            const [];
    final trailer = videos
        .whereType<Map<String, dynamic>>()
        .where((video) => video['site'] == 'YouTube' && video['type'] == 'Trailer')
        .firstOrNull;
    return Movie(
      id: '${json['id'] ?? ''}',
      title: (json['title'] as String?) ?? (json['name'] as String?) ?? 'Chưa có tên',
      genres: genreNames,
      year: int.tryParse(releaseDate.split('-').first) ?? 0,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      duration: json['runtime'] == null ? 'Đang cập nhật' : '${json['runtime']} phút',
      description: (json['overview'] as String?) ?? 'Chưa có mô tả.',
      imageUrl: poster == null ? '' : 'https://image.tmdb.org/t/p/w500$poster',
      releaseDate: releaseDate,
      director: director ?? 'Đang cập nhật',
      country: (json['production_countries'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((country) => country['name'] as String?)
              .whereType<String>()
              .firstOrNull ??
          'Đang cập nhật',
      castList: cast,
      trailerKey: trailer?['key'] as String?,
    );
  }

  static const Map<int, String> _tmdbGenreNames = {
    28: 'Hành Động',
    12: 'Phiêu Lưu',
    16: 'Hoạt Hình',
    35: 'Hài Hước',
    80: 'Tội Phạm',
    18: 'Chính Kịch',
    14: 'Kỳ Ảo',
    27: 'Kinh Dị',
    9648: 'Bí Ẩn',
    10749: 'Tình Cảm',
    878: 'Viễn Tưởng',
    53: 'Giật Gân',
    10752: 'Chiến Tranh',
  };

  String get genreText => genres.join(' • ');

  /// Trả về chuỗi thông tin tóm tắt: "2024 • 2h 46m"
  String get infoText => '$year • $duration';

  /// Trả về chuỗi đánh giá: "4.8 (12.5k đánh giá)"
  String get ratingText {
    if (ratingCount > 0) {
      final countStr = ratingCount >= 1000
          ? '${(ratingCount / 1000).toStringAsFixed(1)}k'
          : '$ratingCount';
      return '$rating ($countStr đánh giá)';
    }
    return '$rating';
  }

  /// Copy with method để tạo bản sao có thay đổi
  Movie copyWith({
    String? id,
    String? title,
    List<String>? genres,
    int? year,
    double? rating,
    int? ratingCount,
    String? duration,
    String? description,
    String? imageUrl,
    bool? isFavorite,
    double? watchProgress,
    String? badge,
    String? quality,
    String? ageRating,
    String? languageInfo,
    String? director,
    String? country,
    String? releaseDate,
    List<CastMember>? castList,
    List<UserReview>? reviews,
    String? trailerKey,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      genres: genres ?? this.genres,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      watchProgress: watchProgress ?? this.watchProgress,
      badge: badge ?? this.badge,
      quality: quality ?? this.quality,
      ageRating: ageRating ?? this.ageRating,
      languageInfo: languageInfo ?? this.languageInfo,
      director: director ?? this.director,
      country: country ?? this.country,
      releaseDate: releaseDate ?? this.releaseDate,
      castList: castList ?? this.castList,
      reviews: reviews ?? this.reviews,
      trailerKey: trailerKey ?? this.trailerKey,
    );
  }
}
