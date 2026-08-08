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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _bannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Movie> featuredMovies = bannerMovies;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.textMuted),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-playing Hero Banner Carousel
            Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 380,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _bannerIndex = index;
                      });
                    },
                  ),
                  items: featuredMovies.map((movie) {
                    return Builder(
                      builder: (BuildContext context) {
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail),
                          child: Stack(
                            children: [
                              Container(
                                height: 380,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(movie.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Container(
                                height: 380,
                                decoration: BoxDecoration(gradient: AppTheme.bannerGradient()),
                              ),
                              Positioned(
                                bottom: 24,
                                left: 20,
                                right: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryRed,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: const Text(
                                        'NỔI BẬT',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(movie.title, style: AppTheme.headingLarge),
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
                                          onPressed: () => Navigator.pushNamed(context, AppRoutes.trailer),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedActionButton(
                                          text: 'Chi tiết',
                                          icon: Icons.info_outline,
                                          onPressed: () => Navigator.pushNamed(context, AppRoutes.movieDetail),
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
                          color: isSelected ? AppTheme.primaryRed : Colors.white38,
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
                            labelStyle: const TextStyle(color: AppTheme.textLight),
                            side: const BorderSide(color: Colors.white12),
                            label: Text(genreList[index]),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.genreDetail),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Các hàng phim theo từng thể loại
            ...genreList.map((genre) {
              final movies = getMoviesByGenre(genre);
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
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.genreDetail),
                          child: const Text('Xem tất cả', style: TextStyle(color: AppTheme.primaryRed)),
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
                          onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail),
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
      bottomNavigationBar: FlixBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.search);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.favorites);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.history);
          if (index == 4) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }
}
