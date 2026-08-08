import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../data/user_data_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/movie_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _repository = UserDataRepository();
  late Future<List<Movie>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Movie>> _load() async {
    if (!AppSession.instance.isAuthenticated) return [];
    return _repository.favorites();
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _remove(Movie movie) async {
    try {
      await _repository.removeFavorite(movie.id);
      _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(title: const Text('Phim yêu thích'), actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ]),
        body: !AppSession.instance.isAuthenticated
            ? _loginRequired()
            : FutureBuilder<List<Movie>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
                  }
                  if (snapshot.hasError) {
                    return _message('${snapshot.error}', action: _reload);
                  }
                  final movies = snapshot.data ?? const [];
                  if (movies.isEmpty) return _message('Bạn chưa lưu phim yêu thích nào.');
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: .58,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        return Stack(children: [
                          Positioned.fill(
                            child: MovieCard.poster(
                              movie: movie,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail, arguments: movie),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: IconButton.filled(
                              onPressed: () => _remove(movie),
                              icon: const Icon(Icons.favorite, color: AppTheme.primaryRed),
                            ),
                          ),
                        ]);
                      },
                    ),
                  );
                },
              ),
        bottomNavigationBar: const FlixBottomNavBar(currentIndex: 2),
      );

  Widget _loginRequired() => _message(
        'Đăng nhập để đồng bộ danh sách yêu thích.',
        action: () => Navigator.pushNamed(context, AppRoutes.login).then((_) => _reload()),
        actionText: 'Đăng nhập',
      );

  Widget _message(String text, {VoidCallback? action, String actionText = 'Thử lại'}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.favorite_border, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: AppTheme.bodyText),
            if (action != null) TextButton(onPressed: action, child: Text(actionText)),
          ]),
        ),
      );
}
