import 'dart:ui';

import 'package:flix_app/screens/home_screen.dart';
import 'package:flix_app/models/movie_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const movies = [
    Movie(
      id: '1',
      title: 'Một',
      genres: [],
      year: 2026,
      rating: 8,
      duration: '',
      description: '',
      imageUrl: '',
      reviews: [],
    ),
    Movie(
      id: '2',
      title: 'Hai',
      genres: [],
      year: 2026,
      rating: 8,
      duration: '',
      description: '',
      imageUrl: '',
      reviews: [],
    ),
    Movie(
      id: '3',
      title: 'Ba',
      genres: [],
      year: 2026,
      rating: 8,
      duration: '',
      description: '',
      imageUrl: '',
      reviews: [],
    ),
  ];

  test('các hàng thể loại ưu tiên phim chưa xuất hiện', () {
    final result = diversifyGenreMovies(
      [
        MapEntry('Hành Động', [movies[0], movies[1]]),
        const MapEntry('Viễn Tưởng', movies),
      ],
      seed: 42,
      initiallyUsedIds: const ['1'],
    );

    expect(result['Hành Động']!.first.id, '2');
    expect(result['Viễn Tưởng']!.first.id, '3');
  });

  testWidgets('Home hỗ trợ thao tác kéo xuống để làm mới', (tester) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);

    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
    final configuration = tester.widget<ScrollConfiguration>(
      find
          .ancestor(
            of: find.byType(RefreshIndicator),
            matching: find.byType(ScrollConfiguration),
          )
          .first,
    );
    expect(
        configuration.behavior.dragDevices, contains(PointerDeviceKind.mouse));
  });
}
