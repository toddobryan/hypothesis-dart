import 'dart:math';

import 'package:better_random/better_random.dart';
import 'package:hypothesis_dart/src/internal/conjecture/engine.dart';
import 'package:sized_ints/sized_ints.dart';

import 'dart_utils/bytes.dart';

abstract class HypothesisRandom<State> {
  int seed;
  double? gaussNext;

  HypothesisRandom(this.seed);

  double random();

  /// returns an int with size random bits. If size is greater than the
  /// number of bits supported by the platform, will throw an ArgumentError
  int getRandBits(int size);

  /// returns a random int from [lower, upper]
  int randInt(int lower, int upper);

  double gauss({double mu = 0.0, double sigma = 1.0}) {
    double? z = gaussNext;
    gaussNext = null;
    if (z == null) {
      double x2pi = random() * 2 * pi;
      double g2rad = sqrt(-2.0 * log(1.0 - random()));
      z = cos(x2pi) * g2rad;
      gaussNext = sin(x2pi) * g2rad;
    }
    return mu + z * sigma;
  }

  T choice<T>(List<T> seq) {
    if (seq.isEmpty) {
      throw ArgumentError("Cannot choose from an empty list");
    }
    return seq[randInt(0, seq.length - 1)];
  }

  State get state;
}

class BetterHypRandom extends HypothesisRandom<BetterRandomState> {
  BetterRandom rand;

  BetterHypRandom._(this.rand) : super(rand.seed);

  factory BetterHypRandom(int? seed) =>
      BetterHypRandom._(BetterRandom(seed ?? currentMillis() % 0xFFFF_FFFF));

  @override
  int getRandBits(int size) => rand.nextBits(size);

  /// returns a random int from [lower, upper]
  @override
  int randInt(int lower, int upper) {
    int? newUpper = (upper == EnvForSafeInt.current.maxInteger)
        ? null
        : upper + 1;
    return rand.nextIntInBounds(lower, newUpper);
  }

  @override
  double random() => rand.nextDouble();

  @override
  BetterRandomState get state => rand.state;

  void setState(BetterRandomState state) {
    rand.setState(state);
  }
}

// in compat.py
int intFromBytes(Bytes data) {
  int result = 0;
  int i = 0;
  while (i + 4 <= data.length) {
    result = result << 32;
    result = result | data.slice(i, i + 4).unpackInt32();
    i += 4;
  }
  while (i < data.length) {
    result = result << 8;
    result = result | data[i];
    i += 1;
  }
  return result;
}

Bytes intToBytes(int i, int size) {
  assert(i >= 0, "Given non-negative integer $i");
  List<Uint8> result = List.filled(size, Uint8.zero);
  int j = size - 1;
  while (i > 0 && j >= 0) {
    result[j] = Uint8.fromInt(i & 255);
    i >>= 8;
    j -= 1;
  }
  if (i > 0) {
    throw RangeError("int $i to big to convert in $size bytes");
  }
  return Bytes(result);
}
