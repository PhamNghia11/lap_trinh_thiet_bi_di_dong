// lib/theme/app_theme.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hệ thống thiết kế của FLIX — "Cinematic Noir".
///
/// Mọi màu sắc, khoảng cách, bo góc, kiểu chữ và hiệu ứng chuyển động đều
/// khai báo tại đây. Màn hình chỉ việc dùng lại, không tự chế style riêng.
class AppTheme {
  AppTheme._();

  // ─── Bảng màu nền (neutral) ───────────────────────────────────────
  // Nền tối gần như trung tính, chỉ ám một chút đỏ để giữ chất "rạp phim"
  // mà không làm poster bị ám màu như bảng màu nâu đỏ cũ.
  static const Color scaffoldBg = Color(0xFF0B0709);
  static const Color surface = Color(0xFF151012);
  static const Color surfaceElevated = Color(0xFF1E1719);
  static const Color surfaceHigh = Color(0xFF2A2124);
  static const Color cardBg = surfaceElevated;
  static const Color inputBg = Color(0xFF120D0F);

  // ─── Màu thương hiệu ──────────────────────────────────────────────
  static const Color primaryRed = Color(0xFFE50914);
  static const Color primaryRedDark = Color(0xFFB00610);
  static const Color primaryRedLight = Color(0xFFFF3D47);
  static const Color accentGold = Color(0xFFF5C518); // vàng kiểu IMDb
  static const Color accentTeal = Color(0xFF3DDC97);

  // ─── Màu chữ ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F3F4);
  static const Color textSecondary = Color(0xFFB9AFB2);
  static const Color textTertiary = Color(0xFF7C7275);
  static const Color textLight = textPrimary;
  static const Color textMuted = textSecondary;

