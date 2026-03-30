// TODO: copy docstrings from Python

class HypothesisException implements Exception {
  String? message;

  HypothesisException(this.message);
}

class CleanupFailed extends HypothesisException {
  CleanupFailed(super.message);
}

class UnsatisfiedAssumption extends HypothesisException {
  UnsatisfiedAssumption(super.message);
}

class BadTemplateDraw extends HypothesisException {
  BadTemplateDraw(super.message);
}

class NoSuchExample extends HypothesisException {
  NoSuchExample(String conditionString, {String extra = ""})
      : super("No examples found of condition $conditionString$extra");
}

class NoExamples extends HypothesisException {
  NoExamples(super.message);
}

class Unsatisfiable extends HypothesisException {
  Unsatisfiable(super.message);
}

class Flaky extends HypothesisException {
  Flaky._(super.message);

  factory Flaky(String message) {
    print("Flaky message: $message");
    return Flaky._(message);
  }
}

class Timeout extends Unsatisfiable {
  Timeout(super.message);
}

class WrongFormat extends HypothesisException {
  WrongFormat(super.message);
}

class BadData extends HypothesisException {
  BadData(super.message);
}

class InvalidArgument extends HypothesisException {
  InvalidArgument(super.message);
}

class InvalidState extends HypothesisException {
  InvalidState(super.message);
}

class InvalidDefinition extends HypothesisException {
  InvalidDefinition(super.message);
}

class AbnormalExit extends HypothesisException {
  AbnormalExit(super.message);
}

class FailedHealthCheck extends HypothesisException {
  FailedHealthCheck(super.message);
}

class HypothesisDeprecationWarning extends HypothesisException {
  HypothesisDeprecationWarning(super.message);
}

class Frozen extends HypothesisException {
  Frozen(super.message);
}
