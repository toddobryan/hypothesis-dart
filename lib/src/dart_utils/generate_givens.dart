import 'package:indent/indent.dart';

String given(int i) {
  List<String> types = listOfTypes(i);

  return """
  |class Given$i<${types.join(", ")}> extends Given<${tupled(types)}> {
  |  Given$i(
  |    ${strategiesWithTypes(i).join(",\n    ")}, {
  |      Settings? settings,
  |      Object? seed,
  |    }) : super(${strategiesTupled(i)}, settings ?? Settings.defaultValue, seed);
  |
  |  @isTest
  |  void test$i(Object? description, void Function(${types.join(", ")}) testFunction) =>
  |    super.test(description, (${tupled(types)} ts) =>
  |       testFunction(${untupled("ts", i)}));
  |}
  |
  """.trimMargin();
}

List<String> listOfTypes(int i) => List.generate(i, (j) => "T${j + 1}");

String untupled(String tup, int i) {
  String helper(int start, int end) {
    if (start == end) {
      return tup;
    } else if (start + 1 == end) {
      return "$tup${nestedTup(start)}.\$1, $tup${nestedTup(start)}.\$2";
    } else {
      return "$tup${nestedTup(start)}.\$1, ${helper(start + 1, end)}";
    }
  }

  return helper(1, i);
}

String nestedTup(int i) {
  if (i == 1) {
    return "";
  } else {
    return "${nestedTup(i - 1)}.\$2";
  }
}

String tupled(List<String> ts) {
  if (ts.length == 1) {
    return ts[0];
  } else {
    return "(${ts[0]}, ${tupled(ts.sublist(1))})";
  }
}

List<String> strategies(int i) => List.generate(i, (j) => "strategy${j + 1}");
List<String> strategiesWithTypes(int i) =>
    List.generate(i, (j) => "SearchStrategy<T${j + 1}> strategy${j + 1}");

String strategiesTupled(int i) {
  String helper(int start, int end) {
    if (start == end) {
      return "strategy$start";
    } else {
      return "strategy$start.and(${helper(start + 1, end)})";
    }
  }

  return helper(1, i);
}

void main() {
  print(
    """
    |import 'package:meta/meta.dart';
    |
    |import 'core.dart';
    |import 'search_strategy/pair.dart';
    |import 'search_strategy/strategies.dart';
    |import 'settings.dart';
    |
    |extension AndPair<T> on SearchStrategy<T> {
    |  SearchStrategy<(T, U)> and<U>(SearchStrategy<U> other) =>
    |      PairStrategy(this, other);
    |}\n\n
    """.trimMargin()
  );

  for (int i = 1; i <= 8; i++) {
    print(given(i));
  }
}

