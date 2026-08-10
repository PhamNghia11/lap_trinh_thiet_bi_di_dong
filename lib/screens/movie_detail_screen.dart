// lib/screens/movie_detail_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';
import '../widgets/movie_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/flix_network_image.dart';
import '../data/tmdb_repository.dart';
import '../data/user_data_repository.dart';
import '../core/app_session.dart';
import '../core/app_preferences.dart';
import '../models/movie_filter.dart';
import '../core/ui_state_store.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie? movie;

  const MovieDetailScreen({
    super.key,
    this.movie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  bool _isFavorite = false;
  bool _isRatingExpanded = false;
  bool _isDescriptionExpanded = false;
  bool _favoriteTouched = false;
  final _movies = TmdbRepository();
  final _userData = UserDataRepository();
  late final PersistentScrollController _scrollController;
  List<Movie> _relatedMovies = [];
  bool _autoPlayHandled = false;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie ?? mockMovies.first;
    final stateKey = 'movie.${_currentMovie.id}';
    _scrollController = PersistentScrollController('$stateKey.scroll');
    _isRatingExpanded =
        UiStateStore.instance.boolean('$stateKey.ratingExpanded') ?? false;
    _isDescriptionExpanded =
        UiStateStore.instance.boolean('$stateKey.descriptionExpanded') ?? false;
    _isFavorite = _currentMovie.isFavorite;
    _loadDetail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    if (int.tryParse(_currentMovie.id) == null) return;
    try {
      final detail = await _movies.detail(_currentMovie.id);
      final rows = await _userData.reviews(_currentMovie.id);
      var favorite = _isFavorite;
      if (AppSession.instance.isAuthenticated) {
        try {
          favorite = await _userData.isFavorite(_currentMovie.id);
        } catch (_) {
          // Chi tiết phim vẫn tải được nếu trạng thái yêu thích tạm thời lỗi.
        }
      }
      final flixReviews = rows.map((row) {
        final user = row['user'] as Map<String, dynamic>? ?? const {};
        return UserReview(
          userName: user['fullName'] as String? ?? 'Người dùng FLIX',
          userAvatar: user['avatarUrl'] as String? ?? '',
          rating: (row['rating'] as num?)?.toDouble() ?? 0,
          date: (row['createdAt'] as String? ?? '').split('T').first,
          comment: row['hasSpoiler'] == true
              ? '[Có tiết lộ nội dung] ${row['comment'] ?? ''}'
              : row['comment'] as String? ?? '',
          imageUrl: row['imageUrl'] as String?,
        );
      }).toList();
      final reviews = [...flixReviews, ...detail.reviews];
      final genreId =
          detail.genres.isEmpty ? null : movieGenreOptions[detail.genres.first];
      final related = genreId == null
          ? <Movie>[]
          : (await _movies.discover(genreId: genreId))
              .where((item) => item.id != detail.id)
              .take(8)
              .toList();
      if (mounted) {
        setState(() {
          if (!_favoriteTouched) _isFavorite = favorite;
          _currentMovie = detail.copyWith(
            isFavorite: _isFavorite,
            reviews: reviews,
          );
          _relatedMovies = related;
        });
        if (!_autoPlayHandled &&
            AppPreferences.instance.autoPlayTrailer &&
            detail.trailerKey != null) {
          _autoPlayHandled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushNamed(
              context,
              AppRoutes.trailer,
              arguments: _currentMovie,
            );
          });
        }
      }
    } catch (_) {
      // Giữ dữ liệu hiện tại khi kết nối tạm thời không khả dụng.
    }
  }

  void _goBack() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  void _showAllCast() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .92,
        builder: (context, controller) => ListView.separated(
          controller: controller,
          padding: const EdgeInsets.all(20),
          itemCount: _currentMovie.castList.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final actor = _currentMovie.castList[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.inputBg,
                backgroundImage: actor.avatarUrl.isEmpty
                    ? null
                    : NetworkImage(actor.avatarUrl),
                child: actor.avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: AppTheme.textMuted)
                    : null,
              ),
              title:
                  Text(actor.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(actor.role, style: AppTheme.smallText),
              onTap: () => _showActorInfoBottomSheet(actor),
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (!AppSession.instance.isAuthenticated) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final next = !_isFavorite;
    _favoriteTouched = true;
    setState(() => _isFavorite = next);
    try {
      next
          ? await _userData.addFavorite(_currentMovie.id)
          : await _userData.removeFavorite(_currentMovie.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  next ? 'Đã thêm vào Yêu thích' : 'Đã xóa khỏi Yêu thích')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isFavorite = !next);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết này.')),
      );
    }
  }

  String _formatMoney(int value) {
    if (value <= 0) return 'Chưa công bố';
    if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(1)} tỷ';
    }
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)} triệu';
    }
    final formatted = value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
    return '\$$formatted';
  }

  String _formatPopularity(double value) {
    if (value <= 0) return '—';
    return value.toStringAsFixed(1);
  }

  String _compactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  String _statusLabel(String status) => switch (status) {
        'Released' => 'Đã phát hành',
        'Post Production' => 'Hậu kỳ',
        'In Production' => 'Đang sản xuất',
        'Planned' => 'Đã lên kế hoạch',
        'Canceled' => 'Đã hủy',
        'Rumored' => 'Đang được đồn đoán',
        _ => status,
      };

  /// Dialog/BottomSheet xem thông tin chi tiết Diễn viên
  void _showActorInfoBottomSheet(CastMember actor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.inputBg,
                backgroundImage: actor.avatarUrl.isEmpty
                    ? null
                    : NetworkImage(actor.avatarUrl),
                child: actor.avatarUrl.isEmpty
                    ? const Icon(Icons.person,
                        color: AppTheme.textMuted, size: 36)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                actor.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                actor.role,
                style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                actor.bio,
                textAlign: TextAlign.center,
                style: AppTheme.bodyText,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppTheme.primaryButtonStyle(),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;
    final relatedMovies = _relatedMovies;

    final page = Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ─── Header Parallax với Ảnh Nền & Play Button Glassmorphism ───
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppTheme.scaffoldBg,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: _goBack,
                ),
                actions: [
                  // Nút Tim Yêu Thích với Animation
                  IconButton(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: AppTheme.primaryRed,
                        size: 22,
                      ),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  // Nút Chia Sẻ với Animation
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(
                        text: 'https://www.themoviedb.org/movie/${movie.id}',
                      ));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Đã sao chép liên kết phim')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlixNetworkImage(
                        movie.backdropUrl.isNotEmpty
                            ? movie.backdropUrl
                            : movie.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      // Gradient phủ mờ tối bên dưới
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.scaffoldBg.withValues(alpha: 0.8),
                              AppTheme.scaffoldBg,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // Nút Play Tròn Nổi Giữa (Glassmorphism)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white30, width: 1.5),
                              ),
                              child: IconButton(
                                iconSize: 38,
                                icon: const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white),
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.trailer,
                                    arguments: movie),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Thân Bài Nội Dung Phim ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 10, 20, 100), // chừa lề dưới cho Sticky Bottom Bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên phim
                      Text(movie.title, style: AppTheme.headingLarge),
                      if (movie.tagline.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '“${movie.tagline}”',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Hàng Badge Thông Tin (Chất lượng, Độ tuổi, Phụ đề)
                      Row(
                        children: [
                          _buildBadge(movie.quality, AppTheme.primaryRed),
                          const SizedBox(width: 8),
                          _buildBadge(movie.ageRating, Colors.orange),
                          const SizedBox(width: 8),
                          _buildBadge(movie.languageInfo, Colors.white24),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Rating Sao (Có thể bấm mở rộng phân bố đánh giá)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isRatingExpanded = !_isRatingExpanded;
                          });
                          UiStateStore.instance.setBool(
                            'movie.${movie.id}.ratingExpanded',
                            _isRatingExpanded,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.accentGold, size: 22),
                              const SizedBox(width: 4),
                              Text(
                                movie.ratingText,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              const SizedBox(width: 12),
                              Text(movie.infoText, style: AppTheme.mutedText),
                              const Spacer(),
                              Icon(
                                _isRatingExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Thống kê phân bố đánh giá (Mở rộng khi bấm)
                      if (_isRatingExpanded) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Phân bố đánh giá',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 8),
                              _buildRatingBar(
                                  5, reviewRatingRatio(movie.reviews, 5)),
                              _buildRatingBar(
                                  4, reviewRatingRatio(movie.reviews, 4)),
                              _buildRatingBar(
                                  3, reviewRatingRatio(movie.reviews, 3)),
                              _buildRatingBar(
                                  2, reviewRatingRatio(movie.reviews, 2)),
                              _buildRatingBar(
                                  1, reviewRatingRatio(movie.reviews, 1)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Hàng Nút Hành Động ("Xem Trailer", "Đánh giá", "+ Danh sách")
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PrimaryIconButton(
                            text: 'Xem Trailer',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.trailer,
                                arguments: movie),
                          ),
                          OutlinedActionButton(
                            text: 'Đánh giá',
                            icon: Icons.rate_review_outlined,
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.review,
                                arguments: movie),
                          ),
                          OutlinedButton.icon(
                            style: AppTheme.outlinedButtonStyle(),
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.favorites),
                            icon: const Icon(
                                Icons.collections_bookmark_outlined,
                                color: Colors.white,
                                size: 18),
                            label: const Text('Danh sách của tôi',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ─── Phần Nội Dung Phim ─────────────────────────
                      const Text('Nội Dung Phim',
                          style: AppTheme.headingMedium),
                      const SizedBox(height: 8),
                      Text(
                        movie.description,
                        maxLines: _isDescriptionExpanded ? null : 3,
                        overflow: _isDescriptionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: AppTheme.bodyText,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                          UiStateStore.instance.setBool(
                            'movie.${movie.id}.descriptionExpanded',
                            _isDescriptionExpanded,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _isDescriptionExpanded ? 'Thu gọn ▲' : 'Xem thêm ▼',
                            style: const TextStyle(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Chips Thể Loại Phim (Bấm vào điều hướng sang GenreDetailScreen)
                      Wrap(
                        spacing: 8,
                        children: movie.genres.map((genre) {
                          return ActionChip(
                            backgroundColor: AppTheme.cardBg,
                            labelStyle: const TextStyle(
                                color: AppTheme.textLight, fontSize: 12),
                            side: const BorderSide(color: Colors.white12),
                            label: Text(genre),
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.genreDetail,
                                arguments: 'Phim $genre'),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Bảng Thông Tin Phụ (Đạo diễn, Quốc gia, Ngày phát hành)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg.withValues(alpha: 0.6),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Đạo diễn', movie.director),
                            const Divider(color: Colors.white10, height: 16),
                            if (movie.originalTitle.isNotEmpty &&
                                movie.originalTitle != movie.title) ...[
                              _buildInfoRow('Tên gốc', movie.originalTitle),
                              const Divider(color: Colors.white10, height: 16),
                            ],
                            _buildInfoRow('Quốc gia', movie.country),
                            const Divider(color: Colors.white10, height: 16),
                            _buildInfoRow('Ngày phát hành', movie.releaseDate),
                            const Divider(color: Colors.white10, height: 16),
                            _buildInfoRow('Thời lượng', movie.duration),
                            const Divider(color: Colors.white10, height: 16),
                            _buildInfoRow(
                                'Trạng thái', _statusLabel(movie.status)),
                            if (movie.languages.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 16),
                              _buildInfoRow(
                                  'Ngôn ngữ', movie.languages.join(', ')),
                            ],
                            if (movie.collectionName.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 16),
                              _buildInfoRow('Bộ sưu tập', movie.collectionName),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text('Thông Tin Chuyên Sâu',
                          style: AppTheme.headingMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.star_rounded,
                              label: 'Điểm TMDB',
                              value: movie.rating.toStringAsFixed(1),
                              color: AppTheme.accentGold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.people_alt_outlined,
                              label: 'Lượt đánh giá',
                              value: _compactNumber(movie.ratingCount),
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.trending_up_rounded,
                              label: 'Độ phổ biến',
                              value: _formatPopularity(movie.popularity),
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg.withValues(alpha: 0.6),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                                'Kinh phí', _formatMoney(movie.budget)),
                            const Divider(color: Colors.white10, height: 16),
                            _buildInfoRow(
                                'Doanh thu', _formatMoney(movie.revenue)),
                            if (movie.writers.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 16),
                              _buildInfoRow(
                                  'Biên kịch', movie.writers.join(', ')),
                            ],
                            if (movie.producers.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 16),
                              _buildInfoRow(
                                  'Nhà sản xuất', movie.producers.join(', ')),
                            ],
                            if (movie.productionCompanies.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 16),
                              _buildInfoRow('Hãng phim',
                                  movie.productionCompanies.join(', ')),
                            ],
                          ],
                        ),
                      ),
                      if (movie.watchProviders.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Nơi Có Thể Xem',
                            style: AppTheme.headingMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: movie.watchProviders
                              .map((provider) => _buildInfoChip(
                                    provider,
                                    Icons.play_circle_outline,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 6),
                        const Text('Thông tin nhà cung cấp từ JustWatch/TMDB.',
                            style: AppTheme.smallText),
                      ],
                      if (movie.keywords.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Từ Khóa', style: AppTheme.headingMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: movie.keywords
                              .take(10)
                              .map((keyword) =>
                                  _buildInfoChip(keyword, Icons.tag_rounded))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('Liên Kết Chính Thức',
                          style: AppTheme.headingMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (movie.imdbId?.isNotEmpty == true)
                            OutlinedActionButton(
                              text: 'IMDb',
                              icon: Icons.open_in_new,
                              onPressed: () => _openExternal(
                                  'https://www.imdb.com/title/${movie.imdbId}/'),
                            ),
                          OutlinedActionButton(
                            text: 'TMDB',
                            icon: Icons.movie_filter_outlined,
                            onPressed: () => _openExternal(
                                'https://www.themoviedb.org/movie/${movie.id}'),
                          ),
                          if (movie.homepage?.isNotEmpty == true)
                            OutlinedActionButton(
                              text: 'Trang chủ',
                              icon: Icons.language_rounded,
                              onPressed: () => _openExternal(movie.homepage!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ─── Phần Diễn Viên Chính ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diễn Viên Chính',
                              style: AppTheme.headingMedium),
                          TextButton(
                            onPressed:
                                movie.castList.isEmpty ? null : _showAllCast,
                            child: const Text('Xem tất cả',
                                style: TextStyle(color: AppTheme.primaryRed)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movie.castList.length,
                          itemBuilder: (context, index) {
                            final actor = movie.castList[index];
                            return GestureDetector(
                              onTap: () => _showActorInfoBottomSheet(actor),
                              child: Container(
                                width: 95,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: AppTheme.inputBg,
                                      backgroundImage: actor.avatarUrl.isEmpty
                                          ? null
                                          : NetworkImage(actor.avatarUrl),
                                      child: actor.avatarUrl.isEmpty
                                          ? const Icon(Icons.person,
                                              color: AppTheme.textMuted,
                                              size: 28)
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      actor.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      actor.role,
                                      style: AppTheme.smallText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Phần Đánh Giá Từ Người Xem ──────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Đánh Giá Từ Người Xem',
                              style: AppTheme.headingMedium),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.review,
                                arguments: movie),
                            child: const Text('Viết đánh giá',
                                style: TextStyle(color: AppTheme.primaryRed)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (movie.reviews.isEmpty)
                        _buildEmptyState(
                          icon: Icons.rate_review_outlined,
                          text:
                              'Chưa có đánh giá nào. Hãy là người đầu tiên chia sẻ cảm nhận.',
                        )
                      else
                        Column(
                          children: movie.reviews.map((rev) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusLg),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppTheme.inputBg,
                                        backgroundImage: rev.userAvatar.isEmpty
                                            ? null
                                            : NetworkImage(rev.userAvatar),
                                        child: rev.userAvatar.isEmpty
                                            ? const Icon(Icons.person,
                                                color: AppTheme.textMuted,
                                                size: 18)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rev.userName,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                            Text(rev.date,
                                                style: AppTheme.smallText),
                                          ],
                                        ),
                                      ),
                                      if (rev.rating > 0)
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                color: AppTheme.accentGold,
                                                size: 16),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${rev.rating}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(rev.comment, style: AppTheme.bodyText),
                                  if (rev.imageUrl?.isNotEmpty == true) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMd),
                                      child: FlixNetworkImage(
                                        rev.imageUrl!,
                                        width: double.infinity,
                                        height: 180,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // ─── Phần Có Thể Bạn Cũng Thích ─────────────────
                      const Text('Có Thể Bạn Cũng Thích',
                          style: AppTheme.headingMedium),
                      const SizedBox(height: 12),
                      if (relatedMovies.isEmpty)
                        _buildEmptyState(
                          icon: Icons.movie_filter_outlined,
                          text: 'Chưa tìm thấy phim tương tự phù hợp.',
                        )
                      else
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedMovies.length,
                            itemBuilder: (context, index) {
                              final relMovie = relatedMovies[index];
                              return MovieCard.poster(
                                movie: relMovie,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MovieDetailScreen(movie: relMovie),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ─── Sticky Bottom Action Bar (▶ Xem Ngay) ───────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg.withValues(alpha: 0.85),
                    border:
                        const Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: AppTheme.primaryButtonStyle(
                            borderRadius: AppTheme.radiusXl),
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.trailer,
                            arguments: movie),
                        icon: const Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white, size: 24),
                        label: const Text(
                          '▶ XEM NGAY',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      },
      child: page,
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRatingBar(int stars, double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.star, color: AppTheme.accentGold, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: Colors.white10,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(ratio * 100).round()}%', style: AppTheme.smallText),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 104, child: Text(label, style: AppTheme.mutedText)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isEmpty ? 'Đang cập nhật' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.smallText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 15),
          const SizedBox(width: 5),
          Text(label, style: AppTheme.smallText),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTheme.mutedText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
