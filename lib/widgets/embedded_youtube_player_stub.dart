import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'flix_network_image.dart';

class EmbeddedYoutubePlayer extends StatelessWidget {
  const EmbeddedYoutubePlayer({
    super.key,
    required this.videoId,
    required this.autoPlay,
    required this.quality,
    this.interactive = true,
  });

  final String videoId;
  final bool autoPlay;
  final String quality;
  final bool interactive;

  Future<void> _openYoutube() => launchUrl(
        Uri.parse('https://www.youtube.com/watch?v=$videoId'),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !interactive,
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: _openYoutube,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlixNetworkImage(
                'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
                fit: BoxFit.cover,
              ),
              Container(color: Colors.black38),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    color: AppTheme.primaryRed, size: 72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
