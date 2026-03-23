import '../internal/conjecture/data.dart';
import 'strategies.dart';

class PairStrategy<T1, T2> extends SearchStrategy<(T1, T2)> {
  final SearchStrategy<T1> strategy1;
  final SearchStrategy<T2> strategy2;

  PairStrategy(this.strategy1, this.strategy2);

  @override
  void validate() {
    strategy1.validate();
    strategy2.validate();
  }

  @override
  (T1, T2) doDraw(TestData data) =>
      (strategy1.doDraw(data), strategy2.doDraw(data));

  @override
  bool get supportsFind => strategy1.supportsFind && strategy2.supportsFind;
}