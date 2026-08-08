import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/tmdb_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/flix_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _repository = TmdbRepository();
  Timer? _debounce;
  List<Movie> _results = suggestedMovies;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() { _results = suggestedMovies; _error = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await _repository.search(query);
      if (mounted && query == _controller.text.trim()) setState(() => _results = results);
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
          title: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            onSubmitted: (value) => value.trim().isNotEmpty ? _search(value.trim()) : null,
            style: const TextStyle(color: Colors.white),
            decoration: AppTheme.inputDecoration(
              hintText: 'Tìm phim theo tên...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
              suffixIcon: _controller.text.isEmpty ? null : IconButton(
                onPressed: () { _controller.clear(); _onChanged(''); },
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
              ),
            ),
          ),
        ),
        body: Column(children: [
          if (_loading) const LinearProgressIndicator(color: AppTheme.primaryRed),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Không tìm thấy phim phù hợp', style: AppTheme.bodyText))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final movie = _results[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FlixNetworkImage(movie.imageUrl, width: 52, height: 78, fit: BoxFit.cover),
                        ),
                        title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('${movie.year}  •  ${movie.rating.toStringAsFixed(1)} ★', style: AppTheme.smallText),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail, arguments: movie),
                      );
                    },
                  ),
          ),
        ]),
        bottomNavigationBar: const FlixBottomNavBar(currentIndex: 1),
      );
}
