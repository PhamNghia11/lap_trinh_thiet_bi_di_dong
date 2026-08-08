import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/flix_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _session = AppSession.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!_session.isAuthenticated) return;
    setState(() => _loading = true);
    try {
      await _session.refreshProfile();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(
        text: _session.user?['fullName'] as String? ?? '');
    final avatar = TextEditingController(
        text: _session.user?['avatarUrl'] as String? ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chỉnh sửa hồ sơ', style: AppTheme.headingMedium),
              const SizedBox(height: 18),
              TextField(
                  controller: name,
                  style: const TextStyle(color: Colors.white),
                  decoration: AppTheme.inputDecoration(hintText: 'Họ và tên')),
              const SizedBox(height: 12),
              TextField(
                  controller: avatar,
                  style: const TextStyle(color: Colors.white),
                  decoration: AppTheme.inputDecoration(
                      hintText: 'URL ảnh đại diện (không bắt buộc)')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _session.updateProfile(name.text.trim(),
                          avatarUrl: avatar.text.trim());
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      if (mounted) setState(() {});
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$error')));
                      }
                    }
                  },
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ]),
      ),
    );
  }

  Future<void> _logout() async {
    await _session.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isAuthenticated) return _guest();
    final user = _session.user ?? const <String, dynamic>{};
    final counts = user['_count'] as Map<String, dynamic>? ?? const {};
    final avatarUrl = user['avatarUrl'] as String? ?? '';
    final createdAt = DateTime.tryParse('${user['createdAt'] ?? ''}');
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        actions: [
          IconButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
              icon: const Icon(Icons.settings_outlined))
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(color: AppTheme.primaryRed))
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF451013), AppTheme.cardBg],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  border: Border.all(
                      color: AppTheme.primaryRed.withValues(alpha: .3)),
                ),
                child: Row(children: [
                  Container(
                    width: 82,
                    height: 82,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppTheme.primaryRed, width: 2)),
                    child: ClipOval(
                      child: avatarUrl.isEmpty
                          ? const ColoredBox(
                              color: AppTheme.inputBg,
                              child: Icon(Icons.person,
                                  color: AppTheme.textMuted, size: 42))
                          : FlixNetworkImage(avatarUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(user['fullName'] as String? ?? 'Người dùng FLIX',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(user['email'] as String? ?? '',
                            style: AppTheme.smallText),
                        const SizedBox(height: 10),
                        Text(
                            createdAt == null
                                ? 'Thành viên FLIX'
                                : 'Thành viên từ ${createdAt.month}/${createdAt.year}',
                            style: const TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ])),
                  IconButton.filledTonal(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_outlined)),
                ]),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  _stat('${counts['history'] ?? 0}', 'Đã xem',
                      () => Navigator.pushNamed(context, AppRoutes.history)),
                  _divider(),
                  _stat('${counts['favorites'] ?? 0}', 'Yêu thích',
                      () => Navigator.pushNamed(context, AppRoutes.favorites)),
                  _divider(),
                  _stat('${counts['reviews'] ?? 0}', 'Đánh giá',
                      () => Navigator.pushNamed(context, AppRoutes.search)),
                ]),
              ),
              const SizedBox(height: 24),
              const Text('Thư viện của bạn', style: AppTheme.headingMedium),
              const SizedBox(height: 10),
              _panel([
                _item(
                    Icons.favorite_border,
                    'Phim yêu thích',
                    'Danh sách đã đồng bộ',
                    () => Navigator.pushNamed(context, AppRoutes.favorites)),
                _item(Icons.history, 'Lịch sử xem', 'Trailer đã mở gần đây',
                    () => Navigator.pushNamed(context, AppRoutes.history)),
                _item(
                    Icons.rate_review_outlined,
                    'Viết đánh giá',
                    'Chọn phim để chia sẻ cảm nhận',
                    () => Navigator.pushNamed(context, AppRoutes.search)),
              ]),
              const SizedBox(height: 20),
              const Text('Tài khoản', style: AppTheme.headingMedium),
              const SizedBox(height: 10),
              _panel([
                _item(Icons.badge_outlined, 'Thông tin hồ sơ',
                    'Tên và ảnh đại diện', _editProfile),
                _item(
                    Icons.settings_outlined,
                    'Cài đặt ứng dụng',
                    'Video, thông báo và quyền riêng tư',
                    () => Navigator.pushNamed(context, AppRoutes.settings)),
              ]),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: AppTheme.primaryRed),
                  label: const Text('Đăng xuất',
                      style: TextStyle(color: AppTheme.primaryRed))),
            ]),
      ),
      bottomNavigationBar: const FlixBottomNavBar(currentIndex: 4),
    );
  }

  Widget _guest() => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(title: const Text('Trang cá nhân')),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.account_circle_outlined,
                      size: 76, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Đăng nhập để xem hồ sơ và đồng bộ thư viện.',
                      textAlign: TextAlign.center, style: AppTheme.bodyText),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      child: const Text('Đăng nhập')),
                ]))),
        bottomNavigationBar: const FlixBottomNavBar(currentIndex: 4),
      );

  Widget _stat(String count, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
          onTap: onTap,
          child: Column(children: [
            Text(count,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label, style: AppTheme.smallText),
          ])));
  Widget _divider() => Container(width: 1, height: 34, color: Colors.white12);
  Widget _panel(List<Widget> children) => Container(
      decoration: BoxDecoration(
          color: AppTheme.cardBg, borderRadius: BorderRadius.circular(18)),
      child: Column(children: children));
  Widget _item(
          IconData icon, String title, String subtitle, VoidCallback onTap) =>
      ListTile(
        leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primaryRed, size: 21)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTheme.smallText),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: onTap,
      );
}
