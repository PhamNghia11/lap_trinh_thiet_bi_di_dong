import 'package:flutter/material.dart';

import '../data/tmdb_repository.dart';
import '../models/movie_filter.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../widgets/adaptive_scaffold.dart';
import '../core/ui_state_store.dart';

class GenreDetailScreen extends StatefulWidget {
  const GenreDetailScreen({super.key, this.genreTitle = 'Phim Hành Động'});

  final String genreTitle;

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  final _repository = TmdbRepository();
  late final PersistentScrollController _gridController;
  late final PersistentScrollController _listController;
  final List<Movie> _movies = [];

  bool _gridView = true;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  String _sortLabel = 'Phổ biến nhất';
  int? _year;
  double _minRating = 0;

  static const _sortOptions = <String, String>{
    'Phổ biến nhất': 'popularity.desc',
    'Đánh giá cao': 'vote_average.desc',
    'Mới phát hành': 'primary_release_date.desc',
  };

  String get _genre => widget.genreTitle.replaceFirst('Phim ', '').trim();
  int? get _genreId => movieGenreOptions[_genre];
  String get _stateKey => 'genre.${widget.genreTitle}';

  @override
  void initState() {
    super.initState();
    _gridView = UiStateStore.instance.boolean('$_stateKey.grid') ?? true;
    _sortLabel =
        UiStateStore.instance.string('$_stateKey.sort') ?? 'Phổ biến nhất';
    _year = UiStateStore.instance.integer('$_stateKey.year');
    _minRating = UiStateStore.instance.decimal('$_stateKey.rating') ?? 0;
    _gridController = PersistentScrollController('$_stateKey.gridScroll');
    _listController = PersistentScrollController('$_stateKey.listScroll');
    _gridController.addListener(() => _onScroll(_gridController));
    _listController.addListener(() => _onScroll(_listController));
    _load();
  }

  @override
  void dispose() {
    _gridController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollController controller) {
    if (controller.hasClients &&
        controller.position.extentAfter < 320 &&
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
      final result = await _repository.discover(
        page: _page,
        genreId: _genreId,
        year: _year,
        sortBy: _sortOptions[_sortLabel]!,
        minRating: _minRating == 0 ? null : _minRating,
      );
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

  Future<void> _openFilters() async {
    var draftYear = _year;
    var draftRating = _minRating;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Bộ Lọc Nâng Cao',
                        style: AppTheme.headingMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        draftYear = null;
                        draftRating = 0;
                      }),
                      child: const Text('Đặt lại'),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Năm phát hành', style: AppTheme.headingSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <int?>[null, 2026, 2025, 2024, 2023, 2022]
                      .map((year) => ChoiceChip(
                            label: Text(year?.toString() ?? 'Tất cả'),
                            selected: draftYear == year,
                            onSelected: (_) =>
                                setSheetState(() => draftYear = year),
                            selectedColor: AppTheme.primaryRed,
                            backgroundColor: AppTheme.scaffoldBg,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  draftRating == 0
                      ? 'Điểm đánh giá: Tất cả'
                      : 'Điểm đánh giá từ ${draftRating.toStringAsFixed(1)}',
                  style: AppTheme.headingSmall,
                ),
                Slider(
                  value: draftRating,
                  min: 0,
                  max: 9,
                  divisions: 18,
                  activeColor: AppTheme.primaryRed,
                  label: draftRating.toStringAsFixed(1),
                  onChanged: (value) =>
                      setSheetState(() => draftRating = value),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Áp Dụng Bộ Lọc'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied != true) return;
    setState(() {
      _year = draftYear;
      _minRating = draftRating;
    });
    if (_year == null) {
      UiStateStore.instance.remove('$_stateKey.year');
    } else {
      UiStateStore.instance.setInt('$_stateKey.year', _year!);
    }
    UiStateStore.instance.setDouble('$_stateKey.rating', _minRating);
    await _load(reset: true);
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
            onPressed: _goBack,
          ),
          title: Text(widget.genreTitle,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: _gridView ? 'Chế độ Danh sách' : 'Chế độ Lưới',
              onPressed: () {
                setState(() => _gridView = !_gridView);
                UiStateStore.instance.setBool('$_stateKey.grid', _gridView);
              },
              icon: Icon(_gridView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded),
            ),
            IconButton(
              tooltip: 'Tìm kiếm',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
              icon: const Icon(Icons.search, color: AppTheme.textMuted),
            ),
          ],
        ),
        body: FlixResponsiveContent(
          maxWidth: 1180,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                color: AppTheme.cardBg.withValues(alpha: 0.5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('${_movies.length} phim đã tải',
                            style: AppTheme.smallText),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: Text(
                            _year == null && _minRating == 0
                                ? 'Bộ lọc'
                                : 'Đang lọc',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _sortOptions.keys.map((option) {
                          final selected = _sortLabel == option;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(option),
                              selected: selected,
                              selectedColor: AppTheme.primaryRed,
                              backgroundColor: AppTheme.cardBg,
                              visualDensity: VisualDensity.compact,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                if (selected) return;
                                setState(() => _sortLabel = option);
                                UiStateStore.instance
                                    .setString('$_stateKey.sort', option);
                                _load(reset: true);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildContent()),
              if (_loading && _movies.isNotEmpty)
                const LinearProgressIndicator(color: AppTheme.primaryRed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                  child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_movies.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          children: const [
            SizedBox(height: 160),
            Icon(Icons.movie_filter_outlined,
                size: 60, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('Không có phim phù hợp',
                textAlign: TextAlign.center, style: AppTheme.bodyText),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: AppTheme.durationMedium,
      child: RefreshIndicator(
        key: ValueKey(_gridView),
        onRefresh: () => _load(reset: true),
        child: _gridView ? _grid() : _list(),
      ),
    );
  }

  Widget _grid() {
    return GridView.builder(
      controller: _gridController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _movies.length,
      itemBuilder: (context, index) {
        final movie = _movies[index];
        return MovieCard.grid(
          movie: movie,
          showBadge: true,
          showRating: true,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.movieDetail,
            arguments: movie,
          ),
        );
      },
    );
  }

  Widget _list() {
    return ListView.builder(
      controller: _listController,
      padding: const EdgeInsets.all(16),
      itemCount: _movies.length,
      itemBuilder: (context, index) {
        final movie = _movies[index];
        return MovieCard.listTile(
          movie: movie,
          showBadge: true,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.movieDetail,
            arguments: movie,
          ),
        );
      },
    );
  }
}
