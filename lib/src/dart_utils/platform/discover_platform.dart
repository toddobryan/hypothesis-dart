import '../platform.dart';
import 'web.dart'
  if (dart.library.io) 'native.dart';

final DiscoverPlatform discoverPlatform = getDiscoverPlatform();