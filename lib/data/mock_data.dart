// lib/data/mock_data.dart

import '../models/movie_model.dart';

/// Danh sách phim mẫu dùng chung cho toàn bộ ứng dụng.
/// Thay thế cho việc hardcode `Map<String, dynamic>` rải rác ở từng screen.
const List<Movie> mockMovies = [
  Movie(
    id: 'dune-2',
    title: 'Dune: Part Two',
    genres: ['Hành Động', 'Viễn Tưởng', 'Phiêu Lưu'],
    year: 2024,
    rating: 4.8,
    ratingCount: 12500,
    duration: '2h 46m',
    description:
        'Hành trình thần thoại của Paul Atreides khi anh liên kết với Chani và người Fremen '
        'trên con đường trả thù những kẻ âm mưu hủy hoại gia đình mình. Đứng trước sự lựa chọn '
        'giữa tình yêu của cuộc đời và số phận của vũ trụ, anh phải nỗ lực ngăn chặn một tương lai tồi tệ.',
    imageUrl: 'https://picsum.photos/id/1015/800/1200',
    director: 'Denis Villeneuve',
    country: 'Mỹ (USA)',
    releaseDate: '01/03/2024',
    castList: [
      CastMember(
          name: 'Timothée Chalamet',
          role: 'Paul Atreides',
          avatarUrl: 'https://picsum.photos/id/1062/200/200'),
      CastMember(
          name: 'Zendaya',
          role: 'Chani',
          avatarUrl: 'https://picsum.photos/id/1063/200/200'),
      CastMember(
          name: 'Rebecca Ferguson',
          role: 'Lady Jessica',
          avatarUrl: 'https://picsum.photos/id/1064/200/200'),
      CastMember(
          name: 'Javier Bardem',
          role: 'Stilgar',
          avatarUrl: 'https://picsum.photos/id/1065/200/200'),
    ],
  ),
  Movie(
    id: 'neon-nights',
    title: 'Neon Nights 2099',
    genres: ['Viễn Tưởng', 'Hành Động'],
    year: 2024,
    rating: 4.9,
    ratingCount: 8700,
    duration: '2h 12m',
    description:
        'Trong một thế giới tương lai nơi công nghệ thống trị, một hacker trẻ phải đối mặt '
        'với tập đoàn quyền lực nhất thành phố để giải cứu những người bị áp bức.',
    imageUrl: 'https://picsum.photos/id/1025/800/1200',
  ),
  Movie(
    id: 'the-void',
    title: 'The Void',
    genres: ['Kinh Dị', 'Viễn Tưởng'],
    year: 2024,
    rating: 4.5,
    ratingCount: 6200,
    duration: '1h 58m',
    description:
        'Một nhóm nhà khoa học phát hiện cổng dẫn tới chiều không gian khác, nhưng những sinh vật '
        'bên kia bắt đầu xâm nhập thế giới thực.',
    imageUrl: 'https://picsum.photos/id/1069/400/600',
  ),
  Movie(
    id: 'desert-run',
    title: 'Desert Run',
    genres: ['Hành Động', 'Phiêu Lưu'],
    year: 2023,
    rating: 4.2,
    ratingCount: 4500,
    duration: '2h 05m',
    description:
        'Một cựu binh bị mắc kẹt giữa sa mạc và phải chiến đấu để sinh tồn trước một nhóm '
        'tội phạm nguy hiểm đang săn đuổi anh.',
    imageUrl: 'https://picsum.photos/id/1074/400/600',
  ),
  Movie(
    id: 'neon-vendetta',
    title: 'Neon Vendetta',
    genres: ['Hành Động', 'Tội Phạm'],
    year: 2024,
    rating: 4.7,
    ratingCount: 9100,
    duration: '2h 20m',
    description:
        'Một sát thủ huyền thoại quay trở lại để trả thù những kẻ đã phản bội anh trong '
        'thế giới ngầm đầy nguy hiểm.',
    imageUrl: 'https://picsum.photos/id/1084/400/600',
  ),
  Movie(
    id: 'shadow-blade',
    title: 'Shadow Blade',
    genres: ['Hành Động', 'Võ Thuật'],
    year: 2023,
    rating: 4.3,
    ratingCount: 5400,
    duration: '1h 52m',
    description:
        'Một kiếm sĩ bí ẩn lang thang khắp vùng đất để tìm kiếm sự cứu rỗi, nhưng quá khứ '
        'đẫm máu không ngừng đuổi theo anh.',
    imageUrl: 'https://picsum.photos/id/1040/400/600',
  ),
  Movie(
    id: 'cyber-storm',
    title: 'Cyber Storm',
    genres: ['Viễn Tưởng', 'Hành Động'],
    year: 2024,
    rating: 4.6,
    ratingCount: 7800,
    duration: '2h 15m',
    description:
        'Khi một hệ thống AI vượt ngoài tầm kiểm soát và đe dọa xóa sổ loài người, một đội '
        'đặc nhiệm công nghệ cao phải ngăn chặn thảm họa.',
    imageUrl: 'https://picsum.photos/id/1041/400/600',
  ),
  Movie(
    id: 'midnight-echo',
    title: 'Midnight Echo',
    genres: ['Kinh Dị', 'Tâm Lý'],
    year: 2023,
    rating: 4.4,
    ratingCount: 3200,
    duration: '1h 48m',
    description:
        'Một nhà tâm lý học phát hiện bệnh nhân của cô đang bị ám ảnh bởi một thực thể siêu nhiên, '
        'và chính cô cũng bắt đầu nhìn thấy nó.',
    imageUrl: 'https://picsum.photos/id/1042/400/600',
  ),
  Movie(
    id: 'ocean-depths',
    title: 'Ocean Depths',
    genres: ['Phiêu Lưu', 'Viễn Tưởng'],
    year: 2024,
    rating: 4.1,
    ratingCount: 2800,
    duration: '2h 02m',
    description:
        'Một đoàn thám hiểm dưới đáy đại dương khám phá ra một nền văn minh cổ đại vẫn còn tồn tại, '
        'với những bí mật có thể thay đổi lịch sử nhân loại.',
    imageUrl: 'https://picsum.photos/id/1043/400/600',
  ),
  Movie(
    id: 'crimson-sky',
    title: 'Crimson Sky',
    genres: ['Hành Động', 'Chiến Tranh'],
    year: 2022,
    rating: 4.0,
    ratingCount: 4100,
    duration: '2h 30m',
    description:
        'Trong bối cảnh cuộc chiến tranh không gian, một phi công trẻ phải dẫn dắt đội bay của mình '
        'chống lại đội quân xâm lược ngoài hành tinh.',
    imageUrl: 'https://picsum.photos/id/1044/400/600',
  ),
  Movie(
    id: 'comedy-night',
    title: 'Chuyện Tình Hài Hước',
    genres: ['Hài Hước', 'Tình Cảm'],
    year: 2024,
    rating: 4.6,
    ratingCount: 5100,
    duration: '1h 45m',
    description:
        'Câu chuyện dở khóc dở cười của hai người bạn thân bất ngờ phải giả làm vợ chồng '
        'để vượt qua kỳ nghỉ gia đình.',
    imageUrl: 'https://picsum.photos/id/1062/400/600',
  ),
  Movie(
    id: 'super-laugh',
    title: 'Biệt Đội Hài Hước',
    genres: ['Hài Hước', 'Hành Động'],
    year: 2023,
    rating: 4.4,
    ratingCount: 6800,
    duration: '1h 50m',
    description:
        'Một nhóm thám tử nghiệp dư đầy vụng về vô tình phá tan một phi vụ tội phạm quốc tế.',
    imageUrl: 'https://picsum.photos/id/1070/400/600',
  ),
  Movie(
    id: 'crazy-vacation',
    title: 'Kỳ Nghỉ Bão Táp',
    genres: ['Hài Hước', 'Phiêu Lưu'],
    year: 2024,
    rating: 4.3,
    ratingCount: 3900,
    duration: '1h 40m',
    description:
        'Chuyến du lịch gia đình trở thành cuộc phiêu lưu điên rồ nhất khi cả nhà bị lạc trên hòn đảo hoang.',
    imageUrl: 'https://picsum.photos/id/1071/400/600',
  ),
  Movie(
    id: 'love-in-paris',
    title: 'Hẹn Ước Mùa Thu',
    genres: ['Tình Cảm', 'Tâm Lý'],
    year: 2024,
    rating: 4.7,
    ratingCount: 7200,
    duration: '2h 05m',
    description:
        'Chuyện tình lãng mạn giữa một họa sĩ trẻ và cô gái tự do trên con phố thu lãng mạn.',
    imageUrl: 'https://picsum.photos/id/1072/400/600',
  ),
  Movie(
    id: 'heart-strings',
    title: 'Giai Điệu Tình Yêu',
    genres: ['Tình Cảm', 'Âm Nhạc'],
    year: 2023,
    rating: 4.5,
    ratingCount: 4800,
    duration: '1h 55m',
    description:
        'Hai tâm hồn đồng điệu gặp nhau qua âm nhạc và cùng nhau sáng tác nên bản tình ca lãng mạn nhất.',
    imageUrl: 'https://picsum.photos/id/1073/400/600',
  ),
  Movie(
    id: 'haunted-mansion',
    title: 'Dinh Biệt U Hồn',
    genres: ['Kinh Dị', 'Bí Ẩn'],
    year: 2024,
    rating: 4.5,
    ratingCount: 5600,
    duration: '2h 00m',
    description:
        'Một gia đình chuyển đến dinh thự cổ kính và đối mặt với những hiện tượng kỳ quái không lời giải.',
    imageUrl: 'https://picsum.photos/id/1075/400/600',
  ),
  Movie(
    id: 'lost-realm',
    title: 'Vương Quốc Thất Lạc',
    genres: ['Phiêu Lưu', 'Hành Động'],
    year: 2024,
    rating: 4.8,
    ratingCount: 9500,
    duration: '2h 25m',
    description:
        'Hành trình tìm kiếm kho báu cổ xưa đưa nhà thám hiểm đến vùng đất huyền bí chưa từng được khai phá.',
    imageUrl: 'https://picsum.photos/id/1076/400/600',
  ),
];

