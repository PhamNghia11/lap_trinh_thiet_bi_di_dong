// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Danh sách lịch sử chia theo nhóm thời gian
  late Map<String, List<_HistoryItemData>> _groupedHistory;

  @override
  void initState() {
    super.initState();
    _initMockHistory();
  }

  void _initMockHistory() {
    final movies = mockMovies;
    _groupedHistory = {
      'Hôm nay': [
        _HistoryItemData(
          movie: movies[0],
          progress: 0.75,
          lastWatched: '14:30',
          watchedMinutes: 124,
          totalMinutes: 166,
        ),
        _HistoryItemData(
          movie: movies[1],
          progress: 0.40,
          lastWatched: '10:15',
          watchedMinutes: 52,
          totalMinutes: 132,
        ),
      ],
      'Hôm qua': [
        _HistoryItemData(
          movie: movies[2],
          progress: 0.90,
          lastWatched: '21:45',
          watchedMinutes: 106,
          totalMinutes: 118,
        ),
        _HistoryItemData(
          movie: movies[3],
          progress: 0.25,
          lastWatched: '19:10',
          watchedMinutes: 31,
          totalMinutes: 125,
        ),
      ],
      'Tuần này': [
        _HistoryItemData(
          movie: movies[4],
          progress: 1.0,
          lastWatched: 'Thứ 3',
          watchedMinutes: 140,
          totalMinutes: 140,
        ),
        _HistoryItemData(
          movie: movies[5],
          progress: 0.60,
          lastWatched: 'Thứ 2',
          watchedMinutes: 67,
          totalMinutes: 112,
        ),
      ],
      'Cũ hơn': [
        _HistoryItemData(
          movie: movies[6],
          progress: 0.85,
          lastWatched: '15/07',
          watchedMinutes: 115,
          totalMinutes: 135,
        ),
      ],
    };
  }

  /// Xóa 1 item khỏi lịch sử
  void _removeItem(String category, int index) {
    final item = _groupedHistory[category]![index];
    setState(() {
      _groupedHistory[category]!.removeAt(index);
      if (_groupedHistory[category]!.isEmpty) {
        _groupedHistory.remove(category);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${item.movie.title}" khỏi lịch sử'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => _initMockHistory(),
        ),
      ),
    );
  }

  /// Dialog xác nhận xóa toàn bộ lịch sử
  void _confirmClearAllHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.primaryRed),
              SizedBox(width: 10),
              Text('Xóa Lịch Sử Xem', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xóa toàn bộ lịch sử xem phim không? Hành động này không thể hoàn tác.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _groupedHistory.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa toàn bộ lịch sử xem phim!')),
                );
              },
              child: const Text('Xóa tất cả', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHistoryEmpty = _groupedHistory.values.every((list) => list.isEmpty);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        title: const Text('Lịch Sử Xem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (!isHistoryEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.primaryRed),
              tooltip: 'Xóa toàn bộ lịch sử',
              onPressed: _confirmClearAllHistory,
            ),
        ],
      ),
      body: isHistoryEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Header Thống Kê Tổng Quan ──────────────────────
                _buildStatsOverviewCard(),
                const SizedBox(height: 20),

                // ─── Danh sách Nhóm theo Thời gian ──────────────────
                for (final entry in _groupedHistory.entries) ...[
                  if (entry.value.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${entry.value.length} phim',
                            style: AppTheme.smallText,
                          ),
                        ],
                      ),
                    ),
                    for (int i = 0; i < entry.value.length; i++)
                      _buildHistoryItem(entry.key, i, entry.value[i]),
                  ],
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  /// Card Thống Kê Tổng Quan
  Widget _buildStatsOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              icon: Icons.movie_filter_rounded,
              title: '24 phim',
              subtitle: 'Đã xem tháng này',
              color: AppTheme.primaryRed,
            ),
          ),
          Container(height: 36, width: 1, color: Colors.white12),
          Expanded(
            child: _buildStatTile(
              icon: Icons.access_time_filled_rounded,
              title: '48h 30m',
              subtitle: 'Tổng thời lượng',
              color: AppTheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.smallText),
          ],
        ),
      ],
    );
  }

  /// Item Lịch sử hỗ trợ Vuốt để xóa (Dismissible) & PopupMenu
  Widget _buildHistoryItem(String category, int index, _HistoryItemData data) {
    final movie = data.movie;
    final percentInt = (data.progress * 100).round();

    return Dismissible(
      key: Key('${category}_${movie.id}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeItem(category, index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade700,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Xóa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: Colors.white10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Poster ảnh phim
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.network(
                    movie.imageUrl,
                    width: 70,
                    height: 95,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Thông tin phim + tiến độ xem
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Menu 3 chấm (Xóa / Yêu thích)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
                        color: AppTheme.cardBg,
                        onSelected: (val) {
                          if (val == 'delete') {
                            _removeItem(category, index);
                          } else if (val == 'favorite') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã thêm "${movie.title}" vào Yêu thích')),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border, color: AppTheme.primaryRed, size: 18),
                                SizedBox(width: 8),
                                Text('Thêm vào Yêu thích', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Text('Xóa khỏi lịch sử', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'Xem lúc ${data.lastWatched} • ${data.watchedMinutes}m / ${data.totalMinutes}m',
                    style: AppTheme.smallText,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: data.progress,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percentInt%',
                        style: TextStyle(
                          color: data.progress >= 1.0 ? AppTheme.accentGold : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nút "Tiếp tục xem" nổi bật
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_arrow_rounded, color: AppTheme.primaryRed, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Tiếp tục xem',
                              style: TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State khi lịch sử trống
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.history_toggle_off_rounded, size: 64, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lịch Sử Xem Trống',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa xem bộ phim nào gần đây. Hãy chọn một bộ phim hấp dẫn để thưởng thức ngay!',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              child: const Text('Khám phá phim ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItemData {
  final Movie movie;
  final double progress;
  final String lastWatched;
  final int watchedMinutes;
  final int totalMinutes;

  _HistoryItemData({
    required this.movie,
    required this.progress,
    required this.lastWatched,
    required this.watchedMinutes,
    required this.totalMinutes,
  });
}
