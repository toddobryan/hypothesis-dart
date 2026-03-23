import '../dart_utils/context_manager.dart';

class DynamicVariable<T> {
  final T defaultValue;
  T? _value;

  DynamicVariable(this.defaultValue);

  T get value => _value ?? defaultValue;

  ContextManager<void> withValue(T tempValue) {
    T oldValue = value;
    return FunctionalContextManager.rethrows(
        () => _value = tempValue,
        () => _value = oldValue,
    );
  }
}