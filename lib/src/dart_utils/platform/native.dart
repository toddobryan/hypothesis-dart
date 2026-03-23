import 'dart:io' as io show Platform;

import '../platform.dart';

class _NativeDiscoverPlatform implements DiscoverPlatform {
  @override
  Platform getCurrentPlatform() {
    if (io.Platform.isAndroid) {
      return Platform.android;
    } else if (io.Platform.isIOS) {
      return Platform.ios;
    } else if (io.Platform.isMacOS) {
      return Platform.ios;
    } else if (io.Platform.isWindows) {
      return Platform.windows;
    } else if (io.Platform.isLinux) {
      return Platform.linux;
    } else if (io.Platform.isFuchsia) {
      return Platform.fuchsia;
    } else {
      throw StateError("Unrecognized native platform");
    }
  }
}

DiscoverPlatform getDiscoverPlatform() => _NativeDiscoverPlatform();