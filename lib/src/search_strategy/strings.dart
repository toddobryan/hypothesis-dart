import 'dart:math';
import '../hypothesis_random.dart';
import 'package:unicode/unicode.dart';

import '../internal/conjecture/data.dart';
import '../internal/conjecture/utils.dart';
import '../internal/interval_sets.dart';
import 'strategies.dart';
import '../internal/charmap.dart' as charmap;

class OneCharStringStrategy extends SearchStrategy<String> {
  final IntervalSet intervals;
  final Set<String> excludedCharacters;
  final int zeroPoint;
  final List<int> special;

  OneCharStringStrategy._(
    this.intervals,
    this.excludedCharacters,
    this.zeroPoint,
    this.special,
  );

  factory OneCharStringStrategy({
    List<UnicodeCategory>? includedCategories,
    List<UnicodeCategory>? excludedCategories,
    List<String>? excludedCharacters,
    int? minCodepoint,
    int? maxCodepoint,
  }) {
    List<Interval> intervalList = charmap.query(
      includeCategories: includedCategories,
      excludeCategories: excludedCategories,
      minCodepoint: minCodepoint,
      maxCodepoint: maxCodepoint,
    );
    if (intervalList.isEmpty) {
      throw ArgumentError("No valid characters in set");
    }
    IntervalSet intervals = IntervalSet(intervalList);
    Set<String> charactersToExclude;
    if (excludedCharacters != null && excludedCharacters.isNotEmpty) {
      charactersToExclude = excludedCharacters
          .where((String c) => intervals.contains(c.ord))
          .toSet();
    } else {
      charactersToExclude = <String>{};
    }
    int zeroPoint = intervals.indexAbove("0".ord);
    List<int> special = [];
    if (!charactersToExclude.contains("\n")) {
      if (intervals.contains("\n".ord)) {
        special.add(intervals.index("\n".ord));
      }
    }
    return OneCharStringStrategy._(
      intervals,
      charactersToExclude,
      zeroPoint,
      special,
    );
  }

  @override
  String doDraw(TestData data) {
    double denom = log1p(-1.0 / 127);

    int d(HypothesisRandom random) {
      if (special.isNotEmpty && random.randInt(0, 10) == 0) {
        return random.choice(special);
      }
      if (intervals.length <= 256 || random.randInt(0, 1) == 1) {
        int i = random.randInt(0, intervals.offsets.length - 1);
        Interval uv = intervals.intervals[i];
        return intervals.offsets[i] + random.randInt(0, uv.end - uv.start + 1);
      } else {
        return min(intervals.length - 1, log(random.random() / denom).toInt());
      }
    }

    while (true) {
      int i = integerRange(
        data,
        0,
        intervals.length - 1,
        center: zeroPoint,
        distribution: d,
      );
      String c = intervals[i].chr;
      if (!excludedCharacters.contains(c)) {
        return c;
      }
    }
  }
}

class StringStrategy extends MappedSearchStrategy<List<String>, String> {
  StringStrategy._(super.mappedStrategy, super.pack);

  factory StringStrategy(
    SearchStrategy<List<String>> listOfOneCharStringsStrategy,
  ) => StringStrategy._(
    listOfOneCharStringsStrategy,
    (List<String> ls) => ls.join(),
  );
}

// No BinaryStringStrategy, just use Bytes

extension Ord on String {
  int get ord {
    assert(length == 1, "do not call ord on more than one character");
    return runes.toList()[0];
  }
}
