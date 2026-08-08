import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNext = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_next.text.length < 8 || _next.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Mật khẩu mới cần ít nhất 8 ký tự và phải trùng xác nhận')));
      return;
    }
    setState(() => _loading = true);
    try {
      await AppSession.instance.changePassword(_current.text, _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu')));
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = AppSession.instance.isAuthenticated;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar:
          AppBar(title: Text(authenticated ? 'Đổi mật khẩu' : 'Quên mật khẩu')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(26),
            decoration: AppTheme.glassCardDecoration(),
            child: authenticated
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const Icon(Icons.lock_reset_rounded,
                            color: AppTheme.primaryRed, size: 54),
                        const SizedBox(height: 14),
                        const Text('Bảo vệ tài khoản',
                            textAlign: TextAlign.center,
                            style: AppTheme.headingMedium),
                        const SizedBox(height: 22),
                        _field(
                            _current,
                            'Mật khẩu hiện tại',
                            _obscureCurrent,
                            () => setState(
                                () => _obscureCurrent = !_obscureCurrent)),
                        const SizedBox(height: 14),
                        _field(_next, 'Mật khẩu mới', _obscureNext,
                            () => setState(() => _obscureNext = !_obscureNext)),
                        const SizedBox(height: 14),
                        TextField(
                            controller: _confirm,
                            obscureText: _obscureNext,
                            style: const TextStyle(color: Colors.white),
                            decoration: AppTheme.inputDecoration(
                                hintText: 'Xác nhận mật khẩu mới')),
                        const SizedBox(height: 22),
                        PrimaryButton(
                            text:
                                _loading ? 'Đang cập nhật...' : 'Đổi mật khẩu',
                            onPressed: _loading ? null : _changePassword),
                      ])
                : Column(children: [
                    const Icon(Icons.mark_email_read_outlined,
                        color: AppTheme.primaryRed, size: 58),
                    const SizedBox(height: 16),
                    const Text('Khôi phục mật khẩu',
                        style: AppTheme.headingMedium),
                    const SizedBox(height: 10),
                    const Text(
                        'Tính năng gửi email tự động chưa được cấu hình trên môi trường này. Hãy liên hệ hỗ trợ để xác minh tài khoản.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyText),
                    const SizedBox(height: 22),
                    PrimaryButton(
                        text: 'Liên hệ hỗ trợ',
                        width: double.infinity,
                        onPressed: () => launchUrl(Uri.parse(
                            'mailto:support@flix.local?subject=Khôi phục mật khẩu FLIX'))),
                  ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, bool obscure,
          VoidCallback toggle) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: AppTheme.inputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
                onPressed: toggle,
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textMuted))),
      );
}
