import 'dart:convert';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

class ProfileMediaEditor {
  static Future<String?> pickAndEdit(
    BuildContext context, {
    required bool isCover,
  }) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !context.mounted) return null;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return null;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CropScreen(image: bytes, isCover: isCover),
      ),
    );
    if (cropped == null || !context.mounted) return null;

    final decoded = img.decodeImage(cropped);
    if (decoded == null) throw const FormatException('Ảnh không hợp lệ');
    final resized = isCover
        ? img.copyResize(decoded, width: 1280)
        : img.copyResizeCropSquare(decoded, size: 512);
    final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 76));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(isCover ? 'Xác nhận ảnh bìa' : 'Xác nhận ảnh đại diện',
            style: const TextStyle(color: Colors.white)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(isCover ? 14 : 200),
          child: Image.memory(compressed,
              width: isCover ? 420 : 220,
              height: isCover ? 210 : 220,
              fit: BoxFit.cover),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Chỉnh lại')),
          ElevatedButton.icon(
            style: AppTheme.primaryButtonStyle(),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text('Dùng ảnh này',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return null;
    return 'data:image/jpeg;base64,${base64Encode(compressed)}';
  }
}

class _CropScreen extends StatefulWidget {
  const _CropScreen({required this.image, required this.isCover});
  final Uint8List image;
  final bool isCover;

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _controller = CropController();
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: Text(widget.isCover ? 'Chỉnh ảnh bìa' : 'Chỉnh ảnh đại diện'),
        actions: [
          TextButton.icon(
            onPressed: _processing
                ? null
                : () {
                    setState(() => _processing = true);
                    _controller.crop();
                  },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Tiếp tục'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Crop(
                image: widget.image,
                controller: _controller,
                aspectRatio: widget.isCover ? 16 / 9 : 1,
                withCircleUi: !widget.isCover,
                interactive: true,
                fixCropRect: true,
                baseColor: AppTheme.scaffoldBg,
                maskColor: Colors.black.withValues(alpha: 0.68),
                cornerDotBuilder: (size, edgeAlignment) => const DotControl(
                  color: AppTheme.primaryRed,
                ),
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      Navigator.pop(context, croppedImage);
                    case CropFailure(:final cause):
                      setState(() => _processing = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không thể cắt ảnh: $cause')),
                      );
                  }
                },
              ),
            ),
            if (_processing)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
