import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../data/tmdb_repository.dart';
import '../data/user_data_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/flix_network_image.dart';

class HistoryEntry {
  const HistoryEntry(this.movie, this.progress, this.lastWatchedAt);
  final Movie movie;
  final double progress;
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
  late Future<List<HistoryEntry>> _future;

  @override
  void initState() { super.initState(); _future = _load(); }

  Future<List<HistoryEntry>> _load() async {
    if (!AppSession.instance.isAuthenticated) return [];
    final rows = await _userData.history();
    return Future.wait(rows.map((row) async {
      final movie = await _movies.detail('${row['tmdbMovieId']}');
      return HistoryEntry(
        movie,
        (row['progress'] as num?)?.toDouble() ?? 0,
        DateTime.tryParse('${row['lastWatchedAt'] ?? ''}'),
      );
    }));
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _clear() async {
    await _userData.clearHistory();
    _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(title: const Text('Lịch sử xem'), actions: [
          if (AppSession.instance.isAuthenticated)
            IconButton(onPressed: _clear, tooltip: 'Xóa toàn bộ', icon: const Icon(Icons.delete_sweep_outlined)),
        ]),
        body: !AppSession.instance.isAuthenticated
            ? _empty('Đăng nhập để đồng bộ lịch sử xem.', login: true)
            : FutureBuilder<List<HistoryEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
                  }
                  if (snapshot.hasError) return _empty('${snapshot.error}', retry: true);
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) return _empty('Bạn chưa xem trailer phim nào.');
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Dismissible(
                          key: ValueKey(entry.movie.id),
                          direction: DismissDirection.endToStart,
                          background: Container(color: AppTheme.primaryRed, alignment: Alignment.centerRight, padding: const EdgeInsets.all(20), child: const Icon(Icons.delete, color: Colors.white)),
                          onDismissed: (_) => _userData.removeHistory(entry.movie.id),
                          child: ListTile(
                            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: FlixNetworkImage(entry.movie.imageUrl, width: 60, height: 84, fit: BoxFit.cover)),
                            title: Text(entry.movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: entry.progress, color: AppTheme.primaryRed, backgroundColor: Colors.white12),
                              const SizedBox(height: 4),
                              Text(entry.lastWatchedAt?.toLocal().toString().split('.').first ?? '', style: AppTheme.smallText),
                            ]),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail, arguments: entry.movie),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        bottomNavigationBar: const FlixBottomNavBar(currentIndex: 3),
      );

  Widget _empty(String text, {bool login = false, bool retry = false}) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.history, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(text, style: AppTheme.bodyText, textAlign: TextAlign.center),
          if (login) TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.login).then((_) => _reload()), child: const Text('Đăng nhập')),
          if (retry) TextButton(onPressed: _reload, child: const Text('Thử lại')),
        ]),
      );
}
