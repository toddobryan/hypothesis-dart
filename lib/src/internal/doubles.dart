import '../dart_utils/bytes.dart';

double sign(double x) {
  if (x.isNegative) {
    return -1.0;
  } else {
    return 1.0;
  }
}

int countBetweenDoubles(double x, double y) {
  assert(x <= y);
  if (x.isNegative) {
    if (y.isNegative) {
      return doubleToInt(x) - doubleToInt(y) + 1;
    } else {
      return countBetweenDoubles(x, -0.0) + countBetweenDoubles(0.0, y);
    }
  } else {
    assert(!y.isNegative);
    return doubleToInt(y) - doubleToInt(x) + 1;
  }
}

int doubleToInt(double value) =>
    ByteFormat.double64.toBytes(value).unpackInt64();

double intToDouble(int value) =>
    ByteFormat.int64.toBytes(value).unpackDouble64();
