import 'dart:math';
import 'package:test/test.dart' as dart_test;

import 'control.dart';
import 'errors.dart';
import 'hypothesis_random.dart';
import 'internal/conjecture/engine.dart';
import 'reporting.dart';
import 'search_strategy/strategies.dart';
import 'settings.dart';
import 'package:meta/meta.dart';

import 'dart_utils/bytes.dart';
import 'dart_utils/context_manager.dart';
import 'internal/conjecture/data.dart';

Random mathRandom = Random();

HypothesisRandom newRandom() => BetterHypRandom(mathRandom.nextInt(1 << 32));

abstract class Given<T> {
  // TODO: examples
  SearchStrategy<T> strategy;
  Settings settings;
  Object? seed;

  TestData? data;
  (Exception, StackTrace)? lastError;
  int index = 0;

  Given(this.strategy, this.settings, this.seed);

  @isTest
  void test(Object? description, void Function(T) testFunction) {
    index = 0;
    void hypothesisTestFunction(TestData d) {
      data = d;
      try {
        testFunction(d.draw(strategy));
      } on HypothesisException {
        rethrow;
      } on dart_test.TestFailure catch (e, st) {
        if (!d.frozen) {
          lastError = (e, st);
          d.markInteresting();
        }
      }
    }
    
    dart_test.test(description, () {
      TestRunner runner = TestRunner(hypothesisTestFunction, settings: settings, random: BetterHypRandom(seed?.hashCode));
      runner.run();
      if (runner.lastData?.status == .interesting) {
        index = 0;
        assert(lastError != null, "lastError should not be null");
        data = TestData.forBuffer(runner.lastData!.buffer);
        throw Flaky("Exception: ${lastError!.$1}\n${lastError!.$2}");
      }
    });
  }
}

/*void Function(TestData) reifyAndExecute<T>(
    SearchStrategy<T> searchStrategy,
    Object? description,
    void Function(T) test,
    {
      bool printExample = false,
      bool isFinal = false,
    }) {
  void run(TestData data) {
    using(BuildContext(isFinal: isFinal), (_) {
      T arg = data.draw(searchStrategy);

      if (printExample) {
        report(() => "Falsifying example: $description($arg)");
      } else if (currentVerbosity() >= .verbose) {
        report(() => "Trying example: $description($arg)");
      }
      test(arg);
    });
  }
  return run;
}

class Given<T> {
  final SearchStrategy<T> strategy;
  final Settings settings;
  final List<T> examples;

  @isTest
  void test(Object? description, void Function(T) testFunction) {
    void runTestWithGenerator() {
      void wrappedTest(T t, {bool isHypothesisTest = true, Object? seed, Settings? settings) {
        settings ??= Settings.defaultValue;
        HypothesisRandom random;
        if (seed != null) {
          random = BetterHypRandom()
      }
      }

        void evaluateTestData(TestData data) {
          /*if perform_health_check and not performed_random_check[0]:
          initial_state = getglobalrandomstate()
            performed_random_check[0] = True
          else:
          initial_state = None*/
          try {
            reifyAndExecute(strategy, description, testFunction)(data);
          } on UnsatisfiedAssumption {
            data.markInvalid();
          } on HypothesisDeprecationWarning {
            rethrow;
          } on FailedHealthCheck {
            rethrow;
          } on StopTest {
            rethrow;
          }
          /*
          except Exception:
              last_exception[0] = traceback.format_exc()
              verbose_report(last_exception[0])
              data.mark_interesting()
          finally:
              if (
                  initial_state is not None and
                  getglobalrandomstate() != initial_state
              ):
                  fail_health_check(
                      'Your test used the global random module. '
                      'This is unlikely to work correctly. You should '
                      'consider using the randoms() strategy from '
                      'hypothesis.strategies instead. Alternatively, '
                      'you can use the random_module() strategy to '
                      'explicitly seed the random module.')
           */
        }

        T? falsifyingExample;
        Bytes databaseKey = Bytes.packInt64(testFunction.hashCode);
        int startTime = currentMillis();

        TestRunner runner = TestRunner(
          evaluateTestData,
          settings: settings,
          random: random,
          databaseKey: databaseKey,
        )
      }

    }
    return runTestWithGenerator(description, testFunction);
  }
}

