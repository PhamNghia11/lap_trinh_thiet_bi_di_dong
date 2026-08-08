// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
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
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String settings = '/settings';

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
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
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
