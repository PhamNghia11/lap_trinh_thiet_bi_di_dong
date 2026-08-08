// lib/screens/genre_detail_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';
import '../widgets/movie_card.dart';

class GenreDetailScreen extends StatefulWidget {
  final String genreTitle;

  const GenreDetailScreen({
    super.key,
    this.genreTitle = 'Phim Hành Động',
  });

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  bool _isGridView = true; // Toggle giữa Grid (2 cột) và List (dọc)
  String _selectedSort = 'Mới nhất'; // "Mới nhất", "Đánh giá cao", "A-Z"
  String _selectedYearFilter = 'Tất cả';
  String _selectedDurationFilter = 'Tất cả';

  bool _isLoadingMore = false;
  int _visibleCount = 8;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _visibleCount < 24) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _visibleCount += 4;
        _isLoadingMore = false;
      });
    }
  }

  /// Lấy danh sách phim đã sắp xếp và lọc
  List<Movie> _getProcessedMovies() {
    // Tách lấy tên thể loại (ví dụ: "Phim Hành Động" -> "Hành Động")
    final rawGenre = widget.genreTitle.replaceAll('Phim ', '').trim();
    List<Movie> list = getMoviesByGenre(rawGenre);

    // Nhân bản dữ liệu mẫu để đủ hiển thị nhiều item cho danh sách lớn
    List<Movie> fullList = [];
    for (int i = 0; i < 3; i++) {
      fullList.addAll(list.map((m) => m.copyWith(id: '${m.id}_$i')));
    }

    // Lọc theo năm phát hành
    if (_selectedYearFilter != 'Tất cả') {
      fullList = fullList.where((m) => m.year.toString() == _selectedYearFilter).toList();
    }

    // Sắp xếp
    if (_selectedSort == 'Đánh giá cao') {
      fullList.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == 'A-Z') {
      fullList.sort((a, b) => a.title.compareTo(b.title));
    } else {
      // Mới nhất (theo năm giảm dần)
      fullList.sort((a, b) => b.year.compareTo(a.year));
    }

    return fullList.take(_visibleCount).toList();
  }

  /// Mở BottomSheet bộ lọc nâng cao
  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ Lọc Nâng Cao',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Năm phát hành', style: AppTheme.headingSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: filterYears.map((year) {
                      final selected = _selectedYearFilter == year;
                      return ChoiceChip(
                        label: Text(year),
                        selected: selected,
                        selectedColor: AppTheme.primaryRed,
                        backgroundColor: AppTheme.scaffoldBg,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.textLight,
                        ),
                        onSelected: (val) {
                          setModalState(() => _selectedYearFilter = year);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Thời lượng', style: AppTheme.headingSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['Tất cả', '< 90 phút', '90-120 phút', '> 120 phút'].map((dur) {
                      final selected = _selectedDurationFilter == dur;
                      return ChoiceChip(
                        label: Text(dur),
                        selected: selected,
                        selectedColor: AppTheme.primaryRed,
                        backgroundColor: AppTheme.scaffoldBg,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.textLight,
                        ),
                        onSelected: (val) {
                          setModalState(() => _selectedDurationFilter = dur);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle(),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Áp Dụng Bộ Lọc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final movies = _getProcessedMovies();
    final totalResults = 128; // Giả lập tổng kết quả

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.genreTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Icon nút chuyển đổi Layout Grid 2 cột / List dọc
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: Colors.white,
            ),
            tooltip: _isGridView ? 'Chế độ Danh sách' : 'Chế độ Lưới',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textMuted),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Header: Số lượng kết quả & Nút Lọc / Sắp xếp ───────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.cardBg.withValues(alpha: 0.5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalResults kết quả',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    InkWell(
                      onTap: _openFilterBottomSheet,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, color: AppTheme.primaryRed, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Bộ lọc',
                              style: TextStyle(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Thanh Chip Sắp xếp ("Mới nhất", "Đánh giá cao", "A-Z")
                Row(
                  children: ['Mới nhất', 'Đánh giá cao', 'A-Z'].map((sortOption) {
                    final isSelected = _selectedSort == sortOption;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(sortOption),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryRed,
                        backgroundColor: AppTheme.cardBg,
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSort = sortOption;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ─── Body: Danh sách Phim với Animation chuyển đổi View ─────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _isGridView
                  ? GridView.builder(
                      key: const ValueKey('grid_view'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: movies.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == movies.length) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                            ),
                          );
                        }
                        final movie = movies[index];
                        return AnimatedOpacity(
                          duration: Duration(milliseconds: 300 + (index % 4) * 100),
                          opacity: 1.0,
                          child: MovieCard.grid(
                            movie: movie,
                            showBadge: true,
                            showRating: true,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      key: const ValueKey('list_view'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: movies.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == movies.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                              ),
                            ),
                          );
                        }
                        final movie = movies[index];
                        return MovieCard.listTile(
                          movie: movie,
                          showBadge: true,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
