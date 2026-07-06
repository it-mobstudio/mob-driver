/// On Flutter Web, the browser's native back/forward buttons only replay
/// the URL — GoRouter's `extra` payload (arbitrary Dart objects passed to
/// `context.push(path, extra: ...)`) does not survive that, since it was
/// never part of the pushed history entry to begin with. Any route whose
/// builder reads data solely from `state.extra` renders blank when reached
/// via browser back/forward instead of an in-app `context.pop()`/`push()`.
///
/// This is an in-memory, last-value-per-path cache: route builders read
/// `state.extra` as normal and, when it's present, mirror it in here too.
/// When `state.extra` comes back empty (the browser-navigation case), they
/// fall back to whatever was last cached for that path in this session.
/// Doesn't survive a full page reload — there's nothing to fall back to
/// then, same as today.
class RouteExtraCache {
  RouteExtraCache._();

  static final Map<String, Object?> _values = {};

  static void put(String routePath, Object? extra) {
    _values[routePath] = extra;
  }

  static T? take<T>(String routePath) {
    final value = _values[routePath];
    return value is T ? value : null;
  }
}
