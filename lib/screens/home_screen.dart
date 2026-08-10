// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';
import '../widgets/movie_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../data/tmdb_repository.dart';
import '../models/movie_filter.dart';
import '../widgets/flix_drawer.dart';
import '../core/ui_state_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = UiStateStore.instance.integer('home.banner') ?? 0;
  final _scrollController = PersistentScrollController('home.scroll');
  final TmdbRepository _repository = TmdbRepository();
  List<Movie> _movies = mockMovies;
  List<Movie> _nowPlaying = const [];
  final Map<String, List<Movie>> _genreMovies = {};

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    try {
      final catalog = await Future.wait([
        _repository.trending(),
        _repository.popular(),
        _repository.nowPlaying(),
      ]);
      final movies = catalog[0];
      final popular = catalog[1];
      final nowPlaying = catalog[2];
      final unique = <String, Movie>{
        for (final movie in [...movies, ...popular]) movie.id: movie,
      };
      final collections = await Future.wait(genreList.map((genre) async {
        try {
          final result =
              await _repository.discover(genreId: movieGenreOptions[genre]);
          return MapEntry(genre, result);
        } catch (_) {
          return MapEntry(genre, const <Movie>[]);
        }
      }));
      if (!mounted) return;
      setState(() {
        if (unique.isNotEmpty) _movies = unique.values.toList();
        if (nowPlaying.isNotEmpty) _nowPlaying = nowPlaying;
        for (final entry in collections) {
          if (entry.value.isNotEmpty) _genreMovies[entry.key] = entry.value;
        }
      });
    } catch (_) {
      // Giữ dữ liệu mẫu để ứng dụng vẫn sử dụng được khi backend đang tắt.
    }
  }

  List<Movie> _moviesByGenre(String genre) {
    return _genreMovies[genre] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final List<Movie> featuredMovies = _movies.take(4).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        leading: Builder(
            builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: AppTheme.textMuted),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )),
        title: const Text('FLIX', style: AppTheme.logoStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textMuted),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: AppTheme.textMuted),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
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
                      UiStateStore.instance.setInt('home.banner', index);
                    },
                  ),
                  items: featuredMovies.map((movie) {
                    return Builder(
                      builder: (BuildContext context) {
                        final hasBackdrop = movie.backdropUrl.isNotEmpty;
                        final bannerUrl =
                            hasBackdrop ? movie.backdropUrl : movie.imageUrl;
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
                                    image: NetworkImage(bannerUrl),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              ),
                              Container(
                                height: 380,
                                decoration: BoxDecoration(
                                    gradient: AppTheme.bannerGradient()),
                              ),
                              Positioned(
                                bottom: 24,
                                left: 20,
                                right: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryRed,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSm),
                                      ),
                                      child: const Text(
                                        'NỔI BẬT',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
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
                                          onPressed: () => Navigator.pushNamed(
                                              context, AppRoutes.trailer,
                                              arguments: movie),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedActionButton(
                                          text: 'Chi tiết',
                                          icon: Icons.info_outline,
                                          onPressed: () => Navigator.pushNamed(
                                              context, AppRoutes.movieDetail,
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
                    children: featuredMovies.asMap().entries.map((entry) {
                      final isSelected = _bannerIndex == entry.key;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 24.0 : 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color:
                              isSelected ? AppTheme.primaryRed : Colors.white38,
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
                  const Text('Thể loại', style: AppTheme.headingMedium),
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
                            labelStyle:
                                const TextStyle(color: AppTheme.textLight),
                            side: const BorderSide(color: Colors.white12),
                            label: Text(genreList[index]),
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.genreDetail,
                                arguments: 'Phim ${genreList[index]}'),
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
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.nowPlaying),
                      child: const Text('Xem tất cả',
                          style: TextStyle(color: AppTheme.primaryRed)),
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

            // Các hàng phim theo từng thể loại
            ...genreList.map((genre) {
              final movies = _moviesByGenre(genre);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Phim $genre', style: AppTheme.headingMedium),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.genreDetail,
                              arguments: 'Phim $genre'),
                          child: const Text('Xem tất cả',
                              style: TextStyle(color: AppTheme.primaryRed)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
      drawer: const FlixDrawer(),
      bottomNavigationBar: const FlixBottomNavBar(currentIndex: 0),
    );
  }
}
