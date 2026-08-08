// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../data/mock_data.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = List.from(defaultRecentSearches);

  @override
  Widget build(BuildContext context) {
    final suggestions = suggestedMovies;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm phim, diễn viên, thể loại...',
            hintStyle: const TextStyle(color: Color(0x80E9BCB6)),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune, color: AppTheme.textMuted),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.searchFilter),
            ),
            filled: true,
            fillColor: AppTheme.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg), borderSide: BorderSide.none),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tìm kiếm gần đây', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((keyword) {
                return Chip(
                  backgroundColor: AppTheme.cardBg,
                  label: Text(keyword, style: const TextStyle(color: AppTheme.textMuted)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                  onDeleted: () {
                    setState(() {
                      _recentSearches.remove(keyword);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text('Gợi Ý Cho Bạn', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final movie = suggestions[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(movie.imageUrl, width: 50, height: 75, fit: BoxFit.cover),
                  ),
                  title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(movie.infoText, style: AppTheme.smallText),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.movieDetail),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
