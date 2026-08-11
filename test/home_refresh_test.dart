import 'dart:ui';

import 'package:flix_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
