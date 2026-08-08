// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lớp chứa toàn bộ hằng số giao diện dùng chung cho ứng dụng FLIX.
/// Tập trung màu sắc, text style, decoration để tránh lặp code.
class AppTheme {
  AppTheme._(); // Không cho phép tạo instance

  // ─── Màu sắc chính ───────────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFF200E0C);
  static const Color primaryRed = Color(0xFFE50914);
  static const Color cardBg = Color(0xFF2E1A18);
  static const Color accentGold = Color(0xFFE9C349);
  static const Color textMuted = Color(0xFFE9BCB6);
  static const Color textLight = Color(0xFFFFDAD5);
  static const Color inputBg = Color(0xFF121212);
  static const Color darkOverlay = Color(0xFF3A2522);
  static const Color inactiveIndicator = Color(0xFF462F2C);

  // ─── Border radius chuẩn ──────────────────────────────────────────
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 14.0;
  static const double radiusXxl = 20.0;
  static const double radiusCard = 24.0;

  // ─── ThemeData chính ──────────────────────────────────────────────
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryRed,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        surface: scaffoldBg,
        secondary: accentGold,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  // ─── Text Styles ──────────────────────────────────────────────────

  /// Heading lớn (tên phim, tiêu đề trang)
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Heading trung bình (tiêu đề section)
  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Heading nhỏ (tiêu đề phụ)
  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Body text chính
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: textMuted,
    height: 1.5,
  );

  /// Text muted / subtitle
  static const TextStyle mutedText = TextStyle(
    fontSize: 13,
    color: textMuted,
  );

  /// Text nhỏ
  static const TextStyle smallText = TextStyle(
    fontSize: 12,
    color: textMuted,
  );

  /// Title cho movie card
  static const TextStyle cardTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Logo FLIX style
  static const TextStyle logoStyle = TextStyle(
    color: primaryRed,
    fontWeight: FontWeight.bold,
    fontSize: 26,
    letterSpacing: -1,
  );

  // ─── Input Decoration ─────────────────────────────────────────────

  /// InputDecoration chuẩn cho các TextField trong app
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0x80E9BCB6)),
      filled: true,
      fillColor: fillColor ?? inputBg,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: primaryRed, width: 2),
      ),
    );
  }

  // ─── Button Styles ────────────────────────────────────────────────

  /// Style cho nút chính (primary, màu đỏ)
  static ButtonStyle primaryButtonStyle({
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryRed,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusLg),
      ),
      elevation: 6,
      shadowColor: primaryRed.withOpacity(0.4),
    );
  }

  /// Style cho nút outlined
  static ButtonStyle outlinedButtonStyle({
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white24),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusMd),
      ),
    );
  }

  // ─── Decorations ──────────────────────────────────────────────────

  /// Box decoration cho card nền tối (login form, register form, v.v.)
  static BoxDecoration glassCardDecoration({double? opacity}) {
    return BoxDecoration(
      color: inputBg.withOpacity(opacity ?? 0.85),
      borderRadius: BorderRadius.circular(radiusXxl),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    );
  }

  /// Box decoration cho card phim (grid, list)
  static BoxDecoration movieCardDecoration() {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radiusLg),
    );
  }

  /// Gradient phủ lên ảnh banner
  static LinearGradient bannerGradient() {
    return LinearGradient(
      colors: [
        scaffoldBg,
        Colors.transparent,
        scaffoldBg.withOpacity(0.9),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// AppBar background cho các screen dùng nền mờ
  static Color appBarBg = Colors.black.withOpacity(0.8);
}
