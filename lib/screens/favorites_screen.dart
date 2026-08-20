import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../data/user_data_repository.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/movie_card.dart';
import '../core/ui_state_store.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _repository = UserDataRepository();
  final _searchController = TextEditingController(
    text: UiStateStore.instance.string('favorites.query') ?? '',
  );
  final _scrollController = PersistentScrollController('favorites.scroll');
  final Set<String> _selectedIds = {};

  List<Movie> _movies = [];
  bool _loading = true;
  String? _error;
  bool _multiSelect =
      UiStateStore.instance.boolean('favorites.multiSelect') ?? false;
  String _searchQuery = UiStateStore.instance.string('favorites.query') ?? '';
  String _selectedGenre =
      UiStateStore.instance.string('favorites.genre') ?? 'Tất cả';
  String _selectedSort =
      UiStateStore.instance.string('favorites.sort') ?? 'Mới thêm';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(
      UiStateStore.instance.strings('favorites.selected') ?? const [],
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.instance.isAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final movies = await _repository.favorites();
      if (mounted) setState(() => _movies = movies);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Movie> get _filteredMovies {
    final query = _searchQuery.trim().toLowerCase();
    final result = _movies.where((movie) {
      final matchesQuery =
          query.isEmpty || movie.title.toLowerCase().contains(query);
      final matchesGenre =
          _selectedGenre == 'Tất cả' || movie.genres.contains(_selectedGenre);
      return matchesQuery && matchesGenre;
    }).toList();

    if (_selectedSort == 'A-Z') {
      result.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == 'Đánh giá') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return result;
  }

  List<String> get _genres {
    final genres = _movies.expand((movie) => movie.genres).toSet().toList()
      ..sort();
    return ['Tất cả', ...genres];
  }

  void _toggleSelection(String id) {
    setState(() {
      _selectedIds.contains(id)
          ? _selectedIds.remove(id)
          : _selectedIds.add(id);
      if (_selectedIds.isEmpty) _multiSelect = false;
    });
    _saveSelection();
  }

  void _saveSelection() {
    UiStateStore.instance.setBool('favorites.multiSelect', _multiSelect);
    UiStateStore.instance.setStrings('favorites.selected', _selectedIds);
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelect = false;
      _selectedIds.clear();
    });
    _saveSelection();
  }

  Future<void> _removeSingle(Movie movie) async {
    final index = _movies.indexWhere((item) => item.id == movie.id);
    setState(() => _movies.removeWhere((item) => item.id == movie.id));
    try {
      await _repository.removeFavorite(movie.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${movie.title}" khỏi Yêu thích'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () => _restoreFavorite(movie, index),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _movies.insert(index < 0 ? 0 : index, movie));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _restoreFavorite(Movie movie, int index) async {
    try {
      await _repository.addFavorite(movie.id);
      if (!mounted || _movies.any((item) => item.id == movie.id)) return;
      setState(() => _movies.insert(index.clamp(0, _movies.length), movie));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title:
            const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Xóa ${_selectedIds.length} phim đã chọn khỏi danh sách yêu thích?',
          style: AppTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ids = Set<String>.from(_selectedIds);
    try {
      await Future.wait(ids.map(_repository.removeFavorite));
      if (!mounted) return;
      setState(() {
        _movies.removeWhere((movie) => ids.contains(movie.id));
        _selectedIds.clear();
        _multiSelect = false;
      });
      _saveSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa ${ids.length} phim khỏi Yêu thích')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMovies = _filteredMovies;
    return FlixAdaptiveScaffold(
      currentIndex: 2,
      contentMaxWidth: 1180,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        title: Text(
          _multiSelect ? 'Đã chọn ${_selectedIds.length}' : 'Phim Yêu Thích',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_multiSelect) ...[
            IconButton(
              tooltip: 'Chọn tất cả',
              onPressed: filteredMovies.isEmpty
                  ? null
                  : () {
                      setState(() =>
                          _selectedIds.addAll(filteredMovies.map((m) => m.id)));
                      _saveSelection();
                    },
              icon: const Icon(Icons.select_all_rounded),
            ),
            IconButton(
              tooltip: 'Xóa mục đã chọn',
              onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.primaryRed),
            ),
            IconButton(
              tooltip: 'Thoát chế độ chọn',
              onPressed: _exitMultiSelect,
              icon: const Icon(Icons.close_rounded),
            ),
          ] else ...[
            if (_movies.isNotEmpty)
              IconButton(
                tooltip: 'Chọn nhiều phim',
                onPressed: () {
                  setState(() => _multiSelect = true);
                  _saveSelection();
                },
                icon: const Icon(Icons.checklist_rtl_rounded),
              ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
      body: _buildBody(filteredMovies),
    );
  }

  Widget _buildBody(List<Movie> filteredMovies) {
    if (!AppSession.instance.isAuthenticated) {
      return _buildEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Đăng nhập để xem Yêu thích',
        description:
            'Danh sách yêu thích sẽ được đồng bộ trên mọi thiết bị của bạn.',
        actionText: 'Đăng nhập',
        onAction: () =>
            Navigator.pushNamed(context, AppRoutes.login).then((_) => _load()),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }
    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Không tải được danh sách',
        description: _error!,
        actionText: 'Thử lại',
        onAction: _load,
      );
    }
    if (_movies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Chưa Có Phim Yêu Thích',
        description:
            'Nhấn biểu tượng trái tim ở phim bạn thích để lưu lại tại đây.',
        actionText: 'Khám phá phim ngay',
        onAction: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.cardBg.withValues(alpha: 0.5),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  UiStateStore.instance.setString('favorites.query', value);
                },
                decoration: AppTheme.inputDecoration(
                  hintText: 'Tìm phim yêu thích...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.primaryRed),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            UiStateStore.instance
                                .setString('favorites.query', '');
                          },
                          icon: const Icon(Icons.clear,
                              color: AppTheme.textMuted),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _genres.map((genre) {
                    final selected = _selectedGenre == genre;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(genre),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedGenre = genre);
                          UiStateStore.instance
                              .setString('favorites.genre', genre);
                        },
                        selectedColor: AppTheme.primaryRed,
                        backgroundColor: AppTheme.cardBg,
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${filteredMovies.length} phim yêu thích',
                  style: AppTheme.smallText),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedSort,
                dropdownColor: AppTheme.cardBg,
                underline: const SizedBox(),
                iconEnabledColor: AppTheme.primaryRed,
                items: const ['Mới thêm', 'A-Z', 'Đánh giá']
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSort = value);
                    UiStateStore.instance.setString('favorites.sort', value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredMovies.isEmpty
              ? const Center(
                  child: Text('Không tìm thấy phim phù hợp',
                      style: AppTheme.bodyText),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 210,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = filteredMovies[index];
                      final selected = _selectedIds.contains(movie.id);
                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _multiSelect = true;
                            _selectedIds.add(movie.id);
                          });
                          _saveSelection();
                        },
                        onTap: () => _multiSelect
                            ? _toggleSelection(movie.id)
                            : Navigator.pushNamed(
                                context,
                                AppRoutes.movieDetail,
                                arguments: movie,
                              ).then((_) => _load()),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: MovieCard.grid(
                                movie: movie,
                                showBadge: true,
                                showRating: true,
                              ),
                            ),
                            if (_multiSelect)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppTheme.primaryRed
                                            .withValues(alpha: 0.28)
                                        : Colors.black38,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLg),
                                    border: Border.all(
                                      color: selected
                                          ? AppTheme.primaryRed
                                          : Colors.white30,
                                      width: 2,
                                    ),
                                  ),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        selected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () => _removeSingle(movie),
                                  borderRadius: BorderRadius.circular(20),
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(7),
                                      child: Icon(Icons.favorite,
                                          color: AppTheme.primaryRed, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(icon, size: 64, color: AppTheme.primaryRed),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center, style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center, style: AppTheme.bodyText),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
