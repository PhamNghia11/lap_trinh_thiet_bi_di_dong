import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../core/ui_state_store.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(
    text: UiStateStore.instance.string('register.name') ?? '',
  );
  final _email = TextEditingController(
    text: UiStateStore.instance.string('register.email') ?? '',
  );
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(
      () => UiStateStore.instance.setString('register.name', _name.text),
    );
    _email.addListener(
      () => UiStateStore.instance.setString('register.email', _email.text),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AppSession.instance.register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
      await Future.wait([
        UiStateStore.instance.remove('register.name'),
        UiStateStore.instance.remove('register.email'),
      ]);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: const Text(
          'FLIX',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(28),
              decoration: AppTheme.glassCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tạo tài khoản mới',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng ký để xem không giới hạn phim hay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _field(
                    controller: _name,
                    hintText: 'Họ và tên',
                    autofillHints: const [AutofillHints.name],
                    validator: (value) => (value?.trim().length ?? 0) >= 2
                        ? null
                        : 'Vui lòng nhập họ tên',
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _email,
                    hintText: 'Địa chỉ Email',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) => value != null && value.contains('@')
                        ? null
                        : 'Email không hợp lệ',
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _password,
                    hintText: 'Mật khẩu',
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) => (value?.length ?? 0) >= 8
                        ? null
                        : 'Mật khẩu cần ít nhất 8 ký tự',
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _confirm,
                    hintText: 'Xác nhận mật khẩu',
                    obscureText: true,
                    validator: (value) => value == _password.text
                        ? null
                        : 'Mật khẩu xác nhận chưa khớp',
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    text: _loading ? 'Đang tạo tài khoản...' : 'Đăng ký',
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      GestureDetector(
                        onTap: _loading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.inputDecoration(
        hintText: hintText,
        fillColor: AppTheme.scaffoldBg,
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
