import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/media_url.dart';
import '../data/tmdb_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({super.key, required this.person});

  final CastMember person;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final _repository = TmdbRepository();
  Map<String, dynamic>? _person;
  String? _error;
  bool _expandedBio = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.person(widget.person.id);
      if (mounted) setState(() => _person = data);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải hồ sơ diễn viên.');
      }
    }
  }

  String _text(String key) => _person?[key] as String? ?? '';

  List<Movie> get _movies {
    final credits = _person?['combined_credits'] as Map?;
    final cast = credits?['cast'] as List? ?? const [];
    final seen = <String>{};
    return cast
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['media_type'] == 'movie' && item['id'] != null)
        .map(Movie.fromTmdbJson)
        .where((movie) => seen.add(movie.id))
        .take(16)
        .toList(growable: false);
  }

  Future<void> _openSocial(String host, String? id) async {
    if (id == null || id.isEmpty) return;
    await launchUrl(Uri.parse('https://$host/$id'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _text('profile_path');
    final image = imagePath.isEmpty
        ? widget.person.avatarUrl
        : 'https://image.tmdb.org/t/p/h632$imagePath';
    final name = _text('name').isEmpty ? widget.person.name : _text('name');

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Hồ sơ diễn viên')),
      body: _person == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHero(name, image)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStats(),
                          const SizedBox(height: 28),
                          _buildPersonalInfo(),
                          _buildBiography(),
                          _buildSocials(),
                          _buildFilmography(),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHero(String name, String image) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF281418), AppTheme.scaffoldBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Hero(
            tag: 'person-${widget.person.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: image.isEmpty
                  ? Container(
                      width: 126,
                      height: 174,
                      color: AppTheme.inputBg,
                      child: const Icon(Icons.person, size: 64),
                    )
                  : Image.network(
                      resolveImageUrl(image),
                      width: 126,
                      height: 174,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.inputBg,
                        child: const Icon(Icons.person, size: 64),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.headingLarge),
                  const SizedBox(height: 8),
                  Text(_text('known_for_department'),
                      style: AppTheme.mutedText),
                  if (_text('place_of_birth').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppTheme.primaryRed),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(_text('place_of_birth'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.smallText),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final credits = _person?['combined_credits'] as Map?;
    final cast = credits?['cast'] as List? ?? const [];
    final popularity =
        (_person?['popularity'] as num?)?.toStringAsFixed(1) ?? '-';
    return Row(
      children: [
        _stat(Icons.movie_outlined, '${cast.length}', 'Tác phẩm'),
        _stat(Icons.trending_up, popularity, 'Độ phổ biến'),
        _stat(
            Icons.language,
            _text('known_for_department').isEmpty ? '-' : 'TMDB',
            'Nguồn dữ liệu'),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: Column(children: [
          Icon(icon, color: AppTheme.primaryRed, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.smallText),
        ]),
      );

  Widget _buildPersonalInfo() {
    final gender = switch (_person?['gender']) {
      1 => 'Nữ',
      2 => 'Nam',
      3 => 'Phi nhị nguyên',
      _ => ''
    };
    final values = <String, String>{
      'Ngày sinh': _text('birthday'),
      'Ngày mất': _text('deathday'),
      'Giới tính': gender,
    };
    final visible =
        values.entries.where((entry) => entry.value.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Thông tin cá nhân',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: visible
            .map((entry) => _InfoTile(label: entry.key, value: entry.value))
            .toList(),
      ),
    );
  }

  Widget _buildBiography() {
    final bio = _text('biography');
    if (bio.isEmpty) return const SizedBox.shrink();
    final long = bio.length > 360;
    return _Section(
      title: 'Tiểu sử',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(long && !_expandedBio ? '${bio.substring(0, 360)}…' : bio,
            style: AppTheme.bodyText),
        if (long)
          TextButton(
            onPressed: () => setState(() => _expandedBio = !_expandedBio),
            child: Text(_expandedBio ? 'Thu gọn' : 'Đọc toàn bộ tiểu sử'),
          ),
      ]),
    );
  }

  Widget _buildSocials() {
    final external = _person?['external_ids'] as Map?;
    final buttons = <Widget>[];
    if (external?['instagram_id'] != null) {
      buttons.add(_social(
          'Instagram',
          Icons.camera_alt_outlined,
          () => _openSocial(
              'instagram.com', external?['instagram_id'] as String?)));
    }
    if (external?['facebook_id'] != null) {
      buttons.add(_social(
          'Facebook',
          Icons.facebook,
          () => _openSocial(
              'facebook.com', external?['facebook_id'] as String?)));
    }
    if (external?['twitter_id'] != null) {
      buttons.add(_social('X / Twitter', Icons.alternate_email,
          () => _openSocial('x.com', external?['twitter_id'] as String?)));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return _Section(
        title: 'Mạng xã hội', child: Wrap(spacing: 8, children: buttons));
  }

  Widget _social(String label, IconData icon, VoidCallback onTap) =>
      OutlinedButton.icon(
          onPressed: onTap, icon: Icon(icon, size: 16), label: Text(label));

  Widget _buildFilmography() {
    final movies = _movies;
    if (movies.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Phim đã tham gia',
      trailing: Text('${movies.length} phim', style: AppTheme.smallText),
      child: SizedBox(
        height: 258,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: movies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return SizedBox(
              width: 132,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail,
                    arguments: movie),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: movie.imageUrl.isEmpty
                            ? Container(
                                height: 190,
                                color: AppTheme.inputBg,
                                child: const Icon(Icons.movie_outlined))
                            : Image.network(resolveImageUrl(movie.imageUrl),
                                height: 190,
                                width: 132,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    height: 190,
                                    color: AppTheme.inputBg,
                                    child: const Icon(Icons.movie_outlined))),
                      ),
                      const SizedBox(height: 7),
                      Text(movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.star,
                            size: 14, color: AppTheme.accentGold),
                        const SizedBox(width: 3),
                        Text(
                            movie.rating > 0
                                ? movie.rating.toStringAsFixed(1)
                                : 'Chưa có điểm',
                            style: AppTheme.smallText),
                        if (movie.year > 0) ...[
                          const Text(' • ',
                              style: TextStyle(color: AppTheme.textTertiary)),
                          Text('${movie.year}', style: AppTheme.smallText),
                        ],
                      ]),
                    ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: AppTheme.headingMedium),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 11),
          child,
        ]),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.smallText),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded,
              size: 52, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message),
          TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại')),
        ]),
      );
}
