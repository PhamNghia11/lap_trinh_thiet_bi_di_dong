// lib/routes/app_routes.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../core/ui_state_store.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/search_filter_screen.dart';
import '../screens/genre_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/trailer_screen.dart';
import '../screens/review_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/social_auth_callback_screen.dart';
import '../screens/my_reviews_screen.dart';
import '../models/movie_model.dart';

/// Lớp quản lý toàn bộ route/điều hướng của ứng dụng.
class AppRoutes {
  AppRoutes._();

  // ─── Hằng số tên route ────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String home = '/home';
  static const String search = '/search';
  static const String searchFilter = '/search_filter';
  static const String genreDetail = '/genre_detail';
  static const String movieList = '/movie_list';
  static const String movieDetail = '/movie_detail';
  static const String trailer = '/trailer';
  static const String review = '/review';
  static const String myReviews = '/my_reviews';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String socialAuthCallback = '/auth/callback';

  static final NavigatorObserver navigationObserver =
      _PersistentNavigationObserver();

  static const _authenticatedRoutes = {
    favorites,
    history,
    profile,
    settings,
    myReviews,
  };

  static const _restorableRoutes = {
    onboarding,
    login,
    register,
    home,
    search,
    genreDetail,
    movieList,
    movieDetail,
    trailer,
    review,
    favorites,
    history,
    profile,
    settings,
    myReviews,
  };

  static RouteSettings restoredRoute({required bool authenticated}) {
    final saved = UiStateStore.instance.json('navigation.last');
    final name = saved?['name'] as String?;
    if (name == null || !_restorableRoutes.contains(name)) {
      return RouteSettings(name: authenticated ? home : onboarding);
    }
    if (authenticated && {onboarding, login, register}.contains(name)) {
      return const RouteSettings(name: home);
    }
    if (!authenticated && _authenticatedRoutes.contains(name)) {
      return const RouteSettings(name: onboarding);
    }

    Object? arguments;
    final encoded = saved?['arguments'];
    if (encoded is Map) {
      final json = Map<String, dynamic>.from(encoded);
      if (json['type'] == 'movie' && json['value'] is Map) {
        arguments = Movie.fromJson(
          Map<String, dynamic>.from(json['value'] as Map),
        );
      } else if (json['type'] == 'string') {
        arguments = json['value'] as String?;
      }
    }
    if ({movieDetail, trailer, review}.contains(name) && arguments is! Movie) {
      return const RouteSettings(name: home);
    }
    return RouteSettings(name: name, arguments: arguments);
  }

  static Map<String, dynamic>? encodeArguments(Object? arguments) {
    if (arguments is Movie) {
      return {'type': 'movie', 'value': arguments.toJson()};
    }
    if (arguments is String) return {'type': 'string', 'value': arguments};
    return null;
  }

  // ─── Route Map ────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        home: (context) => const HomeScreen(),
        search: (context) => const SearchScreen(),
        searchFilter: (context) => const SearchFilterScreen(),
        movieList: (context) => const MovieListScreen(),
        favorites: (context) => const FavoritesScreen(),
        history: (context) => const HistoryScreen(),
        profile: (context) => const ProfileScreen(),
        settings: (context) => const SettingsScreen(),
        myReviews: (context) => const MyReviewsScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';
    if (routeName.startsWith(socialAuthCallback)) {
      final uri = Uri.parse(routeName);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => SocialAuthCallbackScreen(
          accessToken: uri.queryParameters['token'],
          error: uri.queryParameters['error'],
        ),
      );
    }
    switch (settings.name) {
      case movieDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              MovieDetailScreen(movie: settings.arguments as Movie?),
        );
      case trailer:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TrailerScreen(movie: settings.arguments as Movie?),
        );
      case review:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ReviewScreen(movie: settings.arguments as Movie?),
        );
      case genreDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GenreDetailScreen(
            genreTitle: settings.arguments is String
                ? settings.arguments! as String
                : 'Phim Hành Động',
          ),
        );
    }
    return null;
  }
}

class _PersistentNavigationObserver extends NavigatorObserver {
  void _remember(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || !AppRoutes._restorableRoutes.contains(name)) return;
    unawaited(UiStateStore.instance.setJson('navigation.last', {
      'name': name,
      'arguments': AppRoutes.encodeArguments(route?.settings.arguments),
    }));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remember(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _remember(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remember(previousRoute);
    super.didPop(route, previousRoute);
  }
}
