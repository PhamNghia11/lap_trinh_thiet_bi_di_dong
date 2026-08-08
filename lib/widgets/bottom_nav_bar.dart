// lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Thanh điều hướng dưới dùng chung cho các màn hình chính.
class FlixBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FlixBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppTheme.cardBg,
      selectedItemColor: AppTheme.primaryRed,
      unselectedItemColor: AppTheme.textMuted,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yêu thích'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ],
    );
  }
}
