// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libusb/libusb64.dart';

import 'usb_utils.dart';

class UsbStringDescriptor {
  static const dataBufferLength = 256;
  static Pointer<Uint8>? dataBuffer;

  static String? getString(Libusb libusb, Pointer<libusb_device_handle> handle,
      int descriptorIndex) {
    if (handle.address == 0) return null;
    dataBuffer ??= calloc<Uint8>(dataBufferLength);

    final len = libusb.libusb_get_string_descriptor_ascii(
        handle, descriptorIndex, dataBuffer!, dataBufferLength);

    String? value;
    if (len > 0) value = fromUint8ToString(dataBuffer!);

    return value;
  }

  static void dispose() {
    if (dataBuffer != null) calloc.free(dataBuffer!);
    dataBuffer = null;
  }
}
