import 'package:flix_app/core/app_preferences.dart';
import 'package:flix_app/core/app_session.dart';
import 'package:flix_app/screens/settings_screen.dart';
import 'package:flix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();
    AppSession.instance.user = {
      'id': 'user-id',
      'email': 'user@example.com',
      'fullName': 'FLIX User',
    };
  });

  tearDown(() {
    AppSession.instance.user = null;
  });

  testWidgets('signed-in users can discover permanent account deletion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme(), home: const SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('Xóa tài khoản'), findsOneWidget);
    await tester.tap(find.text('Xóa tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Xóa vĩnh viễn'), findsOneWidget);
    expect(
      find.textContaining('danh sách yêu thích, lịch sử và đánh giá'),
      findsOneWidget,
    );
  });

  testWidgets('legal dialog includes privacy links and TMDB attribution',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme(), home: const SettingsScreen()),
    );
    await tester.pump();

    final legalTile = find.text('Điều khoản & Chính sách bảo mật');
    await tester.scrollUntilVisible(
      legalTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(legalTile);
    await tester.pumpAndSettle();

    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(
      find.textContaining('not endorsed or certified by TMDB'),
      findsOneWidget,
    );
  });
}
