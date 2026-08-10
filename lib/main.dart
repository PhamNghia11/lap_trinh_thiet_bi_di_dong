// lib/main.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/ui_state_store.dart';
import 'core/app_session.dart';
import 'core/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialRouteName = AppRoutes.resolveInitialRouteName(
    baseUri: Uri.base,
    platformRouteName:
        WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  );
  runApp(_FlixBootstrap(initialRouteName: initialRouteName));
}

class _FlixBootstrap extends StatefulWidget {
  const _FlixBootstrap({required this.initialRouteName});

  final String initialRouteName;

  @override
  State<_FlixBootstrap> createState() => _FlixBootstrapState();
}

class _FlixBootstrapState extends State<_FlixBootstrap> {
  late final Future<void> _initialization = _initialize();

  Future<void> _initialize() async {
    await Future.wait([
      _guardInitialization(
        'UI state',
        UiStateStore.instance.initialize(),
      ),
      _guardInitialization(
        'session',
        AppSession.instance.restore(),
      ),
      _guardInitialization(
        'preferences',
        AppPreferences.instance.load(),
      ),
    ]);
  }

  Future<void> _guardInitialization(String name, Future<void> operation) async {
    try {
      await operation.timeout(const Duration(seconds: 8));
    } catch (error) {
      debugPrint('Không thể khôi phục $name khi khởi động: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FlixApp(initialRouteName: widget.initialRouteName);
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme(),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const _StartupScreen(),
          ),
        );
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FLIX',
              style: TextStyle(
                color: AppTheme.primaryRed,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppTheme.primaryRed),
          ],
        ),
      ),
    );
  }
}

class FlixApp extends StatelessWidget {
  const FlixApp({
    super.key,
    this.initialRouteName = AppRoutes.splash,
  });

  final String initialRouteName;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      initialRoute: initialRouteName,
      onGenerateInitialRoutes: AppRoutes.onGenerateInitialRoutes,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorObservers: [AppRoutes.navigationObserver],
    );
  }
}
