import 'dart:math';

import '../core.dart';
import '../errors.dart';
import '../hypothesis_random.dart';
import 'flatmapped.dart';

import '../control.dart';
import '../internal/conjecture/data.dart';
import '../internal/conjecture/utils.dart';
import '../settings.dart';

abstract class SearchStrategy<T> {
  bool get supportsFind => true;

  T example({HypothesisRandom? random}) {
    NoExamples exc = NoExamples("Could not find any valid examples in 100 tries");

    try {
      return find(this, (_) => true, random: random, settings: Settings(maxShrinks: 0, maxIterations: 1000, /*database: null*/));
    } on NoSuchExample {
      throw exc;
    } on Unsatisfiable {
      throw exc;
    }
  }

  SearchStrategy<U> map<U>(U Function(T) pack) => 
      MappedSearchStrategy(this, pack);

  SearchStrategy<U> flatMap<U>(SearchStrategy<U> Function(T) expand) =>
      FlatMapStrategy(this, expand);
  
  SearchStrategy<T> filter(bool Function(T) condition) =>
      FilteredStrategy(this, condition);

  void validate() {
    // do nothing
  }

  T doDraw(TestData data);
}

extension Or<U, T extends U> on SearchStrategy<T> {
  SearchStrategy<U> or(SearchStrategy<U> other) {
    return OneOfStrategy([this, other]);
  }
}

class OneOfStrategy<T> extends SearchStrategy<T> {
  final List<SearchStrategy<T>> elementStrategies;
  double? bias;
  List<double>? weights;

  OneOfStrategy._(this.elementStrategies, this.bias, this.weights);

  factory OneOfStrategy(List<SearchStrategy<T>> strategies, {double? bias}) {
    List<double>? weights;
    if (bias != null) {
      assert(0 < bias && bias < 1);
      weights = List.generate(strategies.length, (int i) => pow(bias, i) as double);
    }
    return OneOfStrategy._(strategies, bias, weights);
  }

  @override
  T doDraw(TestData data) {
    int n = elementStrategies.length;
    int i;
    if (bias == null) {
      i = integerRange(data, 0, n - 1);
    } else {
      int biasedI(HypothesisRandom random) {
        while (true) {
          int i = random.randInt(0, n - 1);
          if (random.random() <= weights![i]) {
            return i;
          }
        }
      }
      i = integerRangeWithDistribution(data, 0, n - 1, biasedI);
    }
    return data.draw(elementStrategies[i]);
  }

  @override
  void validate() {
    for (SearchStrategy<T> s in elementStrategies) {
      s.validate();
    }
  }
}

class MappedSearchStrategy<From, To> extends SearchStrategy<To> {
  final SearchStrategy<From> mappedStrategy;
  To Function(From) pack;

  MappedSearchStrategy(this.mappedStrategy, this.pack);

  @override
  To doDraw(TestData data) {
    for (int x = 0; x < 3; x++) {
      int i = data.index;
      try {
        return pack(mappedStrategy.doDraw(data));
      } on UnsatisfiedAssumption {
        if (data.index == i) {
          rethrow;
        }
      }
    }
    reject();
  }

  @override
  void validate() {
    mappedStrategy.validate();
  }
}

class FilteredStrategy<T> extends SearchStrategy<T> {
  SearchStrategy<T> filteredStrategy;
  bool Function(T) condition;

  FilteredStrategy(this.filteredStrategy, this.condition);

  @override
  T doDraw(TestData data) {
    for (int x = 0; x < 3; x++) {
      int startIndex = data.index;
      T value = data.draw(filteredStrategy);
      if (condition(value)) {
        return value;
      } else {
        assume(data.index > startIndex);
      }
    }
    data.markInvalid();
  }

  @override
  void validate() {
    filteredStrategy.validate();
  }
}