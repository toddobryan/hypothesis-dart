


import 'platform.dart';

abstract class FlexInt implements Comparable<FlexInt> {
  int get bitLength;

  FlexInt operator <<(int bits);
  FlexInt operator >>(int bits);
  FlexInt operator |(FlexInt other);
  FlexInt operator &(FlexInt other);

  FBigInt promote();

  bool operator <(FlexInt other) => compareTo(other) < 0;
  bool operator <=(FlexInt other) => compareTo(other) <= 0;
  bool operator >(FlexInt other) => compareTo(other) > 0;
  bool operator >=(FlexInt other) => compareTo(other) > 0;

  static FlexInt fromInt(int i) => FInt(i);
  static FlexInt fromBigInt(BigInt bi) => FBigInt(bi);
}

class FInt extends FlexInt {
  final int value;

  FInt(this.value);

  @override
  int get bitLength => value.bitLength;

  @override
  FlexInt operator <<(int bits) {
    if (value.bitLength + bits < Platform.current.maxBitLength) {
      return FInt(value << bits);
    } else {
      return promote() << bits;
    }
  }

  @override
  FlexInt operator >>(int bits) {
    return FInt(value >> bits);
  }

  @override
  FlexInt operator |(FlexInt fi) {
    if (fi is FInt) {
      return FInt(value | fi.value);
    } else {
      return promote() | fi;
    }
  }

  @override operator &(FlexInt fi) {
    if (fi is FInt) {
      return FInt(value & fi.value);
    } else {
      return promote() & fi;
    }
  }

  @override
  FBigInt promote() => FBigInt(BigInt.from(value));

  @override
  int compareTo(FlexInt other) {
    if (other is FInt) {
      return value - other.value;
    } else {
      return promote().compareTo(other);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlexInt && compareTo(other) == 0;

  @override
  int get hashCode => value.hashCode;
}

class FBigInt extends FlexInt {
  BigInt value;

  FBigInt(this.value);

  @override
  int get bitLength => value.bitLength;

  @override
  FBigInt promote() => this;


  @override
  FlexInt operator <<(int bits) => FBigInt(value << bits);

  @override
  FlexInt operator >>(int bits) => FBigInt(value >> bits);

  @override
  FlexInt operator |(FlexInt other) => FBigInt(value | other.promote().value);

  @override
  FlexInt operator &(FlexInt other) => FBigInt(value & other.promote().value);

  @override
  int compareTo(FlexInt other) => value.compareTo(other.promote().value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FlexInt && compareTo(other) == 0;

  @override
  int get hashCode => value.hashCode;
}
