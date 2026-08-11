import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/screens/home_screen.dart';
import 'package:flix_app/screens/movie_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  void ignoreNetworkImages() {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
  }

  testWidgets('nút quay lại về Home khi chi tiết phim là route gốc',
      (tester) async {
    ignoreNetworkImages();

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

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('nút quay lại giữ đúng màn nguồn khi còn route trước',
      (tester) async {
    ignoreNetworkImages();

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.movieDetail: (_) => const MovieDetailScreen(movie: movie),
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.movieDetail,
              ),
              child: const Text('OPEN_DETAIL'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN_DETAIL'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_DETAIL'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
