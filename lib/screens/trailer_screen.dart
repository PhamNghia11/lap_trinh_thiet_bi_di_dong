import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mock_data.dart';
import '../data/tmdb_repository.dart';
import '../data/user_data_repository.dart';
import '../models/movie_model.dart';
import '../theme/app_theme.dart';
import '../widgets/flix_network_image.dart';

class TrailerScreen extends StatefulWidget {
  const TrailerScreen({super.key, this.movie});
  final Movie? movie;
  @override
  State<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends State<TrailerScreen> {
  late Movie _movie;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie ?? mockMovies.first;
    _load();
  }

  Future<void> _load() async {
    try {
      if (int.tryParse(_movie.id) != null) _movie = await TmdbRepository().detail(_movie.id);
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _play() async {
    final key = _movie.trailerKey;
    if (key == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phim này chưa có trailer trên YouTube')));
      return;
    }
    final uri = Uri.parse('https://www.youtube.com/watch?v=$key');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở YouTube')));
      return;
    }
    try {
      await UserDataRepository().saveHistory(_movie.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Trailer ${_movie.title}'),
        ),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator(color: AppTheme.primaryRed)
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(fit: StackFit.expand, alignment: Alignment.center, children: [
                        FlixNetworkImage(_movie.imageUrl, fit: BoxFit.cover),
                        Container(color: Colors.black45),
                        Center(
                          child: IconButton(
                            onPressed: _play,
                            iconSize: 76,
                            icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryRed),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    Text(_movie.title, style: AppTheme.headingMedium, textAlign: TextAlign.center),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
                    ],
                  ]),
                ),
        ),
      );
}
