import '../internal/conjecture/data.dart';
import 'strategies.dart';

class WrapperStrategy<T> extends SearchStrategy<T> {
  final SearchStrategy<T> wrappedStrategy;

  WrapperStrategy(this.wrappedStrategy);

  @override
  bool get supportsFind => wrappedStrategy.supportsFind;

  @override
  void validate() => wrappedStrategy.validate();

  @override
  T doDraw(TestData data) => wrappedStrategy.doDraw(data);
}