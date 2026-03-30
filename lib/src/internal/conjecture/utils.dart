import 'dart:math';

import 'package:sized_ints/sized_ints.dart';

import '../../hypothesis_random.dart';
import '../../dart_utils/bytes.dart';
import 'data.dart';

int nByteUnsigned(TestData data, int n) => intFromBytes(data.drawBytes(n));

int saturate(int n) {
  int bits = n.bitLength;
  int k = 1;
  while (k < bits) {
    n |= (n >> k);
    k *= 2;
  }
  return n;
}

int integerRange(
  TestData data,
  int lower,
  int upper, {
  int? center,
  int Function(HypothesisRandom)? distribution,
}) {
  assert(lower <= upper);
  if (lower == upper) {
    return lower;
  }
  center ??= lower;
  center = min(max(center, lower), upper);
  if (distribution == null) {
    if (lower < center && center < upper) {
      distribution = (HypothesisRandom random) {
        if (random.randInt(0, 1) != 0) {
          return random.randInt(center!, upper);
        } else {
          return random.randInt(lower, center!);
        }
      };
    } else {
      distribution = (HypothesisRandom random) => random.randInt(lower, upper);
    }
  }

  int gap = upper - lower;
  int bits = gap.bitLength;
  int nBytes = bits ~/ 8 + (bits % 8 == 0 ? 0 : 1);
  int mask = saturate(gap);

  Bytes byteDistribution(HypothesisRandom random, int n) {
    assert(n == nBytes);
    int v = distribution!(random);
    int probe = v >= center! ? v - center : upper - v;
    return intToBytes(probe, n);
  }

  int probe =
      intFromBytes(data.drawBytes(nBytes, distribution: byteDistribution)) &
      mask;
  int result;
  if (probe <= gap) {
    if (center == upper) {
      result = upper - probe;
    } else if (center == lower) {
      result = lower + probe;
    } else {
      if (center + probe <= upper) {
        result = center + probe;
      } else {
        result = upper - probe;
      }
    }
    assert(lower <= result && result <= upper);
    return result;
  } else {
    return data.markInvalid();
  }
}

int integerRangeWithDistribution(
  TestData data,
  int lower,
  int upper,
  int Function(HypothesisRandom) nums,
) => integerRange(data, lower, upper, distribution: nums);

int centeredIntegerRange(TestData data, int lower, int upper, int center) =>
    integerRange(data, lower, upper, center: center);

T choice<T>(TestData data, List<T> values) =>
    values[integerRange(data, 0, values.length - 1)];

int geometric(TestData data, double p) {
  double denom = log1p(-p);
  int nBytes = 8;

  Bytes distribution(HypothesisRandom random, int n) {
    assert(n == nBytes);
    for (int x = 0; x < 100; x++) {
      try {
        return intToBytes((log1p(-random.random()) / denom).toInt(), n);
      } on Exception {
        // do nothing
      }
    }
    throw AssertionError(
      "We got a one in a million chance 100 times in a row. "
      "Something is up.",
    );
  }

  int ifb = intFromBytes(data.drawBytes(nBytes, distribution: distribution));
  print("ifb: ${ifb.toRadixString(16)}");
  return ifb;
}

bool boolean(TestData data) {
  return nByteUnsigned(data, 1) & 1 == 1;
}

bool biasedCoin(TestData data, double p) {
  Bytes distribution(HypothesisRandom random, int n) {
    assert(n == 1);
    return Bytes(List<Uint8>.from([random.random() <= p ? Uint8.one : Uint8.zero]));
  }
  return data.drawBytes(1, distribution: distribution)[0] & 1 == 1;
}

double log1p(double x) {
  if (x.abs() < 1e-9) {
    return x - x * x / 2;
  } else {
    return log(1 + x);
  }
}
