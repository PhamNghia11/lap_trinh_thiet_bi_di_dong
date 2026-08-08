import 'package:flutter/material.dart';

import '../models/movie_filter.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key, this.initial = const MovieFilter()});
  final MovieFilter initial;
  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late String _genre;
  late int? _year;
  late String _sortBy;
  late double _rating;

  static const _sorts = <String, String>{
    'Phổ biến nhất': 'popularity.desc',
    'Đánh giá cao': 'vote_average.desc',
    'Mới phát hành': 'primary_release_date.desc',
  };

  @override
  void initState() {
    super.initState();
    _genre = widget.initial.genreLabel;
    _year = widget.initial.year;
    _sortBy = widget.initial.sortBy;
    _rating = widget.initial.minRating;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('Bộ lọc phim'),
          actions: [
            TextButton(
              onPressed: () => setState(() {
                _genre = 'Tất cả'; _year = null; _sortBy = 'popularity.desc'; _rating = 0;
              }),
              child: const Text('Đặt lại'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Thể loại', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: movieGenreOptions.keys.map((genre) => ChoiceChip(
                label: Text(genre),
                selected: _genre == genre,
                onSelected: (_) => setState(() => _genre = genre),
                selectedColor: AppTheme.primaryRed,
                backgroundColor: AppTheme.cardBg,
                labelStyle: TextStyle(color: _genre == genre ? Colors.white : AppTheme.textMuted),
              )).toList(),
            ),
            const SizedBox(height: 28),
            const Text('Năm phát hành', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <int?>[null, 2026, 2025, 2024, 2023, 2022].map((year) => ChoiceChip(
                label: Text(year?.toString() ?? 'Tất cả'),
                selected: _year == year,
                onSelected: (_) => setState(() => _year = year),
                selectedColor: AppTheme.primaryRed,
                backgroundColor: AppTheme.cardBg,
                labelStyle: TextStyle(color: _year == year ? Colors.white : AppTheme.textMuted),
              )).toList(),
            ),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Điểm TMDB tối thiểu', style: AppTheme.headingSmall),
              Text(_rating == 0 ? 'Bất kỳ' : '${_rating.toStringAsFixed(1)} ★', style: const TextStyle(color: AppTheme.accentGold)),
            ]),
            Slider(
              value: _rating,
              min: 0,
              max: 9,
              divisions: 18,
              activeColor: AppTheme.primaryRed,
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 20),
            const Text('Sắp xếp', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sorts.entries.map((entry) => ChoiceChip(
                label: Text(entry.key),
                selected: _sortBy == entry.value,
                onSelected: (_) => setState(() => _sortBy = entry.value),
                selectedColor: AppTheme.primaryRed,
                backgroundColor: AppTheme.cardBg,
                labelStyle: TextStyle(
                  color: _sortBy == entry.value ? Colors.white : AppTheme.textMuted,
                ),
              )).toList(),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              width: double.infinity,
              text: 'Áp dụng bộ lọc',
              onPressed: () {
                final sortLabel = _sorts.entries.firstWhere((entry) => entry.value == _sortBy).key;
                Navigator.pop(context, MovieFilter(
                  genreId: movieGenreOptions[_genre],
                  genreLabel: _genre,
                  year: _year,
                  sortBy: _sortBy,
                  sortLabel: sortLabel,
                  minRating: _rating,
                ));
              },
            ),
          ]),
        ),
      );
}
