import '../../dart_utils/bytes.dart';
import '../../dart_utils/comparable_operators.dart';
import '../../dart_utils/default_map.dart';
import '../../errors.dart';
import '../../hypothesis_random.dart';
import '../../search_strategy/strategies.dart';
import '../../strategies.dart';
import '../interval_sets.dart';

typedef Distribution = Bytes Function(HypothesisRandom, int);
typedef ByteDrawer = Bytes Function(TestData, int, Distribution);

Bytes uniform(HypothesisRandom random, int n) =>
    intToBytes(random.getRandBits(n * 8), n);

enum Status with ComparableOperators<Status> {
  overrun(0),
  invalid(1),
  valid(2),
  interesting(3);

  final int value;
  const Status(this.value);

  @override
  int compareTo(Status other) => value - other.value;
}

class StopTest implements Exception {
  final int testCounter;

  StopTest(this.testCounter);
}

int globalTestCounter = 0;

class TestData {
  int maxLength;
  ByteDrawer? _drawBytes;

  bool isFind = false;
  int overdraw = 0;
  int level = 0;
  Map<int, List<int>> blockStarts = DefaultMap<int, List<int>>(() => []);
  List<Interval> blocks = [];
  Bytes buffer = Bytes.ofLength(0);
  String output = "";
  Status status = .valid;
  bool frozen = false;
  List<List<Interval>> intervalsByLevel = [];
  List<Interval> intervals = [];
  List<int> intervalStack = [];
  int testCounter = globalTestCounter;
  Map<Object, Object?> sharedStrategies = {};
  DataObject? sharedDataStrategy;

  TestData._(this.maxLength, this._drawBytes);

  factory TestData(int maxLength, ByteDrawer drawBytes) {
    TestData result = TestData._(maxLength, drawBytes);
    globalTestCounter += 1;
    return result;
  }

  factory TestData.forBuffer(Bytes buffer) => TestData._(
    buffer.length,
    (TestData d, int n, Distribution _) => buffer.slice(d.index, d.index + n),
  );

  void _assertNotFrozen(String name) {
    if (frozen) {
      throw Frozen("Cannot call $name on frozen TestData");
    }
  }

  int get index => buffer.length;

  void note(Object? value) {
    _assertNotFrozen("note");
    output += "$value";
  }

  T draw<T>(SearchStrategy<T> strategy) {
    if (isFind && !strategy.supportsFind) {
      throw ArgumentError(
        "Cannot use strategy $strategy within a call to find "
        "(presumably be8cause it would be invalid after the call had ended)",
      );
    }
    startExample();
    try {
      return strategy.doDraw(this);
    } finally {
      if (!frozen) {
        stopExample();
      }
    }
  }

  void startExample() {
    _assertNotFrozen("startExample");
    intervalStack.add(index);
    level += 1;
  }

  void stopExample() {
    _assertNotFrozen("stopExample");
    level -= 1;
    while (level >= intervalsByLevel.length) {
      intervalsByLevel.add([]);
    }
    int k = intervalStack.last;
    if (k != index) {
      Interval t = Interval(k, index);
      intervalsByLevel[level].add(t);
      if (intervals.isEmpty || intervals.last != t) {
        intervals.add(t);
      }
    }
  }

  void freeze() {
    if (frozen) {
      return;
    }
    frozen = true;
    // Intervals are sorted as longest first, then by interval start.
    for (List<Interval> l in intervalsByLevel) {
      for (int i = 0; i < l.length - 1; i++) {
        if (l[i].end == l[i + 1].start) {
          intervals.add(Interval(l[i].start, l[i + 1].end));
        }
      }
    }
    intervals.sort(
      (Interval i1, Interval i2) => compareByLengthAndStart(i1, i2),
    );
    _drawBytes = null;
  }

  Bytes drawBytes(int n, {Distribution distribution = uniform}) {
    if (n == 0) {
      return Bytes.ofLength(0);
    }
    _assertNotFrozen("drawBytes");
    int initial = index;
    if (index + n > maxLength) {
      overdraw = index + n - maxLength;
      status = .overrun;
      freeze();
      throw StopTest(testCounter);
    }
    Bytes result = _drawBytes!(this, n, distribution);
    blockStarts[n]!.add(initial);
    blocks.add(Interval(initial, initial + n));
    assert(result.length == n);
    assert(index == initial);
    buffer.addAll(result);
    intervals.add(Interval(initial, index));
    return result;
  }

  Never markInteresting() {
    _assertNotFrozen("markInteresting");
    status = .interesting;
    freeze();
    throw StopTest(testCounter);
  }

  Never markInvalid() {
    _assertNotFrozen("markInvalid");
    status = .invalid;
    freeze();
    throw StopTest(testCounter);
  }
}

int compareByLengthAndStart(Interval x, Interval y) {
  int negLengthX = x.start - x.end;
  int negLengthY = y.start - y.end;
  int cmpLength = negLengthX - negLengthY;
  if (cmpLength != 0) {
    return cmpLength;
  } else {
    return x.start - y.start;
  }
}
