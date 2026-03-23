
abstract class ContextManager<T> {
  (Exception, StackTrace)? excStack;
  bool? suppressExceptions;

  ContextManager(this.suppressExceptions);

  T enter();
  bool exit();
}

class FunctionalContextManager<T> extends ContextManager<T> {
  final T Function() _enter;
  final void Function()? _exit;
  final bool Function()? _exitWithSuppression;

  FunctionalContextManager._(super.suppressExceptions, this._enter, this._exit, this._exitWithSuppression);

  factory FunctionalContextManager.rethrows(T Function() enter, void Function() exit) =>
      FunctionalContextManager._(false, enter, exit, null);

  factory FunctionalContextManager.suppresses(T Function() enter, void Function() exit) =>
      FunctionalContextManager._(true, enter, exit, null);

  factory FunctionalContextManager.depends(T Function() enter, bool Function() exit) =>
      FunctionalContextManager._(null, enter, null, exit);

  @override
  T enter() => _enter();

  @override
  bool exit() {
    if (suppressExceptions != null) {
      _exit!();
      return suppressExceptions!;
    } else {
      return _exitWithSuppression!();
    }
  }
}

class SubTypeOf<T> {
  SubTypeOf();

  factory SubTypeOf.fromInstance(T t) => SubTypeOf<T>();
}

void using<T>(ContextManager<T> cm, void Function(T) f) {
  bool suppressException;
  try {
    T t = cm.enter();
    f(t);
  } on Exception catch (e, s) {
    cm.excStack = (e, s);
  } finally {
    suppressException = cm.exit();
  }
  if (!suppressException && cm.excStack != null) {
    Error.throwWithStackTrace(cm.excStack!.$1, cm.excStack!.$2);
  }
}
