import 'dart:async';

import 'package:flutter/material.dart';

import '../data/tmdb_repository.dart';
import '../models/movie_filter.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/flix_network_image.dart';
import 'search_filter_screen.dart';
import '../core/ui_state_store.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController(
    text: UiStateStore.instance.string('search.query') ?? '',
  );
  final _scrollController = PersistentScrollController('search.scroll');
  final _repository = TmdbRepository();
  Timer? _debounce;
  List<Movie> _results = [];
  late MovieFilter _filter;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final savedFilter = UiStateStore.instance.json('search.filter');
    _filter = savedFilter == null
        ? const MovieFilter()
        : MovieFilter.fromJson(savedFilter);
    _runSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    UiStateStore.instance.setString('search.query', value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runSearch);
  }

  Future<void> _openFilter() async {
    final result = await Navigator.push<MovieFilter>(
      context,
      MaterialPageRoute(builder: (_) => SearchFilterScreen(initial: _filter)),
    );
    if (result == null || !mounted) return;
    setState(() => _filter = result);
    UiStateStore.instance.setJson('search.filter', result.toJson());
    _runSearch();
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _controller.text.trim();
      final results = query.isEmpty
          ? await _repository.discover(
              genreId: _filter.genreId,
              year: _filter.year,
              sortBy: _filter.sortBy,
              minRating: _filter.minRating == 0 ? null : _filter.minRating,
            )
          : await _repository.search(query, year: _filter.year);
      var filtered = _filter.genreId == null
          ? List<Movie>.from(results)
          : results
              .where((movie) => movie.genres.contains(_filter.genreLabel))
              .toList();
      if (_filter.minRating > 0) {
        filtered = filtered
            .where((movie) => movie.rating >= _filter.minRating)
            .toList();
      }
      if (_filter.sortBy == 'vote_average.desc') {
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (_filter.sortBy == 'primary_release_date.desc') {
        filtered.sort((a, b) => b.year.compareTo(a.year));
      }
      if (mounted) setState(() => _results = filtered);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          titleSpacing: 8,
          title: TextField(
            controller: _controller,
            onChanged: _onChanged,
            onSubmitted: (_) => _runSearch(),
            style: const TextStyle(color: Colors.white),
            decoration: AppTheme.inputDecoration(
              hintText: 'Tên phim, ví dụ: Batman',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    ),
            ),
          ),
          actions: [
            Badge(
              isLabelVisible: _filter.isActive,
              smallSize: 8,
              child: IconButton(
                tooltip: 'Bộ lọc',
                onPressed: _openFilter,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_filter.isActive)
            SizedBox(
              height: 50,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: [
                  if (_filter.genreId != null) _chip(_filter.genreLabel),
                  if (_filter.year != null) _chip('${_filter.year}'),
                  if (_filter.minRating > 0)
                    _chip('Từ ${_filter.minRating.toStringAsFixed(1)} ★'),
                  if (_filter.sortBy != 'popularity.desc')
                    _chip(_filter.sortLabel),
                ],
              ),
            ),
          if (_loading)
            const LinearProgressIndicator(color: AppTheme.primaryRed),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              _controller.text.trim().isEmpty
                  ? 'Khám phá phim'
                  : '${_results.length} kết quả',
              style: AppTheme.headingSmall,
            ),
          ),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent))),
          Expanded(
            child: _results.isEmpty && !_loading
                ? const Center(
                    child: Text(
                        'Không tìm thấy phim phù hợp. Hãy thử nới bộ lọc.',
                        style: AppTheme.bodyText,
                        textAlign: TextAlign.center))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final movie = _results[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FlixNetworkImage(movie.imageUrl,
                                width: 58, height: 86, fit: BoxFit.cover)),
                        title: Text(movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${movie.year == 0 ? 'Chưa rõ năm' : movie.year}  •  ${movie.rating.toStringAsFixed(1)} ★\n${movie.genreText}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.smallText),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppTheme.textMuted),
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.movieDetail,
                            arguments: movie),
                      );
                    },
                  ),
          ),
        ]),
        bottomNavigationBar: const FlixBottomNavBar(currentIndex: 1),
      );

  Widget _chip(String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(label),
          backgroundColor: AppTheme.cardBg,
          side: const BorderSide(color: Colors.white12),
          labelStyle: const TextStyle(color: AppTheme.textLight, fontSize: 12),
        ),
      );
}
