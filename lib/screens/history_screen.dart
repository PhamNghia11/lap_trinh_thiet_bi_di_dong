import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../data/tmdb_repository.dart';
import '../data/user_data_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/flix_network_image.dart';
import '../core/ui_state_store.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.movie,
    required this.progress,
    required this.watchedSeconds,
    required this.durationSeconds,
    required this.lastWatchedAt,
  });

  final Movie movie;
  final double progress;
  final int watchedSeconds;
  final int? durationSeconds;
  final DateTime? lastWatchedAt;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _userData = UserDataRepository();
  final _movies = TmdbRepository();
  final _scrollController = PersistentScrollController('history.scroll');

  List<HistoryEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.instance.isAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _userData.history();
      final entries = await Future.wait(rows.map((row) async {
        Movie movie;
        if (row['movie'] is Map) {
          movie = Movie.fromTmdbJson(
            Map<String, dynamic>.from(row['movie'] as Map),
          );
        } else {
          try {
            movie = await _movies.detail('${row['tmdbMovieId']}');
          } catch (_) {
            movie = Movie(
              id: '${row['tmdbMovieId']}',
              title: row['title']?.toString() ?? 'Phim #${row['tmdbMovieId']}',
              genres: const [],
              year: 0,
              rating: 0,
              duration: '',
              description: '',
              imageUrl: '',
              reviews: const [],
            );
          }
        }
        return HistoryEntry(
          movie: movie,
          progress: ((row['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1),
          watchedSeconds: (row['watchedSeconds'] as num?)?.toInt() ?? 0,
          durationSeconds: (row['durationSeconds'] as num?)?.toInt(),
          lastWatchedAt:
              DateTime.tryParse('${row['lastWatchedAt'] ?? ''}')?.toLocal(),
        );
      }));
      if (mounted) setState(() => _entries = entries);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<HistoryEntry>> get _groupedEntries {
    final groups = <String, List<HistoryEntry>>{};
    for (final entry in _entries) {
      groups.putIfAbsent(_dateGroup(entry.lastWatchedAt), () => []).add(entry);
    }
    return groups;
  }

  String _dateGroup(DateTime? date) {
    if (date == null) return 'Cũ hơn';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Hôm nay';
    if (difference == 1) return 'Hôm qua';
    if (difference < 7) return 'Tuần này';
    return 'Cũ hơn';
  }

  String _lastWatchedLabel(DateTime? date) {
    if (date == null) return 'Không rõ thời gian';
    final group = _dateGroup(date);
    if (group == 'Hôm nay' || group == 'Hôm qua') {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _durationLabel(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  Future<void> _remove(HistoryEntry entry) async {
    final index = _entries.indexOf(entry);
    setState(() => _entries.remove(entry));
    try {
      await _userData.removeHistory(entry.movie.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${entry.movie.title}" khỏi lịch sử'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () => _restore(entry, index),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _entries.insert(index < 0 ? 0 : index, entry));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _restore(HistoryEntry entry, int index) async {
    try {
      await _userData.saveHistory(
        entry.movie.id,
        progress: entry.progress,
        watchedSeconds: entry.watchedSeconds,
        durationSeconds: entry.durationSeconds,
      );
      if (!mounted || _entries.contains(entry)) return;
      setState(() => _entries.insert(index.clamp(0, _entries.length), entry));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _addFavorite(HistoryEntry entry) async {
    try {
      await _userData.addFavorite(entry.movie.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Đã thêm "${entry.movie.title}" vào Yêu thích')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.primaryRed),
            SizedBox(width: 10),
            Text('Xóa Lịch Sử Xem',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử xem phim không?',
          style: AppTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _userData.clearHistory();
      if (!mounted) return;
      setState(() => _entries.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ lịch sử xem')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlixAdaptiveScaffold(
      currentIndex: 3,
      contentMaxWidth: 960,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        title: const Text('Lịch Sử Xem',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (AppSession.instance.isAuthenticated && _entries.isNotEmpty)
            IconButton(
              tooltip: 'Xóa toàn bộ lịch sử',
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppTheme.primaryRed),
            ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!AppSession.instance.isAuthenticated) {
      return _emptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Đăng nhập để xem lịch sử',
        description: 'Lịch sử xem sẽ được đồng bộ trên mọi thiết bị.',
        actionText: 'Đăng nhập',
        onAction: () =>
            Navigator.pushNamed(context, AppRoutes.login).then((_) => _load()),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }
    if (_error != null) {
      return _emptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Không tải được lịch sử',
        description: _error!,
        actionText: 'Thử lại',
        onAction: _load,
      );
    }
    if (_entries.isEmpty) {
      return _emptyState(
        icon: Icons.history_toggle_off_rounded,
        title: 'Lịch Sử Xem Trống',
        description:
            'Bạn chưa xem phim nào gần đây. Hãy chọn một bộ phim để bắt đầu.',
        actionText: 'Khám phá phim ngay',
        onAction: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
      );
    }

    final groups = _groupedEntries;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _statsCard(),
          const SizedBox(height: 20),
          for (final group in groups.entries) ...[
            _groupHeader(group.key, group.value.length),
            for (final entry in group.value) _historyItem(entry),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statsCard() {
    final watchedSeconds =
        _entries.fold<int>(0, (sum, entry) => sum + entry.watchedSeconds);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.movie_filter_rounded,
              value: '${_entries.length} phim',
              label: 'Trong lịch sử',
              color: AppTheme.primaryRed,
            ),
          ),
          Container(height: 36, width: 1, color: Colors.white12),
          Expanded(
            child: _statTile(
              icon: Icons.access_time_filled_rounded,
              value: _durationLabel(watchedSeconds),
              label: 'Đã xem',
              color: AppTheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
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
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text(label, style: AppTheme.smallText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _groupHeader(String title, int count) {
    return Padding(
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
          Text(title, style: AppTheme.headingSmall),
          const Spacer(),
          Text('$count phim', style: AppTheme.smallText),
        ],
      ),
    );
  }

  Widget _historyItem(HistoryEntry entry) {
    final movie = entry.movie;
    final percent = (entry.progress * 100).round();
    final duration = entry.durationSeconds ?? 0;
    return Dismissible(
      key: ValueKey('${movie.id}_${entry.lastWatchedAt}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _remove(entry);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryRedDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Xóa',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.movieDetail,
          arguments: movie,
        ).then((_) => _load()),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: FlixNetworkImage(
                      movie.imageUrl,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white70, size: 30),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Tùy chọn',
                          color: AppTheme.cardBg,
                          padding: EdgeInsets.zero,
                          onSelected: (value) => value == 'favorite'
                              ? _addFavorite(entry)
                              : _remove(entry),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'favorite',
                              child: Row(
                                children: [
                                  Icon(Icons.favorite_border,
                                      color: AppTheme.primaryRed, size: 18),
                                  SizedBox(width: 8),
                                  Text('Thêm vào Yêu thích'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text('Xóa khỏi lịch sử'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (movie.genres.isNotEmpty ||
                        movie.year > 0 ||
                        movie.rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (movie.year > 0) ...[
                            Text(
                              '${movie.year}',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (movie.rating > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.accentGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 11, color: AppTheme.accentGold),
                                  const SizedBox(width: 2),
                                  Text(
                                    movie.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: AppTheme.accentGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (movie.genres.isNotEmpty)
                            Expanded(
                              child: Text(
                                movie.genres.take(2).join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Xem lúc ${_lastWatchedLabel(entry.lastWatchedAt)}'
                      '${duration > 0 ? ' • ${_durationLabel(entry.watchedSeconds)} / ${_durationLabel(duration)}' : (movie.duration.isNotEmpty ? ' • ${movie.duration}' : '')}',
                      style: AppTheme.smallText,
                    ),
                    if (entry.progress > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: entry.progress,
                                minHeight: 4,
                                color: AppTheme.primaryRed,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$percent%', style: AppTheme.smallText),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.movieDetail,
                          arguments: movie,
                        ).then((_) => _load()),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Xem chi tiết',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(icon, size: 64, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center, style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center, style: AppTheme.bodyText),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
