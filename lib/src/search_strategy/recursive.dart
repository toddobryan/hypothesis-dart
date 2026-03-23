import 'dart:math';

import '../dart_utils/context_manager.dart';

import '../internal/conjecture/data.dart';
import 'strategies.dart';
import 'wrappers.dart';

class LimitReached implements Exception {}

class LimitedStrategy<T> extends WrapperStrategy<T> {
  int marker = 0;
  bool currentlyCapped = false;

  LimitedStrategy(super.wrappedStrategy);

  @override
  T doDraw(TestData data) {
    assert(currentlyCapped);
    if (marker <= 0) {
      throw LimitReached();
    }
    marker -= 1;
    return super.doDraw(data);
  }

  ContextManager<void> capped(int maxTemplates) =>
      FunctionalContextManager.rethrows(() {
        assert(!currentlyCapped);
        currentlyCapped = true;
        marker = maxTemplates;
      }, () => currentlyCapped = false);
}

class RecursiveStrategy<T> extends SearchStrategy<T> {
  final LimitedStrategy<T> base;
  final SearchStrategy<T> strategy;
  final SearchStrategy<T> Function(SearchStrategy<T>) extend;
  final int maxLeaves;

  RecursiveStrategy._(this.base, this.strategy, this.extend, this.maxLeaves);

  factory RecursiveStrategy(SearchStrategy<T> base, SearchStrategy<T> Function(SearchStrategy<T>) extend, int maxLeaves) {
    List<SearchStrategy<T>> strategies = [base, extend(base)];
    while (maxLeaves >= pow(2, strategies.length)) {
      strategies.add(extend(OneOfStrategy(strategies, bias: 0.8)));
    }
    return RecursiveStrategy._(
        LimitedStrategy(base), OneOfStrategy(strategies), extend, maxLeaves);
  }

  @override
  T doDraw(TestData data) {
    while (true) {
      try {
        using(base.capped(maxLeaves), (void _) {
          return data.draw(strategy);
        });
      } on LimitReached {
        rethrow;
      }
    }
  }
}