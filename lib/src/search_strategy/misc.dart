import '../internal/conjecture/utils.dart';

import '../internal/conjecture/data.dart';
import 'strategies.dart';

class BoolStrategy extends SearchStrategy<bool> {
  @override
  bool doDraw(TestData data) => boolean(data);
}

class JustStrategy<T> extends SearchStrategy<T> {
  final T value;

  JustStrategy(this.value);

  @override
  T doDraw(TestData data) => value;
}

// not sure what RandomStrategy does

class SampledFromStrategy<T> extends SearchStrategy<T> {
  final List<T> elements;

  SampledFromStrategy(this.elements);

  @override
  T doDraw(TestData data) => choice(data, elements);
}