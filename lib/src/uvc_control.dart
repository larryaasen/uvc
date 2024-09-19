// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libusb/libusb64.dart';

import 'usb_configuration_descriptor_ext.dart';
import 'usb_device_ext.dart';
import 'usb_utils.dart';
import 'uvc_constants.dart';
import 'uvc_device.dart';

/// UVC request code (A.8)
enum UvcReqCode {
  undefined(0x00),

  setCurrent(0x01),

  /// Report the current value
  getCurrent(0x81),

  /// Report the minimum supported value
  getMin(0x82),

  /// Report the maximum supported value
  getMax(0x83),

  /// Report the resolution (step-size).
  getRes(0x84),

  /// Report the maximum length of the payload.
  getLen(0x85),

  /// ???
  getInfo(0x86),

  /// Report the default value
  getDef(0x87);

  final int value;
  const UvcReqCode(this.value);
}

/// Camera terminal control selector (A.9.4)
enum UvcCtCtrlSelector {
  controlUndefined(0x00),
  scanningModeControl(0x01),
  aeModeControl(0x02),
  aePriorityControl(0x03),
  exposureTimeAbsoluteControl(0x04),
  exposureTimeRelativeControl(0x05),
  focusAbsoluteControl(0x06),
  focusRelativeControl(0x07),
  focusAutoControl(0x08),
  irisAbsoluteControl(0x09),
  irisRelativeControl(0x0a),
  zoomAbsoluteControl(0x0b),
  zoomRelativeControl(0x0c),
  pantiltAbsoluteControl(0x0d),
  pantiltRelativeControl(0x0e),
  rollAbsoluteControl(0x0f),
  rollRelativeControl(0x10),
  privacyControl(0x11),
  focusSimpleControl(0x12),
  digitalWindowControl(0x13),
  regionOfInterestControl(0x14);

  final int value;
  const UvcCtCtrlSelector(this.value);
}

/// Processing unit control selector (A.9.5)
enum UvcPuControlSelector {
  undefined,
  backlightCompensation,
  brightness,
  contrast,
  gain,
  powerLineFrequency,
  hue,
  saturation,
  sharpness,
  gamma,
  whiteBalanceTemperature,
  whiteBalanceTemperatureAuto,
  whiteBalanceComponent,
  whiteBalanceComponentAuto,
  digitalMultiplier,
  digitalMultiplierLimit,
  hueAuto,
  analogVideoStandard,
  analogLockStatus,
  contrastAuto,
}

typedef UvcControlGetHandler = int? Function(
    Pointer<libusb_device_handle> handle,
    UvcReqCode reqCode,
    int bTerminalID,
    int bInterfaceNumber);

typedef UvcControlSetHandler = void Function(
    Pointer<libusb_device_handle> handle,
    UvcReqCode reqCode,
    int value,
    int bTerminalID,
    int bInterfaceNumber);

class UvcController {
  UvcController(
    this.handlePtr,
    this.getHandler,
    this.setHandler, {
    required this.bTerminalID,
    required this.bInterfaceNumber,
    required this.info,
    required this.name,
  });

  Pointer<libusb_device_handle>? handlePtr;
  final UvcControlGetHandler getHandler;
  final UvcControlSetHandler setHandler;
  final int bTerminalID;
  final int bInterfaceNumber;
  final uvc_device_info info;
  final String name;

  /// Get the control current value.
  int? get current =>
      _controlGet(UvcReqCode.getCurrent, bTerminalID, bInterfaceNumber);

  /// Set the control current value.
  set current(int? value) => _controlSet(UvcReqCode.setCurrent, value);

  /// Get the control default value.
  int? get defaultValue =>
      _controlGet(UvcReqCode.getDef, bTerminalID, bInterfaceNumber);

  /// Get the control info value.
  /// TODO: this does not work for `zoom absolute get`.
  int? get information =>
      _controlGet(UvcReqCode.getInfo, bTerminalID, bInterfaceNumber);

  /// Get the control length value.
  /// TODO: this does not work for `zoom absolute get`.
  int? get len => _controlGet(UvcReqCode.getLen, bTerminalID, bInterfaceNumber);

