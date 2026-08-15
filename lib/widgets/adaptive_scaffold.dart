import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'bottom_nav_bar.dart';

const double flixDesktopBreakpoint = 900;

class FlixResponsiveContent extends StatelessWidget {
  const FlixResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.desktopPadding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets desktopPadding;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < flixDesktopBreakpoint) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(padding: desktopPadding, child: child),
        ),
      ),
    );
  }
}

class FlixAdaptiveScaffold extends StatelessWidget {
  const FlixAdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.appBar,
    this.desktopAppBar,
    this.drawer,
    this.contentMaxWidth = 1280,
  });

  final int currentIndex;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final PreferredSizeWidget? desktopAppBar;
  final Widget? drawer;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= flixDesktopBreakpoint;
    if (!isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: appBar,
        body: body,
        drawer: drawer,
        bottomNavigationBar: FlixBottomNavBar(currentIndex: currentIndex),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Row(
        children: [
          _DesktopNavigation(currentIndex: currentIndex),
          const VerticalDivider(width: 1, thickness: 1, color: Colors.white10),
          Expanded(
            child: Column(
              children: [
                if (desktopAppBar ?? appBar case final desktopBar?) desktopBar,
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: body,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({required this.currentIndex});

  final int currentIndex;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.favorites,
    AppRoutes.history,
    AppRoutes.profile,
  ];

  void _open(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.instance.user;
    final name = user?['fullName'] as String? ?? 'Khách FLIX';
    final email = user?['email'] as String? ?? 'Khám phá điện ảnh';

    return SizedBox(
      width: 248,
      child: Material(
        color: AppTheme.appBarBg,
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('FLIX', style: AppTheme.logoStyle),
                ),
              ),
              Expanded(
                child: NavigationRail(
                  extended: true,
                  minExtendedWidth: 247,
                  backgroundColor: AppTheme.appBarBg,
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) => _open(context, index),
                  indicatorColor: AppTheme.primaryRed.withValues(alpha: 0.18),
                  selectedIconTheme:
                      const IconThemeData(color: AppTheme.primaryRed),
                  unselectedIconTheme:
                      const IconThemeData(color: AppTheme.textMuted),
                  selectedLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelTextStyle:
                      const TextStyle(color: AppTheme.textMuted),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Trang chủ'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_rounded),
                      label: Text('Tìm kiếm'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded),
                      label: Text('Yêu thích'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_rounded),
                      label: Text('Lịch sử'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Cá nhân'),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined,
                    color: AppTheme.textMuted),
                title: const Text('Cài đặt',
                    style: TextStyle(color: AppTheme.textLight)),
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryRed,
                      child: Icon(Icons.movie_filter_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          Text(email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.smallText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
