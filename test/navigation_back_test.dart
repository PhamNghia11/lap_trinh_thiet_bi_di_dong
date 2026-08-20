import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/screens/movie_reviews_screen.dart';
import 'package:flix_app/screens/my_reviews_screen.dart';
import 'package:flix_app/widgets/adaptive_scaffold.dart';

void main() {
  testWidgets('MyReviewsScreen displays back button and triggers navigation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.profile: (_) => const Scaffold(body: Text('PROFILE_PAGE')),
        },
        home: const MyReviewsScreen(),
      ),
    );

    // Verify leading back button icon exists
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Đánh giá của tôi'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify navigates safely to profile page
    expect(find.text('PROFILE_PAGE'), findsOneWidget);
  });

  testWidgets(
      'MovieReviewsScreen displays back button and navigates to home when movie is null',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.home: (_) => const Scaffold(body: Text('HOME_PAGE')),
        },
        home: const MovieReviewsScreen(),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Tất cả đánh giá'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('HOME_PAGE'), findsOneWidget);
  });

  testWidgets(
      'MovieReviewsScreen navigates to movie detail when back button pressed with movie',
      (tester) async {
    const movie = Movie(
      id: '123',
      title: 'Phim Test',
      genres: ['Hành Động'],
      year: 2026,
      rating: 8.5,
      duration: '120 phút',
      description: 'Mô tả test',
      imageUrl: '',
      reviews: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.movieDetail: (_) =>
              const Scaffold(body: Text('MOVIE_DETAIL_PAGE')),
        },
        home: const MovieReviewsScreen(movie: movie),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('MOVIE_DETAIL_PAGE'), findsOneWidget);
  });

  testWidgets(
      'FlixAdaptiveScaffold on tab 1 (Search) navigates to home on system back',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.home: (_) => const Scaffold(body: Text('HOME_PAGE')),
        },
        home: const FlixAdaptiveScaffold(
          currentIndex: 1,
          body: Center(child: Text('SEARCH_TAB')),
        ),
      ),
    );

    expect(find.text('SEARCH_TAB'), findsOneWidget);

    // Simulate system back invocation
    final popScopeFinder =
        find.byWidgetPredicate((widget) => widget is PopScope);
    expect(popScopeFinder, findsOneWidget);
    final popScope = tester.widget<PopScope>(popScopeFinder);
    popScope.onPopInvokedWithResult?.call(false, null);

    await tester.pumpAndSettle();
    expect(find.text('HOME_PAGE'), findsOneWidget);
  });
}
