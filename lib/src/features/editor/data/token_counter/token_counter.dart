/// Platform-specific token counting backend.
///
/// Desktop/mobile counts tokens in a background isolate so large contexts
/// never block the UI thread; web (no `Isolate.spawn`) counts inline in
/// small async slices. Both files expose an identical `TokenCounter` API -
/// keep them in sync when changing either.
library;

export 'token_counter_io.dart'
    if (dart.library.js_interop) 'token_counter_web.dart';
