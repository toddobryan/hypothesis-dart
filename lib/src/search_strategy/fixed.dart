import '../control.dart';
import '../hypothesis_random.dart';

import '../dart_utils/bytes.dart';
import '../internal/conjecture/data.dart';
import 'strategies.dart';

abstract class FixedStrategy<T> extends SearchStrategy<T> {
  final int blockSize;

  FixedStrategy(this.blockSize);

  @override
  T doDraw(TestData data) {
    Bytes block = data.drawBytes(blockSize, distribution: distribution);
    assert(block.length == blockSize);
    T value = fromBytes(block);
    assume(isAcceptable(value));
    return value;
  }

  Bytes distribution(HypothesisRandom random, int n) {
    assert(n == blockSize);
    for (int i = 0; i < 100; i++) {
      T value = drawValue(random);
      if (isAcceptable(value)) {
        Bytes block = toBytes(value);
        assert(block.length == blockSize);
        return block;
      }
    }
    throw AssertionError("After 100 tries, was unable to draw a valid value. "
        "This is a bug in the implementation of $runtimeType."
    );
  }

  T drawValue(HypothesisRandom random);

  Bytes toBytes(T value);

  T fromBytes(Bytes block);

  bool isAcceptable(T value) => true;
}