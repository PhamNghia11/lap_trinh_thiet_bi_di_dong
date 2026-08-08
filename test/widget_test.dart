// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flix_app/main.dart';

void main() {
  testWidgets('FLIX app starts on the splash screen', (tester) async {
    await tester.pumpWidget(const FlixApp());
    expect(find.text('MOVIE FINDER'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
