import '../platform.dart';

class _WebDiscoverPlatform implements DiscoverPlatform {
  @override
  Platform getCurrentPlatform() {
    const bool isJsLoaded = bool.fromEnvironment("dart.library.js");
    if (isJsLoaded) {
      return Platform.js;
    } else {
      return Platform.wasm;
    }
  }
}

DiscoverPlatform getDiscoverPlatform() => _WebDiscoverPlatform();