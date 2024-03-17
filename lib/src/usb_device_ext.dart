// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:ffi';

import 'package:convert/convert.dart';
import 'package:ffi/ffi.dart';
import 'package:libusb/libusb64.dart';

import 'usb_configuration_descriptor_ext.dart';
import 'usb_device.dart';
import 'usb_device_descriptor_ext.dart';

extension UsbDeviceExt on UsbDevice {
  /// Example: UsbDeviceExt.fromDev();
  static UsbDevice? fromDev(Libusb libusb, Pointer<libusb_device> usbDevPtr) {
    final busNumber = libusb.libusb_get_bus_number(usbDevPtr);
    final deviceAddress = libusb.libusb_get_device_address(usbDevPtr);
    final path = _getPath(libusb, usbDevPtr);
    final speed = _getDeviceSpeed(libusb, usbDevPtr);

    final deviceDescriptor = UsbDeviceDescriptorExt.fromDev(libusb, usbDevPtr);
    final configurationDescriptor =
        UsbConfigurationDescriptorExt.fromDev(libusb, usbDevPtr);
    if (deviceDescriptor == null || configurationDescriptor == null) {
      return null;
    }

    // Find the USB devices that are UVC.
    final uvc = isUvc(deviceDescriptor, configurationDescriptor);

    final usbDevice = UsbDevice(
      busNumber: busNumber,
      deviceAddress: deviceAddress,
      path: path,
      speed: speed,
      deviceDescriptor: deviceDescriptor,
      configurationDescriptor: configurationDescriptor,
      isUvc: uvc,
    );
    return usbDevice;
  }

  static UsbSpeed _getDeviceSpeed(
      Libusb libusb, Pointer<libusb_device> usbDevPtr) {
    final index = libusb.libusb_get_device_speed(usbDevPtr);
    return UsbSpeed.values[index];
  }

  static String? _getPath(Libusb libusb, Pointer<libusb_device> usbDevPtr) {
    String? path;
    final pathPtr = calloc<Uint8>(8);
    final portCount = libusb.libusb_get_port_numbers(usbDevPtr, pathPtr, 8);
    if (portCount > 0) {
      final hexList =
          pathPtr.asTypedList(portCount).map((e) => hex.encode([e])).toList();
      path = hexList.join('.');
    }
    calloc.free(pathPtr);
    return path;
  }

  static bool isUvc(UsbDeviceDescriptor deviceDescriptor,
      UsbConfigDescriptor configurationDescriptor) {
    // Skip TIS cameras that definitely aren't UVC even though they might look that way
    if (0x199e == deviceDescriptor.vendorId &&
        deviceDescriptor.productId >= 0x8201 &&
        deviceDescriptor.productId <= 0x8208) {
      return false;
    }

    var gotInterface = false;

    for (final interface in configurationDescriptor.interfaces) {
      for (final interfaceDescriptor in interface.interfaceDescriptors) {
        // Special case for Imaging Source cameras
        /* Video, Streaming */
        if (0x199e == deviceDescriptor.vendorId &&
            (0x8101 == deviceDescriptor.productId ||
                0x8102 == deviceDescriptor.productId) &&
            interfaceDescriptor.bInterfaceClass == 255 &&
            interfaceDescriptor.bInterfaceSubClass == 2) {
          gotInterface = true;
        }
        /* Video, Streaming */
        else if (interfaceDescriptor.bInterfaceClass == 14 &&
            interfaceDescriptor.bInterfaceSubClass == 2) {
          gotInterface = true;
        }
        if (gotInterface) break;
      }
      if (gotInterface) break;
    }
    return gotInterface;
  }
}
