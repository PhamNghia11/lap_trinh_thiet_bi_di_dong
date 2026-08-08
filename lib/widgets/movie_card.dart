// lib/widgets/movie_card.dart

import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../theme/app_theme.dart';

/// Widget thẻ phim dùng chung cho toàn bộ ứng dụng.
/// Có 3 dạng hiển thị: poster (ngang), grid (lưới 2 cột), listTile (hàng ngang).
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final _MovieCardVariant _variant;
  final bool showFavoriteIcon;
  final bool showRating;
  final bool showProgress;
  final bool showBadge;

  /// Dạng poster dọc — dùng trong danh sách ngang (Home trending)
  const MovieCard.poster({
    super.key,
    required this.movie,
    this.onTap,
  })  : _variant = _MovieCardVariant.poster,
        showFavoriteIcon = false,
        showRating = false,
        showProgress = false,
        showBadge = false;

  /// Dạng grid — dùng trong lưới 2 cột (Favorites, Genre Detail)
  const MovieCard.grid({
    super.key,
    required this.movie,
    this.onTap,
    this.showFavoriteIcon = false,
    this.showRating = true,
    this.showBadge = true,
  })  : _variant = _MovieCardVariant.grid,
        showProgress = false;

  /// Dạng list tile — dùng trong danh sách dọc (Movie List, History, Search)
  const MovieCard.listTile({
    super.key,
    required this.movie,
    this.onTap,
    this.showProgress = false,
    this.showBadge = true,
  })  : _variant = _MovieCardVariant.listTile,
        showFavoriteIcon = false,
        showRating = false;

  @override
  Widget build(BuildContext context) {
    switch (_variant) {
      case _MovieCardVariant.poster:
        return _buildPoster();
      case _MovieCardVariant.grid:
        return _buildGrid();
      case _MovieCardVariant.listTile:
        return _buildListTile();
    }
  }

  /// ─── Poster variant ────────────────────────────────────────────
  Widget _buildPoster() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Image.network(
                movie.imageUrl,
                height: 170,
                width: 130,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cardTitle,
            ),
          ],
        ),
      ),
    );
  }

  /// ─── Grid variant ──────────────────────────────────────────────
  Widget _buildGrid() {
    final badgeText = movie.badge ?? (movie.rating >= 4.7 ? 'TOP 10' : 'HD');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: Image.network(
                      movie.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: AppTheme.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${movie.year} • ${movie.genres.isNotEmpty ? movie.genres.first : ''}',
                        style: AppTheme.smallText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showRating) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${movie.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (showBadge)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeText == 'TOP 10'
                        ? AppTheme.primaryRed
                        : Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: badgeText == 'TOP 10' ? Colors.white30 : AppTheme.primaryRed,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (showFavoriteIcon)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppTheme.primaryRed,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ─── List Tile variant ─────────────────────────────────────────
  Widget _buildListTile() {
    final badgeText = movie.badge ?? (movie.rating >= 4.7 ? 'TOP 10' : 'HD');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: Colors.white10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.network(
                    movie.imageUrl,
                    width: showProgress ? 60 : 80,
                    height: showProgress ? 85 : 110,
                    fit: BoxFit.cover,
                  ),
                ),
                if (showBadge && !showProgress)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: showProgress ? 15 : 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (showProgress) ...[
                    Text(
                      'Đã xem ${_formatProgress(movie.watchProgress)} / ${movie.duration}',
                      style: AppTheme.smallText,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: movie.watchProgress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                    ),
                  ] else ...[
                    Text(
                      '${movie.year} • ${movie.genreText}',
                      style: AppTheme.mutedText,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.accentGold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${movie.rating} / 5',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatProgress(double progress) {
    final minutes = (progress * 130).round();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

enum _MovieCardVariant { poster, grid, listTile }
