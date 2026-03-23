import 'utils/dynamic_variable.dart';
import 'dart_utils/context_manager.dart';
import 'errors.dart';
import 'reporting.dart';

Never reject() => throw UnsatisfiedAssumption(null);

bool assume(bool condition) {
  if (!condition) {
    throw UnsatisfiedAssumption(null);
  }
  return true;
}

DynamicVariable<BuildContext?> _currentBuildContext = DynamicVariable(null);

BuildContext currentBuildContext() {
  BuildContext? context = _currentBuildContext.value;
  if (context == null) {
    throw InvalidArgument("No build context registered");
  }
  return context;
}

class BuildContext extends ContextManager<BuildContext> {
  final List<void Function()> tasks;
  final bool isFinal;
  final bool closeOnCapture;
  final bool closeOnDel;
  final List<Object> notes;
  ContextManager<void>? assignVariable;

  BuildContext._(
    this.tasks,
    this.isFinal,
    this.closeOnCapture,
    this.closeOnDel,
    this.notes,
  ) : super(false);

  factory BuildContext({bool isFinal = false, bool closeOnCapture = true}) {
    return BuildContext._([], isFinal, closeOnCapture, false, []);
  }

  @override
  BuildContext enter() {
    assignVariable = _currentBuildContext.withValue(this);
    assignVariable!.enter();
    return this;
  }

  @override
  bool exit() {
    assignVariable!.excStack = excStack;
    assignVariable!.exit();
    if (close() && excStack == null) {
      throw CleanupFailed(null);
    }
    return false;
  }

  ContextManager<void> local() => _currentBuildContext.withValue(this);

  bool close() {
    bool anyFailed = false;
    for (void Function() task in tasks) {
      try {
        task();
      } on Exception {
        anyFailed = true;
        report(StackTrace.current);
      }
    }
    return anyFailed;
  }
}

void cleanup(void Function() teardown) {
  BuildContext? context = _currentBuildContext.value;
  if (context == null) {
    throw InvalidArgument("Cannot register cleanup outside of build context");
  }
  context.tasks.add(teardown);
}

void note(Object value) {
  BuildContext? context = _currentBuildContext.value;
  if (context == null) {
    // throw InvalidArgument("Cannot make notes outside of build context");
  } else {
    context.notes.add(value);
    if (context.isFinal) {
      report(value);
    }
  }
}
