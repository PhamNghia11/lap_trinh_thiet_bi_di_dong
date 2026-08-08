import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AppSession.instance.login(_email.text.trim(), _password.text);
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(title: const Text('FLIX', style: AppTheme.logoStyle), centerTitle: true),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(28),
                decoration: AppTheme.glassCardDecoration(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Chào mừng trở lại', textAlign: TextAlign.center, style: AppTheme.headingLarge),
                  const SizedBox(height: 8),
                  const Text('Đăng nhập để đồng bộ dữ liệu trên mọi thiết bị.', textAlign: TextAlign.center, style: AppTheme.bodyText),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: AppTheme.inputDecoration(hintText: 'Email'),
                    validator: (value) => value != null && value.contains('@') ? null : 'Email không hợp lệ',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: AppTheme.inputDecoration(
                      hintText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) >= 8 ? null : 'Mật khẩu cần ít nhất 8 ký tự',
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                      child: const Text('Quên mật khẩu?', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                  PrimaryButton(text: _loading ? 'Đang đăng nhập...' : 'Đăng nhập', onPressed: _loading ? null : _submit),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Chưa có tài khoản? Đăng ký ngay', style: TextStyle(color: AppTheme.primaryRed)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
