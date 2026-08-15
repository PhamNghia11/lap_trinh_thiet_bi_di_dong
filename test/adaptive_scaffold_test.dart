import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/widgets/adaptive_scaffold.dart';

void main() {
  Widget app() {
    return MaterialApp(
      routes: {
        AppRoutes.search: (_) => const Scaffold(body: Text('SEARCH_PAGE')),
      },
      home: FlixAdaptiveScaffold(
        currentIndex: 0,
        appBar: AppBar(title: const Text('FLIX')),
        body: const Center(child: Text('HOME_BODY')),
      ),
    );
  }

  testWidgets('hiển thị sidebar và ẩn bottom bar trên màn hình PC',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('HOME_BODY'), findsOneWidget);

    await tester.tap(find.text('Tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('SEARCH_PAGE'), findsOneWidget);
  });

  testWidgets('giữ bottom navigation trên màn hình điện thoại', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('HOME_BODY'), findsOneWidget);
  });
}
