class Interval implements Comparable<Interval> {
  final int start;
  final int end;

  Interval(this.start, this.end);

  @override
  int compareTo(Interval other) {
    if (start != other.start) {
      return start - other.start;
    } else {
      return end - other.end;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interval &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

class IntervalSet extends Iterable<int> {
  final List<Interval> intervals;
  final List<int> offsets;
  final int size;

  IntervalSet._(this.intervals, this.offsets, this.size);

  factory IntervalSet(List<Interval> intervals) {
    List<int> offsets = [0];
    for (Interval i in intervals) {
      offsets.add(offsets.last + i.end - i.start + 1);
    }
    int size = offsets.removeLast();
    return IntervalSet._(intervals, offsets, size);
  }

  @override
  int get length => size;

  @override
  Iterator<int> get iterator {
    Iterable<int> gen() sync* {
      for (Interval interval in intervals) {
        for (int i = interval.start; i <= interval.end; i++) {
          yield i;
        }
      }
    }
    return gen().iterator;
  }

  int operator [](int i) {
    if (i < 0) {
      i = size + i;
    }
    if (i < 0 || i >= size) {
      throw IndexError.withLength(i, length);
    }

    int j = intervals.length - 1;
    if (offsets[j] > i) {
      int hi = j;
      int lo = 0;
      while (lo + 1 < hi) {
        int mid = (lo + hi) ~/ 2;
        if (offsets[mid] <= i) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      j = lo;
    }
    int t = i -offsets[j];
    Interval uv = intervals[j];
    int r = uv.start + t;
    assert(r <= uv.end);
    return r;
  }

  int index(int value) {
    for ((int, Interval) ouv in offsets.zip(intervals)) {
      int offset = ouv.$1;
      int u = ouv.$2.start;
      int v = ouv.$2.end;
      if (u == value) {
        return offset;
      } else if (u > value) {
        throw ArgumentError("Value $value is not in list");
      }
      if (value <= v) {
        return offset + (value - u);
      }
    }
    throw ArgumentError("Value $value is not in list");
  }

  int indexAbove(int value) {
    for ((int, Interval) ouv in offsets.zip(intervals)) {
      int offset = ouv.$1;
      int u = ouv.$2.start;
      int v = ouv.$2.end;
      if (u >= value) {
        return offset;
      }
      if (value <= v) {
        return offset + (value - u);
      }
    }
    return size;
  }
}

extension Zip<T1> on Iterable<T1> {
  Iterable<(T1, T2)> zip<T2>(Iterable<T2> other) sync* {
    final it1 = iterator;
    final it2 = other.iterator;
    while (it1.moveNext() && it2.moveNext()) {
      yield (it1.current, it2.current);
    }
  }
}