  // ─── Màu ngữ nghĩa ────────────────────────────────────────────────
  static const Color success = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4D4F);

  // ─── Đường viền & lớp phủ ─────────────────────────────────────────
  static const Color border = Color(0x1AFFFFFF); // trắng 10%
  static const Color borderStrong = Color(0x33FFFFFF); // trắng 20%
  static const Color scrim = Color(0xCC000000);
  static const Color darkOverlay = surfaceHigh;
  static const Color inactiveIndicator = Color(0xFF3A3134);

  // ─── Thang khoảng cách (bội số của 4) ─────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  /// Lề ngang chuẩn của mọi màn hình.
  static const double screenPadding = space16;

  // ─── Bo góc ───────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 28.0;
  static const double radiusCard = radiusMd;
  static const double radiusPill = 999.0;

  // ─── Thời lượng chuyển động ───────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 280);
  static const Duration durationSlow = Duration(milliseconds: 450);
  static const Curve curveEmphasized = Curves.easeOutCubic;

  // ─── Tỉ lệ poster phim chuẩn (2:3) ────────────────────────────────
  static const double posterAspectRatio = 2 / 3;

  // ─── ThemeData chính ──────────────────────────────────────────────
  static ThemeData darkTheme() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      textTheme: textTheme,
      primaryColor: primaryRed,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        onPrimary: Colors.white,
        secondary: accentGold,
        onSecondary: Colors.black,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceHigh,
        error: danger,
        outline: borderStrong,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: textPrimary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primaryRed,
        disabledColor: surface,
        side: const BorderSide(color: border),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle:
            textTheme.labelLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: space4, vertical: space2),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaceHigh,
          disabledForegroundColor: textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space20,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        showDragHandle: true,
        dragHandleColor: textTertiary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        actionTextColor: primaryRedLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        insetPadding: const EdgeInsets.all(space16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryRed;
          return surfaceHigh;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryRed;
          return Colors.transparent;
        }),
        side: const BorderSide(color: textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryRed,
        linearTrackColor: surfaceHigh,
        circularTrackColor: Colors.transparent,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: space16),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textTertiary,
        indicatorColor: primaryRed,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─── Kiểu chữ dùng nhanh ──────────────────────────────────────────
  // Giữ lại các hằng số này để màn hình cũ vẫn dùng được, nhưng ưu tiên
  // `Theme.of(context).textTheme` cho code mới.

  /// Tiêu đề rất lớn — tên phim trên banner hero.
  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.1,
    letterSpacing: -0.8,
  );

  /// Tiêu đề lớn — tên phim ở trang chi tiết, tiêu đề trang.
  static const TextStyle headingLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// Tiêu đề vừa — tên section ("Phim Hành Động").
  static const TextStyle headingMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  /// Tiêu đề nhỏ.
  static const TextStyle headingSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  /// Nội dung chính.
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: textSecondary,
    height: 1.55,
  );

  /// Phụ đề / mô tả ngắn.
  static const TextStyle mutedText = TextStyle(
    fontSize: 13,
    color: textSecondary,
    height: 1.4,
  );

  /// Chữ nhỏ — metadata, nhãn phụ.
  static const TextStyle smallText = TextStyle(
    fontSize: 12,
    color: textTertiary,
    height: 1.35,
  );

  /// Tên phim trên thẻ card.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.25,
  );

  /// Nhãn viết hoa cách chữ rộng — "TẬP MỚI", "HOẠT ĐỘNG GẦN ĐÂY".
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: textTertiary,
    letterSpacing: 1.2,
  );

  /// Logo FLIX.
  static const TextStyle logoStyle = TextStyle(
    color: primaryRed,
    fontWeight: FontWeight.w900,
    fontSize: 26,
    letterSpacing: -1.5,
  );

  // ─── Trang trí dùng lại ───────────────────────────────────────────

  /// Nền thẻ nổi (card thông tin, panel).
  static BoxDecoration surfaceCard({
    Color? color,
    double radius = radiusMd,
    Color borderColor = border,
  }) {
    return BoxDecoration(
      color: color ?? surfaceElevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
    );
  }

  /// Thẻ kính mờ — form đăng nhập, đăng ký.
  static BoxDecoration glassCardDecoration({double? opacity}) {
    return BoxDecoration(
      color: surface.withValues(alpha: opacity ?? 0.88),
      borderRadius: BorderRadius.circular(radiusXl),
      border: Border.all(color: border),
    );
  }

  /// Nền thẻ phim.
  static BoxDecoration movieCardDecoration() {
    return BoxDecoration(
      color: surfaceElevated,
      borderRadius: BorderRadius.circular(radiusMd),
    );
  }

  /// Đổ bóng mềm cho thẻ nổi trên nền tối.
  static List<BoxShadow> softShadow({double blur = 16, double y = 6}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }

  /// Vệt sáng đỏ quanh phần tử nổi bật (nút play, avatar).
  static List<BoxShadow> redGlow({double blur = 24, double alpha = 0.35}) {
    return [
      BoxShadow(
        color: primaryRed.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: 1,
      ),
    ];
  }

  /// Gradient phủ trên ảnh hero để chữ luôn đọc được.
  ///
  /// Nhiều điểm dừng ở nửa dưới để chuyển màu mượt, không bị "vệt cắt"
  /// như gradient 3 điểm dừng trước đây.
  static LinearGradient heroGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scaffoldBg.withValues(alpha: 0.85),
        scaffoldBg.withValues(alpha: 0.20),
        scaffoldBg.withValues(alpha: 0.55),
        scaffoldBg.withValues(alpha: 0.94),
        scaffoldBg,
      ],
      stops: const [0.0, 0.32, 0.62, 0.86, 1.0],
    );
  }

  /// Giữ tên cũ để code hiện có không vỡ.
  static LinearGradient bannerGradient() => heroGradient();

  /// Gradient phủ dưới đáy poster (cho nhãn chồng lên ảnh).
  static LinearGradient posterScrim() {
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.black.withValues(alpha: 0.88),
        Colors.black.withValues(alpha: 0.35),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }

  /// Gradient thương hiệu — dùng cho nút CTA nổi bật và ring avatar.
  static LinearGradient brandGradient() {
    return const LinearGradient(
      colors: [primaryRedLight, primaryRed, primaryRedDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Nền app bar khi cuộn (mờ đục).
  static Color appBarBg = scaffoldBg.withValues(alpha: 0.92);

  // ─── Helper còn dùng ở màn hình cũ ────────────────────────────────

  /// InputDecoration chuẩn. Phần lớn thuộc tính đã nằm trong
  /// `inputDecorationTheme`, hàm này chỉ để thêm icon/hint nhanh.
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      fillColor: fillColor,
    );
  }

  /// Style nút chính. Ưu tiên dùng `ElevatedButton` mặc định của theme.
  static ButtonStyle primaryButtonStyle({
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: space20, vertical: space12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusSm),
      ),
      elevation: 0,
    );
  }

  /// Style nút viền.
  static ButtonStyle outlinedButtonStyle({
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      side: const BorderSide(color: borderStrong),
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusSm),
      ),
    );
  }
}
