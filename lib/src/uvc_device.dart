// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'usb_device.dart';

class uvc_device_info {
  /// Configuration descriptor for USB device
  UsbConfigDescriptor? config;

  /// VideoControl interface provided by device
  uvc_control_interface? ctrl_if;

  /// VideoStreaming interfaces on the device
  List<uvc_streaming_interface> stream_ifs = [];
}

/// Format descriptor
///
/// A "format" determines a stream's image type (e.g., raw YUYV or JPEG)
/// and includes many "frame" configurations.
class uvc_format_desc {}

/// VideoStream interface
class uvc_streaming_interface {
  uvc_device_info? parent;
  uvc_streaming_interface? prev, next;

  /// Interface number
  int? bInterfaceNumber;

  /// Video formats that this interface provides
  uvc_format_desc? format_descs;

  /// USB endpoint to use when communicating with this interface
  int? bEndpointAddress;
  int? bTerminalLink;
  int? bStillCaptureMethod;
}

/// Representation of the interface that brings data into the UVC device
class uvc_input_terminal {
  uvc_input_terminal({
    required this.bTerminalID,
    required this.wTerminalType,
    required this.wObjectiveFocalLengthMin,
    required this.wObjectiveFocalLengthMax,
    required this.wOcularFocalLength,
    required this.bmControls,
  });

  /// Index of the terminal within the device
  int bTerminalID;

  /// Type of terminal (e.g., camera)
  int wTerminalType;

  int wObjectiveFocalLengthMin;
  int wObjectiveFocalLengthMax;
  int wOcularFocalLength;

  /// Camera controls (meaning of bits given in {uvc_ct_ctrl_selector})
  int bmControls;
}

/// VideoControl interface
class uvc_control_interface {
  uvc_control_interface();

  uvc_input_terminal? input_term_descs;
  // // struct uvc_output_terminal *output_term_descs;
  // struct uvc_selector_unit *selector_unit_descs;
  // struct uvc_processing_unit *processing_unit_descs;
  // struct uvc_extension_unit *extension_unit_descs;
  int? bcdUVC;

  int? dwClockFrequency;
  int? bEndpointAddress;

  /// Interface number
  int? bInterfaceNumber;
}
