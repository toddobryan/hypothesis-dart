import 'dart:convert';

import 'settings.dart';
import 'utils/dynamic_variable.dart';

import 'dart_utils/bytes.dart';
import 'dart_utils/context_manager.dart';

typedef Reporter = void Function(String);

// just default in Python, but is keyword in Dart
void defaultReporter(String value) {
  // TODO: what if String has an invalid character
  print(value);
}

DynamicVariable<Reporter> reporter = DynamicVariable(defaultReporter);

Reporter currentReporter() => reporter.value;

ContextManager<void> withReporter(Reporter newReporter) =>
    reporter.withValue(newReporter);

Verbosity currentVerbosity() => settings.verbosity; // TODO: settings.default.verbosity

String toText(Object textish) {
  if (textish is Function) {
    return textish() as String;
  } else if (textish is Bytes) {
    return utf8.decode(textish.wrapped.toIntList(), allowMalformed: true);
  } else {
    return textish.toString();
  }
}

void verboseReport(Object text) {
  if (currentVerbosity() >= .verbose) {
    currentReporter()(toText(text));
  }
}

void debugReport(Object text) {
  if (currentVerbosity() >= .debug) {
    currentReporter()(toText(text));
  }
}

void report(Object text) {
  if (currentVerbosity() >= .normal) {
    currentReporter()(toText(text));
  }
}