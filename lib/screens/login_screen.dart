import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../core/ui_state_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(
    text: UiStateStore.instance.string('login.email') ?? '',
  );
  final _password = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = UiStateStore.instance.boolean('login.remember') ?? true;
  bool _loading = false;
  String? _socialLoading;

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
      await UiStateStore.instance.setBool('login.remember', _rememberMe);
      if (_rememberMe) {
        await UiStateStore.instance
            .setString('login.email', _email.text.trim());
      } else {
        await UiStateStore.instance.remove('login.email');
      }
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

  Future<void> _startSocialLogin(String provider) async {
    setState(() => _socialLoading = provider);
    try {
      final data = Map<String, dynamic>.from(
        await ApiClient.instance.get(
          socialAuthorizationPath(provider, isWeb: kIsWeb),
        ),
      );
      final url = Uri.tryParse(data['url'] as String? ?? '');
      if (url == null ||
          !await launchUrl(
            url,
            mode: kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
            webOnlyWindowName: kIsWeb ? '_self' : null,
          )) {
        throw const ApiException('Không thể mở trang đăng nhập');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _socialLoading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Flutter Web can report a transient negative viewInset while Chrome
      // moves focus away from a text field during an OAuth redirect. The form
      // already scrolls, so resizing the whole scaffold is unnecessary and
      // can abort the Google navigation in debug mode.
      resizeToAvoidBottomInset: !kIsWeb,
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'FLIX',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
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
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chào mừng trở lại',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng nhập để thưởng thức các bộ phim yêu thích.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(color: Colors.white),
                    decoration: AppTheme.inputDecoration(
                      hintText: 'Email hoặc số điện thoại',
                    ),
                    validator: (value) => value != null && value.contains('@')
                        ? null
                        : 'Email không hợp lệ',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    style: const TextStyle(color: Colors.white),
                    decoration: AppTheme.inputDecoration(
                      hintText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) >= 8
                        ? null
                        : 'Mật khẩu cần ít nhất 8 ký tự',
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppTheme.primaryRed,
                            onChanged: _loading
                                ? null
                                : (value) {
                                    setState(
                                      () => _rememberMe = value ?? false,
                                    );
                                    UiStateStore.instance.setBool(
                                      'login.remember',
                                      _rememberMe,
                                    );
                                  },
                          ),
                          const Text(
                            'Ghi nhớ',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.forgotPassword,
                                ),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: _loading ? 'Đang đăng nhập...' : 'Đăng nhập',
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const label = Text(
                        'Hoặc đăng nhập bằng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      );
                      if (constraints.maxWidth < 220) return label;
                      return const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white12)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: label,
                          ),
                          Expanded(child: Divider(color: Colors.white12)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonWidth = constraints.maxWidth < 240
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: buttonWidth,
                            child: OutlinedButton.icon(
                              style: AppTheme.outlinedButtonStyle(),
                              onPressed: _loading || _socialLoading != null
                                  ? null
                                  : () => _startSocialLogin('google'),
                              icon: const Icon(
                                Icons.g_mobiledata,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                              label: Text(
                                _socialLoading == 'google'
                                    ? 'Đang mở...'
                                    : 'Google',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            child: OutlinedButton.icon(
                              style: AppTheme.outlinedButtonStyle(),
                              onPressed: _loading || _socialLoading != null
                                  ? null
                                  : () => _startSocialLogin('facebook'),
                              icon: const Icon(
                                Icons.facebook,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              label: Text(
                                _socialLoading == 'facebook'
                                    ? 'Đang mở...'
                                    : 'Facebook',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Chưa có tài khoản? ',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.register,
                                ),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
}

@visibleForTesting
String socialAuthorizationPath(String provider, {required bool isWeb}) {
  final returnTarget = isWeb ? 'web' : 'mobile';
  return '/auth/oauth/$provider/url?returnTo=$returnTarget';
}
