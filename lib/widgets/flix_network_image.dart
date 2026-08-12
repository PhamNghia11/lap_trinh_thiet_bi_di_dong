import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/media_url.dart';
import '../theme/app_theme.dart';

class FlixNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const FlixNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:image/')) {
      try {
        final bytes = base64Decode(url.substring(url.indexOf(',') + 1));
        return Image.memory(bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _error());
      } catch (_) {
        return _error();
      }
    }
    return Image.network(
      resolveImageUrl(url),
      width: width,
      height: height,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return Container(
          width: width,
          height: height,
          color: AppTheme.surfaceElevated,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) => _error(),
    );
  }

  Widget _error() => Container(
        width: width,
        height: height,
        color: AppTheme.surfaceElevated,
        alignment: Alignment.center,
        child:
            const Icon(Icons.broken_image_outlined, color: AppTheme.textMuted),
      );
}
