import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/core/app_preferences.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/screens/home_screen.dart';
import 'package:flix_app/screens/movie_detail_screen.dart';
import 'package:flix_app/viewmodels/movie_note_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

  Widget withMovieNotes(Widget child) => ChangeNotifierProvider(
        create: (_) => MovieNoteViewModel(),
        child: child,
      );

  testWidgets('nút quay lại về Home khi chi tiết phim là route gốc',
      (tester) async {
    ignoreNetworkImages();

    await tester.pumpWidget(
      withMovieNotes(
        MaterialApp(
          routes: {
            AppRoutes.home: (_) => const Scaffold(body: Text('HOME_SCREEN')),
          },
          home: const MovieDetailScreen(movie: movie),
        ),
      ),
    );

    expect(find.byKey(const Key('movie-note-action')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('nút quay lại giữ đúng màn nguồn khi còn route trước',
      (tester) async {
    ignoreNetworkImages();

    await tester.pumpWidget(
      withMovieNotes(
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
      ),
    );

    await tester.tap(find.text('OPEN_DETAIL'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_DETAIL'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('tự động phát không tự điều hướng khỏi trang chi tiết',
      (tester) async {
    ignoreNetworkImages();
    final previousAutoPlay = AppPreferences.instance.autoPlayTrailer;
    AppPreferences.instance.autoPlayTrailer = true;
    addTearDown(
      () => AppPreferences.instance.autoPlayTrailer = previousAutoPlay,
    );

    const movieWithTrailer = Movie(
      id: 'local-test',
      title: 'Phim có trailer',
      genres: [],
      year: 2026,
      rating: 8,
      duration: '120 phút',
      description: 'Nội dung kiểm thử',
      imageUrl: '',
      reviews: [],
      trailerKey: 'trailer-key',
    );

    await tester.pumpWidget(
      withMovieNotes(
        MaterialApp(
          routes: {
            AppRoutes.trailer: (_) =>
                const Scaffold(body: Text('TRAILER_SCREEN')),
          },
          home: const MovieDetailScreen(movie: movieWithTrailer),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phim có trailer'), findsWidgets);
    expect(find.text('TRAILER_SCREEN'), findsNothing);
  });
}
