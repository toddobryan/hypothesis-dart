import '../internal/conjecture/data.dart';

import 'strategies.dart';

class StreamStrategy<T> extends SearchStrategy<Iterable<T>> {
  final SearchStrategy<T> sourceStrategy;

  StreamStrategy(this.sourceStrategy);

  @override
  Iterable<T> doDraw(TestData data) {
    Iterable<T> gen() sync* {
      while (true) {
        yield data.draw(sourceStrategy);
      }
    }
    return gen();
  }
}