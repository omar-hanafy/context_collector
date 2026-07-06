/// Platform-specific window integration.
///
/// Desktop uses `window_manager` (which cannot even be imported on web
/// because it depends on `dart:io`); web maps window focus/blur to the
/// browser window events and treats window configuration as a no-op. Both
/// files expose an identical API - keep them in sync when changing either.
library;

export 'app_window_io.dart' if (dart.library.js_interop) 'app_window_web.dart';
