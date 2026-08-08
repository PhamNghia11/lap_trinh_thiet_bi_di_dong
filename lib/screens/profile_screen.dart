// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../widgets/bottom_nav_bar.dart';
import '../core/app_session.dart';
import '../widgets/flix_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _session = AppSession.instance;

  Future<void> _logout() async {
    await _session.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
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
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản FLIX không?',
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
              _logout();
            },
            child: const Text('Đăng xuất',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final controller = TextEditingController(
      text: _session.user?['fullName'] as String? ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Chỉnh sửa hồ sơ',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: AppTheme.inputDecoration(hintText: 'Họ và tên'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _session.updateProfile(controller.text.trim());
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                setState(() {});
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$error')));
                }
              }
            },
            child: const Text('Lưu'),
          ),
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
        title: const Text('Trang Cá Nhân',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Header Avatar với Viền Gradient Glow & Edit Icon ─────
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Viền Ring Gradient Glow đỏ rực
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryRed,
                              AppTheme.accentGold,
                              AppTheme.primaryRed,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (_session.user?['avatarUrl'] as String? ?? '')
                                  .isEmpty
                              ? const ColoredBox(
                                  color: AppTheme.inputBg,
                                  child: SizedBox(
                                    width: 92,
                                    height: 92,
                                    child: Icon(Icons.person,
                                        color: AppTheme.textMuted, size: 46),
                                  ),
                                )
                              : FlixNetworkImage(
                                  _session.user!['avatarUrl'] as String,
                                  width: 92,
                                  height: 92,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),

                      // Icon Bút Chì Chỉnh Sửa ở Góc Phải Avatar
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _showEditProfileDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.scaffoldBg, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _session.user?['fullName'] as String? ?? 'Khách FLIX',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _session.user?['email'] as String? ?? 'Chưa đăng nhập',
                    style: AppTheme.mutedText,
                  ),
                  const SizedBox(height: 8),

                  // Badge Hạng Thành Viên ("GOLD MEMBER • Thành viên từ 2023")
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppTheme.accentGold, width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech_rounded,
                            color: AppTheme.accentGold, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'GOLD MEMBER • Từ 2023',
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Phần Thống Kê (Đã xem / Yêu thích / Đánh giá) ─────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildClickableStatItem(
                      count:
                          '${(_session.user?['_count'] as Map<String, dynamic>?)?['history'] ?? 0}',
                      label: 'Đã xem',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.history),
                    ),
                  ),
                  Container(height: 32, width: 1, color: Colors.white12),
                  Expanded(
                    child: _buildClickableStatItem(
                      count:
                          '${(_session.user?['_count'] as Map<String, dynamic>?)?['favorites'] ?? 0}',
                      label: 'Yêu thích',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.favorites),
                    ),
                  ),
                  Container(height: 32, width: 1, color: Colors.white12),
                  Expanded(
                    child: _buildClickableStatItem(
                      count:
                          '${(_session.user?['_count'] as Map<String, dynamic>?)?['reviews'] ?? 0}',
                      label: 'Đánh giá',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.review),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Card Nổi Bật Gói VIP Premium ─────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF800A10),
                    Color(0xFF3D080C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.6),
                    width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: AppTheme.accentGold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gói VIP Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Xem không giới hạn, không quảng cáo, 4K Ultra HD',
                          style: TextStyle(
                              color: AppTheme.textLight, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Tính năng đăng ký VIP Premium đang mở rộng!')),
                      );
                    },
                    child: const Text(
                      'Nâng cấp',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Danh Sách Điều Hướng Nâng Cấp ──────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildNavTile(
                    icon: Icons.history_rounded,
                    iconColor: AppTheme.textMuted,
                    title: 'Lịch sử xem phim',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.history),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildNavTile(
                    icon: Icons.favorite_border_rounded,
                    iconColor: AppTheme.primaryRed,
                    title: 'Phim đã lưu & Yêu thích',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.favorites),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildNavTile(
                    icon: Icons.rate_review_outlined,
                    iconColor: AppTheme.accentGold,
                    title: 'Đánh giá của tôi',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.review),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildNavTile(
                    icon: Icons.badge_outlined,
                    iconColor: Colors.lightBlueAccent,
                    title: 'Thông tin tài khoản',
                    onTap: _showEditProfileDialog,
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildNavTile(
                    icon: Icons.card_giftcard_rounded,
                    iconColor: Colors.purpleAccent,
                    title: 'Mời bạn bè nhận quà',
                    badgeText: '+50 điểm',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Tính năng mời bạn bè sẽ được kết nối khi hệ thống điểm hoạt động.')),
                      );
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildNavTile(
                    icon: Icons.settings_outlined,
                    iconColor: AppTheme.textMuted,
                    title: 'Cài đặt hệ thống',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ─── Phần Hoạt Động Gần Đây (Timeline) ──────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'HOẠT ĐỘNG GẦN ĐÂY',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildTimelineItem(
                    icon: Icons.play_circle_fill_rounded,
                    iconColor: AppTheme.primaryRed,
                    text: 'Lịch sử xem phim sẽ hiển thị tại đây',
                    time: 'Đồng bộ từ máy chủ',
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _buildTimelineItem(
                    icon: Icons.star_rounded,
                    iconColor: AppTheme.accentGold,
                    text: 'Đánh giá của bạn được lưu trong tài khoản',
                    time: 'Đồng bộ từ máy chủ',
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _buildTimelineItem(
                    icon: Icons.favorite_rounded,
                    iconColor: AppTheme.primaryRed,
                    text: 'Phim yêu thích được đồng bộ tự động',
                    time: 'Đồng bộ từ máy chủ',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── Nút Đăng Xuất Đỏ Viền (Outline) Tách Biệt ─────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppTheme.primaryRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded,
                    color: AppTheme.primaryRed),
                label: const Text(
                  'Đăng Xuất Tài Khoản',
                  style: TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const FlixBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildClickableStatItem({
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.smallText),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purpleAccent, width: 0.6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required String time,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        Text(time, style: AppTheme.smallText),
      ],
    );
  }
}
