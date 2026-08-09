import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_preferences.dart';
import '../data/mock_data.dart';
import '../data/tmdb_repository.dart';
import '../data/user_data_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/flix_network_image.dart';
import '../widgets/embedded_youtube_player.dart';

class TrailerScreen extends StatefulWidget {
  const TrailerScreen({super.key, this.movie});

  final Movie? movie;

  @override
  State<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends State<TrailerScreen> {
  late Movie _movie;
  bool _loading = false;
  bool _historySaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie ?? mockMovies.first;
    final hasTrailer = _hasTrailer(_movie);
    _loading = !hasTrailer;
    if (hasTrailer) _saveHistoryOnce();
    _load();
  }

  bool _hasTrailer(Movie movie) => movie.trailerKey?.isNotEmpty ?? false;

  Future<void> _load() async {
    try {
      if (int.tryParse(_movie.id) != null) {
        _movie = await TmdbRepository().detail(_movie.id);
      }
      final trailerKey = _movie.trailerKey;
      if (trailerKey == null || trailerKey.isEmpty) {
        _error = 'Phim này chưa có trailer trên YouTube.';
      } else {
        _saveHistoryOnce();
      }
    } catch (error) {
      if (!_hasTrailer(_movie)) _error = '$error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveHistoryOnce() async {
    if (_historySaved) return;
    _historySaved = true;
    try {
      await UserDataRepository().saveHistory(_movie.id);
    } catch (_) {
      // Trailer vẫn phát bình thường khi người dùng chưa đăng nhập hoặc mất mạng.
    }
  }

  Future<void> _openOnYouTube() async {
    final key = _movie.trailerKey;
    if (key == null) return;
    final launched = await launchUrl(
      Uri.parse('https://www.youtube.com/watch?v=$key'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở YouTube.')),
      );
    }
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final trailerKey = _movie.trailerKey;
    final backdrop =
        _movie.backdropUrl.isNotEmpty ? _movie.backdropUrl : _movie.imageUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Trailer ${_movie.title}'),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: AppTheme.primaryRed)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        child: trailerKey == null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  FlixNetworkImage(backdrop, fit: BoxFit.cover),
                                  Container(color: Colors.black54),
                                  const Icon(Icons.videocam_off_outlined,
                                      color: AppTheme.textMuted, size: 54),
                                ],
                              )
                            : EmbeddedYoutubePlayer(
                                videoId: trailerKey,
                                autoPlay:
                                    AppPreferences.instance.autoPlayTrailer,
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _movie.title,
                      style: AppTheme.headingMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (AppPreferences.instance.autoPlayTrailer &&
                        trailerKey != null) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Trailer tự phát ở chế độ tắt tiếng. Bạn có thể bật âm thanh trong trình phát.',
                        style: AppTheme.smallText,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (trailerKey != null) ...[
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: _openOnYouTube,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Mở trên YouTube'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
