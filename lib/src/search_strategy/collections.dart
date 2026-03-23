import '../internal/conjecture/data.dart';
import '../internal/conjecture/utils.dart';
import 'strategies.dart';

// ignore TupleStrategy, since Given1, Given2, etc. can handle it


class ListStrategy<T> extends SearchStrategy<List<T>> {
  final SearchStrategy<T> elementStrategy;
  final int averageLength;
  final int minSize;
  final int? maxSize;

  ListStrategy._(this.elementStrategy, this.averageLength, this.minSize,
      this.maxSize);

  factory ListStrategy(SearchStrategy<T> elementStrategy,
      {int averageLength = 50, int minSize = 0, int? maxSize}) {
    assert(averageLength > 0);
    return ListStrategy._(elementStrategy, averageLength, minSize, maxSize);
  }

  @override
  void validate() => elementStrategy.validate();

  @override
  List<T> doDraw(TestData data) {
    if (maxSize == minSize) {
      return List.generate(minSize, (_) => data.draw(elementStrategy));
    }
    double stoppingValue = 1 - 1.0 / (1 + averageLength);
    List<T> result = [];
    while (true) {
      data.startExample();
      bool getMore = biasedCoin(data, stoppingValue);
      T value = data.draw(elementStrategy);
      data.stopExample();
      if (!getMore) {
        if (result.length < minSize) {
          continue;
        } else {
          break;
        }
      }
      result.add(value);
    }
    if (maxSize != null) {
      result = result.sublist(0, maxSize);
    }
    return result;
  }
}