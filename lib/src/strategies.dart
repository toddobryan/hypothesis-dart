import 'package:hypothesis_dart/src/search_strategy/misc.dart';
import 'package:hypothesis_dart/src/search_strategy/numbers.dart';
import 'package:hypothesis_dart/src/search_strategy/reprwrapper.dart';
import 'package:hypothesis_dart/src/search_strategy/strategies.dart';

import 'control.dart';
import 'errors.dart';
import 'hypothesis_random.dart';
import 'internal/conjecture/data.dart';

class DoubleKey {
  final double value;

  DoubleKey(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DoubleKey && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

// returns either DoubleKey or (Type, v)
Object convertValue(Object v) =>
    v is double ? DoubleKey(v) : (v.runtimeType, v);

SearchStrategy<T> just<T>(T value) =>
    ReprWrapperStrategy(JustStrategy(value), "just($value)");

SearchStrategy<T> oneOf<T>(List<SearchStrategy<T>> strats) {
  assert(strats.isNotEmpty);
  if (strats.length == 1) {
    return strats.first;
  } else {
    return OneOfStrategy(strats);
  }
}

SearchStrategy<int> integers([int? minValue, int? maxValue]) {
  if (minValue != null && maxValue != null) {
    assert(minValue <= maxValue);
  }
  if (minValue == null) {
    if (maxValue == null) {
      return WideRangeIntStrategy();
    } else {
      return IntegersFromStrategy(0).map((x) => maxValue - x);
    }
  } else {
    if (maxValue == null) {
      return IntegersFromStrategy(minValue);
    } else {
      if (minValue == maxValue) {
        return just(minValue);
      } else if (minValue >= 0) {
        return BoundedIntStrategy(minValue, maxValue);
      } else if (maxValue <= 0) {
        return BoundedIntStrategy(-maxValue, -minValue).map((t) => -t);
      } else {
        return integers(0, maxValue).or(integers(minValue, 0)) as SearchStrategy<int>;
      }
    }
  }
}

SearchStrategy<DataObject> data() => _DataStrategy();

class DataObject {
  int count = 0;
  final TestData data;

  DataObject(this.data);

  T draw<T>(SearchStrategy<T> strategy) {
    T result = data.draw(strategy);
    count += 1;
    note("Draw $count: $result");
    return result;
  }
}

class _DataStrategy extends SearchStrategy<DataObject> {
  @override
  bool get supportsFind => false;

  @override
  DataObject doDraw(TestData data) {
    data.sharedDataStrategy ??= DataObject(data);
    return data.sharedDataStrategy!;
  }

  @override
  SearchStrategy<U> map<U>(U Function(DataObject) pack) =>
      _notFirstClassStrategy("map");

  @override
  SearchStrategy<DataObject> filter(bool Function(DataObject) condition) =>
      _notFirstClassStrategy("filter");

  @override
  SearchStrategy<U> flatMap<U>(SearchStrategy<U> Function(DataObject) expand) =>
      _notFirstClassStrategy("flatMap");

  @override
  DataObject example({HypothesisRandom? random}) =>
      _notFirstClassStrategy("example");

  Never _notFirstClassStrategy(String name) => throw InvalidArgument(
    "Cannot call $name on a DataStrategy. You should probably be "
        "using composite for whatever it is you're trying to do.",
  );
}
