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
        genreDetail: (context) => const GenreDetailScreen(),
        movieList: (context) => const MovieListScreen(),
        movieDetail: (context) => const MovieDetailScreen(),
        trailer: (context) => const TrailerScreen(),
        review: (context) => const ReviewScreen(),
        favorites: (context) => const FavoritesScreen(),
        history: (context) => const HistoryScreen(),
        profile: (context) => const ProfileScreen(),
        settings: (context) => const SettingsScreen(),
      };
}
