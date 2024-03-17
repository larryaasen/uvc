// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:typed_data';

import 'package:libusb/libusb64.dart';

/// USB Speed codes. Indicates the speed at which the device is operating.
enum UsbSpeed {
  /// The OS doesn't report or know the device speed.
  unknown,

  /// The device is operating at low speed (1.5MBit/s).
  low,

  /// The device is operating at full speed (12MBit/s).
  full,

  /// The device is operating at high speed (480MBit/s).
  high,

  // The device is operating at super speed (5000MBit/s).
  superNormal,

  /// The device is operating at super speed plus (10000MBit/s).
  superPlus,
}

extension UsbSpeedExt on UsbSpeed {
  String get description {
    try {
      switch (this) {
        case UsbSpeed.unknown:
          return 'Unknown';
        case UsbSpeed.low:
          return '1.5M';
        case UsbSpeed.full:
          return '12M';
        case UsbSpeed.high:
          return '480M';
        case UsbSpeed.superNormal:
          return '5G';
        case UsbSpeed.superPlus:
          return '10G';
      }
    } catch (e) {
      print('UsbSpeedExt.description exception: $e');
      return 'Unknown';
    }
  }
}

/// A USB compliant device.
class UsbDevice {
  /// Creates a USB compliant device.
  UsbDevice({
    required this.busNumber,
    required this.deviceAddress,
    required this.path,
    required this.speed,
    required this.deviceDescriptor,
    required this.configurationDescriptor,
    this.isUvc = false,
  });

  /// Returns the number of the bus.
  final int busNumber;

  /// Returns the device address.
  final int deviceAddress;

  /// All of the port numbers from root.
  final String? path;

  /// Get the negotiated connection speed for a device.
  final UsbSpeed speed;

  final UsbDeviceDescriptor deviceDescriptor;

  final UsbConfigDescriptor configurationDescriptor;

  /// Is this a UVC device?
  final bool isUvc;

  @override
  String toString() {
    return 'vendorId: ${deviceDescriptor.vendorId.toHexAbbr}, '
        'productId: ${deviceDescriptor.productId.toHexAbbr}, '
        '${deviceDescriptor.manufacturerName} - ${deviceDescriptor.productName} path: $path, '
        'speed: $speed(${speed.description}), isUvc: $isUvc';
  }
}

/// The standard USB device descriptor.
class UsbDeviceDescriptor {
  /// Creates the standard USB device descriptor.
  UsbDeviceDescriptor({
    required this.length,
    required this.descriptorType,
    required this.bcdUSB,
    required this.deviceClass,
    required this.deviceSubClass,
    required this.deviceProtocol,
    required this.maxPacketSize0,
    required this.vendorId,
    required this.productId,
    required this.bcdDevice,
    required this.manufacturer,
    required this.product,
    required this.serialNumber,
    required this.numConfigurations,
    this.manufacturerName,
    this.productName,
    this.serialNumberName,
  });

  /// Size of this descriptor (in bytes)
  final int length;

  /// Descriptor type. Will have value
  /// \ref libusb_descriptor_type::LIBUSB_DT_DEVICE LIBUSB_DT_DEVICE in this
  /// context.
  final int descriptorType;

  /// USB specification release number in binary-coded decimal. A value of
  /// 0x0200 indicates USB 2.0, 0x0110 indicates USB 1.1, etc.
  final int bcdUSB;

  /// USB-IF class code for the device. See \ref libusb_class_code.
  final int deviceClass;

  /// USB-IF subclass code for the device, qualified by the bDeviceClass
  /// value
  final int deviceSubClass;

  /// USB-IF protocol code for the device, qualified by the bDeviceClass and
  /// bDeviceSubClass values
  final int deviceProtocol;

  /// Maximum packet size for endpoint 0
  final int maxPacketSize0;

  /// USB-IF vendor ID
  final int vendorId;

  /// USB-IF product ID
  final int productId;

  /// Device release number in binary-coded decimal
  final int bcdDevice;

  /// Index of string descriptor describing manufacturer
  final int manufacturer;

  /// Index of string descriptor describing product
  final int product;

  /// Index of string descriptor containing device serial number
  final int serialNumber;

  /// Number of possible configurations
  final int numConfigurations;

  String? manufacturerName;
  String? productName;
  String? serialNumberName;

  String toHex(int value) => value.toRadixString(16).padLeft(4, '0');
}

