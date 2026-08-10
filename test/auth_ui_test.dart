import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/data/tmdb_repository.dart';
import 'package:flix_app/main.dart';
import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/screens/favorites_screen.dart';
import 'package:flix_app/screens/history_screen.dart';
import 'package:flix_app/screens/login_screen.dart';
import 'package:flix_app/screens/movie_list_screen.dart';
import 'package:flix_app/screens/social_auth_callback_screen.dart';
import 'package:flix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme(),
      home: child,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const SizedBox(),
        AppRoutes.forgotPassword: (_) => const SizedBox(),
        AppRoutes.home: (_) => const SizedBox(),
      },
    );

class _MovieListRepository extends TmdbRepository {
  final nowPlayingPages = <int>[];

  @override
  Future<List<Movie>> popular({int page = 1}) async => const [];

  @override
  Future<List<Movie>> nowPlaying({int page = 1}) async {
    nowPlayingPages.add(page);
    if (page > 1) return const [];
    return List.generate(
      8,
      (index) => Movie.fromTmdbJson({
        'id': index + 1,
        'title': 'Movie $index',
        'poster_path': '/poster.jpg',
      }),
    );
  }
}

void main() {
  testWidgets('login restores legacy controls and social buttons react',
      (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Ghi nhớ'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);

    await tester.tap(find.text('Google'));
    await tester.pump();
    expect(
      find.text('Google/Facebook hiện được cấu hình cho Flutter Web.'),
      findsOneWidget,
    );
  });

  testWidgets('social callback renders a provider error', (tester) async {
    await tester.pumpWidget(
      _app(const SocialAuthCallbackScreen(error: 'Người dùng đã hủy')),
    );
    await tester.pump();

    expect(find.text('Không thể đăng nhập'), findsOneWidget);
    expect(find.text('Người dùng đã hủy'), findsOneWidget);
    expect(find.text('Quay lại đăng nhập'), findsOneWidget);
  });

  testWidgets('OAuth callback is handled before the splash screen',
      (tester) async {
    const callbackRoute = '/auth/callback?error=Google%20callback%20failed';
    await tester.pumpWidget(
      const FlixApp(initialRouteName: callbackRoute),
    );
    await tester.pump();

    expect(find.byType(SocialAuthCallbackScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Google callback failed'), findsOneWidget);
  });

  test('OAuth callback is recovered from the browser URL fragment', () {
    final route = AppRoutes.resolveInitialRouteName(
      baseUri: Uri.parse(
        'http://localhost:8765/#/auth/callback?token=google-token',
      ),
      platformRouteName: '/',
    );

    expect(route, '/auth/callback?token=google-token');
  });

  testWidgets('login controls remain responsive on a narrow viewport',
      (tester) async {
    tester.view.physicalSize = const Size(260, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const LoginScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Google'), findsOneWidget);
  });

  testWidgets('favorites and history keep useful signed-out states',
      (tester) async {
    await tester.pumpWidget(_app(const FavoritesScreen()));
    await tester.pump();
    expect(find.text('Đăng nhập để xem Yêu thích'), findsOneWidget);

    await tester.pumpWidget(_app(const HistoryScreen()));
    await tester.pump();
    expect(find.text('Đăng nhập để xem lịch sử'), findsOneWidget);
  });

  testWidgets('movie list can initialize without a setState assertion',
      (tester) async {
    await tester.pumpWidget(_app(const MovieListScreen()));
    await tester.pump();

    expect(find.text('Danh Sách Phim Nổi Bật'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('now-playing list uses the existing movie-list UI',
      (tester) async {
    final repository = _MovieListRepository();
    await tester.pumpWidget(_app(MovieListScreen(
      collection: MovieCollection.nowPlaying,
      repository: repository,
    )));
    await tester.pump();

    expect(find.text('Phim Đang Chiếu'), findsOneWidget);
    expect(repository.nowPlayingPages, [1]);

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(repository.nowPlayingPages, contains(2));
  });
}
