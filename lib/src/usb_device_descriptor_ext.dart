// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libusb/libusb64.dart';

import 'usb_device.dart';
import 'usb_string_descriptor.dart';

extension UsbDeviceDescriptorExt on UsbDeviceDescriptor {
  static UsbDeviceDescriptor? fromDev(
      Libusb libusb, Pointer<libusb_device> usbDevPtr) {
    final descPtr = calloc<libusb_device_descriptor>();
    if (libusb.libusb_get_device_descriptor(usbDevPtr, descPtr) !=
        libusb_error.LIBUSB_SUCCESS) return null;

    final devDesc = descPtr.ref;

    String? manufacturer;
    String? product;
    String? serialNumber;

    final handlePtr = calloc<Pointer<libusb_device_handle>>();
    if (libusb.libusb_open(usbDevPtr, handlePtr) ==
        libusb_error.LIBUSB_SUCCESS) {
      // print('uvc: opened device');

      final handle = handlePtr.value;

      manufacturer =
          UsbStringDescriptor.getString(libusb, handle, devDesc.iManufacturer);
      product = UsbStringDescriptor.getString(libusb, handle, devDesc.iProduct);
      serialNumber =
          UsbStringDescriptor.getString(libusb, handle, devDesc.iSerialNumber);

      libusb.libusb_close(handle);
      calloc.free(handlePtr);

      // print('uvc: closed device');
    }

    final desc = UsbDeviceDescriptor(
      length: devDesc.bLength,
      descriptorType: devDesc.bDescriptorType,
      bcdUSB: devDesc.bcdUSB,
      deviceClass: devDesc.bDeviceClass,
      deviceSubClass: devDesc.bDeviceSubClass,
      deviceProtocol: devDesc.bDeviceProtocol,
      maxPacketSize0: devDesc.bMaxPacketSize0,
      vendorId: devDesc.idVendor,
      productId: devDesc.idProduct,
      bcdDevice: devDesc.bcdDevice,
      manufacturer: devDesc.iManufacturer,
      product: devDesc.iProduct,
      serialNumber: devDesc.iSerialNumber,
      numConfigurations: devDesc.bNumConfigurations,
      manufacturerName: manufacturer,
      productName: product,
      serialNumberName: serialNumber,
    );
    calloc.free(descPtr);
    return desc;
  }
}
