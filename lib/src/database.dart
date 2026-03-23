import 'dart:io';

import 'dart_utils/default_map.dart';
import 'package:path/path.dart' as p;

import 'dart_utils/bytes.dart';

abstract class ExampleDatabase {
  void save(Bytes key, Bytes value);
  void delete(Bytes key, Bytes value);
  Iterable<Bytes> fetch(Bytes key);
  void close();
}

class InMemoryExampleDatabase extends ExampleDatabase {
  DefaultMap<Bytes, Set<Bytes>> map;

  InMemoryExampleDatabase._(this.map);

  factory InMemoryExampleDatabase() =>
      InMemoryExampleDatabase._(DefaultMap(() => <Bytes>{}));

  @override
  Iterable<Bytes> fetch(Bytes key) {
    return map.get(key);
  }

  @override
  void save(Bytes key, Bytes value) {
    Set<Bytes> curr = map.get(key);
    curr.add(value);
    map[key] = curr;
  }

  @override
  void delete(Bytes key, Bytes value) {
    Set<Bytes> curr = map.get(key);
    curr.remove(value);
    map[key] = curr;
  }

  @override
  void close() {
    // do nothing
  }
}

// mkdirp in Python
// TODO: make this async?
Directory createDirectoriesRecursively(String path) {
  Directory directory = Directory(path);
  directory.createSync(recursive: true);
  return directory;
}

// _hash(key) is done by key.digest)

class DirectoryBasedExampleDatabase extends ExampleDatabase {
  String path;
  Map<Bytes, Directory> keypaths;

  DirectoryBasedExampleDatabase._(this.path, this.keypaths);

  factory DirectoryBasedExampleDatabase(String path) {
    return DirectoryBasedExampleDatabase._(path, {});
  }

  @override
  void close() {
    // do nothing
  }

  Directory _keyPath(Bytes key) {
    if (keypaths.containsKey(key)) {
      return keypaths[key]!;
    }
    Directory directory = createDirectoriesRecursively(p.join(path, key.digest.substring(0, 16)));
    keypaths[key] = directory;
    return directory;
  }

  File _valuePath(Bytes key, Bytes value) {
    return File(p.join(_keyPath(key).path, value.digest.substring(0, 16)));
  }

  @override
  Iterable<Bytes> fetch(Bytes key) sync* {
    Directory kp = _keyPath(key);
    for (File path in kp.listSync().whereType<File>()) {
      yield Bytes(path.readAsBytesSync());
    }
  }

  @override
  void save(Bytes key, Bytes value) {
    File path = _valuePath(key, value);
    if (!path.existsSync()) {
      value.writeTo(path);
    }
  }

  @override
  void delete(Bytes key, Bytes value) => _valuePath(key, value).deleteSync();
}