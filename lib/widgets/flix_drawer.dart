import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class FlixDrawer extends StatelessWidget {
  const FlixDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppSession.instance.user;
    return Drawer(
      backgroundColor: AppTheme.scaffoldBg,
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.cardBg),
              accountName: Text(user?['fullName'] as String? ?? 'Khách FLIX'),
              accountEmail:
                  Text(user?['email'] as String? ?? 'Khám phá phim cùng FLIX'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppTheme.primaryRed,
                child: Icon(Icons.movie_filter_rounded, color: Colors.white),
              ),
            ),
            _item(context, Icons.home_outlined, 'Trang chủ', AppRoutes.home),
            _item(context, Icons.search_rounded, 'Tìm kiếm', AppRoutes.search),
            _item(context, Icons.favorite_border_rounded, 'Yêu thích',
                AppRoutes.favorites),
            _item(context, Icons.history_rounded, 'Lịch sử xem',
                AppRoutes.history),
            const Divider(color: Colors.white12),
            _item(context, Icons.person_outline_rounded, 'Trang cá nhân',
                AppRoutes.profile),
            _item(context, Icons.settings_outlined, 'Cài đặt',
                AppRoutes.settings),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('FLIX  •  1.0.0',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
          BuildContext context, IconData icon, String label, String route) =>
      ListTile(
        leading: Icon(icon, color: AppTheme.textMuted),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          if (route != AppRoutes.home) Navigator.pushNamed(context, route);
        },
      );
}
