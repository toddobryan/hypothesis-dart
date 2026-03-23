import 'dart_utils/context_manager.dart';
import 'utils/dynamic_variable.dart';

import 'dart_utils/comparable_operators.dart';
import 'database.dart';

Settings settings = Settings();

DynamicVariable<Settings?> defaultVariable = DynamicVariable(null);

class Settings implements ContextManager<Settings> {
  // from _settings.py starting at line 333
  int minSatisfyingExamples;
  int maxExamples = 200;
  int maxIterations = 1000;
  int maxMutations = 10;
  int bufferSize = 8 * 1024;
  int maxShrinks = 500;
  int timeout = 60000; // in millis
  bool shouldDerandomize = false;
  bool isStrict = true;
  //String databaseFile = // lots of env stuff
  Verbosity verbosity = .normal;
  int statefulStepCount = 50;
  bool shouldPerformHealthCheck = true;
  ExampleDatabase? _database;

  List<ContextManager<void>> defaultsStack = [];

  Settings._(
    this.minSatisfyingExamples,
    this.maxExamples,
    this.maxIterations,
    this.maxMutations,
    this.bufferSize,
    this.maxShrinks,
    this.timeout,
    this.shouldDerandomize,
    this.isStrict,
    this.verbosity,
    this.statefulStepCount,
    this.shouldPerformHealthCheck,
  );

  factory Settings({
    int minSatisfyingExamples = 5,
    int maxExamples = 200,
    int maxIterations = 1000,
    int maxMutations = 10,
    int bufferSize = 8 * 1024,
    int maxShrinks = 500,
    int timeout = 60000, // in millis
    bool shouldDerandomize = false,
    bool isStrict = true,
    Verbosity verbosity = .normal,
    int statefulStepCount = 50,
    bool shouldPerformHealthCheck = true,
  }) => Settings._(
    minSatisfyingExamples,
    maxExamples,
    maxIterations,
    maxMutations,
    bufferSize,
    maxShrinks,
    timeout,
    shouldDerandomize,
    isStrict,
    verbosity,
    statefulStepCount,
    shouldPerformHealthCheck,
  );

  factory Settings.fromParent(
      Settings parent,
      {
        int? minSatisfyingExamples,
        int? maxExamples,
        int? maxIterations,
        int? maxMutations,
        int? bufferSize,
        int? maxShrinks,
        int? timeout, // in millis
        bool? shouldDerandomize,
        bool? isStrict,
        Verbosity? verbosity,
        int? statefulStepCount,
        bool? shouldPerformHealthCheck,
      }) => Settings._(
    minSatisfyingExamples ?? parent.minSatisfyingExamples,
    maxExamples ?? parent.maxExamples,
    maxIterations ?? parent.maxIterations,
    maxMutations ?? parent.maxMutations,
    bufferSize ?? parent.bufferSize,
    maxShrinks ?? parent.maxShrinks,
    timeout ?? parent.timeout,
    shouldDerandomize ?? parent.shouldDerandomize,
    isStrict ?? parent.isStrict,
    verbosity ?? parent.verbosity,
    statefulStepCount ?? parent.statefulStepCount,
    shouldPerformHealthCheck ?? parent.shouldPerformHealthCheck,
  );

  static Settings defaultValue = Settings();

  ExampleDatabase? get database => _database ?? InMemoryExampleDatabase();

  @override
  (Exception, StackTrace)? excStack;

  @override
  bool? suppressExceptions;

  @override
  Settings enter() {
    ContextManager<void> defaultContextManager = defaultVariable.withValue(
      this,
    );
    defaultsStack.add(defaultContextManager);
    defaultContextManager.enter();
    return this;
  }

  @override
  bool exit() {
    ContextManager<void> defaultContextManager = defaultsStack.removeLast();
    return defaultContextManager.exit();
  }
}

enum Verbosity with ComparableOperators<Verbosity> {
  quiet(0),
  normal(1),
  verbose(2),
  debug(3);

  final int value;
  const Verbosity(this.value);

  @override
  int compareTo(Verbosity other) => value - other.value;
}
