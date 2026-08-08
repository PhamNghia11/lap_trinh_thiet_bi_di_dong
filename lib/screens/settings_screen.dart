// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_preferences.dart';
import '../core/app_session.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _preferences = AppPreferences.instance;
  final _session = AppSession.instance;
  bool _notifications = true;
  final bool _darkMode = true;
  bool _autoPlay = false;
  bool _wifiOnlyDownload = true;

  String _cacheSize = '1.2 GB';

  @override
  void initState() {
    super.initState();
    _preferences.addListener(_syncPreferences);
    _syncPreferences();
  }

  @override
  void dispose() {
    _preferences.removeListener(_syncPreferences);
    super.dispose();
  }

  void _syncPreferences() {
    if (!mounted) return;
    setState(() {
      _notifications = _preferences.notifications;
      _autoPlay = _preferences.autoPlayTrailer;
      _wifiOnlyDownload = _preferences.wifiOnly;
    });
  }

  void _clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title:
            const Text('Xóa bộ nhớ đệm', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn xóa bộ nhớ đệm ($_cacheSize) không?',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle(),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cacheSize = '0 MB');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa bộ nhớ đệm thành công!')),
              );
            },
            child: const Text('Xóa ngay',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.primaryRed),
            SizedBox(width: 10),
            Text('Đăng Xuất',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle(),
            onPressed: () {
              Navigator.pop(context);
              _session.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false);
            },
            child: const Text('Đăng xuất',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseQuality() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Chất lượng video', style: AppTheme.headingMedium)),
          for (final quality in [
            'Tự động',
            'Tiết kiệm dữ liệu',
            'HD 720p',
            'Full HD 1080p'
          ])
            ListTile(
              title: Text(quality, style: const TextStyle(color: Colors.white)),
              trailing: _preferences.videoQuality == quality
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryRed)
                  : null,
              onTap: () => Navigator.pop(context, quality),
            ),
        ]),
      ),
    );
    if (value != null) await _preferences.setVideoQuality(value);
  }

  void _showDownloads() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Quản lý dung lượng tải xuống',
            style: TextStyle(color: Colors.white)),
        content: const Text('Chưa có nội dung tải xuống.',
            style: AppTheme.mutedText),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'))
        ],
      ),
    );
  }

  void _showLegal() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Điều khoản & Chính sách bảo mật',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'FLIX dùng TMDB cho dữ liệu phim. Tài khoản, yêu thích, lịch sử và đánh giá được lưu an toàn trên Supabase.',
            style: AppTheme.mutedText),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cài Đặt',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── User Profile Header Card ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      NetworkImage('https://picsum.photos/id/1005/200/200'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _session.user?['fullName'] as String? ?? 'Khách FLIX',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _session.user?['email'] as String? ?? 'Chưa đăng nhập',
                        style: AppTheme.smallText,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppTheme.accentGold, width: 0.5),
                        ),
                        child: const Text(
                          'TÀI KHOẢN FLIX',
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.profile),
                  child: const Text('Sửa',
                      style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Nhóm 1: Tài khoản & Bảo mật ──────────────────────────
          _buildSectionHeader('TÀI KHOẢN & BẢO MẬT'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded,
                color: AppTheme.textMuted),
            title: const Text('Thông tin cá nhân',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded,
                color: AppTheme.textMuted),
            title: const Text('Đổi mật khẩu',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
          ),
          const Divider(color: Colors.white12, height: 24),

          // ─── Nhóm 2: Phát Video & Tải Xuống ────────────────────────
          _buildSectionHeader('PHÁT VIDEO & TẢI XUỐNG'),
          SwitchListTile(
            activeThumbColor: AppTheme.primaryRed,
            secondary: const Icon(Icons.play_circle_outline_rounded,
                color: AppTheme.textMuted),
            title: const Text('Tự động phát Trailer',
                style: TextStyle(color: Colors.white)),
            value: _autoPlay,
            onChanged: (val) => _preferences.setAutoPlayTrailer(val),
          ),
          SwitchListTile(
            activeThumbColor: AppTheme.primaryRed,
            secondary:
                const Icon(Icons.wifi_rounded, color: AppTheme.textMuted),
            title: const Text('Chỉ tải xuống qua Wi-Fi',
                style: TextStyle(color: Colors.white)),
            value: _wifiOnlyDownload,
            onChanged: (val) => _preferences.setWifiOnly(val),
          ),
          ListTile(
            leading: const Icon(Icons.high_quality_rounded,
                color: AppTheme.textMuted),
            title: const Text('Chất lượng video',
                style: TextStyle(color: Colors.white)),
            subtitle:
                Text(_preferences.videoQuality, style: AppTheme.mutedText),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: _chooseQuality,
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined,
                color: AppTheme.textMuted),
            title: const Text('Quản lý dung lượng tải xuống',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Chưa có nội dung tải xuống',
                style: AppTheme.mutedText),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: _showDownloads,
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded,
                color: AppTheme.textMuted),
            title: const Text('Xóa bộ nhớ đệm',
                style: TextStyle(color: Colors.white)),
            subtitle:
                Text('Dung lượng đệm: $_cacheSize', style: AppTheme.mutedText),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: _clearCache,
          ),
          const Divider(color: Colors.white12, height: 24),

          // ─── Nhóm 3: Giao diện & Ngôn ngữ ─────────────────────────
          _buildSectionHeader('GIAO DIỆN & NGÔN NGỮ'),
          SwitchListTile(
            activeThumbColor: AppTheme.primaryRed,
            secondary:
                const Icon(Icons.dark_mode_outlined, color: AppTheme.textMuted),
            title: const Text('Giao diện tối (Cinematic Noir)',
                style: TextStyle(color: Colors.white)),
            value: _darkMode,
            onChanged: null,
          ),
          ListTile(
            leading:
                const Icon(Icons.language_rounded, color: AppTheme.textMuted),
            title: const Text('Ngôn ngữ ứng dụng',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Tiếng Việt', style: AppTheme.mutedText),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('FLIX hiện chỉ hỗ trợ Tiếng Việt'))),
          ),
          const Divider(color: Colors.white12, height: 24),

          // ─── Nhóm 4: Thông báo ────────────────────────────────────
          _buildSectionHeader('THÔNG BÁO'),
          SwitchListTile(
            activeThumbColor: AppTheme.primaryRed,
            secondary: const Icon(Icons.notifications_none_rounded,
                color: AppTheme.textMuted),
            title: const Text('Thông báo phim mới & cập nhật',
                style: TextStyle(color: Colors.white)),
            value: _notifications,
            onChanged: (val) => _preferences.setNotifications(val),
          ),
          const Divider(color: Colors.white12, height: 24),

          // ─── Nhóm 5: Hỗ trợ & Về ứng dụng ─────────────────────────
          _buildSectionHeader('VỀ ỨNG DỤNG'),
          ListTile(
            leading:
                const Icon(Icons.star_rate_rounded, color: AppTheme.accentGold),
            title: const Text('Đánh giá ứng dụng',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cảm ơn bạn đã đánh giá 5 sao cho FLIX!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded, color: AppTheme.textMuted),
            title: const Text('Chia sẻ ứng dụng',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: () async {
              await Clipboard.setData(const ClipboardData(
                  text:
                      'https://github.com/PhamNghia11/lap_trinh_thiet_bi_di_dong'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép liên kết FLIX')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.headset_mic_outlined,
                color: AppTheme.textMuted),
            title: const Text('Liên hệ hỗ trợ',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: () => launchUrl(
                Uri.parse('mailto:support@flix.local?subject=Hỗ trợ FLIX')),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppTheme.textMuted),
            title: const Text('Điều khoản & Chính sách bảo mật',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
            onTap: _showLegal,
          ),
          const ListTile(
            leading:
                Icon(Icons.info_outline_rounded, color: AppTheme.textMuted),
            title: Text('Phiên bản ứng dụng',
                style: TextStyle(color: Colors.white)),
            subtitle:
                Text('FLIX v1.2.0 (Build 2026)', style: AppTheme.mutedText),
          ),
          const SizedBox(height: 28),

          // ─── Nút Đăng Xuất Đỏ Viền Tách Biệt ───────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _confirmLogout,
              icon:
                  const Icon(Icons.logout_rounded, color: AppTheme.primaryRed),
              label: const Text(
                'Đăng Xuất Tài Khoản',
                style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
