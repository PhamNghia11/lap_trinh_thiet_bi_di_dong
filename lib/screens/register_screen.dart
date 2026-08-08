// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
        title: const Text('FLIX', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tạo tài khoản mới', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Đăng ký để xem không giới hạn phim hay.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              const SizedBox(height: 28),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.inputDecoration(hintText: 'Họ và tên', fillColor: AppTheme.scaffoldBg),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.inputDecoration(hintText: 'Địa chỉ Email', fillColor: AppTheme.scaffoldBg),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.inputDecoration(hintText: 'Mật khẩu', fillColor: AppTheme.scaffoldBg),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.inputDecoration(hintText: 'Xác nhận mật khẩu', fillColor: AppTheme.scaffoldBg),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Đăng ký',
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? ', style: TextStyle(color: AppTheme.textMuted)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Đăng nhập', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
