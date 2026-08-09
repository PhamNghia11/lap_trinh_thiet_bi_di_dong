import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flix_app/core/ui_state_store.dart';
import 'package:flix_app/models/movie_filter.dart';
import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await UiStateStore.instance.initialize();
  });

  test('safe UI values survive a storage round trip', () async {
    await UiStateStore.instance.setString('search.query', 'Dune');
    await UiStateStore.instance.setBool('favorites.multiSelect', true);
    await UiStateStore.instance.setDouble('search.scroll', 216.5);

    expect(UiStateStore.instance.string('search.query'), 'Dune');
    expect(UiStateStore.instance.boolean('favorites.multiSelect'), isTrue);
    expect(UiStateStore.instance.decimal('search.scroll'), 216.5);
  });

  test('last movie route restores its typed arguments', () async {
    const movie = Movie(
      id: '693134',
      title: 'Dune: Part Two',
      genres: ['Khoa học viễn tưởng'],
      year: 2024,
      rating: 8.5,
      duration: '166 phút',
      description: 'Arrakis',
      imageUrl: 'https://example.com/poster.jpg',
    );
    await UiStateStore.instance.setJson('navigation.last', {
      'name': AppRoutes.movieDetail,
      'arguments': AppRoutes.encodeArguments(movie),
    });

    final restored = AppRoutes.restoredRoute(authenticated: true);

    expect(restored.name, AppRoutes.movieDetail);
    expect(restored.arguments, isA<Movie>());
    expect((restored.arguments! as Movie).id, movie.id);
  });

  test('movie filters remain serializable', () {
    const original = MovieFilter(
      genreId: 28,
      genreLabel: 'Hành Động',
      year: 2025,
      sortBy: 'vote_average.desc',
      sortLabel: 'Đánh giá cao',
      minRating: 7.5,
    );

    final restored = MovieFilter.fromJson(original.toJson());

    expect(restored.genreId, original.genreId);
    expect(restored.year, original.year);
    expect(restored.sortBy, original.sortBy);
    expect(restored.minRating, original.minRating);
  });
}
