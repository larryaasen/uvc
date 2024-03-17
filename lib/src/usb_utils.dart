// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

String? fromUint8ToString(Pointer<Uint8> pointer) {
  return pointer.address == 0 ? null : pointer.cast<Utf8>().toDartString();
}

String? fromInt8ToString(Pointer<Int8> pointer) {
  return pointer.address == 0 ? null : pointer.cast<Utf8>().toDartString();
}

/// Converts an int16 into an unaligned two-byte little-endian integer
void SHORT_TO_SW(int s, Pointer<Uint8> p) {
  p[0] = s;
  p[1] = s >> 8;
}

/// Converts an int32 into an unaligned four-byte little-endian integer
void INT_TO_DW(int s, Pointer<Uint8> p) {
  p[0] = s;
  p[1] = s >> 8;
  p[2] = s >> 16;
  p[3] = s >> 24;
}

/// Converts an unaligned two-byte little-endian integer into an int16.
int SW_TO_SHORT(Uint8List data) => swToShort(data);

/// Converts an unaligned two-byte little-endian integer into an int16.
int swToShort(Uint8List data, [int startIndex = 0]) {
  if (data.length < (startIndex + 2)) {
    throw ArgumentError('Input list must contain at least 2 elements');
  }
  return ((data[startIndex + 0]) | (data[startIndex + 1] << 8)).toSigned(16);
}

/// Converts an unaligned four-byte little-endian integer into an int32
int dwToInt(Uint8List data, [int startIndex = 0]) {
  if (data.length < (startIndex + 4)) {
    throw ArgumentError('Input list must contain at least 4 elements');
  }
  return (data[startIndex + 0] |
          (data[startIndex + 1] << 8) |
          (data[startIndex + 2] << 16) |
          (data[startIndex + 3] << 24))
      .toSigned(32);
}
