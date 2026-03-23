import 'package:checks/checks.dart';
import 'package:hypothesis_dart/src/givens.dart';
import 'package:hypothesis_dart/src/search_strategy/collections.dart';
import 'package:hypothesis_dart/src/search_strategy/data.dart';
import 'package:hypothesis_dart/src/search_strategy/misc.dart';
import 'package:hypothesis_dart/src/search_strategy/numbers.dart';

void main() {
  Given2(IntegersFromStrategy(), DataStrategy()).test2("conditional draw", (
    int x,
    DataObject data,
  ) {
    print("line 13: $x");
    int y = data.draw(IntegersFromStrategy(lowerBound: x));
    print("line 15: $y");
    check(y).isGreaterOrEqual(x);
    print("line 17");
  });

  Given1(DataStrategy()).test("prints on failure", (DataObject data) {
    print("line 21");
    List<int> x = data.draw(ListStrategy(IntegersFromStrategy(), minSize: 1));
    print(x);
    int y = data.draw(SampledFromStrategy(x));
    print(y);
    check(x).contains(y);
    x.remove(y);
    print(x);
    check(x.contains(y)).isFalse();
  });
}
