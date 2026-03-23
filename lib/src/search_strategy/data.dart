import '../control.dart';
import '../errors.dart';
import '../hypothesis_random.dart';
import '../internal/conjecture/data.dart';
import 'strategies.dart';

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

class DataStrategy extends SearchStrategy<DataObject> {
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
