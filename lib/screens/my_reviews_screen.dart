import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_session.dart';
import '../theme/app_theme.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late Future<List<Map<String, dynamic>>> _reviews = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final data =
        await ApiClient.instance.get('/me/reviews', authenticated: true);
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _delete(String id) async {
    await ApiClient.instance.delete('/reviews/$id', authenticated: true);
    await AppSession.instance.refreshProfile();
    if (!mounted) return;
    setState(() => _reviews = _load());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã xóa đánh giá')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Đánh giá của tôi'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _reviews = _load()),
                icon: const Icon(Icons.refresh),
                label: Text('Tải lại (${snapshot.error})'),
              ),
            );
          }
          final reviews = snapshot.data ?? const [];
          if (reviews.isEmpty) {
            return const Center(
              child:
                  Text('Bạn chưa viết đánh giá nào', style: AppTheme.mutedText),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final rating = review['rating'] as int? ?? 0;
              return Material(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: ListTile(
                  title: Text('Phim #${review['tmdbMovieId']}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('★' * rating,
                          style: const TextStyle(color: AppTheme.accentGold)),
                      Text(review['comment'] as String? ?? '',
                          style: AppTheme.mutedText),
                    ],
                  ),
                  trailing: IconButton(
                    tooltip: 'Xóa đánh giá',
                    onPressed: () => _delete(review['id'] as String),
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.primaryRed),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
