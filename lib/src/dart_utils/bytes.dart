import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'comparable_operators.dart';

class Bytes with ComparableOperators<Bytes> {
  Uint8List wrapped;

  Bytes(this.wrapped);

  factory Bytes.ofLength(int size) => Bytes(Uint8List(size));

  @override
  int compareTo(Bytes other) {
    if (wrapped.length == other.wrapped.length) {
      for (int i = 0; i < wrapped.length; i++) {
        if (wrapped[i] != other.wrapped[i]) {
          return wrapped[i] - other.wrapped[i];
        }
      }
      return 0;
    } else {
      return wrapped.length - other.wrapped.length;
    }
  }

  int operator [](int i) => wrapped[i];

  int get length => wrapped.length;

  bool get isEmpty => wrapped.isEmpty;
  bool get isNotEmpty => wrapped.isNotEmpty;

  Bytes sublist(int start, [int? end]) => Bytes(wrapped.sublist(start, end));

  int get max => wrapped.reduce(math.max);

  void addAll(Bytes other) {
    wrapped = Uint8List.fromList([...wrapped, ...other.wrapped]);
  }

  String get digest => sha1.convert(wrapped).toString();

  Future<void> writeTo(File f) async {
    f.writeAsBytes(wrapped, flush: true);
  }

  bool any(bool Function(int) test) => wrapped.any(test);

  static Bytes generate(int length, int Function(int) gen) {
    return Bytes(Uint8List.fromList(List.generate(length, gen)));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Bytes && compareTo(other) == 0;

  @override
  int get hashCode => wrapped.hashCode;

  ByteData get _byteData => wrapped.buffer.asByteData();

  double unpackDouble32() => _byteData.getFloat32(0);
  double unpackDouble64() => _byteData.getFloat64(0);
  int unpackInt16() => _byteData.getInt16(0);
  int unpackInt32() => _byteData.getInt32(0);
  int unpackInt64() => _byteData.getInt64(0);
  int unpackUint16() => _byteData.getUint16(0);
  int unpackUint32() => _byteData.getUint32(0);
  int unpackUint64() => _byteData.getUint64(0);

  static Bytes packDouble32(double value) => ByteFormat.double32.toBytes(value);
  static Bytes packDouble64(double value) => ByteFormat.double64.toBytes(value);
  static Bytes packInt16(int value) => ByteFormat.int16.toBytes(value);
  static Bytes packInt32(int value) => ByteFormat.int32.toBytes(value);
  static Bytes packInt64(int value) => ByteFormat.int64.toBytes(value);
  static Bytes packUint16(int value) => ByteFormat.uint16.toBytes(value);
  static Bytes packUint32(int value) => ByteFormat.uint32.toBytes(value);
  static Bytes packUint64(int value) => ByteFormat.uint64.toBytes(value);

  Bytes followedBy(Bytes other) =>
      Bytes(Uint8List.fromList(wrapped.followedBy(other.wrapped).toList()));
}

class ByteFormat {
  static ByteFormat double32 = ByteFormat(
    4,
    (ByteData bd, num value) => bd.setFloat32(0, value as double),
  );
  static ByteFormat double64 = ByteFormat(
    8,
    (ByteData bd, num value) => bd.setFloat64(0, value as double),
  );
  static ByteFormat int16 = ByteFormat(
    2,
    (ByteData bd, num value) => bd.setInt16(0, value as int),
  );
  static ByteFormat int32 = ByteFormat(
    4,
    (ByteData bd, num value) => bd.setInt32(0, value as int),
  );
  static ByteFormat int64 = ByteFormat(
    8,
    (ByteData bd, num value) => bd.setInt64(0, value as int),
  );
  static ByteFormat uint16 = ByteFormat(
    2,
    (ByteData bd, num value) => bd.setUint16(0, value as int),
  );
  static ByteFormat uint32 = ByteFormat(
    4,
    (ByteData bd, num value) => bd.setUint32(0, value as int),
  );
  static ByteFormat uint64 = ByteFormat(
    8,
    (ByteData bd, num value) => bd.setUint64(0, value as int),
  );

  final int numBytes;
  final void Function(ByteData, num) f;

  ByteFormat(this.numBytes, this.f);

  Bytes toBytes(num value) {
    ByteData bd = ByteData(numBytes);
    f(bd, value);
    return Bytes(Uint8List.sublistView(bd));
  }
}
