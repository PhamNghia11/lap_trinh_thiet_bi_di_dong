import 'package:flutter/material.dart';

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
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
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
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppTheme.surfaceElevated,
        alignment: Alignment.center,
        child:
            const Icon(Icons.broken_image_outlined, color: AppTheme.textMuted),
      ),
    );
  }
}
