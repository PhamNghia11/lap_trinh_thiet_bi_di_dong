import 'dart:ui';

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
  static const _relatedVideoLimit = 4;

  late Movie _movie;
  final _contentController = ScrollController();
  bool _loading = false;
  bool _historySaved = false;
  String? _error;
  String? _selectedVideoKey;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

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
      _selectedVideoKey ??= _movie.trailerKey;
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
    final key = _selectedVideoKey ?? _movie.trailerKey;
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

  void _selectVideo(MovieVideo video) {
    if (video.key == _selectedVideoKey) return;
    setState(() => _selectedVideoKey = video.key);
    if (_contentController.hasClients) {
      _contentController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  MovieVideo? get _selectedVideo {
    final key = _selectedVideoKey ?? _movie.trailerKey;
    return _movie.videos.where((video) => video.key == key).firstOrNull;
  }

  List<MovieVideo> get _relatedVideos => _movie.videos
      .where((video) => video.key != (_selectedVideoKey ?? _movie.trailerKey))
      .toList(growable: false);

  Future<void> _showAllVideos() async {
    final selected = await showModalBottomSheet<MovieVideo>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AllVideosSheet(
        videos: _movie.videos,
        selectedVideoKey: _selectedVideoKey ?? _movie.trailerKey,
      ),
    );
    if (selected != null && mounted) _selectVideo(selected);
  }

  String get _youtubeQuality => switch (AppPreferences.instance.videoQuality) {
        'Tiết kiệm dữ liệu' => 'small',
        'HD 720p' => 'hd720',
        'Full HD 1080p' => 'hd1080',
        _ => 'default',
      };

  @override
  Widget build(BuildContext context) {
    final trailerKey = _selectedVideoKey ?? _movie.trailerKey;
    final backdrop =
        _movie.backdropUrl.isNotEmpty ? _movie.backdropUrl : _movie.imageUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxPlayerHeight = constraints.maxHeight *
                    (constraints.maxWidth > constraints.maxHeight
                        ? 0.82
                        : 0.58);
                final minPlayerHeight =
                    maxPlayerHeight < 240 ? maxPlayerHeight : 240.0;
                final playerHeight = (constraints.maxWidth * 9 / 16)
                    .clamp(minPlayerHeight, maxPlayerHeight);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FlixNetworkImage(backdrop, fit: BoxFit.cover),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.66),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Quay lại',
                                  onPressed: _goBack,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                Expanded(
                                  child: Text(
                                    _movie.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: playerHeight,
                            child: trailerKey == null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FlixNetworkImage(backdrop,
                                          fit: BoxFit.cover),
                                      Container(color: Colors.black54),
                                      const Icon(Icons.videocam_off_outlined,
                                          color: AppTheme.textMuted, size: 54),
                                    ],
                                  )
                                : EmbeddedYoutubePlayer(
                                    key: ValueKey(trailerKey),
                                    videoId: trailerKey,
                                    autoPlay:
                                        AppPreferences.instance.autoPlayTrailer,
                                    quality: _youtubeQuality,
                                  ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _contentController,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 22, 20, 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedVideo?.name ?? _movie.title,
                                      style: AppTheme.headingMedium),
                                  if (_selectedVideo != null) ...[
                                    const SizedBox(height: 4),
                                    Text(_movie.title,
                                        style: AppTheme.smallText),
                                  ],
                                  const SizedBox(height: 14),
                                  _PlaybackSettings(
                                    autoPlay:
                                        AppPreferences.instance.autoPlayTrailer,
                                    quality:
                                        AppPreferences.instance.videoQuality,
                                  ),
                                  if (AppPreferences.instance.autoPlayTrailer &&
                                      trailerKey != null) ...[
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Trailer tự phát ở chế độ tắt tiếng. Chạm biểu tượng loa trong trình phát để bật âm thanh.',
                                      style: AppTheme.smallText,
                                    ),
                                  ],
                                  if (_error != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                          color: AppTheme.textMuted),
                                    ),
                                  ],
                                  if (trailerKey != null) ...[
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _openOnYouTube,
                                        icon: const Icon(Icons.open_in_new,
                                            size: 18),
                                        label: const Text('Mở trên YouTube'),
                                      ),
                                    ),
                                  ],
                                  if (_relatedVideos.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text('Video liên quan',
                                              style: AppTheme.headingSmall),
                                        ),
                                        if (_relatedVideos.length >
                                            _relatedVideoLimit)
                                          TextButton(
                                            onPressed: _showAllVideos,
                                            child: const Text('Xem tất cả'),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    for (final video in _relatedVideos
                                        .take(_relatedVideoLimit))
                                      _VideoOption(
                                        video: video,
                                        selected: false,
                                        onTap: () => _selectVideo(video),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PlaybackSettings extends StatelessWidget {
  const _PlaybackSettings({required this.autoPlay, required this.quality});

  final bool autoPlay;
  final String quality;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _TrailerMeta(
            icon: autoPlay
                ? Icons.play_circle_fill_rounded
                : Icons.play_circle_outline_rounded,
            text: autoPlay ? 'Tự động phát' : 'Phát thủ công',
          ),
          _TrailerMeta(icon: Icons.high_quality_rounded, text: quality),
          if (autoPlay)
            const _TrailerMeta(
              icon: Icons.volume_off_rounded,
              text: 'Khởi động tắt tiếng',
            ),
        ],
      );
}

class _VideoOption extends StatelessWidget {
  const _VideoOption({
    required this.video,
    required this.selected,
    required this.onTap,
  });

  final MovieVideo video;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: SizedBox(
            width: 92,
            height: 52,
            child: FlixNetworkImage(
              'https://i.ytimg.com/vi/${video.key}/mqdefault.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          video.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(_videoMetadata(video), style: AppTheme.smallText),
        trailing: Icon(
          selected ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
          color: selected ? AppTheme.primaryRed : AppTheme.textMuted,
        ),
      );
}

String _videoMetadata(MovieVideo video) {
  final parts = <String>[
    video.type,
    if (video.official) 'Official',
    if (video.language.isNotEmpty) video.language.toUpperCase(),
  ];
  return parts.join(' · ');
}

class _AllVideosSheet extends StatefulWidget {
  const _AllVideosSheet({
    required this.videos,
    required this.selectedVideoKey,
  });

  final List<MovieVideo> videos;
  final String? selectedVideoKey;

  @override
  State<_AllVideosSheet> createState() => _AllVideosSheetState();
}

class _AllVideosSheetState extends State<_AllVideosSheet> {
  String _filter = 'Tất cả';

  List<MovieVideo> get _filteredVideos => _filter == 'Tất cả'
      ? widget.videos
      : widget.videos.where((video) => video.type == _filter).toList();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text('Tất cả video', style: AppTheme.headingSmall),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['Tất cả', 'Trailer', 'Teaser', 'Clip']
                      .where((type) =>
                          type == 'Tất cả' ||
                          widget.videos.any((video) => video.type == type))
                      .map((type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: _filter == type,
                              onSelected: (_) => setState(() => _filter = type),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _filteredVideos.length,
                  itemBuilder: (context, index) {
                    final video = _filteredVideos[index];
                    return _VideoOption(
                      video: video,
                      selected: video.key == widget.selectedVideoKey,
                      onTap: () => Navigator.pop(context, video),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _TrailerMeta extends StatelessWidget {
  const _TrailerMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(text, style: AppTheme.smallText),
        ],
      );
}