class HypothesisTest<T> {
  final void Function(T) test;
  Settings settings;
  Object? seed;

  HypothesisTest(
    this.test,
    this.settings,
    this.seed,
  );

  void call() {
    HypothesisRandom random;
    if (seed != null) {
      random = BetterHypRandom(seed.hashCode);
    } else if (settings.shouldDerandomize) {
      random = BetterHypRandom(test.hashCode);
    } else {
      random = newRandom();
    }

    void Function(TestData?, void Function(TestData?)) testRunner = exec
        .newStyleExecutor(t);

    for (T example in explicitExamples) {
      String messageOnFailure = "Falsifying example: $description($example)";
      BuildContext b = BuildContext();
      try {
        using(b, (b) => testRunner(null, (TestData? data) => test(t)));
      } on Exception {
        report(messageOnFailure);
        for (Object n in b.notes) {
          report(n);
        }
        rethrow;
      }
    }
    if (settings.maxExamples <= 0) {
      return;
    }

    T givenSpecifier = t;

    Never failHealthCheck(String message) {
      message +=
          '\nSee http://hypothesis.readthedocs.org/en/latest/health'
          'checks.html for more information about this.';
      throw FailedHealthCheck(message);
    }

    SearchStrategy<T> searchStrategy = JustStrategy(givenSpecifier);
    searchStrategy.validate();

    bool performHealthCheck =
        settings.shouldPerformHealthCheck &&
        Settings.defaultValue.shouldPerformHealthCheck;

    if (performHealthCheck) {
      BetterRandomState initialState = random.state;
      HypothesisRandom healthCheckRandom = newRandom();
      int count = 0;
      int overruns = 0;
      int filteredDraws = 0;
      int start = currentMillis();
      while (count < 10 &&
          currentMillis() < start + 1000 &&
          filteredDraws < 50 &&
          overruns < 20) {
        TestData data = TestData(
          settings.bufferSize,
          (TestData data, int n, Distribution distribution) =>
              distribution(healthCheckRandom, n),
        );
        try {
          using(Settings.fromParent(settings, verbosity: .quiet), (Settings s) {
            testRunner(data, reifyAndExecute(searchStrategy, this));
          });
          count += 1;
        } on UnsatisfiedAssumption {
          filteredDraws += 1;
        } on StopTest {
          if (data.status == .invalid) {
            filteredDraws += 1;
          } else {
            assert(data.status == .overrun);
            overruns += 1;
          }
        } on Exception catch (e, stackTrace) {
          report(stackTrace);
          if (testRunner == exec.defaultNewStyleExecutor) {
            failHealthCheck(
              'An exception occurred during data '
              'generation in initial health check. '
              'This indicates a bug in the strategy. '
              'This could either be a Hypothesis bug or '
              "an error in a function you've passed to "
              'it to construct your data.',
            );
          } else {
            failHealthCheck(
              'An exception occurred during data '
              'generation in initial health check. '
              'This indicates a bug in the strategy. '
              'This could either be a Hypothesis bug or '
              "an error in a function you've passed to "
              'it to construct your data. Additionally, '
              'you have a custom executor, which means '
              'that this could be your executor failing '
              'to handle a function which returns None. ',
            );
          }
        }
      }
      if (overruns >= 20 || (count == 0 && overruns > 0)) {
        failHealthCheck(
          'Examples routinely exceeded the max allowable size. '
          '($overruns examples overran while generating $count valid ones)'
          '. Generating examples this large will usually lead to'
          ' bad results. You should try setting average_size or '
          'max_size parameters on your collections and turning '
          'max_leaves down on recursive() calls.',
        );
      }
      if (filteredDraws >= 50 || (count == 0 && filteredDraws > 0)) {
        failHealthCheck(
          'It looks like your strategy is filtering out a lot '
          'of data. Health check found $filteredDraws filtered examples'
          'but only $count good ones. This will make your tests much '
          'slower, and also will probably distort the data '
          'generation quite a lot. You should adapt your '
          'strategy to filter less. This can also be caused by '
          'a low max_leaves parameter in recursive() calls',
        );
      }
      int runtime = currentMillis() - start;
      if (runtime > 1000 || count < 10) {
        failHealthCheck(
          'Data generation is extremely slow: Only produced '
          '$count valid examples in $runtime ms ($filteredDraws invalid '
          'ones and $overruns exceeded maximum size). Try decreasing '
          "size of the data you're generating (with e.g."
          'average_size or max_leaves parameters).',
        );
      }
      if (random.state != initialState) {
        failHealthCheck(
          'Data generation depends on global random module. '
          'This makes results impossible to replay, which '
          'prevents Hypothesis from working correctly. '
          'If you want to use methods from random, use '
          'randoms() from hypothesis.strategies to get an '
          'instance of Random you can use. Alternatively, you '
          'can use the random_module() strategy to explicitly '
          'seed the random module.',
        );
      }
    }
    List<String?> lastException = [null];
    List<String?> reprForLastException = [null];
    List<bool> performedRandomCheck = [false];

    Bytes? falsifyingExample;
    Bytes databaseKey = Bytes.packInt64(test.hashCode);
    int startTime = currentMillis();
    TestRunner runner = TestRunner(
      evaluateTestData,
      settings: settings,
      random: random,
      databaseKey: databaseKey,
    );
    runner.run();
    int runTime = currentMillis() - startTime;
    bool timedOut = settings.timeout > 0 && runTime >= settings.timeout;
    if (runner.lastData?.status == .interesting) {
      falsifyingExample = runner.lastData!.buffer;
      if (settings.database != null) {
        settings.database!.save(databaseKey, falsifyingExample);
      }
    } else {
      if (runner.validExamples <
          min(settings.minSatisfyingExamples, settings.maxExamples)) {
        if (timedOut) {
          throw Timeout(
            'Ran out of time before finding a satisfying '
                    'example for '
                    '$test. Only found ${runner.validExamples} examples in ' +
                '$runTime ms',
          );
        } else {
          throw Unsatisfiable(
            'Unable to satisfy assumptions of hypothesis '
            '$test. Only ${runner.validExamples} examples considered '
            'satisfied assumptions',
          );
        }
      }
      return;
    }
    assert(lastException[0] != null);

    try {
      using(settings, (s) {
        testRunner(
          TestData.forBuffer(falsifyingExample!),
          reifyAndExecute(
            searchStrategy,
            this,
            printExample: true,
            isFinal: true,
          ),
        );
      });
    } on UnsatisfiedAssumption catch (e, st) {
      report("$st");
      throw Flaky(
        'Unreliable assumption: An example which satisfied '
        'assumptions on the first run now fails it.',
      );
    } on StopTest catch (e, st) {
      report("$st");
      throw Flaky(
        'Unreliable assumption: An example which satisfied '
        'assumptions on the first run now fails it.',
      );
    }

    report("Failed to reproduce exception. Expected: \n${lastException[0]}");

    String filterMessage =
        'Unreliable test data: Failed to reproduce a failure '
        'and then when it came to recreating the example in '
        'order to print the test data with a flaky result '
        'the example was filtered out (by e.g. a '
        "call to filter in your strategy) when we didn't "
        'expect it to be.';

    try {
      void Function(T) failIfSucceeds(WrappedTest<T> wrappedTest, String repr) {
        return (T t) {
          wrappedTest.call(t);
          throw Flaky(
            'Hypothesis ${wrappedTest.description}($t) produces unreliable results: Falsified'
            ' on the first call but did not on a subsequent one',
          );
        };
      }

      WrappedTest<T> isTestFlaky = WrappedTest(
        description,
        failIfSucceeds(this, reprForLastException[0]!),
        [],
        settings,
        seed,
      );

      testRunner(
        TestData.forBuffer(falsifyingExample),
        reifyAndExecute(
          searchStrategy,
          isTestFlaky,
          printExample: true,
          isFinal: true,
        ),
      );
    } on UnsatisfiedAssumption {
      throw Flaky(filterMessage);
    } on StopTest {
      throw Flaky(filterMessage);
    }
  }

