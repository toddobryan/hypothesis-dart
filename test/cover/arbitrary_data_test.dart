import 'package:checks/checks.dart';
import 'package:hypothesis_dart/src/givens.dart';
import 'package:hypothesis_dart/src/search_strategy/collections.dart';
import 'package:hypothesis_dart/src/search_strategy/misc.dart';
import 'package:hypothesis_dart/src/search_strategy/numbers.dart';
import 'package:hypothesis_dart/src/strategies.dart';

void main() {
  Given2(integers(), data()).test2("conditional draw", (
    int x,
    DataObject data,
  ) {
    print("x=${x.toRadixString(16)}");
    int y = data.draw(integers(x));
    print("y=${y.toRadixString(16)}");
    check(y).isGreaterOrEqual(x);
    print("didn't have error");
  });

  Given1(data()).test("prints on failure", (DataObject data) {
    print("line 21");
    List<int> x = data.draw(ListStrategy(integers(), minSize: 1));
    print(x);
    int y = data.draw(SampledFromStrategy(x));
    print(y);
    check(x).contains(y);
    x.remove(y);
    print(x);
    check(x.contains(y)).isFalse();
  });
}
