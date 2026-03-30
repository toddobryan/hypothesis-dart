import '../internal/conjecture/data.dart';
import '../settings.dart';

import 'strategies.dart';

class FlatMapStrategy<From, To> extends SearchStrategy<To> {
  final SearchStrategy<From> flatMappedStrategy;
  final SearchStrategy<To> Function(From) expand;
  final Settings settings;

  FlatMapStrategy._(this.flatMappedStrategy, this.expand, this.settings);

  factory FlatMapStrategy(
    SearchStrategy<From> strategy,
    SearchStrategy<To> Function(From) expand,
  ) {
    return FlatMapStrategy._(strategy, expand, Settings.defaultValue);
  }

  @override
  To doDraw(TestData data) {
    From source = data.draw(flatMappedStrategy);
    return data.draw(expand(source));
  }

  @override
  void validate() {
    flatMappedStrategy.validate();
  }
}
