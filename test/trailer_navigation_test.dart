import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/screens/trailer_screen.dart';

void main() {
  testWidgets('trailer route gốc luôn có thể quay về trang chủ',
      (tester) async {
    const movie = Movie(
      id: 'local-movie',
      title: 'Phim kiểm thử',
      genres: ['Hành động'],
      year: 2026,
      rating: 8,
      duration: '120 phút',
      description: 'Mô tả kiểm thử',
      imageUrl: '',
      trailerKey: 'test-video',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const TrailerScreen(movie: movie),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.home) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Trang chủ kiểm thử')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Quay lại'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Trang chủ kiểm thử'), findsOneWidget);
  });
}
