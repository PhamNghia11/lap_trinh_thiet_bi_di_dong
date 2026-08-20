// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/ui_state_store.dart';
import 'core/app_session.dart';
import 'core/app_preferences.dart';
import 'viewmodels/movie_note_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_sentryDsn.isEmpty) {
    _runFlixApp();
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = _sentryEnvironment;
      options.release = _sentryRelease.isEmpty ? null : _sentryRelease;
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
      options.tracesSampleRate = _sentryTracesSampleRate;
    },
    appRunner: _runFlixApp,
  );
}

const _sentryDsn = String.fromEnvironment('FLIX_SENTRY_DSN');
const _sentryEnvironment = String.fromEnvironment(
  'FLIX_ENVIRONMENT',
  defaultValue: kReleaseMode ? 'production' : 'development',
);
const _sentryRelease = String.fromEnvironment('FLIX_RELEASE');
final _sentryTracesSampleRate = (double.tryParse(
          const String.fromEnvironment(
            'FLIX_SENTRY_TRACES_SAMPLE_RATE',
            defaultValue: '0.1',
          ),
        ) ??
        0.1)
    .clamp(0.0, 1.0)
    .toDouble();

void _runFlixApp() {
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
      _guardInitialization(
        'movie notes',
        MovieNoteViewModel.instance.initialize(),
      ),
    ]);
  }

  Future<void> _guardInitialization(String name, Future<void> operation) async {
    try {
      await operation.timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      if (_sentryDsn.isNotEmpty) {
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) => scope.setTag('initialization', name),
        );
      }
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

class FlixApp extends StatefulWidget {
  const FlixApp({
    super.key,
    this.initialRouteName = AppRoutes.splash,
  });

  final String initialRouteName;

  @override
  State<FlixApp> createState() => _FlixAppState();
}

class _FlixAppState extends State<FlixApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppSession.instance.addListener(_handleSessionChange);
    _handleSessionChange();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppSession.instance.removeListener(_handleSessionChange);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(
      RouteInformation routeInformation) async {
    final path = routeInformation.uri.toString();
    final callback = AppRoutes.normalizeSocialAuthCallbackRoute(path);
    if (callback != null) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        callback,
        (_) => false,
      );
      return true;
    }
    return super.didPushRouteInformation(routeInformation);
  }

  void _handleSessionChange() {
    if (!AppSession.instance.consumeSessionExpired()) return;
    if (_showExpiredSession()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showExpiredSession();
    });
  }

  bool _showExpiredSession() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !mounted) return false;
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    _messengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Phiên đăng nhập đã hết hạn.')),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppSession.instance),
        ChangeNotifierProvider.value(value: AppPreferences.instance),
        ChangeNotifierProvider.value(value: MovieNoteViewModel.instance),
      ],
      child: MaterialApp(
        title: 'FLIX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        initialRoute: widget.initialRouteName,
        onGenerateInitialRoutes: AppRoutes.onGenerateInitialRoutes,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        navigatorObservers: [
          AppRoutes.navigationObserver,
          if (_sentryDsn.isNotEmpty) SentryNavigatorObserver(),
        ],
      ),
    );
  }
}
