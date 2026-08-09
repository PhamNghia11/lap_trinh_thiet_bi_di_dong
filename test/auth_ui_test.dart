import 'package:flix_app/routes/app_routes.dart';
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
}
