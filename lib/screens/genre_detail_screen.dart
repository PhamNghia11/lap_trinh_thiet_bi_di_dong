import 'package:flutter/material.dart';

import '../data/tmdb_repository.dart';
import '../models/movie_filter.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/flix_network_image.dart';
import '../widgets/movie_card.dart';

class GenreDetailScreen extends StatefulWidget {
  const GenreDetailScreen({super.key, this.genreTitle = 'Phim Hành Động'});
  final String genreTitle;
  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  final _repository = TmdbRepository();
  final _scrollController = ScrollController();
  final List<Movie> _movies = [];
  bool _grid = true;
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _sortBy = 'popularity.desc';

  String get _genre => widget.genreTitle.replaceFirst('Phim ', '').trim();
  int? get _genreId => movieGenreOptions[_genre];

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) _load();
    });
  }

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!_hasMore && !reset)) return;
    if (reset) { _page = 1; _hasMore = true; _movies.clear(); }
    setState(() => _loading = true);
    try {
      final result = await _repository.discover(page: _page, genreId: _genreId, sortBy: _sortBy);
      final existing = _movies.map((movie) => movie.id).toSet();
      final unique = result.where((movie) => !existing.contains(movie.id)).toList();
      if (mounted) {
        setState(() {
          _movies.addAll(unique);
          _hasMore = result.isNotEmpty;
          _page++;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: Text(widget.genreTitle),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Sắp xếp',
              icon: const Icon(Icons.sort_rounded),
              onSelected: (value) { _sortBy = value; _load(reset: true); },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'popularity.desc', child: Text('Phổ biến nhất')),
                PopupMenuItem(value: 'vote_average.desc', child: Text('Đánh giá cao')),
                PopupMenuItem(value: 'primary_release_date.desc', child: Text('Mới phát hành')),
              ],
            ),
            IconButton(onPressed: () => setState(() => _grid = !_grid), icon: Icon(_grid ? Icons.view_list : Icons.grid_view)),
          ],
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('${_movies.length} phim đã tải', style: const TextStyle(color: AppTheme.textMuted)),
          ),
          Expanded(
            child: _movies.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: _grid ? _gridView() : _listView(),
                  ),
          ),
          if (_loading && _movies.isNotEmpty) const LinearProgressIndicator(color: AppTheme.primaryRed),
        ]),
      );

  Widget _gridView() => GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          return MovieCard.poster(movie: movie, onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail, arguments: movie));
        },
      );

  Widget _listView() => ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _movies.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final movie = _movies[index];
          return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: FlixNetworkImage(movie.imageUrl, width: 58, height: 86, fit: BoxFit.cover)),
            title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${movie.year} • ${movie.rating.toStringAsFixed(1)} ★\n${movie.genreText}', maxLines: 2, style: AppTheme.smallText),
            onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail, arguments: movie),
          );
        },
      );
}
