import 'dart:async';

import 'package:flutter/material.dart';

import '../data/tmdb_repository.dart';
import '../models/movie_filter.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/flix_network_image.dart';
import 'search_filter_screen.dart';
import '../core/ui_state_store.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.repository});

  final TmdbRepository? repository;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController(
    text: UiStateStore.instance.string('search.query') ?? '',
  );
  final _scrollController = PersistentScrollController('search.scroll');
  late final TmdbRepository _repository;
  Timer? _debounce;
  List<Movie> _results = [];
  late MovieFilter _filter;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _requestVersion = 0;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TmdbRepository();
    final savedFilter = UiStateStore.instance.json('search.filter');
    _filter = savedFilter == null
        ? const MovieFilter()
        : MovieFilter.fromJson(savedFilter);
    _scrollController.addListener(_onScroll);
    _runSearch();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 320 &&
        !_loading &&
        _hasMore) {
      _runSearch(reset: false);
    }
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
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
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

  Future<void> _runSearch({bool reset = true}) async {
    if (!reset && (_loading || !_hasMore)) return;
    final requestVersion = reset ? ++_requestVersion : _requestVersion;
    final page = reset ? 1 : _page;
    final query = _controller.text.trim();
    final filter = _filter;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = query.isEmpty
          ? await _repository.discover(
              page: page,
              genreId: filter.genreId,
              year: filter.year,
              sortBy: filter.sortBy,
              minRating: filter.minRating == 0 ? null : filter.minRating,
            )
          : await _repository.search(query, page: page, year: filter.year);
      if (!mounted || requestVersion != _requestVersion) return;
      var filtered = filter.genreId == null
          ? List<Movie>.from(results)
          : results
              .where((movie) => movie.genres.contains(filter.genreLabel))
              .toList();
      if (filter.minRating > 0) {
        filtered = filtered
            .where((movie) => movie.rating >= filter.minRating)
            .toList();
      }
      if (filter.sortBy == 'vote_average.desc') {
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (filter.sortBy == 'primary_release_date.desc') {
        filtered.sort((a, b) => b.year.compareTo(a.year));
      }
      setState(() {
        if (reset) {
          _results = filtered;
        } else {
          final existing = _results.map((movie) => movie.id).toSet();
          _results.addAll(
            filtered.where((movie) => !existing.contains(movie.id)),
          );
        }
        _page = page + 1;
        _hasMore = results.isNotEmpty;
      });
    } catch (error) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FlixAdaptiveScaffold(
        currentIndex: 1,
        contentMaxWidth: 1040,
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
                      tooltip: 'Xóa từ khóa tìm kiếm',
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 56, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          const Text(
                            'Không tìm thấy phim phù hợp',
                            style: AppTheme.headingSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hãy thử tìm với từ khóa khác hoặc thiết lập lại bộ lọc.',
                            style: AppTheme.smallText,
                            textAlign: TextAlign.center,
                          ),
                          if (_filter.isActive) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _filter = const MovieFilter());
                                UiStateStore.instance.setJson(
                                  'search.filter',
                                  const MovieFilter().toJson(),
                                );
                                _runSearch();
                              },
                              icon: const Icon(Icons.clear_all_rounded,
                                  size: 16, color: AppTheme.primaryRed),
                              label: const Text('Đặt lại bộ lọc',
                                  style: TextStyle(color: AppTheme.primaryRed)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
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