/// The standard USB configuration descriptor.
class UsbConfigDescriptor {
  /// Creates the standard USB configuration descriptor.
  UsbConfigDescriptor({required this.interfaces});

  final List<UsbInterface> interfaces;

  // libusb_interface_descriptor? if_desc;
}

class UsbInterface {
  UsbInterface({required this.interfaceDescriptors});

  final List<UsbInterfaceDescriptor> interfaceDescriptors;
}

/// The standard USB interface descriptor.
class UsbInterfaceDescriptor {
  /// Creates the standard USB interface descriptor.

  UsbInterfaceDescriptor({
    required this.bLength,
    required this.bDescriptorType,
    required this.bInterfaceNumber,
    required this.bAlternateSetting,
    required this.bNumEndpoints,
    required this.bInterfaceClass,
    required this.bInterfaceSubClass,
    required this.bInterfaceProtocol,
    required this.iInterface,
    required this.endpoint,
    this.extra,
  });

  /// Size of this descriptor (in bytes)
  final int bLength;

  /// Descriptor type. Will have value
  /// libusb_descriptor_type::LIBUSB_DT_INTERFACE LIBUSB_DT_INTERFACE
  /// in this context.
  final int bDescriptorType;

  /// Number of this interface
  final int bInterfaceNumber;

  /// Value used to select this alternate setting for this interface
  final int bAlternateSetting;

  /// Number of endpoints used by this interface (excluding the control
  /// endpoint).
  final int bNumEndpoints;

  /// USB-IF class code for this interface. See \ref libusb_class_code.
  final int bInterfaceClass;

  /// USB-IF subclass code for this interface, qualified by the
  /// bInterfaceClass value
  final int bInterfaceSubClass;

  /// USB-IF protocol code for this interface, qualified by the
  /// bInterfaceClass and bInterfaceSubClass values
  final int bInterfaceProtocol;

  /// Index of string descriptor describing this interface
  final int iInterface;

  /// Array of endpoint descriptors. This length of this array is determined
  /// by the bNumEndpoints field.
  final List<UsbEndpointDescriptor> endpoint;

  /// Extra descriptors. If libusb encounters unknown interface descriptors,
  /// it will store them here, should you wish to parse them.
  final Uint8List? extra;

  /// Length of the extra descriptors, in bytes. Must be non-negative.
  int get extraLength => extra?.length ?? 0;
}

/// The standard USB interface descriptor.
class UsbEndpointDescriptor {
  UsbEndpointDescriptor({
    required this.bLength,
    required this.bDescriptorType,
    required this.bEndpointAddress,
    required this.bmAttributes,
    required this.wMaxPacketSize,
    required this.bInterval,
    required this.bRefresh,
    required this.bSynchAddress,
    required this.extra,
    required this.extraLength,
  });

  /// Size of this descriptor (in bytes)
  int bLength;

  /// Descriptor type. Will have value
  /// [libusb_descriptor_type.LIBUSB_DT_ENDPOINT] in this context.
  int bDescriptorType;

  /// The address of the endpoint described by this descriptor. Bits 0:3 are
  /// the endpoint number. Bits 4:6 are reserved. Bit 7 indicates direction,
  /// see [libusb_endpoint_direction].
  int bEndpointAddress;

  /// Attributes which apply to the endpoint when it is configured using
  /// the bConfigurationValue. Bits 0:1 determine the transfer type and
  /// correspond to [libusb_endpoint_transfer_type]. Bits 2:3 are only used
  /// for isochronous endpoints and correspond to [libusb_iso_sync_type].
  /// Bits 4:5 are also only used for isochronous endpoints and correspond to
  /// [libusb_iso_usage_type]. Bits 6:7 are reserved.
  int bmAttributes;

  /// Maximum packet size this endpoint is capable of sending/receiving.
  int wMaxPacketSize;

  /// Interval for polling endpoint for data transfers.
  int bInterval;

  /// For audio devices only: the rate at which synchronization feedback
  /// is provided.
  int bRefresh;

  /// For audio devices only: the address if the synch endpoint
  int bSynchAddress;

  /// Extra descriptors. If libusb encounters unknown endpoint descriptors,
  /// it will store them here, should you wish to parse them.
  Uint8List? extra;

  /// Length of the extra descriptors, in bytes. Must be non-negative.
  int extraLength;
}

extension IntExt on int {
  String get toHexAbbr =>
      '0x${toRadixString(16).padLeft(4, '0').toUpperCase()}';
}
