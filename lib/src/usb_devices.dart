// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libusb/libusb64.dart';

import 'usb_device.dart';
import 'usb_device_ext.dart';

/// Access to all USB devices, including UVC devices.
class UsbDevices {
  /// Creates access to all USB devices, including UVC devices.
  UsbDevices({required this.libusb});

  final Libusb libusb;

  /// Get all of the USB devices on this system, or just the UVC USB devices.
  List<UsbDevice> get({bool onlyUvcDevices = false}) =>
      _getDevices(onlyUvcDevices: onlyUvcDevices);

  /// Get all of the UVC devices on this system.
  List<UsbDevice> _getDevices({bool onlyUvcDevices = false}) {
    var deviceListPtr = calloc<Pointer<Pointer<libusb_device>>>();

    final numUsbDevices = libusb.libusb_get_device_list(nullptr, deviceListPtr);
    if (numUsbDevices < 0) {
      calloc.free(deviceListPtr);
      return [];
    }

    final deviceList = deviceListPtr.value;

    final listInternal = <UsbDevice>[];

    for (var devIdx = 0; devIdx < numUsbDevices; devIdx++) {
      final usbDevPtr = deviceList[devIdx];
      final usbDevice = UsbDeviceExt.fromDev(libusb, usbDevPtr);
      if (usbDevice == null) continue;
      if (!onlyUvcDevices || usbDevice.isUvc) {
        listInternal.add(usbDevice);
      }
    }

    calloc.free(deviceListPtr);
    libusb.libusb_free_device_list(deviceList, 1);

    return listInternal;
  }
}
