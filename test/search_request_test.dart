import 'dart:async';

import 'package:flix_app/data/tmdb_repository.dart';
import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/screens/search_screen.dart';
import 'package:flix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SearchRepository extends TmdbRepository {
  final initial = Completer<List<Movie>>();
  final requests = <String, Completer<List<Movie>>>{};
  final discoverPages = <int>[];

  @override
  Future<List<Movie>> discover({
    int page = 1,
    int? genreId,
    int? year,
    String sortBy = 'popularity.desc',
    double? minRating,
  }) {
    discoverPages.add(page);
    return page == 1 ? initial.future : Future.value(const []);
  }

  @override
  Future<List<Movie>> search(String query, {int page = 1, int? year}) =>
      (requests[query] ??= Completer<List<Movie>>()).future;
}

Movie _movie(int id, String title) => Movie.fromTmdbJson({
      'id': id,
      'title': title,
      'poster_path': '/poster.jpg',
    });

void main() {
  testWidgets('kết quả tìm kiếm cũ không ghi đè từ khóa mới', (tester) async {
    final repository = _SearchRepository();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: SearchScreen(repository: repository),
    ));
    repository.initial.complete(const []);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 450));

    repository.requests['new']!.complete([_movie(2, 'New result')]);
    await tester.pump();
    repository.requests['old']!.complete([_movie(1, 'Old result')]);
    await tester.pump();

    expect(find.text('New result'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
  });

  testWidgets('khám phá phim tải trang tiếp theo khi cuộn gần cuối',
      (tester) async {
    final repository = _SearchRepository();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: SearchScreen(repository: repository),
    ));
    repository.initial.complete(
      List.generate(8, (index) => _movie(index + 1, 'Movie $index')),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(repository.discoverPages, containsAllInOrder([1, 2]));
  });
}