  void evaluateTestData(TestData data) {
    BetterRandomState? innerInitialState;
    if (performHealthCheck && !performedRandomCheck[0]) {
      innerInitialState = random.state;
      performedRandomCheck[0] = true;
    } else {
      innerInitialState = null;
    }
    // Python contains check that test is void,
    // but impossible with type checking
    try {
      testRunner(data, reifyAndExecute(searchStrategy, this));
    } on UnsatisfiedAssumption {
      data.markInvalid();
    } on HypothesisDeprecationWarning {
      rethrow;
    } on FailedHealthCheck {
      rethrow;
    } on StopTest {
      rethrow;
    } on Exception catch (e, st) {
      lastException[0] = "$st";
      verboseReport(lastException[0] as String);
      data.markInteresting();
    } finally {
      if (innerInitialState != null && random.state != innerInitialState) {
        failHealthCheck(
          'Your test used the global random module. '
              'This is unlikely to work correctly. You should '
              'consider using the randoms() strategy from '
              'hypothesis.strategies instead. Alternatively, '
              'you can use the random_module() strategy to '
              'explicitly seed the random module.',
        );
      }
    }
  }

}*/

T find<T>(
  SearchStrategy<T> specifier,
  bool Function(T) condition, {
  Settings? settings,
  HypothesisRandom? random,
  Bytes? databaseKey,
}) {
  settings ??= Settings(
    maxExamples: 2000,
    minSatisfyingExamples: 0,
    maxShrinks: 2000,
  );
  if (databaseKey == null && settings.database != null) {
    databaseKey = Bytes.packInt64(condition.hashCode);
  }

  SearchStrategy<T> search = specifier;

  random ??= newRandom();
  List<int> successfulExamples = [0];
  List<TestData?> lastData = [null];
  bool? success;
  T? result;

  void templateCondition(TestData data) {
    using(BuildContext(), (BuildContext bc) {
      try {
        data.isFind = true;
        T result = data.draw(search);
        data.note(result);
        success = condition(result);
      } on UnsatisfiedAssumption {
        data.markInvalid();
      }
    });

    if (success != null && success!) {
      successfulExamples[0] += 1;
    }

    if (settings!.verbosity == .verbose) {
      if (successfulExamples[0] == 0) {
        report("Trying example $result");
      } else if (success != null && success!) {
        if (successfulExamples[0] == 1) {
          report("Found satisfying example $result");
        } else {
          report("Shrunk example to $result");
        }
        lastData[0] = data;
      }
    }
    if (success != null && success! && !data.frozen) {
      data.markInteresting();
    }
  }

  int start = currentMillis();
  TestRunner runner = TestRunner(
    templateCondition,
    settings: settings,
    random: random,
    databaseKey: databaseKey,
  );
  runner.run();
  int runTime = currentMillis() - start;
  if (runner.lastData?.status == .interesting) {
    using(
      BuildContext(),
      (BuildContext bc) =>
          TestData.forBuffer(runner.lastData!.buffer).draw(search),
    );
  }
  if (runner.validExamples <= settings.minSatisfyingExamples) {
    if (settings.timeout > 0 && runTime > settings.timeout) {
      throw Timeout(
        "Ran out of time before finding enough valid examples "
        "for $condition. Only ${runner.validExamples} found in $runTime ms.",
      );
    } else {
      throw Unsatisfiable(
        "Unable to satisfy assumptions of $condition. Only "
        "${runner.validExamples} examples considered satisfied assumptions",
      );
    }
  }
  throw NoSuchExample("$condition");
}
