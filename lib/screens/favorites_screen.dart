// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';
import '../widgets/movie_card.dart';
import '../widgets/bottom_nav_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<Movie> _favoriteList;
  final Set<String> _selectedIds = {};
  bool _isMultiSelectMode = false;

  String _searchQuery = '';
  String _selectedGenre = 'Tất cả';
  String _selectedSort = 'Mới thêm';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _favoriteList = List.from(favoriteMovies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lọc danh sách phim yêu thích theo từ khóa, thể loại và sắp xếp
  List<Movie> _getFilteredFavorites() {
    List<Movie> list = List.from(_favoriteList);

    // Lọc theo từ khóa tìm kiếm
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
              (m) => m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Lọc theo thể loại
    if (_selectedGenre != 'Tất cả') {
      list = list.where((m) => m.genres.contains(_selectedGenre)).toList();
    }

    // Sắp xếp
    if (_selectedSort == 'A-Z') {
      list.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == 'Đánh giá') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return list;
  }

  /// Bật/Tắt chọn item trong chế độ Multi-select
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// Xóa các item đã chọn trong chế độ chọn nhiều
  void _deleteSelectedItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title:
            const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${_selectedIds.length} phim đã chọn khỏi danh sách yêu thích?',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle(),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _favoriteList.removeWhere((m) => _selectedIds.contains(m.id));
                _selectedIds.clear();
                _isMultiSelectMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đã xóa phim khỏi danh sách yêu thích!')),
              );
            },
            child: const Text('Xóa',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Xóa 1 phim lẻ khỏi danh sách yêu thích
  void _removeSingleFavorite(Movie movie) {
    setState(() {
      _favoriteList.removeWhere((m) => m.id == movie.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${movie.title}" khỏi Yêu thích'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            setState(() {
              _favoriteList.add(movie);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMovies = _getFilteredFavorites();
    final isEmpty = _favoriteList.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        title: Text(
          _isMultiSelectMode
              ? 'Đã chọn ${_selectedIds.length}'
              : 'Phim Yêu Thích',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all_rounded, color: Colors.white),
              tooltip: 'Chọn tất cả',
              onPressed: () {
                setState(() {
                  _selectedIds.addAll(filteredMovies.map((m) => m.id));
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.primaryRed),
              tooltip: 'Xóa mục đã chọn',
              onPressed: _selectedIds.isEmpty ? null : _deleteSelectedItems,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedIds.clear();
                });
              },
            ),
          ] else if (!isEmpty) ...[
            IconButton(
              icon:
                  const Icon(Icons.checklist_rtl_rounded, color: Colors.white),
              tooltip: 'Chế độ chọn nhiều',
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = true;
                });
              },
            ),
          ],
        ],
      ),
      body: isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // ─── Thanh Tìm Kiếm Nhanh & Chip Lọc Thể Loại ───────
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.cardBg.withValues(alpha: 0.5),
                  child: Column(
                    children: [
                      // Ô tìm kiếm nhanh
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Tìm phim yêu thích...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppTheme.primaryRed),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppTheme.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Hàng Chip Lọc Thể Loại
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            'Tất cả',
                            'Hành Động',
                            'Viễn Tưởng',
                            'Kinh Dị',
                            'Tình Cảm',
                            'Hài Hước'
                          ].map((genre) {
                            final selected = _selectedGenre == genre;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(genre),
                                selected: selected,
                                selectedColor: AppTheme.primaryRed,
                                backgroundColor: AppTheme.cardBg,
                                visualDensity: VisualDensity.compact,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                ),
                                onSelected: (val) {
                                  setState(() => _selectedGenre = genre);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Header Thống kê & Dropdown Sắp Xếp ────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredMovies.length} phim yêu thích',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedSort,
                        dropdownColor: AppTheme.cardBg,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: AppTheme.primaryRed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        items: ['Mới thêm', 'A-Z', 'Đánh giá'].map((sort) {
                          return DropdownMenuItem(
                            value: sort,
                            child: Text(sort),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSort = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // ─── Danh sách Grid Phim Yêu Thích ──────────────────
                Expanded(
                  child: filteredMovies.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy phim phù hợp',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filteredMovies.length,
                          itemBuilder: (context, index) {
                            final movie = filteredMovies[index];
                            final isSelected = _selectedIds.contains(movie.id);

                            return GestureDetector(
                              onLongPress: () {
                                if (!_isMultiSelectMode) {
                                  setState(() {
                                    _isMultiSelectMode = true;
                                    _selectedIds.add(movie.id);
                                  });
                                }
                              },
                              onTap: () {
                                if (_isMultiSelectMode) {
                                  _toggleSelection(movie.id);
                                } else {
                                  Navigator.pushNamed(
                                      context, AppRoutes.movieDetail,
                                      arguments: movie);
                                }
                              },
                              child: Stack(
                                children: [
                                  MovieCard.grid(
                                    movie: movie,
                                    showBadge: true,
                                    showRating: true,
                                  ),

                                  // Overlay Checkbox khi ở Chế độ Chọn Nhiều
                                  if (_isMultiSelectMode)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryRed
                                                  .withValues(alpha: 0.3)
                                              : Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusLg),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryRed
                                                : Colors.white30,
                                            width: 2,
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppTheme.primaryRed
                                                    : Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isSelected
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .radio_button_unchecked,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    // Nút Tim đỏ để bỏ Yêu thích với animation
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: InkWell(
                                        onTap: () =>
                                            _removeSingleFavorite(movie),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.favorite,
                                            color: AppTheme.primaryRed,
                                            size: 18,
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
              ],
            ),
      bottomNavigationBar: const FlixBottomNavBar(currentIndex: 2),
    );
  }

  /// Empty State khi chưa có phim yêu thích
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  size: 64, color: AppTheme.primaryRed),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa Có Phim Yêu Thích',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Danh sách yêu thích của bạn đang trống. Hãy nhấn vào biểu tượng trái tim ở các bộ phim bạn yêu thích để lưu lại!',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.home),
              child: const Text('Khám phá phim ngay',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
