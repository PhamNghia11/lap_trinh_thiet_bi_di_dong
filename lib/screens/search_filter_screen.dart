// lib/screens/search_filter_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/custom_button.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  String _selectedGenre = 'Tất cả';
  String _selectedYear = '2024';
  String _selectedSort = 'Mới nhất';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bộ Lọc Phim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thể loại', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filterGenres.map((genre) {
                final selected = _selectedGenre == genre;
                return ChoiceChip(
                  label: Text(genre),
                  selected: selected,
                  selectedColor: AppTheme.primaryRed,
                  backgroundColor: AppTheme.cardBg,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textLight),
                  onSelected: (val) {
                    setState(() => _selectedGenre = genre);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text('Năm phát hành', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filterYears.map((year) {
                final selected = _selectedYear == year;
                return ChoiceChip(
                  label: Text(year),
                  selected: selected,
                  selectedColor: AppTheme.primaryRed,
                  backgroundColor: AppTheme.cardBg,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textLight),
                  onSelected: (val) {
                    setState(() => _selectedYear = year);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text('Sắp xếp theo', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filterSortOptions.map((sort) {
                final selected = _selectedSort == sort;
                return ChoiceChip(
                  label: Text(sort),
                  selected: selected,
                  selectedColor: AppTheme.primaryRed,
                  backgroundColor: AppTheme.cardBg,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textLight),
                  onSelected: (val) {
                    setState(() => _selectedSort = sort);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              text: 'Áp Dụng Bộ Lọc',
              width: double.infinity,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