  /// Get the control maximum value.
  int? get max => _controlGet(UvcReqCode.getMax, bTerminalID, bInterfaceNumber);

  /// Get the control minimum value.
  int? get min => _controlGet(UvcReqCode.getMin, bTerminalID, bInterfaceNumber);

  /// Get the control resolution.
  int? get resolution =>
      _controlGet(UvcReqCode.getRes, bTerminalID, bInterfaceNumber);

  int? _controlGet(UvcReqCode reqCode, int bTerminalID, int bInterfaceNumber) {
    if (handlePtr == null) return null;
    final rv = getHandler(handlePtr!, reqCode, bTerminalID, bInterfaceNumber);
    return rv;
  }

  void _controlSet(UvcReqCode reqCode, int? value) {
    if (handlePtr == null || value == null) return;
    setHandler(handlePtr!, reqCode, value, bTerminalID, bInterfaceNumber);
    return;
  }
}

class UvcControl {
  UvcControl({
    required Libusb libusb,
    required Pointer<Pointer<libusb_context>>? contextPtr,
    required this.vendorId,
    required this.productId,
    this.debugLogging = false,
  })  : _libusb = libusb,
        _contextPtr = contextPtr;

  final Libusb _libusb;
  final Pointer<Pointer<libusb_context>>? _contextPtr;
  final int vendorId;
  final int productId;
  final bool debugLogging;

  Pointer<libusb_device_handle>? _handlePtr;
  final _info = uvc_device_info();

  /// Close this camera and release the resources.
  void dispose() {
    close();
  }

  bool isOpen() {
    final handlePtr = _open();
    return handlePtr != null;
  }

  /// Perform a USB port reset for a USB device. Returns true on success.
  bool resetDevice() {
    final handlePtr = _open();
    if (handlePtr == null) return false;

    // Perform an USB port reset for an usb device. Returns 0 on success, LIBUSB_ERROR_NOT_FOUND if
    // re-enumeration is required or if the device has been disconnected and a LIBUSB_ERROR code on failure.
    final ret = _libusb.libusb_reset_device(handlePtr);

    final success = ret == libusb_error.LIBUSB_SUCCESS;

    if (debugLogging) {
      if (success) {
        print('uvc: reset device vendorId: $vendorId, productId: $productId');
      } else {
        print(
            'uvc: reset device failed: $ret, vendorId: $vendorId, productId: $productId');
      }
    }

    if (success) {
      close();
    }
    return success;
  }

  UvcController _controller(String name, UvcControlGetHandler getHandler,
      UvcControlSetHandler setHandler,
      {required int vendorId, required int productId}) {
    final handlePtr = _open();

    int bInterfaceNumber = 0;
    int bTerminalID = 0;

    if (handlePtr != null) {
      bInterfaceNumber = _info.config?.interfaces.first.interfaceDescriptors
              .first.bInterfaceNumber ??
          0;
      bTerminalID = _info.ctrl_if?.input_term_descs?.bTerminalID ?? 0;
    }

    return UvcController(
      handlePtr,
      getHandler,
      setHandler,
      bTerminalID: bTerminalID,
      bInterfaceNumber: bInterfaceNumber,
      info: _info,
      name: name,
    );
  }

  Pointer<libusb_device_handle>? _open() {
    if (_handlePtr != null || _contextPtr == null) return _handlePtr;

    final handlePtr = _libusb.libusb_open_device_with_vid_pid(
        _contextPtr.value, vendorId, productId);
    if (handlePtr.address == 0) return null;

    if (debugLogging) {
      print('uvc: opened device vendorId: $vendorId, productId: $productId');
    }

    _handlePtr = handlePtr;

    final usbDevPtr = _libusb.libusb_get_device(handlePtr);

    final ret = _uvc_get_device_info(usbDevPtr, _info);
    if (ret != UVC_SUCCESS) {
      if (debugLogging) {
        print('uvc: UVCController._uvc_get_device_info failure: $ret');
      }
    }

    return _handlePtr;
  }

  /// Close this camera and release the resources.
  void close() {
    if (_handlePtr != null) {
      _libusb.libusb_close(_handlePtr!);
      _handlePtr = null;
      if (debugLogging) {
        print('uvc: closed device vendorId: $vendorId, productId: $productId');
      }
    }
  }

