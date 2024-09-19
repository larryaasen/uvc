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
  UvcLib({
    String? libraryName,
    this.debugLogging = false,
    this.debugLoggingLibUsb = false,
  }) {
    if (_libusb == null) {
      final lib = _loadLibrary(libraryName: libraryName);
      _lib = lib;
      _libusb = Libusb(lib);

      final contextPtr = calloc<Pointer<libusb_context>>();
      final initResult = _libusb!.libusb_init(contextPtr);
      if (initResult < 0 || contextPtr.address == 0) {
        if (debugLogging) {
          print('uvc: libusb library not initialized successfully');
        }
        _libusb!.libusb_exit(contextPtr.value);
        calloc.free(contextPtr);
        _libusb = null;

        _lib?.close();
        _lib = null;
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
    }
  }

  final bool debugLogging;
  final bool debugLoggingLibUsb;

  DynamicLibrary? _lib;
  static Libusb? _libusb;
  Libusb get libusb => _libusb!;

  static Pointer<Pointer<libusb_context>>? _contextPtr;

  /// Access to all USB devices, including UVC devices.
  UsbDevices get devices {
    return UsbDevices(libusb: _libusb);
  }

  /// Release all resources used by this library including the libusb library.
  void dispose() {
    if (_contextPtr != null) {
      libusb.libusb_exit(_contextPtr!.value);
      _libusb = null;

      calloc.free(_contextPtr!);
      _contextPtr = null;
      if (debugLogging) {
        print('uvc: libusb library deinitialized');
      }

      _lib?.close();
      _lib = null;
      if (debugLogging) {
        print('uvc: library closed');
      }
    }
    UsbStringDescriptor.dispose();
  }

  /// Is the libusb library loaded?
  bool get isLibraryLoaded => _libusb != null;

  /// Create a camera control for a `vendorId` and `productId`.
  /// Remember to release the camera with `close` when you are done using it.
  UvcControl control({required int vendorId, required int productId}) =>
      UvcControl(
        libusb: libusb,
        contextPtr: _contextPtr,
        vendorId: vendorId,
        productId: productId,
        debugLogging: debugLogging,
      );

  DynamicLibrary _loadLibrary({String? libraryName}) {
    try {
      String fullPath;
      if (libraryName != null && libraryName.isNotEmpty) {
        fullPath = libraryName;
      } else {
        final libraryPath = Directory.current.path;
        if (Platform.isMacOS) {
          final result = Process.runSync('uname', ['-m']);
          final isArm = result.stdout.toString().contains('arm64');
          final libName = 'libusb-1.0.0-${isArm ? 'arm' : 'intel'}';
          fullPath = '$libraryPath/libusb-1.0.27/$libName.dylib';
        } else if (Platform.isWindows) {
          fullPath = '$libraryPath/libusb-1.0.27/libusb-1.0.dll';
        } else if (Platform.isLinux) {
          fullPath = '$libraryPath/libusb-1.0.27/libusb-1.0.so';
        } else {
          throw UnsupportedError('This platform is not supported.');
        }
      }
      if (debugLogging) {
        print('uvc: opening library: $fullPath');
      }
      final lib = DynamicLibrary.open(fullPath);
      return lib;
    } catch (e) {
      if (debugLogging) {
        print('uvc: loadLibrary exception: $e');
      }
      throw 'uvc: libusb dynamic library not found: $e';
    }
  }
}
