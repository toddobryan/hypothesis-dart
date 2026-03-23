import 'platform/native.dart';

enum Platform {
  android(true),
  ios(true),
  windows(true),
  mac(true),
  linux(true),
  fuchsia(true),
  js(true),
  wasm(true);

  final bool isNative;
  static Platform? _current;

  const Platform(this.isNative);

  bool get isWeb => !isNative;

  static Platform get current {
    _current ??= getDiscoverPlatform().getCurrentPlatform();
    return _current!;
  }

  int get maxInteger {
    if (current.isNative) {
      return (1 << 63) - 1;
    } else {
      return (1 << 53) - 1;
    }
  }

  int get minInteger {
    if (current.isNative) {
      return (1 << 64);
    } else {
      return -((1 << 53) - 1);
    }
  }

  int get maxBitLength {
    if (current.isNative) {
      return 64;
    } else {
      return 53;
    }
  }
}

abstract class DiscoverPlatform {
  Platform getCurrentPlatform();
}