/// Phim banner nổi bật trên trang chủ (carousel 4 phim)
List<Movie> get bannerMovies => mockMovies
    .where((m) =>
        m.id == 'dune-2' ||
        m.id == 'neon-nights' ||
        m.id == 'cyber-storm' ||
        m.id == 'lost-realm')
    .toList();

/// Phim trending
List<Movie> get trendingMovies => mockMovies.take(5).toList();

/// Lấy danh sách phim theo thể loại (nếu ít hơn 3 thì lấy thêm phim ngẫu nhiên)
List<Movie> getMoviesByGenre(String genre) {
  final filtered = mockMovies.where((m) => m.genres.contains(genre)).toList();
  if (filtered.length >= 3) return filtered;
  final remaining =
      mockMovies.where((m) => !filtered.contains(m)).take(4 - filtered.length);
  return [...filtered, ...remaining];
}

/// Phim yêu thích (mock)
List<Movie> get favoriteMovies =>
    mockMovies.take(6).map((m) => m.copyWith(isFavorite: true)).toList();

/// Phim đã xem (mock với progress)
List<Movie> get historyMovies => mockMovies
    .take(5)
    .toList()
    .asMap()
    .entries
    .map((e) => e.value.copyWith(watchProgress: (e.key + 2) / 6))
    .toList();

/// Phim gợi ý cho tìm kiếm
List<Movie> get suggestedMovies => mockMovies.skip(2).take(4).toList();

/// Danh sách thể loại
const List<String> genreList = [
  'Hành Động',
  'Viễn Tưởng',
  'Kinh Dị',
  'Hài Hước',
  'Tình Cảm',
  'Phiêu Lưu',
];

/// Từ khóa tìm kiếm gần đây (mock)
const List<String> defaultRecentSearches = [
  'Dune',
  'Cyberpunk',
  'Avengers',
  'Batman'
];

/// Danh sách năm phát hành cho bộ lọc
const List<String> filterYears = [
  'Tất cả',
  '2024',
  '2023',
  '2022',
  '2021',
  'Trở về trước'
];

/// Danh sách sắp xếp cho bộ lọc
const List<String> filterSortOptions = [
  'Mới nhất',
  'Đánh giá cao',
  'Phổ biến nhất'
];

/// Danh sách thể loại cho bộ lọc (có "Tất cả")
const List<String> filterGenres = [
  'Tất cả',
  'Hành Động',
  'Viễn Tưởng',
  'Kinh Dị',
  'Tình Cảm',
  'Hài Hước'
];