  int _uvc_get_device_info(
      Pointer<libusb_device> usbDevPtr, uvc_device_info info) {
    final usbDevice = UsbDeviceExt.fromDev(_libusb, usbDevPtr);

    if (usbDevice != null) {
      info.config = usbDevice.configurationDescriptor;

      final ifDesc = usbDevice
          .configurationDescriptor.interfaces.first.interfaceDescriptors.first;
      var buffer = ifDesc.extra;
      if (buffer != null) {
        var bufferLeft = ifDesc.extraLength;

        while (bufferLeft >= 3) {
          // parseX needs to see buf[0,2] = length,type
          final block_size = buffer![0];
          final parse_ret = UsbConfigurationDescriptorExt.uvc_parse_vc(
              usbDevPtr, info, buffer, block_size);

          if (parse_ret != UVC_SUCCESS) {
            return parse_ret;
          }

          bufferLeft -= block_size;
          // buffer += block_size;
          buffer = buffer.sublist(block_size);
        }
      }
    }

    return UVC_SUCCESS;
  }

  // ignore: unused_element
  int _unsupportedGet(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
          int bTerminalID, int bInterfaceNumber) =>
      throw UnsupportedError('uvc: Not implemented or supported yet: $reqCode');

  void _unsupportedSet(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
          int value, int bTerminalID, int bInterfaceNumber) =>
      throw UnsupportedError('uvc: Not implemented or supported yet: $reqCode');
}

extension UvcControlExt on UvcControl {
  /// Backlight compensation: 0: off or 1: on
  UvcController get backlightCompensation => _controller(
      'backlight compensation', _getBacklightCompensation, _unsupportedSet,
      vendorId: vendorId, productId: productId);

  /// Brightness
  UvcController get brightness =>
      _controller('brightness', _getBrightness, _setBrightness,
          vendorId: vendorId, productId: productId);

  /// Contrast
  UvcController get contrast =>
      _controller('contrast', _getContrast, _setContrast,
          vendorId: vendorId, productId: productId);

  /// Saturation
  UvcController get saturation =>
      _controller('saturation', _getSaturation, _setSaturation,
          vendorId: vendorId, productId: productId);

  /// Sharpness
  UvcController get sharpness =>
      _controller('sharpness', _getSharpness, _setSharpness,
          vendorId: vendorId, productId: productId);

  /// White Balance
  UvcController get whiteBalance =>
      _controller('white balance', _getWhiteBalance, _setWhiteBalance,
          vendorId: vendorId, productId: productId);

  /// Powerline frequency: 0: disabled: 1: 50 Hz, 2: 60 Hz: 3: automatic
  UvcController get powerlineFrequency => _controller(
      'powerline frequency', _getPowerlineFrequency, _unsupportedSet,
      vendorId: vendorId, productId: productId);

  /// The Focus control.
  UvcController get focus =>
      _controller('focus', _getFocusAbsolute, _setFocusAbsolute,
          vendorId: vendorId, productId: productId);

  /// Auto focus. A value of 1 means auto focus is on, and a value of 0 means it is off.
  UvcController get focusAuto =>
      _controller('auto focus', _getFocusAuto, _setFocusAuto,
          vendorId: vendorId, productId: productId);

  /// The Pan control.
  UvcController get pan => _controller('pan', _getPanAbsolute, _setPanAbsolute,
      vendorId: vendorId, productId: productId);

  /// The Tilt control.
  UvcController get tilt =>
      _controller('tilt', _getTiltAbsolute, _setTiltAbsolute,
          vendorId: vendorId, productId: productId);

  /// The Zoom absolute control.
  UvcController get zoom =>
      _controller('zoom', _getZoomAbsolute, _setZoomAbsolute,
          vendorId: vendorId, productId: productId);

  /// The Zoom relative control.
  UvcController get zoomRelative =>
      _controller('zoom relative', _getZoomRelative, _unsupportedSet,
          vendorId: vendorId, productId: productId);

