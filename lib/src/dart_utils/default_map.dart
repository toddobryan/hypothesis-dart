import 'dart:collection';

class DefaultMap<K, V> extends MapBase<K, V> {
  final V Function() missingCreator;
  final Map<K, V> _map = {};

  DefaultMap(this.missingCreator);

  V get(Object? key) => this[key]!;

  @override
  V? operator [](Object? key) {
    _map.putIfAbsent(key as K, missingCreator);
    return _map[key]!;
  }

  @override
  void operator []=(K key, V value) => _map[key] = value;

  @override
  Iterable<K> get keys => _map.keys;

  @override
  V? remove(Object? key) => _map.remove(key);

  @override
  void clear() => _map.clear();
}