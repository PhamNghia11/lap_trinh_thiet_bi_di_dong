import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class EmbeddedYoutubePlayer extends StatefulWidget {
  const EmbeddedYoutubePlayer({
    super.key,
    required this.videoId,
    required this.autoPlay,
  });

  final String videoId;
  final bool autoPlay;

  @override
  State<EmbeddedYoutubePlayer> createState() => _EmbeddedYoutubePlayerState();
}

class _EmbeddedYoutubePlayerState extends State<EmbeddedYoutubePlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'flix-youtube-${widget.videoId}-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final autoPlay = widget.autoPlay ? 1 : 0;
      final mute = widget.autoPlay ? 1 : 0;
      final iframe = web.HTMLIFrameElement()
        ..src = 'https://www.youtube-nocookie.com/embed/${widget.videoId}'
            '?autoplay=$autoPlay&mute=$mute&controls=1&playsinline=1&rel=0'
        ..title = 'Trailer YouTube'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share';
      iframe
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      iframe.setAttribute('allowfullscreen', 'true');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
