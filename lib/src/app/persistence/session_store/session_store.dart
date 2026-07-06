/// Platform-specific key/value storage for saved sessions.
///
/// Desktop stores sessions as JSON files under the application-support
/// directory (atomic writes); web stores them in browser local storage via
/// `shared_preferences`. Both files expose an identical `SessionStore` API -
/// keep them in sync when changing either.
library;

export 'session_store_io.dart'
    if (dart.library.js_interop) 'session_store_web.dart';
