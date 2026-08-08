import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AppSession.instance.register(_name.text.trim(), _email.text.trim(), _password.text);
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
        appBar: AppBar(title: const Text('Tạo tài khoản')),
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
                  const Text('Gia nhập FLIX', textAlign: TextAlign.center, style: AppTheme.headingLarge),
                  const SizedBox(height: 24),
                  _field(_name, 'Họ và tên', (v) => (v?.trim().length ?? 0) >= 2 ? null : 'Vui lòng nhập họ tên'),
                  const SizedBox(height: 14),
                  _field(_email, 'Email', (v) => v != null && v.contains('@') ? null : 'Email không hợp lệ', keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _field(_password, 'Mật khẩu', (v) => (v?.length ?? 0) >= 8 ? null : 'Mật khẩu cần ít nhất 8 ký tự', obscure: true),
                  const SizedBox(height: 14),
                  _field(_confirm, 'Xác nhận mật khẩu', (v) => v == _password.text ? null : 'Mật khẩu xác nhận chưa khớp', obscure: true),
                  const SizedBox(height: 24),
                  PrimaryButton(text: _loading ? 'Đang tạo tài khoản...' : 'Đăng ký', onPressed: _loading ? null : _submit),
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _field(TextEditingController controller, String hint, String? Function(String?) validator,
      {bool obscure = false, TextInputType? keyboard}) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: AppTheme.inputDecoration(hintText: hint),
        validator: validator,
      );
}
