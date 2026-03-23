import '../internal/conjecture/data.dart';
import 'strategies.dart';

class SharedStrategy<T> extends SearchStrategy<T> {
  final Object? key;
  final SearchStrategy<T> base;

  SharedStrategy(this.base, {this.key});

  @override
  bool get supportsFind => base.supportsFind;

  @override
  T doDraw(TestData data) {
    Object safeKey = key ?? this;
    if (!data.sharedStrategies.containsKey(safeKey)) {
      data.sharedStrategies[safeKey] = base.doDraw(data);
    }
    return data.sharedStrategies[safeKey] as T;
  }
}