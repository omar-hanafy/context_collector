/// Platform-specific filesystem primitives for the scan feature.
///
/// The desktop/mobile implementation is backed by `dart:io`; the web
/// implementation keeps dropped/picked file handles in an in-memory registry
/// and reads their bytes through the browser. Both files expose an identical
/// `PlatformFs` static API - keep them in sync when changing either.
library;

export 'platform_fs_io.dart'
    if (dart.library.js_interop) 'platform_fs_web.dart';
