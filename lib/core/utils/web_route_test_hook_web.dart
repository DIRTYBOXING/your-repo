import 'package:web/web.dart' as web;

void setWebRouteTestHook(String routeKey) {
  final body = web.document.body;
  body?.setAttribute('data-test-route', routeKey);
  body?.setAttribute('data-test', routeKey);
}
