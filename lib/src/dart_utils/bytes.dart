import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sized_ints/sized_ints.dart';
import 'comparable_operators.dart';

class Bytes with ComparableOperators<Bytes> {
  List<Uint8> wrapped;

  Bytes(this.wrapped);

  factory Bytes.ofLength(int size) => Bytes(List.generate(size, (_) => Uint8.zero));

  @override
  int compareTo(Bytes other) {
    for (int i = 0; i < math.min(length, other.length); i++) {
      if (wrapped[i] < other.wrapped[i]) {
        return -1;
      } else if (wrapped[i] > other.wrapped[i]) {
        return 1;
      }
    }
    if (wrapped.length < other.wrapped.length) {
      return -1;
    } else if (wrapped.length > other.wrapped.length) {
      return 1;
    } else {
      return 0;
    }
  }

  int operator [](int i) => wrapped[i].toSafeInt();

  int get length => wrapped.length;

  bool get isEmpty => wrapped.isEmpty;
  bool get isNotEmpty => wrapped.isNotEmpty;

  Bytes slice(final int start, [final int? end]) {
    int realStart = start < 0 ? length - start : start;
    int realEnd = end ?? length;
    realEnd = realEnd < 0 ? length - realEnd : realEnd;
    realEnd = realEnd > length ? length : realEnd;
    return Bytes(wrapped.sublist(realStart, realEnd));
  }

  int get max => wrapped.reduce((acc, elt) => acc >= elt ? acc : elt).toSafeInt();

  void addAll(Bytes other) {
    wrapped = List<Uint8>.from([...wrapped, ...other.wrapped]);
  }

  String get digest => sha1.convert(wrapped.toIntList()).toString();

  Future<void> writeTo(File f) async {
    f.writeAsBytes(wrapped.toIntList(), flush: true);
  }

  bool any(bool Function(int) test) => wrapped.toIntList().any(test);

  static Bytes generate(int length, int Function(int) gen) {
    return Bytes(List<Uint8>.generate(length, (i) => Uint8.fromInt(gen(i))));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Bytes && compareTo(other) == 0;

  @override
  int get hashCode => wrapped.hashCode;

  ByteData get _byteData => Uint8List.fromList(wrapped.toIntList()).buffer.asByteData();

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
      Bytes(List<Uint8>.from([... wrapped, ...other.wrapped]));

  @override
  String toString() => wrapped.toString();
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
    return Bytes(List<Uint8>.from(bd.buffer.asUint8List()));
  }
}

extension ToIntList on List<Uint8> {
  List<int> toIntList() => map((e) => e.toSafeInt()).toList();
}
