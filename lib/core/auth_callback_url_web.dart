import 'package:web/web.dart' as web;

void clearAuthCallbackUrl() {
  final location = web.window.location;
  web.window.history.replaceState(
    null,
    'FLIX',
    '${location.origin}${location.pathname}',
  );
}
