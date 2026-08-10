import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../theme/app_theme.dart';
import '../widgets/user_review_card.dart';

class MovieReviewsScreen extends StatefulWidget {
  final Movie? movie;

  const MovieReviewsScreen({super.key, this.movie});

  @override
  State<MovieReviewsScreen> createState() => _MovieReviewsScreenState();
}

class _MovieReviewsScreenState extends State<MovieReviewsScreen> {
  int? _ratingFilter;
  String _sourceFilter = 'Tất cả';
  String _sort = 'Mới nhất';

  List<UserReview> get _filteredReviews {
    final reviews = widget.movie?.reviews ?? const <UserReview>[];
    final filtered = reviews.where((review) {
      final ratingMatches =
          _ratingFilter == null || review.rating.round() == _ratingFilter;
      final isTmdb = review.userName.toUpperCase().contains('(TMDB)');
      final sourceMatches = _sourceFilter == 'Tất cả' ||
          (_sourceFilter == 'TMDB' && isTmdb) ||
          (_sourceFilter == 'FLIX' && !isTmdb);
      return ratingMatches && sourceMatches;
    }).toList();
    filtered.sort((a, b) {
      if (_sort == 'Điểm cao') return b.rating.compareTo(a.rating);
      if (_sort == 'Điểm thấp') return a.rating.compareTo(b.rating);
      return b.date.compareTo(a.date);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final reviews = _filteredReviews;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Tất cả đánh giá'),
      ),
      body: movie == null
          ? const Center(
              child: Text('Không tìm thấy phim', style: AppTheme.mutedText))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Text(movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headingSmall),
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('Tất cả sao'),
                        selected: _ratingFilter == null,
                        onSelected: (_) => setState(() => _ratingFilter = null),
                      ),
                      ...List.generate(5, (index) {
                        final rating = 5 - index;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text('$rating sao'),
                            selected: _ratingFilter == rating,
                            onSelected: (_) =>
                                setState(() => _ratingFilter = rating),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _sourceFilter,
                        dropdownColor: AppTheme.cardBg,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                              value: 'Tất cả', child: Text('Mọi nguồn')),
                          DropdownMenuItem(value: 'TMDB', child: Text('TMDB')),
                          DropdownMenuItem(value: 'FLIX', child: Text('FLIX')),
                        ],
                        onChanged: (value) =>
                            setState(() => _sourceFilter = value!),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _sort,
                        dropdownColor: AppTheme.cardBg,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                              value: 'Mới nhất', child: Text('Mới nhất')),
                          DropdownMenuItem(
                              value: 'Điểm cao', child: Text('Điểm cao')),
                          DropdownMenuItem(
                              value: 'Điểm thấp', child: Text('Điểm thấp')),
                        ],
                        onChanged: (value) => setState(() => _sort = value!),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('${reviews.length} đánh giá',
                      style: AppTheme.smallText),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: reviews.isEmpty
                      ? const Center(
                          child: Text('Không có đánh giá phù hợp',
                              style: AppTheme.mutedText))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: reviews.length,
                          itemBuilder: (_, index) =>
                              UserReviewCard(review: reviews[index]),
                        ),
                ),
              ],
            ),
    );
  }
}
