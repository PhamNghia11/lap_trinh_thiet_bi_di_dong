import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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
  late final String _viewType;
  web.HTMLIFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewType = 'flix-youtube-${widget.videoId}-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final autoPlay = widget.autoPlay ? 1 : 0;
      final mute = widget.autoPlay ? 1 : 0;
      final origin = Uri.encodeComponent(
        web.window.location.origin.isNotEmpty
            ? web.window.location.origin
            : 'http://localhost',
      );
      final iframe = web.HTMLIFrameElement()
        ..src = 'https://www.youtube.com/embed/${widget.videoId}'
            '?autoplay=$autoPlay&mute=$mute&controls=1&playsinline=1&rel=0'
            '&fs=1&enablejsapi=1&origin=$origin'
        ..title = 'Trailer YouTube'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share';
      iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
      iframe
        ..style.border = '0'
        ..style.display = 'block'
        ..style.pointerEvents = widget.interactive ? 'auto' : 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      iframe.setAttribute('allowfullscreen', 'true');
      _iframe = iframe;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant EmbeddedYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interactive != widget.interactive) {
      _iframe?.style.pointerEvents = widget.interactive ? 'auto' : 'none';
    }
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
