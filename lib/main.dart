// lib/main.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/ui_state_store.dart';
import 'core/app_session.dart';
import 'core/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    UiStateStore.instance.initialize(),
    AppSession.instance.restore(),
    AppPreferences.instance.load(),
  ]);
  runApp(const FlixApp());
}

class FlixApp extends StatelessWidget {
  const FlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorObservers: [AppRoutes.navigationObserver],
    );
  }
}
