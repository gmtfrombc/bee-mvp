import 'package:flutter/widgets.dart';

/// RouteInformationProvider that ignores non-web (http/https) custom-scheme
/// links so that GoRouter doesn’t throw `Bad state: Origin is only applicable
/// to schemes http and https`. This is a lightweight guard around the default
/// [PlatformRouteInformationProvider].
///
/// TODO(ai-router): Revisit once go_router supports custom-scheme parsing or
/// when deep-link handling is migrated to a dedicated handler. For now this
/// is adequate to suppress the exception without side-effects.
class FilteringRouteInformationProvider extends RouteInformationProvider {
  FilteringRouteInformationProvider(this._inner) {
    _value = _inner.value;
    _inner.addListener(_handleInner);
  }

  final RouteInformationProvider _inner;
  late RouteInformation _value;

  final List<VoidCallback> _listeners = [];

  void _notify() {
    for (final l in List<VoidCallback>.from(_listeners)) {
      l();
    }
  }

  void _handleInner() {
    final info = _inner.value;
    debugPrint('FILTERING_PROVIDER: got inner change to ${info.uri}');
    if (_shouldForward(info)) {
      debugPrint('FILTERING_PROVIDER: forwarding ${info.uri}');
      _value = info;
      _notify();
    } else {
      debugPrint(
        'FILTERING_PROVIDER: blocking ${info.uri} (scheme=${info.uri.scheme})',
      );
    }
  }

  bool _shouldForward(RouteInformation? info) {
    final uri = info?.uri ?? Uri();
    // Allow empty scheme (in-app routes) or web URLs handled by go_router.
    final shouldForward =
        uri.scheme.isEmpty || uri.scheme == 'http' || uri.scheme == 'https';
    debugPrint(
      'FILTERING_PROVIDER: _shouldForward($uri) = $shouldForward (scheme="${uri.scheme}")',
    );
    return shouldForward;
  }

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    // Forward programmatic route updates back to the wrapped provider so the
    // platform (e.g., Web) receives them.
    _inner.routerReportsNewRouteInformation(routeInformation, type: type);
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _inner.removeListener(_handleInner);
    _listeners.clear();
  }
}
