// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:libusb/libusb64.dart';

import 'usb_devices.dart';
import 'usb_string_descriptor.dart';
import 'uvc_control.dart';

/// A library for controlling UVC compliant webcams.
class UvcLib {
  /// Loads the library for controlling UVC compliant webcams.
  UvcLib(
      {String? libraryName,
      bool debugLogging = false,
      bool debugLoggingLibUsb = false}) {
    if (_libusb == null) {
      _libusb = Libusb(_loadLibrary(libraryName: libraryName));

      final contextPtr = calloc<Pointer<libusb_context>>();
      final initResult = _libusb!.libusb_init(contextPtr);
      if (initResult < 0 || contextPtr.address == 0) {
        if (debugLogging) {
          print('uvc: libusb library not initialized successfully');
        }
        _libusb!.libusb_exit(contextPtr.value);
        calloc.free(contextPtr);
        _libusb = null;
        return;
      }

      if (debugLogging) {
        print('uvc: libusb library initialized successfully');
      }

      _contextPtr = contextPtr;

      if (debugLoggingLibUsb) {
        libusb.libusb_set_debug(
            nullptr, libusb_log_level.LIBUSB_LOG_LEVEL_DEBUG);
      }

      if (_libusb != null) {
        _devices = UsbDevices(libusb: _libusb!);
      }
    }
  }

  static Libusb? _libusb;
  Libusb get libusb => _libusb!;

  static Pointer<Pointer<libusb_context>>? _contextPtr;
  late UsbDevices _devices;

  /// Access to all USB devices, including UVC devices.
  UsbDevices get devices => _devices;

  /// Release all resources used by this library including the libusb library.
  void dispose() {
    if (_contextPtr != null) {
      libusb.libusb_exit(_contextPtr!.value);
      _libusb = null;

      calloc.free(_contextPtr!);
      _contextPtr = null;
    }
    UsbStringDescriptor.dispose();
  }

  /// Is the libusb library loaded?
  bool get isLibraryLoaded => _libusb != null;

  /// Create a camera control for a `vendorId` and `productId`.
  UvcControl control({required int vendorId, required int productId}) =>
      UvcControl(
          libusb: libusb,
          contextPtr: _contextPtr,
          vendorId: vendorId,
          productId: productId);

  DynamicLibrary _loadLibrary({String? libraryName}) {
    try {
      String fullPath;
      if (libraryName != null && libraryName.isNotEmpty) {
        fullPath = libraryName;
      } else {
        final libraryPath = Directory.current.path;
        if (Platform.isMacOS) {
          fullPath = '$libraryPath/libusb-1.0.27/libusb-1.0.0.dylib';
        } else if (Platform.isWindows) {
          fullPath = '$libraryPath/libusb-1.0.27/libusb-1.0.dll';
        } else if (Platform.isLinux) {
          fullPath = '$libraryPath/libusb-1.0.27/libusb-1.0.so';
        } else {
          throw UnsupportedError('This platform is not supported.');
        }
      }
      print('uvc: Opening library: $fullPath');
      return DynamicLibrary.open(fullPath);
    } catch (e) {
      print('uvc: loadLibrary exception: $e');
      throw 'uvc: libusb dynamic library not found: $e';
    }
  }
}
