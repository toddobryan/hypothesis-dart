import 'internal/conjecture/data.dart';

void defaultExecutor(Function function) {
  throw UnimplementedError();
}

void Function(T Function()) setupTeardownExecutor<T, U>({
  U? Function()? setup,
  void Function(U?)? teardown,
}) {
  setup ??= () {
    return null;
  };
  teardown ??= (_) {
    return;
  };

  T execute(T Function() function) {
    U? token;
    try {
      token = setup!();
      return function();
    } finally {
      teardown!(token);
    }
  }

  return execute;
}

abstract interface class ExampleExecutor<T, U> {
  T executeExample(U example);
}

abstract interface class ExampleWithSetupTeardown<T> {
  T? Function()? setupExample;
  void Function(T?)? teardownExample;
}

void Function(T) executor<T>(Object? runner) {
  if (runner is ExampleExecutor) {
    return runner.executeExample;
  }

  if (runner is ExampleWithSetupTeardown) {
    return setupTeardownExecutor(
          setup: runner.setupExample,
          teardown: runner.teardownExample,
        ) as void Function(T);
  }

  return defaultExecutor as void Function(T);
}

void defaultNewStyleExecutor<T>(TestData? data, void Function(TestData) test) {
  return test(data!);
}

class ConjectureRunner<T> {
  void hypothesisExecuteExampleWithData(
    TestData? data,
    void Function(TestData?) test,
  ) {
    return test(data);
  }
}

void Function(TestData?, void Function(TestData?)) newStyleExecutor<T>(
  Object? runner,
) {
  if (runner == null) {
    return defaultNewStyleExecutor;
  }
  if (runner is ConjectureRunner) {
    return runner.hypothesisExecuteExampleWithData;
  }

  void Function(void Function(T)) oldSchool = executor(runner);
  if (oldSchool == defaultExecutor) {
    return defaultNewStyleExecutor;
  } else {
    return (TestData? data, void Function(TestData?) function) =>
        oldSchool((T t) => function(data!));
  }
}
