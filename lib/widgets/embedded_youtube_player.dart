export 'embedded_youtube_player_stub.dart'
    if (dart.library.io) 'embedded_youtube_player_mobile.dart'
    if (dart.library.js_interop) 'embedded_youtube_player_web.dart';
