// lib/screens/home_screen.dart
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';
import '../widgets/movie_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/adaptive_scaffold.dart';
import '../data/tmdb_repository.dart';
import '../data/user_data_repository.dart';
import '../models/movie_filter.dart';
import '../widgets/flix_drawer.dart';
import '../core/ui_state_store.dart';
import '../core/media_url.dart';
import '../core/app_session.dart';

Map<String, List<Movie>> diversifyGenreMovies(
  Iterable<MapEntry<String, List<Movie>>> collections, {
  required int seed,
  Iterable<String> initiallyUsedIds = const [],
}) {
  final used = initiallyUsedIds.toSet();
  return {
    for (final entry in collections)
      entry.key: (() {
        final movies = [...entry.value]
          ..shuffle(Random(seed + entry.key.hashCode));
        final fresh = movies.where((movie) => !used.contains(movie.id));
        final repeated = movies.where((movie) => used.contains(movie.id));
        final ordered = [...fresh, ...repeated];
        used.addAll(ordered.take(8).map((movie) => movie.id));
        return ordered;
      })(),
  };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = UiStateStore.instance.integer('home.banner') ?? 0;
  final _scrollController = PersistentScrollController('home.scroll');
  final TmdbRepository _repository = TmdbRepository();
  final UserDataRepository _userData = UserDataRepository();
  List<Movie> _movies = const [];
  List<Movie> _nowPlaying = const [];
  List<Movie> _continueWatching = const [];
  final Map<String, List<Movie>> _genreMovies = {};
  int _catalogSeed = DateTime.now().difference(DateTime(2020)).inDays;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadContinueWatching();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) _catalogSeed++;
      final catalog = await Future.wait([
        forceRefresh ? _repository.refreshTrending() : _repository.trending(),
        forceRefresh ? _repository.refreshPopular() : _repository.popular(),
        forceRefresh
            ? _repository.refreshNowPlaying()
            : _repository.nowPlaying(),
      ]);
      final movies = catalog[0];
      final popular = catalog[1];
      final nowPlaying = catalog[2];
      final unique = <String, Movie>{
        for (final movie in [...movies, ...popular]) movie.id: movie,
      };
      final collections =
          await Future.wait(genreList.indexed.map((entry) async {
        final index = entry.$1;
        final genre = entry.$2;
        try {
          final genreId = movieGenreOptions[genre];
          final page = 1 + ((_catalogSeed + index) % 3);
          const sorts = [
            'popularity.desc',
            'vote_average.desc',
            'primary_release_date.desc',
          ];
          final sortBy = sorts[(_catalogSeed + index) % sorts.length];
          final result = forceRefresh
              ? await _repository.refreshDiscover(
                  page: page,
                  genreId: genreId,
                  sortBy: sortBy,
                )
              : await _repository.discover(
                  page: page,
                  genreId: genreId,
                  sortBy: sortBy,
                );
          return MapEntry(genre, result);
        } catch (_) {
          return MapEntry(genre, const <Movie>[]);
        }
      }));
      final diverseCollections = diversifyGenreMovies(
        collections,
        seed: _catalogSeed,
        initiallyUsedIds: nowPlaying.take(8).map((movie) => movie.id),
      );
      if (!mounted) return;
      setState(() {
        _loadError = null;
        if (unique.isNotEmpty) _movies = unique.values.toList();
        if (nowPlaying.isNotEmpty) _nowPlaying = nowPlaying;
        for (final entry in diverseCollections.entries) {
          if (entry.value.isNotEmpty) _genreMovies[entry.key] = entry.value;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Không thể tải danh sách phim.');
    }
  }

  Future<void> _loadContinueWatching() async {
    if (!AppSession.instance.isAuthenticated) {
      return;
    }
    try {
      final rows = await _userData.history();
      final entries = rows
          .map((row) {
            final progress = (row['progress'] as num?)?.toDouble() ?? 0;
            final movieData = row['movie'];
            if (movieData is! Map || progress <= 0 || progress >= .95) {
              return null;
            }
            return Movie.fromTmdbJson(
              Map<String, dynamic>.from(movieData),
            ).copyWith(watchProgress: progress);
          })
          .whereType<Movie>()
          .take(8)
          .toList(growable: false);
      if (mounted) setState(() => _continueWatching = entries);
    } catch (_) {
      // Continue Watching is optional; catalog loading remains independent.
    }
  }

  List<Movie> _moviesByGenre(String genre) {
    return _genreMovies[genre] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final List<Movie> featuredMovies = _movies.take(4).toList();

    return FlixAdaptiveScaffold(
      currentIndex: 0,
      contentMaxWidth: 1500,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        leading: Builder(
            builder: (context) => IconButton(
                  tooltip: 'Mở menu',
                  icon: const Icon(Icons.menu, color: AppTheme.textMuted),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )),
        title: const Text('FLIX', style: AppTheme.logoStyle),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search, color: AppTheme.textMuted),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          IconButton(
            tooltip: 'Trang cá nhân',
            icon: const Icon(Icons.person, color: AppTheme.textMuted),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      desktopAppBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        title: const Text('Khám phá', style: AppTheme.headingMedium),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search, color: AppTheme.textMuted),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          IconButton(
            tooltip: 'Trang cá nhân',
            icon: const Icon(Icons.person, color: AppTheme.textMuted),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        child: RefreshIndicator(
          color: AppTheme.primaryRed,
          onRefresh: () => _loadMovies(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            child: _movies.isEmpty && _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 56, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(_loadError!, textAlign: TextAlign.center),
                          TextButton.icon(
                            onPressed: _loadMovies,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Auto-playing Hero Banner Carousel
                      Stack(
                        children: [
                          CarouselSlider(
                            options: CarouselOptions(
                              initialPage: _bannerIndex,
                              height: 380,
                              viewportFraction: 1.0,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 3),
                              autoPlayAnimationDuration:
                                  const Duration(milliseconds: 800),
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _bannerIndex = index;
                                });
                                UiStateStore.instance
                                    .setInt('home.banner', index);
                              },
                            ),
                            items: featuredMovies.map((movie) {
                              return Builder(
                                builder: (BuildContext context) {
                                  final hasBackdrop =
                                      movie.backdropUrl.isNotEmpty;
                                  final bannerUrl = hasBackdrop
                                      ? movie.backdropUrl
                                      : movie.imageUrl;
                                  return GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, AppRoutes.movieDetail,
                                        arguments: movie),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 380,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: AppTheme.appBarBg,
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  resolveImageUrl(bannerUrl)),
                                              fit: BoxFit.cover,
                                              alignment: Alignment.center,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 380,
                                          decoration: BoxDecoration(
                                              gradient:
                                                  AppTheme.bannerGradient()),
                                        ),
                                        Positioned(
                                          bottom: 24,
                                          left: 20,
                                          right: 20,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryRed,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppTheme.radiusSm),
                                                ),
                                                child: const Text(
                                                  'NỔI BẬT',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(movie.title,
                                                  style: AppTheme.headingLarge),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${movie.genreText.toUpperCase()} • ${movie.duration}',
                                                style: AppTheme.mutedText,
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  PrimaryIconButton(
                                                    text: 'Xem Trailer',
                                                    icon: Icons.play_arrow,
                                                    onPressed: () =>
                                                        Navigator.pushNamed(
                                                            context,
                                                            AppRoutes.trailer,
                                                            arguments: movie),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  OutlinedActionButton(
                                                    text: 'Chi tiết',
                                                    icon: Icons.info_outline,
                                                    onPressed: () =>
                                                        Navigator.pushNamed(
                                                            context,
                                                            AppRoutes
                                                                .movieDetail,
                                                            arguments: movie),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),

                          // Dot Indicators ở phía dưới Banner
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  featuredMovies.asMap().entries.map((entry) {
                                final isSelected = _bannerIndex == entry.key;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: isSelected ? 24.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    color: isSelected
                                        ? AppTheme.primaryRed
                                        : Colors.white38,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),

                      // Category Chips
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Thể loại',
                                style: AppTheme.headingMedium),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: genreList.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ActionChip(
                                      backgroundColor: AppTheme.cardBg,
                                      labelStyle: const TextStyle(
                                          color: AppTheme.textLight),
                                      side: const BorderSide(
                                          color: Colors.white12),
                                      label: Text(genreList[index]),
                                      onPressed: () => Navigator.pushNamed(
                                          context, AppRoutes.genreDetail,
                                          arguments:
                                              'Phim ${genreList[index]}'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_nowPlaying.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Phim đang chiếu',
                                  style: AppTheme.headingMedium),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.nowPlaying),
                                child: const Text('Xem tất cả',
                                    style:
                                        TextStyle(color: AppTheme.primaryRed)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _nowPlaying.length,
                            itemBuilder: (context, index) {
                              final movie = _nowPlaying[index];
                              return MovieCard.poster(
                                movie: movie,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.movieDetail,
                                    arguments: movie),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_continueWatching.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child:
                              Text('Xem tiếp', style: AppTheme.headingMedium),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 132,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _continueWatching.length,
                            itemBuilder: (context, index) {
                              final movie = _continueWatching[index];
                              return SizedBox(
                                width: 320,
                                child: MovieCard.listTile(
                                  movie: movie,
                                  showProgress: true,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.trailer,
                                    arguments: movie,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Các hàng phim theo từng thể loại
                      ...genreList.map((genre) {
                        final movies = _moviesByGenre(genre);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Phim $genre',
                                      style: AppTheme.headingMedium),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, AppRoutes.genreDetail,
                                        arguments: 'Phim $genre'),
                                    child: const Text('Xem tất cả',
                                        style: TextStyle(
                                            color: AppTheme.primaryRed)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: movies.length,
                                itemBuilder: (context, index) {
                                  final movie = movies[index];
                                  return MovieCard.poster(
                                    movie: movie,
                                    onTap: () => Navigator.pushNamed(
                                        context, AppRoutes.movieDetail,
                                        arguments: movie),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),

                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
      drawer: const FlixDrawer(),
    );
  }
}
