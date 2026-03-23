import 'default_map.dart';

class Counter<T> {
    final Map<T, int> _map;

    Counter._(this._map);

    factory Counter._fromMap(DefaultMap<T, int> map) => Counter._(map);

    factory Counter(Iterable<T> elements) {
        DefaultMap<T, int> map = DefaultMap(() => 0);
        for (T elt in elements) {
            map[elt] = map[elt]! + 1;
        }
        return Counter._fromMap(map);
    }

    Iterable<MapEntry<T, int>> get entries => _map.entries;


}