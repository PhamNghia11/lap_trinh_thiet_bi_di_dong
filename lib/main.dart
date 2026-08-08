// lib/main.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

void main() {
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
    );
  }
}
