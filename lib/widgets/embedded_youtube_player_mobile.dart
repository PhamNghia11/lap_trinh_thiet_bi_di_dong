import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class EmbeddedYoutubePlayer extends StatefulWidget {
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

  @override
  State<EmbeddedYoutubePlayer> createState() => _EmbeddedYoutubePlayerState();
}

class _EmbeddedYoutubePlayerState extends State<EmbeddedYoutubePlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    try {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: widget.autoPlay,
        params: YoutubePlayerParams(
          mute: widget.autoPlay,
          showControls: true,
          showFullscreenButton: true,
          playsInline: true,
        ),
      );
    } catch (_) {
      // Widget tests and unsupported desktop platforms do not register WebView.
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child:
              Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 72),
        ),
      );
    }
    return AbsorbPointer(
      absorbing: !widget.interactive,
      child: YoutubePlayer(
        controller: controller,
        gestureRecognizers: const {
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
        enableFullScreenOnVerticalDrag: true,
      ),
    );
  }
}
