import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class SocialAuthCallbackScreen extends StatefulWidget {
  const SocialAuthCallbackScreen({
    super.key,
    this.accessToken,
    this.error,
  });

  final String? accessToken;
  final String? error;

  @override
  State<SocialAuthCallbackScreen> createState() =>
      _SocialAuthCallbackScreenState();
}

class _SocialAuthCallbackScreenState extends State<SocialAuthCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.error;
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    if (_error != null) return;
    final token = widget.accessToken;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Không nhận được phiên đăng nhập từ máy chủ');
      return;
    }
    try {
      await AppSession.instance.completeSocialLogin(token);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('FLIX', style: AppTheme.logoStyle),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _error == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryRed),
                    SizedBox(height: 18),
                    Text('Đang hoàn tất đăng nhập...',
                        style: AppTheme.bodyText),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 64, color: AppTheme.primaryRed),
                    const SizedBox(height: 16),
                    const Text('Không thể đăng nhập',
                        style: AppTheme.headingMedium),
                    const SizedBox(height: 8),
                    Text(_error!,
                        textAlign: TextAlign.center, style: AppTheme.bodyText),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (_) => false,
                      ),
                      child: const Text('Quay lại đăng nhập'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
