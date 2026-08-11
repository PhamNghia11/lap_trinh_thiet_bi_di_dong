import 'package:flix_app/core/api_client.dart';
import 'package:flix_app/core/app_session.dart';
import 'package:flix_app/main.dart';
import 'package:flix_app/screens/login_screen.dart';
import 'package:flix_app/screens/social_auth_callback_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expired session clears user and returns to login',
      (tester) async {
    await tester.pumpWidget(const FlixApp(
      initialRouteName: '/auth/callback?error=session-test',
    ));
    await tester.pump();
    expect(find.byType(SocialAuthCallbackScreen), findsOneWidget);

    AppSession.instance.user = {'id': 'session-test'};
    expect(ApiClient.instance.onUnauthorized, isNotNull);
    await ApiClient.instance.onUnauthorized?.call();
    await tester.pumpAndSettle();

    expect(AppSession.instance.user, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Phiên đăng nhập đã hết hạn.'), findsOneWidget);
  });
}
