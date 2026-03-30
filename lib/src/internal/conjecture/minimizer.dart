import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:sized_ints/sized_ints.dart';

import '../../dart_utils/bytes.dart';
import '../../hypothesis_random.dart';

class Minimizer {
  Bytes current;
  int size;
  bool Function(Bytes) condition;
  HypothesisRandom? random;
  int changes = 0;
  Set<Bytes> seen;
  int considerations = 0;
  int duplicates = 0;

  Minimizer._(this.current, this.size, this.condition, this.random, this.seen);

  factory Minimizer(
    Bytes initial,
    bool Function(Bytes) condition, {
    HypothesisRandom? random,
  }) => Minimizer._(initial, initial.length, condition, random, <Bytes>{});

  bool incorporate(Bytes buffer) {
    assert(buffer.length == size);
    print(buffer);
    print(current);
    assert(buffer <= current);
    considerations += 1;
    if (seen.contains(buffer)) {
      duplicates += 1;
      return false;
    }
    seen.add(buffer);
    if (condition(buffer)) {
      current = buffer;
      changes += 1;
      return true;
    }
    return false;
  }

  bool _shrinkIndex(int i, int c) {
    assert(0 <= i && i < size);
    if (current[i] <= c) {
      return false;
    }
    if (incorporate(
      Bytes([
        ...current.slice(0, i).wrapped,
        Uint8.fromInt(c),
        ...current.slice(i + 1).wrapped,
      ]),
    )) {
      return true;
    }
    if (i == size - 1) {
      return false;
    }
    return incorporate(
      Bytes([
        ...current.slice(0, i).wrapped,
        Uint8.fromInt(c),
        Uint8.fromInt(255),
        ...current.slice(i + 2).wrapped,
      ])
    ) ||
        incorporate(
          Bytes([
            ...current.slice(0, i).wrapped,
            Uint8.fromInt(c),
            ...List<Uint8>.filled(size - i - 1, Uint8.fromInt(255)),
          ])
        );
  }

  void run() {
    if (!current.any((elt) => elt != 0)) {
      return;
    }
    if (incorporate(Bytes.ofLength(size))) {
      return;
    }
    for (int c in Iterable.generate(current.max)) {
      if (incorporate(
        Bytes.generate(current.length, (j) => math.min(current[j], c)),
      )) {
        break;
      }
    }
    int changeCounter = -1;
    while (current.isNotEmpty && changeCounter < changes) {
      changeCounter = changes;
      for (int i = 0; i < size ; i++) {
        int t = current[i];
        if (t > 0) {
          print(t);
          print(i);
          print(current[i]);
          List<int> ss = smallShrinks[current[i]];
          for (int c1 in ss) {
            if (_shrinkIndex(i, c1)) {
              for (int c2 = 0; c2 < current[i]; c2++) {
                if (ss.contains(c2)) {
                  continue;
                }
                if (_shrinkIndex(i, c2)) {
                  break;
                }
              }
              break;
            }
          }
        }
      }
    }
  }
}

List<List<int>> smallShrinks = _createSmallShrinks();

List<List<int>> _createSmallShrinks() {
  List<List<int>> ss = List.generate(
    10,
    (b) => Iterable<int>.generate(b).toList(),
  );
  for (int b = 10; b < 256; b++) {
    Set<int> result = <int>{0};
    result.add(b - 1);
    for (int i = 0; i < 8; i++) {
      result.add(b ^ (1 << i));
    }
    result.remove(b);
    assert(result.length <= 10);
    ss.add(result.sorted((int i, int j) => i - j));
  }
  return ss;
}

Bytes minimize(
  Bytes initial,
  bool Function(Bytes) condition, {
  HypothesisRandom? random,
}) {
  Minimizer m = Minimizer(initial, condition, random: random);
  m.run();
  return m.current;
}
