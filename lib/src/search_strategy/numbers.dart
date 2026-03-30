import 'dart:math';

import 'package:better_random/better_random.dart';

import '../hypothesis_random.dart';
import '../internal/conjecture/utils.dart';

import '../control.dart';
import '../dart_utils/bytes.dart';
import '../internal/conjecture/data.dart';
import '../internal/doubles.dart';
import 'strategies.dart';

class IntegersFromStrategy extends SearchStrategy<int> {
  final int lowerBound;
  final double averageSize;

  IntegersFromStrategy(this.lowerBound, [this.averageSize = 100_000.0]);

  @override
  int doDraw(TestData data) => lowerBound + geometric(data, 1.0 / averageSize);
}

class WideRangeIntStrategy extends SearchStrategy<int> {
  @override
  int doDraw(TestData data) {
    int size = 16;
    int signMask = 1 << (size * 8 - 1);

    Bytes distribution(HypothesisRandom random, int n) {
      assert(n == size);
      int k = min(random.randInt(0, n * 8 - 1), random.randInt(0, n * 8 - 1));
      int r;
      if (k > 0) {
        r = random.getRandBits(k);
      } else {
        r = 0;
      }
      if (random.randInt(0, 1) == 1) {
        r = r | signMask;
      } else {
        r = r & ~signMask;
      }
      return intToBytes(r, n);
    }

    Bytes byt = data.drawBytes(size, distribution: distribution);
    int r = intFromBytes(byt);
    int negative = r & signMask;
    r = r & ~signMask;
    if (negative != 0) {
      r = -r;
    }
    return r;
  }
}

class BoundedIntStrategy extends SearchStrategy<int> {
  final int start;
  final int end;

  BoundedIntStrategy(this.start, this.end);

  @override
  int doDraw(TestData data) => integerRange(data, start, end);
}

final List<double> nastyDoubles = [
  0.0,
  0.5,
  1.0 / 3,
  10e6,
  10e-6,
  1.175494351e-38,
  2.2250738585072014e-308,
  1.7976931348623157e+308,
  3.402823466e+38,
  9007199254740992,
  1 - 10e-6,
  2 + 10e-6,
  1.192092896e-07,
  2.2204460492503131e-016,
  double.infinity,
  double.nan,
  -0.0,
  -0.5,
  -1.0 / 3,
  -10e6,
  -10e-6,
  -1.175494351e-38,
  -2.2250738585072014e-308,
  -1.7976931348623157e+308,
  -3.402823466e+38,
  -9007199254740992,
  -(1 - 10e-6),
  -(2 + 10e-6),
  -1.192092896e-07,
  -2.2204460492503131e-016,
  double.negativeInfinity,
];

class DoubleStrategy extends SearchStrategy<double> {
  final bool allowInfinity;
  final bool allowNan;

  DoubleStrategy(this.allowInfinity, this.allowNan);

  bool isPermitted(double f) {
    if (!allowInfinity && f.isInfinite) {
      return false;
    }
    if (!allowNan && f.isNaN) {
      return false;
    }
    return true;
  }

  @override
  double doDraw(TestData data) {
    Bytes drawDoubleBytes(HypothesisRandom random, int n) {
      assert(n == 8);
      double randomDouble;
      while (true) {
        int i = random.randInt(1, 10);
        if (i <= 4) {
          randomDouble = random.choice(nastyDoubles);
        } else if (i == 5) {
          return Bytes.generate(8, (int _) => random.randInt(0, 255));
        } else if (i == 6) {
          randomDouble = random.random() * (random.randInt(0, 1) * 2 - 1);
        } else if (i == 7) {
          randomDouble = random.gauss(mu: 0.0, sigma: 1.0);
        } else if (i == 8) {
          randomDouble =
              random.randInt(
                EnvForSafeInt.current.minInteger,
                EnvForSafeInt.current.maxInteger,
              ) *
              1.0;
        } else {
          randomDouble = random.gauss(
            mu:
                1.0 *
                random.randInt(
                  EnvForSafeInt.current.minInteger,
                  EnvForSafeInt.current.maxInteger,
                ),
            sigma: 1.0,
          );
        }
        if (isPermitted(randomDouble)) {
          return Bytes.packDouble64(randomDouble);
        }
      }
    }

    double result = data
        .drawBytes(8, distribution: drawDoubleBytes)
        .unpackDouble64();
    assume(isPermitted(result));
    return result;
  }
}

Comparator<double> doubleComparator = (double a, double b) {
  double sa = sign(a);
  double sb = sign(b);
  if (sa != sb) {
    return (sa - sb).toInt();
  } else if (a < b) {
    return -1;
  } else if (b < a) {
    return 1;
  } else {
    return 0;
  }
};

class FixedBoundedDoubleStrategy extends SearchStrategy<double> {
  final double lowerBound;
  final double upperBound;
  final List<double> criticalValues;

  FixedBoundedDoubleStrategy._(
    this.lowerBound,
    this.upperBound,
    this.criticalValues,
  );

  factory FixedBoundedDoubleStrategy(double lowerBound, double upperBound) {
    List<double> criticalValues = [-0.0, 0.0]
        .where(
          (d) =>
              doubleComparator(lowerBound, d) <= 0 &&
              doubleComparator(d, upperBound) <= 0,
        )
        .toList();
    criticalValues.addAll([lowerBound, upperBound]);
    return FixedBoundedDoubleStrategy._(lowerBound, upperBound, criticalValues);
  }

  @override
  double doDraw(TestData data) {
    Bytes drawDoubleBytes(HypothesisRandom random, int n) {
      assert(n == 8);
      int i = random.randInt(0, 20);
      double randomDouble;
      if (i <= 2) {
        randomDouble = random.choice(criticalValues);
      } else {
        randomDouble = random.random() * (upperBound - lowerBound) + lowerBound;
      }
      return Bytes.packDouble64(randomDouble);
    }

    double d = data
        .drawBytes(8, distribution: drawDoubleBytes)
        .unpackDouble64();
    assume(
      doubleComparator(lowerBound, d) <= 0 &&
          doubleComparator(d, upperBound) <= 0,
    );
    assume(sign(lowerBound) <= sign(d) && sign(d) <= sign(upperBound));
    return d;
  }
}