  /// Sets the TILT ABSOLUTE control.
  /// UVC request code (A.8)
  void _setTiltAbsolute(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 8;
    final data = calloc<Uint8>(dataLength);

    // First, get the pan value since pan/tilt have to be set together.
    final pan = _getPanAbsolute(
        handle, UvcReqCode.getCurrent, bTerminalID, bInterfaceNumber);
    final tilt = value;

    INT_TO_DW(pan, data + 0);
    INT_TO_DW(tilt, data + 4);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcCtCtrlSelector.pantiltAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) {
      return;
    }

    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _setTiltAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _setTiltAbsolute error: ${fromInt8ToString(err)}');
  }

  /// Reads the backlight compensation control.
  int _getBacklightCompensation(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcPuControlSelector.backlightCompensation.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    final msg =
        'uvc: _getBacklightCompensation error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Reads the BRIGHTNESS control.
  int _getBrightness(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcPuControlSelector.brightness.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _getBrightness error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Sets the BRIGHTNESS control.
  void _setBrightness(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    SHORT_TO_SW(value, data);
    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcPuControlSelector.brightness.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) return;

    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _setBrightness error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Reads the BRIGHTNESS control.
  int _getContrast(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcPuControlSelector.contrast.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _getContrast error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Sets the CONTRAST control.
  void _setContrast(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    SHORT_TO_SW(value, data);
    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcPuControlSelector.contrast.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) return;

    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _setContrast error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Reads the SATURATION control.
  int _getSaturation(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcPuControlSelector.saturation.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _getSaturation error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Sets the SATURATION control.
  void _setSaturation(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    SHORT_TO_SW(value, data);
    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcPuControlSelector.saturation.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) return;

    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _setSaturation error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Reads the SHARPNESS control.
  int _getSharpness(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcPuControlSelector.sharpness.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _getSharpness error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Sets the SHARPNESS control.
  void _setSharpness(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    SHORT_TO_SW(value, data);
    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcPuControlSelector.sharpness.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) return;

    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _setSharpness error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Reads the WHITE BALANCE control.
  int _getWhiteBalance(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcPuControlSelector.whiteBalanceTemperature.index << 8)
            .toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _getWhiteBalance error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Sets the WHITE BALANCE control.
  void _setWhiteBalance(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    SHORT_TO_SW(value, data);
    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcPuControlSelector.whiteBalanceTemperature.index << 8)
            .toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) return;

    final err = _libusb.libusb_strerror(ret);
    final msg = 'uvc: _setWhiteBalance error: ${fromInt8ToString(err)}';
    if (debugLogging) print(msg);
    throw Exception(msg);
  }

  /// Reads the powerline frequency control.
  int _getPowerlineFrequency(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 1;
    final data = calloc<Uint8>(dataLength);

    final bUnitID = _info.ctrl_if?.processing_unit_descs.first.bUnitID ?? 0;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcPuControlSelector.powerLineFrequency.index << 8).toUnsigned(16),
        (bUnitID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = data[0];
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _getPowerlineFrequency error: ${fromInt8ToString(err)}');
    }
    throw Exception(
        'uvc: _getPowerlineFrequency error: ${fromInt8ToString(err)}');
  }

  /// Reads the FOCUS ABSOLUTE control.
  int _getFocusAbsolute(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcCtCtrlSelector.focusAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _getFocusAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _getFocusAbsolute error: ${fromInt8ToString(err)}');
  }

  /// Sets the FOCUS ABSOLUTE control.
  /// UVC request code (A.8)
  void _setFocusAbsolute(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int value, int bTerminalID, int bInterfaceNumber) {
    // The focus update can only be made when auto focus is true.
    final focusAuto =
        _getFocusAuto(handle, reqCode, bTerminalID, bInterfaceNumber);
    if (focusAuto == 1) return;

    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    SHORT_TO_SW(value, data);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcCtCtrlSelector.focusAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) {
      return;
    }

    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _setFocusAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _setFocusAbsolute error: ${fromInt8ToString(err)}');
  }

  /// Reads the FOCUS AUTO control.
  int _getFocusAuto(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 1;
    final data = calloc<Uint8>(dataLength);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcCtCtrlSelector.focusAutoControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final value = data[0];
      calloc.free(data);
      return value;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _getFocusAuto error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _getFocusAuto error: ${fromInt8ToString(err)}');
  }

  /// Sets the FOCUS AUTO control.
  /// UVC request code (A.8)
  void _setFocusAuto(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 1;
    final data = calloc<Uint8>(dataLength);
    data[0] = value;

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcCtCtrlSelector.focusAutoControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) {
      return;
    }

    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _setFocusAuto error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _setFocusAuto error: ${fromInt8ToString(err)}');
  }

  /// Sets the ZOOM ABSOLUTE control.
  /// UVC request code (A.8)
  void _setZoomAbsolute(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    SHORT_TO_SW(value, data);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcCtCtrlSelector.zoomAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) {
      return;
    }

    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _setZoomAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _setZoomAbsolute error: ${fromInt8ToString(err)}');
  }

  /// Reads the ZOOM ABSOLUTE control.
  /// UVC request code (A.8)
  int? _getZoomAbsolute(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 2;
    final data = calloc<Uint8>(dataLength);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcCtCtrlSelector.zoomAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final focalLength = swToShort(data.asTypedList(dataLength));
      calloc.free(data);
      return focalLength;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _getZoomAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _getZoomAbsolute error: ${fromInt8ToString(err)}');
  }

  /// Reads the ZOOM RELATIVE control.
  /// UVC request code (A.8)
  int? _getZoomRelative(Pointer<libusb_device_handle> handle,
      UvcReqCode reqCode, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 3;
    final data = calloc<Uint8>(dataLength);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcCtCtrlSelector.zoomRelativeControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final zoom_rel = data[0];
      // final digital_zoom = data[1];
      // final speed = data[2];
      calloc.free(data);
      return zoom_rel;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _getZoomRelative error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _getZoomRelative error: ${fromInt8ToString(err)}');
  }

  /// Reads the PANTILT ABSOLUTE control and returns the pan value.
  int _getPanAbsolute(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 8;
    final data = calloc<Uint8>(dataLength);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcCtCtrlSelector.pantiltAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final dataList = data.asTypedList(dataLength);
      final pan = dwToInt(dataList, 0);
      calloc.free(data);
      return pan;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _getPanAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _getPanAbsolute error: ${fromInt8ToString(err)}');
  }

  /// Reads the PANTILT ABSOLUTE control and returns the tilt value.
  int _getTiltAbsolute(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int bTerminalID, int bInterfaceNumber) {
    const dataLength = 8;
    final data = calloc<Uint8>(dataLength);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_GET,
        reqCode.value,
        (UvcCtCtrlSelector.pantiltAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);
    if (ret == dataLength) {
      final dataList = data.asTypedList(dataLength);
      final tilt = dwToInt(dataList, 4);
      calloc.free(data);
      return tilt;
    }

    calloc.free(data);
    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _getTiltAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _getTiltAbsolute error: ${fromInt8ToString(err)}');
  }

  /// Sets the PAN ABSOLUTE control.
  /// UVC request code (A.8)
  void _setPanAbsolute(Pointer<libusb_device_handle> handle, UvcReqCode reqCode,
      int value, int bTerminalID, int bInterfaceNumber) {
    const dataLength = 8;
    final data = calloc<Uint8>(dataLength);

    // First, get the tilt value since pan/tilt have to be set together.
    final tilt = _getTiltAbsolute(
        handle, UvcReqCode.getCurrent, bTerminalID, bInterfaceNumber);
    final pan = value;

    INT_TO_DW(pan, data + 0);
    INT_TO_DW(tilt, data + 4);

    final ret = _libusb.libusb_control_transfer(
        handle,
        REQ_TYPE_SET,
        reqCode.value,
        (UvcCtCtrlSelector.pantiltAbsoluteControl.value << 8).toUnsigned(16),
        (bTerminalID << 8 | bInterfaceNumber).toUnsigned(16),
        data,
        dataLength,
        0);

    calloc.free(data);
    if (ret == dataLength) {
      return;
    }

    final err = _libusb.libusb_strerror(ret);
    if (debugLogging) {
      print('uvc: _setPanAbsolute error: ${fromInt8ToString(err)}');
    }
    throw Exception('uvc: _setPanAbsolute error: ${fromInt8ToString(err)}');
  }
}
