import 'dart:math' as math;

import 'package:collection/collection.dart';

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

  factory Minimizer(Bytes initial, bool Function(Bytes) condition,
  {HypothesisRandom? random}) =>
      Minimizer._(initial, initial.length, condition, random, <Bytes>{});

  bool incorporate(Bytes buffer) {
    assert(buffer.length == size);
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
        Bytes.generate(current.length, (int j) => j == i ? c : current[j]))) {
      return true;
    }
    if (i == size - 1) {
      return false;
    }
    return incorporate(
        Bytes.generate(current.length, (int j) {
          if (j == i) {
            return c;
          } else if (j == i + 1) {
            return 255;
          } else {
            return current[i];
          }
        })
    ) || incorporate(
        Bytes.generate(current.length, (int j) {
          if (j == i) {
            return c;
          } else if (j < i) {
            return current[i];
          } else {
            return 255;
          }
        })
    );
  }

  void run() {
    if (current.isEmpty || !current.any((i) => i != 0)) {
      return;
    }
    if (incorporate(Bytes.ofLength(size))) {
      return;
    }
    for (int c in Iterable.generate(current.max)) {
      if (incorporate(
          Bytes.generate(current.length, (j) => math.min(current[j], c)))) {
        break;
      }
    }
    int changeCounter = -1;
    while (current.isNotEmpty && changeCounter < changes) {
      changeCounter = changes;
      for (int i in Iterable.generate(size)) {
        int t = current[i];
        if (t > 0) {
          List<int> ss = smallShrinks[current[i]];
          for (int c1 in ss) {
            if (_shrinkIndex(i, c1)) {
              for (int c2 in Iterable.generate(current[i])) {
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
      10, (b) => Iterable<int>.generate(b).toList());
  for (int b in Iterable.generate(255 - 10, (i) => i + 10)) {
    Set<int> result = <int>{0};
    result.add(b - 1);
    for (int i in Iterable.generate(8)) {
      result.add(b ^ (1 << i));
    }
    result.remove(b);
    assert(result.length <= 10);
    ss.add(result.sorted((int i, int j) => i - j));
  }
  return ss;
}

Bytes minimize(Bytes initial, bool Function(Bytes) condition, {HypothesisRandom? random}) {
  Minimizer m = Minimizer(initial, condition, random: random);
  m.run();
  return m.current;
}
  