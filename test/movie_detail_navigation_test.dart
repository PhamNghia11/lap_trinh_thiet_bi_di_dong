import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/screens/movie_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('nút quay lại về Home khi chi tiết phim là route gốc',
      (tester) async {
    const movie = Movie(
      id: 'local-test',
      title: 'Phim kiểm thử',
      genres: [],
      year: 2026,
      rating: 8,
      duration: '120 phút',
      description: 'Nội dung kiểm thử',
      imageUrl: '',
      reviews: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.home: (_) => const Scaffold(body: Text('HOME_SCREEN')),
        },
        home: const MovieDetailScreen(movie: movie),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });
}
