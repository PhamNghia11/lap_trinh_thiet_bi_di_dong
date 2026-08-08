import 'package:flutter/material.dart';

import '../data/tmdb_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});
  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late Future<List<Movie>> _future;
  @override
  void initState() {
    super.initState();
    _future = TmdbRepository().popular();
  }

  void _reload() => setState(() => _future = TmdbRepository().popular());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(title: const Text('Phim phổ biến')),
        body: FutureBuilder<List<Movie>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRed));
            }
            if (snapshot.hasError) {
              return Center(
                  child: TextButton(
                      onPressed: _reload,
                      child: Text('${snapshot.error}\nThử lại',
                          textAlign: TextAlign.center)));
            }
            final movies = snapshot.data ?? const [];
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .58,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return MovieCard.poster(
                    movie: movie,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.movieDetail,
                        arguments: movie));
              },
            );
          },
        ),
      );
}
