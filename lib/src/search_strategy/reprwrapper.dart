import 'package:hypothesis_dart/src/search_strategy/wrappers.dart';

class ReprWrapperStrategy<T> extends WrapperStrategy<T> {
  String representation; // either function or String

  ReprWrapperStrategy(super.wrappedStrategy, this.representation);

  @override
  String toString() => repr();

  String repr() => representation;
}