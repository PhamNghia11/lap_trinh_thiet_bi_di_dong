import 'package:flutter/material.dart';

import '../data/tmdb_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/flix_network_image.dart';
import '../widgets/adaptive_scaffold.dart';
import '../core/ui_state_store.dart';

enum MovieCollection { popular, nowPlaying }

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    this.collection = MovieCollection.popular,
    this.repository,
  });

  final MovieCollection collection;
  final TmdbRepository? repository;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final PersistentScrollController _scrollController;
  late final TmdbRepository _repository;
  final List<Movie> _movies = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;

  String get _title => widget.collection == MovieCollection.nowPlaying
      ? 'Phim Đang Chiếu'
      : 'Danh Sách Phim Nổi Bật';

  Future<List<Movie>> _fetch(int page) =>
      widget.collection == MovieCollection.nowPlaying
          ? _repository.nowPlaying(page: page)
          : _repository.popular(page: page);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TmdbRepository();
    _scrollController = PersistentScrollController(
      'movieList.${widget.collection.name}.scroll',
    );
    _scrollController.addListener(_onScroll);
    _load();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 320 &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!_hasMore && !reset)) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
      _error = null;
      _movies.clear();
    }
    setState(() => _loading = true);
    try {
      final result = await _fetch(_page);
      final existing = _movies.map((movie) => movie.id).toSet();
      final unique =
          result.where((movie) => !existing.contains(movie.id)).toList();
      if (!mounted) return;
      setState(() {
        _movies.addAll(unique);
        _hasMore = result.isNotEmpty;
        _page++;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => _load(reset: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FlixResponsiveContent(maxWidth: 920, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_movies.isEmpty && _loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }
    if (_movies.isEmpty && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => _load(reset: true),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _movies.length,
              itemBuilder: (context, index) => _movieTile(_movies[index]),
            ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(color: AppTheme.primaryRed),
      ],
    );
  }

  Widget _movieTile(Movie movie) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.movieDetail,
        arguments: movie,
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: FlixNetworkImage(
                movie.imageUrl,
                width: 80,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${movie.year == 0 ? 'Chưa rõ năm' : movie.year} • ${movie.genreText}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.smallText,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppTheme.accentGold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.rating.toStringAsFixed(1)} / 10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
