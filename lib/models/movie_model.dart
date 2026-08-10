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

  Map<String, dynamic> toJson() =>
      {'name': name, 'role': role, 'avatarUrl': avatarUrl, 'bio': bio};

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
      );
}

/// Class đại diện cho đánh giá của người xem
class UserReview {
  final String userName;
  final String userAvatar;
  final double rating;
  final String date;
  final String comment;
  final String? imageUrl;

  const UserReview({
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.date,
    required this.comment,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'date': date,
        'comment': comment,
        'imageUrl': imageUrl,
      };

  factory UserReview.fromJson(Map<String, dynamic> json) => UserReview(
        userName: json['userName'] as String? ?? '',
        userAvatar: json['userAvatar'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        date: json['date'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
      );
}

double reviewRatingRatio(Iterable<UserReview> reviews, int stars) {
  final items = reviews.toList(growable: false);
  if (items.isEmpty) return 0;
  final count = items.where((review) => review.rating.round() == stars).length;
  return count / items.length;
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
  final String backdropUrl;
  final String originalTitle;
  final String tagline;
  final String status;
  final int budget;
  final int revenue;
  final double popularity;
  final List<String> languages;
  final List<String> writers;
  final List<String> producers;
  final List<String> productionCompanies;
  final List<String> keywords;
  final List<String> watchProviders;
  final String? imdbId;
  final String? homepage;
  final String collectionName;
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
    this.backdropUrl = '',
    this.originalTitle = '',
    this.tagline = '',
    this.status = 'Đang cập nhật',
    this.budget = 0,
    this.revenue = 0,
    this.popularity = 0,
    this.languages = const [],
    this.writers = const [],
    this.producers = const [],
    this.productionCompanies = const [],
    this.keywords = const [],
    this.watchProviders = const [],
    this.imdbId,
    this.homepage,
    this.collectionName = '',
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
    final backdrop = json['backdrop_path'] as String?;
    final spokenLanguages = _names(json['spoken_languages']);
    final productionCompanies = _names(json['production_companies']);
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
    final writers = crew
        .where((person) =>
            person['department'] == 'Writing' ||
            person['job'] == 'Writer' ||
            person['job'] == 'Screenplay')
        .map((person) => person['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .take(4)
        .toList();
    final producers = crew
        .where((person) =>
            person['job'] == 'Producer' ||
            person['job'] == 'Executive Producer')
        .map((person) => person['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .take(4)
        .toList();
    final videos = (json['videos'] as Map<String, dynamic>?)?['results']
            as List<dynamic>? ??
        const [];
    final trailer = videos
        .whereType<Map<String, dynamic>>()
        .where(
            (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer')
        .firstOrNull;
    final tmdbReviews = _tmdbReviews(json['reviews']);
    return Movie(
      id: '${json['id'] ?? ''}',
      title: (json['title'] as String?) ??
          (json['name'] as String?) ??
          'Chưa có tên',
      genres: genreNames,
      year: int.tryParse(releaseDate.split('-').first) ?? 0,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      duration:
          json['runtime'] == null ? 'Đang cập nhật' : '${json['runtime']} phút',
      description: (json['overview'] as String?) ?? 'Chưa có mô tả.',
      imageUrl: poster == null ? '' : 'https://image.tmdb.org/t/p/w500$poster',
      backdropUrl:
          backdrop == null ? '' : 'https://image.tmdb.org/t/p/w1280$backdrop',
      originalTitle: (json['original_title'] as String?) ?? '',
      tagline: (json['tagline'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'Đang cập nhật',
      budget: (json['budget'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      languages: spokenLanguages,
      writers: writers,
      producers: producers,
      productionCompanies: productionCompanies,
      keywords: _keywordNames(json['keywords']),
      watchProviders: _watchProviderNames(json['watch/providers']),
      imdbId: json['imdb_id'] as String?,
      homepage: json['homepage'] as String?,
      collectionName: (json['belongs_to_collection']
              as Map<String, dynamic>?)?['name'] as String? ??
          '',
      releaseDate: releaseDate,
      director: director ?? 'Đang cập nhật',
      languageInfo: spokenLanguages.isEmpty
          ? 'Đang cập nhật'
          : spokenLanguages.join(', '),
      ageRating: _certification(json) ?? 'Chưa phân loại',
      country: (json['production_countries'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((country) => country['name'] as String?)
              .whereType<String>()
              .firstOrNull ??
          'Đang cập nhật',
      castList: cast,
      reviews: tmdbReviews,
      trailerKey: trailer?['key'] as String?,
    );
  }

  static List<UserReview> _tmdbReviews(dynamic value) {
    final results =
        (value as Map<String, dynamic>?)?['results'] as List<dynamic>?;
    return (results ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((review) {
          final details =
              review['author_details'] as Map<String, dynamic>? ?? const {};
          final avatar = details['avatar_path'] as String?;
          final avatarUrl = avatar == null
              ? ''
              : avatar.startsWith('/https')
                  ? avatar.substring(1)
                  : 'https://image.tmdb.org/t/p/w185$avatar';
          final author = review['author'] as String? ?? 'Người dùng TMDB';
          return UserReview(
            userName: '$author (TMDB)',
            userAvatar: avatarUrl,
            rating: ((details['rating'] as num?)?.toDouble() ?? 0) / 2,
            date: (review['created_at'] as String? ?? '').split('T').first,
            comment: review['content'] as String? ?? '',
          );
        })
        .where((review) => review.comment.trim().isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'genres': genres,
        'year': year,
        'rating': rating,
        'ratingCount': ratingCount,
        'duration': duration,
        'description': description,
        'imageUrl': imageUrl,
        'backdropUrl': backdropUrl,
        'originalTitle': originalTitle,
        'tagline': tagline,
        'status': status,
        'budget': budget,
        'revenue': revenue,
        'popularity': popularity,
        'languages': languages,
        'writers': writers,
        'producers': producers,
        'productionCompanies': productionCompanies,
        'keywords': keywords,
        'watchProviders': watchProviders,
        'imdbId': imdbId,
        'homepage': homepage,
        'collectionName': collectionName,
        'isFavorite': isFavorite,
        'watchProgress': watchProgress,
        'badge': badge,
        'quality': quality,
        'ageRating': ageRating,
        'languageInfo': languageInfo,
        'director': director,
        'country': country,
        'releaseDate': releaseDate,
        'castList': castList.map((item) => item.toJson()).toList(),
        'reviews': reviews.map((item) => item.toJson()).toList(),
        'trailerKey': trailerKey,
      };

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        genres: (json['genres'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(),
        year: (json['year'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        duration: json['duration'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        backdropUrl: json['backdropUrl'] as String? ?? '',
        originalTitle: json['originalTitle'] as String? ?? '',
        tagline: json['tagline'] as String? ?? '',
        status: json['status'] as String? ?? 'Đang cập nhật',
        budget: (json['budget'] as num?)?.toInt() ?? 0,
        revenue: (json['revenue'] as num?)?.toInt() ?? 0,
        popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
        languages: (json['languages'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(),
        writers: (json['writers'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(),
        producers: (json['producers'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(),
        productionCompanies:
            (json['productionCompanies'] as List<dynamic>? ?? const [])
                .map((item) => '$item')
                .toList(),
        keywords: (json['keywords'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(),
        watchProviders: (json['watchProviders'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(),
        imdbId: json['imdbId'] as String?,
        homepage: json['homepage'] as String?,
        collectionName: json['collectionName'] as String? ?? '',
        isFavorite: json['isFavorite'] as bool? ?? false,
        watchProgress: (json['watchProgress'] as num?)?.toDouble() ?? 0,
        badge: json['badge'] as String?,
        quality: json['quality'] as String? ?? '4K Ultra HD',
        ageRating: json['ageRating'] as String? ?? 'T16',
        languageInfo: json['languageInfo'] as String? ?? '',
        director: json['director'] as String? ?? '',
        country: json['country'] as String? ?? '',
        releaseDate: json['releaseDate'] as String? ?? '',
        castList: (json['castList'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => CastMember.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        reviews: (json['reviews'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => UserReview.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        trailerKey: json['trailerKey'] as String?,
      );

  static List<String> _names(
          dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) =>
              item['name'] as String? ?? item['provider_name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

  static List<String> _keywordNames(dynamic value) {
    final data = value as Map<String, dynamic>?;
    return _names(data?['keywords'] ?? data?['results']);
  }

  static List<String> _watchProviderNames(dynamic value) {
    final results =
        (value as Map<String, dynamic>?)?['results'] as Map<String, dynamic>?;
    final region = results?['VN'] as Map<String, dynamic>? ??
        results?['US'] as Map<String, dynamic>?;
    if (region == null) return const [];
    final providers = <String>{};
    for (final key in ['flatrate', 'rent', 'buy']) {
      providers.addAll(_names(region[key]));
    }
    return providers.take(6).toList();
  }

  static String? _certification(Map<String, dynamic> json) {
    final results = (json['release_dates'] as Map<String, dynamic>?)?['results']
            as List<dynamic>? ??
        const [];
    for (final countryCode in ['VN', 'US']) {
      final country = results.whereType<Map<String, dynamic>>().where(
            (item) => item['iso_3166_1'] == countryCode,
          );
      if (country.isEmpty) continue;
      final dates =
          country.first['release_dates'] as List<dynamic>? ?? const [];
      final certification = dates
          .whereType<Map<String, dynamic>>()
          .map((item) => item['certification'] as String? ?? '')
          .where((value) => value.isNotEmpty)
          .firstOrNull;
      if (certification != null) return certification;
    }
    return null;
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
    String? backdropUrl,
    String? originalTitle,
    String? tagline,
    String? status,
    int? budget,
    int? revenue,
    double? popularity,
    List<String>? languages,
    List<String>? writers,
    List<String>? producers,
    List<String>? productionCompanies,
    List<String>? keywords,
    List<String>? watchProviders,
    String? imdbId,
    String? homepage,
    String? collectionName,
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
      backdropUrl: backdropUrl ?? this.backdropUrl,
      originalTitle: originalTitle ?? this.originalTitle,
      tagline: tagline ?? this.tagline,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      revenue: revenue ?? this.revenue,
      popularity: popularity ?? this.popularity,
      languages: languages ?? this.languages,
      writers: writers ?? this.writers,
      producers: producers ?? this.producers,
      productionCompanies: productionCompanies ?? this.productionCompanies,
      keywords: keywords ?? this.keywords,
      watchProviders: watchProviders ?? this.watchProviders,
      imdbId: imdbId ?? this.imdbId,
      homepage: homepage ?? this.homepage,
      collectionName: collectionName ?? this.collectionName,
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
