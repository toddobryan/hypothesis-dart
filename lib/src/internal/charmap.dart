import 'dart:math';

import 'package:collection/collection.dart';
import '../dart_utils/default_map.dart';
import 'package:unicode/unicode.dart';

import 'interval_sets.dart';

typedef CharMap = Map<UnicodeCategory, List<Interval>>;

CharMap? _charMap;

CharMap get charMap {
  if (_charMap == null) {
    DefaultMap<UnicodeCategory, List<Interval>> tmpCharMap =
        DefaultMap<UnicodeCategory, List<Interval>>(() => []);
    for (int i = 0; i <= maxUnicode; i++) {
      UnicodeCategory cat = getUnicodeCategory(i);
      List<Interval> rs = tmpCharMap[cat]!;
      if (rs.isNotEmpty && rs.last.end == i - 1) {
        Interval last = rs.last;
        rs[rs.length - 1] = Interval(last.start, last.end + 1);
        tmpCharMap[cat] = rs;
      } else {
        tmpCharMap[cat]!.add(Interval(i, i));
      }
    }
    _charMap = tmpCharMap;
  }
  assert(_charMap != null);
  return _charMap!;
}

List<UnicodeCategory>? _categories;

List<UnicodeCategory> get categories {
  if (_categories == null) {
    CharMap cm = charMap;
    _categories = cm.keys.sortedBy((c) => cm[c]!.length);
    _categories!.remove(UnicodeCategory.control);
    _categories!.remove(UnicodeCategory.surrogate);
    _categories!.add(UnicodeCategory.control);
    _categories!.add(UnicodeCategory.surrogate);
  }
  return _categories!;
}

Map<String, List<Interval>> categoryIndexCache = <String, List<Interval>>{
  "": [],
};

List<UnicodeCategory> _categoryKey(Iterable<UnicodeCategory>? exclude, Iterable<UnicodeCategory>? include) {
  List<UnicodeCategory> cs = categories;
  include = (include ?? cs).toSet();
  exclude = (exclude ?? []).toSet();
  (include as Set).removeAll(exclude);
  List<UnicodeCategory> result = cs.where((UnicodeCategory c) => include!.contains(c)).toList();
  return result;
}

List<Interval> _queryForKey(List<UnicodeCategory> key) {
  if (categoryIndexCache.containsKey(key.join())) {
    return categoryIndexCache[key.join()]!;
  }
  List<UnicodeCategory> cs = categories;
  List<Interval> result;
  if (key.length == cs.length) {
    result = [Interval(0, maxUnicode)];
  } else {
    result = _queryForKey(key.sublist(0, key.length - 1)).union(charMap[key.last]!).toList();
  }
  categoryIndexCache[key.join()] = result;
  return result;
}

Map<(String, int, int), List<Interval>> limitedCategoryIndexCache = {};

List<Interval> query({
    List<UnicodeCategory>? excludeCategories,
    List<UnicodeCategory>? includeCategories,
    int? minCodepoint,
    int? maxCodepoint,
}) {
  minCodepoint ??= 0;
  maxCodepoint ??= maxUnicode;
  List<UnicodeCategory> catKey = _categoryKey(excludeCategories, includeCategories);
  (String, int, int) qKey = (catKey.join(), minCodepoint, maxCodepoint);
  if (limitedCategoryIndexCache.containsKey(qKey)) {
    return limitedCategoryIndexCache[qKey]!;
  }
  List<Interval> base = _queryForKey(catKey);
  List<Interval> result = [];
  for (Interval uv in base) {
    if (uv.end >= minCodepoint && uv.start <= maxCodepoint) {
      result.add(Interval(max(uv.start, minCodepoint), min(uv.end, maxCodepoint)));
    }
  }
  limitedCategoryIndexCache[qKey] = result;
  return result;
}

int maxUnicode = 0x10FFFF;

extension Chr on int {
  String get chr => String.fromCharCode(this);
}

extension Union on Iterable<Interval> {
  Iterable<Interval> union(Iterable<Interval> other) {
    if (isEmpty) {
      return other;
    }
    if (other.isEmpty) {
      return this;
    }
    List<Interval> intervals = [...this, ...other].sorted((Interval a, Interval b) => -a.compareTo(b)).toList();
    List<Interval> result = [intervals.removeLast()];
    while (intervals.isNotEmpty) {
      Interval uv = intervals.removeLast();
      Interval ab = result.last;
      if (uv.start < ab.end + 1) {
        result[result.length - 1] = Interval(ab.start, uv.end);
      } else {
        result.add(uv);
      }
    }
    return result;
  }
}
