// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: camel_case_types, constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:libusb/libusb64.dart';

import 'usb_device.dart';
import 'usb_utils.dart';
import 'uvc_constants.dart';
import 'uvc_device.dart';

/// VideoControl interface descriptor subtype (A.5)
class uvc_vc_desc_subtype {
  static const int UVC_VC_DESCRIPTOR_UNDEFINED = 0x00;
  static const int UVC_VC_HEADER = 0x01;
  static const int UVC_VC_INPUT_TERMINAL = 0x02;
  static const int UVC_VC_OUTPUT_TERMINAL = 0x03;
  static const int UVC_VC_SELECTOR_UNIT = 0x04;
  static const int UVC_VC_PROCESSING_UNIT = 0x05;
  static const int UVC_VC_EXTENSION_UNIT = 0x06;
}

/// Input terminal type (B.2)
class uvc_it_type {
  static const int UVC_ITT_VENDOR_SPECIFIC = 0x0200;
  static const int UVC_ITT_CAMERA = 0x0201;
  static const int UVC_ITT_MEDIA_TRANSPORT_INPUT = 0x0202;
}

extension UsbConfigurationDescriptorExt on UsbConfigDescriptor {
  /// Get a USB configuration descriptor based on its index idx. Returns 0 on success, LIBUSB_ERROR_NOT_FOUND if the configuration does not exist and a LIBUSB_ERROR code on error.
  /// UsbConfigurationDescriptorExt.fromDev();
  static UsbConfigDescriptor? fromDev(
      Libusb libusb, Pointer<libusb_device> usbDevPtr,
      {int configIndex = 0}) {
    var configPtr = calloc<Pointer<libusb_config_descriptor>>();
    if (libusb.libusb_get_config_descriptor(
            usbDevPtr, configIndex, configPtr) !=
        libusb_error.LIBUSB_SUCCESS) return null;

    final usbInterfaces = <UsbInterface>[];

    final config = configPtr.value.ref;

    for (var i = 0; i < config.bNumInterfaces; i++) {
      final interface = config.interface_1[i];

      final interfaceDescriptors = <UsbInterfaceDescriptor>[];
      for (var alt = 0; alt < interface.num_altsetting; alt++) {
        final ifDesc = interface.altsetting[alt]; // libusb_interface_descriptor

        UsbEndpointDescriptor? endpointDescriptor;

        if (ifDesc.bNumEndpoints != 0) {
          final endpoint = ifDesc.endpoint[0];
          endpointDescriptor = UsbEndpointDescriptor(
            bLength: endpoint.bLength,
            bDescriptorType: endpoint.bDescriptorType,
            bEndpointAddress: endpoint.bEndpointAddress,
            bmAttributes: endpoint.bmAttributes,
            wMaxPacketSize: endpoint.wMaxPacketSize,
            bInterval: endpoint.bInterval,
            bRefresh: endpoint.bRefresh,
            bSynchAddress: endpoint.bSynchAddress,
            extra: endpoint.extra.asTypedList(endpoint.extra_length),
            extraLength: endpoint.extra_length,
          );
        }

        final interfaceDescriptor = UsbInterfaceDescriptor(
          bInterfaceClass: ifDesc.bInterfaceClass,
          bInterfaceSubClass: ifDesc.bInterfaceSubClass,
          bLength: ifDesc.bLength,
          bDescriptorType: ifDesc.bDescriptorType,
          bInterfaceNumber: ifDesc.bInterfaceNumber,
          bAlternateSetting: ifDesc.bAlternateSetting,
          bNumEndpoints: ifDesc.bNumEndpoints,
          bInterfaceProtocol: ifDesc.bInterfaceProtocol,
          iInterface: ifDesc.iInterface,
          endpoint: endpointDescriptor != null ? [endpointDescriptor] : [],
          extra: ifDesc.extra.asTypedList(ifDesc.extra_length),
        );
        interfaceDescriptors.add(interfaceDescriptor);
      }

      final usbInterface =
          UsbInterface(interfaceDescriptors: interfaceDescriptors);
      usbInterfaces.add(usbInterface);
    }

    calloc.free(configPtr);

    final desc = UsbConfigDescriptor(interfaces: usbInterfaces);
    return desc;
  }

  ///Process a single VideoControl descriptor block.
  static int uvc_parse_vc(Pointer<libusb_device> usbDevPtr,
      uvc_device_info info, Uint8List block, int block_size) {
    // if not a CS_INTERFACE descriptor??
    if (block[1] != 36) {
      return UVC_SUCCESS;
    }

    int ret = UVC_SUCCESS;
    final descriptorSubtype = block[2];

    switch (descriptorSubtype) {
      case uvc_vc_desc_subtype.UVC_VC_HEADER:
        uvc_control_interface? ctrl_if;
        (ret, ctrl_if) =
            uvc_parse_vc_header(usbDevPtr, info, block, block_size);
        info.ctrl_if = ctrl_if;
        break;
      case uvc_vc_desc_subtype.UVC_VC_INPUT_TERMINAL:
        uvc_input_terminal? term;
        (ret, term) =
            uvc_parse_vc_input_terminal(usbDevPtr, info, block, block_size);
        info.ctrl_if?.input_term_descs = term;
        break;
      case uvc_vc_desc_subtype.UVC_VC_OUTPUT_TERMINAL:
        break;
      case uvc_vc_desc_subtype.UVC_VC_SELECTOR_UNIT:
        // ret = uvc_parse_vc_selector_unit(dev, info, block, block_size);
        break;
      case uvc_vc_desc_subtype.UVC_VC_PROCESSING_UNIT:
        // ret = uvc_parse_vc_processing_unit(dev, info, block, block_size);
        break;
      case uvc_vc_desc_subtype.UVC_VC_EXTENSION_UNIT:
        // ret = uvc_parse_vc_extension_unit(dev, info, block, block_size);
        break;
      default:
        ret = -1; // UVC_ERROR_INVALID_DEVICE;
    }

    return ret;
  }

  /// Parse a VideoControl header.
  static (int, uvc_control_interface?) uvc_parse_vc_header(
      Pointer<libusb_device> usbDevPtr,
      uvc_device_info info,
      Uint8List block,
      int block_size) {
    int i;
    int ret = UVC_SUCCESS;

    int bcdUVC = swToShort(block, 3);
    int dwClockFrequency = 0;

    switch (bcdUVC) {
      case 0x0100:
      case 0x010a:
        dwClockFrequency = dwToInt(block, 7);
        break;
      case 0x0110:
        break;
      default:
        return (UVC_ERROR_NOT_SUPPORTED, null);
    }

    for (i = 12; i < block_size; ++i) {
      int scan_ret = uvc_scan_streaming(usbDevPtr, info, block[i]);
      if (scan_ret != UVC_SUCCESS) {
        ret = scan_ret;
        break;
      }
    }

    final controlInterface = uvc_control_interface();
    controlInterface.bcdUVC = bcdUVC;
    controlInterface.dwClockFrequency = dwClockFrequency;

    return (ret, controlInterface);
  }

  /// Process a VideoStreaming interface
  static int uvc_scan_streaming(Pointer<libusb_device> usbDevPtr,
      uvc_device_info info, int interface_idx) {
    int ret = UVC_SUCCESS;

    final if_desc =
        info.config?.interfaces[interface_idx].interfaceDescriptors[0];
    if (if_desc == null) return -1;

    var buffer = if_desc.extra;
    if (buffer == null) return ret;

    var buffer_left = if_desc.extraLength;

    final stream_if = uvc_streaming_interface();
    stream_if.parent = info;
    stream_if.bInterfaceNumber = if_desc.bInterfaceNumber;
    info.stream_ifs.add(stream_if);

    while (buffer_left >= 3) {
      final block_size = buffer![0];
      final parse_ret =
          uvc_parse_vs(usbDevPtr, info, stream_if, buffer, block_size);

      if (parse_ret != UVC_SUCCESS) {
        ret = parse_ret;
        break;
      }

      buffer_left -= block_size;
      // buffer += block_size;
      buffer = buffer.sublist(block_size);
    }

    return ret;
  }

  /// Process a single VideoStreaming descriptor block
  static int uvc_parse_vs(
      Pointer<libusb_device> usbDevPtr,
      uvc_device_info info,
      uvc_streaming_interface stream_if,
      Uint8List block,
      int block_size) {
    return UVC_SUCCESS;

    /*
  uvc_error_t ret;
  int descriptor_subtype;

  UVC_ENTER();

  ret = UVC_SUCCESS;
  descriptor_subtype = block[2];

  switch (descriptor_subtype) {
  case UVC_VS_INPUT_HEADER:
    ret = uvc_parse_vs_input_header(stream_if, block, block_size);
    break;
  case UVC_VS_OUTPUT_HEADER:
    UVC_DEBUG("unsupported descriptor subtype VS_OUTPUT_HEADER");
    break;
  case UVC_VS_STILL_IMAGE_FRAME:
    ret = uvc_parse_vs_still_image_frame(stream_if, block, block_size);
    break;
  case UVC_VS_FORMAT_UNCOMPRESSED:
    ret = uvc_parse_vs_format_uncompressed(stream_if, block, block_size);
    break;
  case UVC_VS_FORMAT_MJPEG:
    ret = uvc_parse_vs_format_mjpeg(stream_if, block, block_size);
    break;
  case UVC_VS_FRAME_UNCOMPRESSED:
  case UVC_VS_FRAME_MJPEG:
    ret = uvc_parse_vs_frame_uncompressed(stream_if, block, block_size);
    break;
  case UVC_VS_FORMAT_MPEG2TS:
    UVC_DEBUG("unsupported descriptor subtype VS_FORMAT_MPEG2TS");
    break;
  case UVC_VS_FORMAT_DV:
    UVC_DEBUG("unsupported descriptor subtype VS_FORMAT_DV");
    break;
  case UVC_VS_COLORFORMAT:
    UVC_DEBUG("unsupported descriptor subtype VS_COLORFORMAT");
    break;
  case UVC_VS_FORMAT_FRAME_BASED:
    ret = uvc_parse_vs_frame_format ( stream_if, block, block_size );
    break;
  case UVC_VS_FRAME_FRAME_BASED:
    ret = uvc_parse_vs_frame_frame ( stream_if, block, block_size );
    break;
  case UVC_VS_FORMAT_STREAM_BASED:
    UVC_DEBUG("unsupported descriptor subtype VS_FORMAT_STREAM_BASED");
    break;
  default:
    /** @todo handle JPEG and maybe still frames or even DV... */
    //UVC_DEBUG("unsupported descriptor subtype: %d",descriptor_subtype);
    break;
  }

  UVC_EXIT(ret);
  return ret;
  */
  }

  /// Parse a VideoControl input terminal.
  static (int, uvc_input_terminal?) uvc_parse_vc_input_terminal(
      Pointer<libusb_device> usbDevPtr,
      uvc_device_info info,
      Uint8List block,
      int block_size) {
    // uvc_input_terminal_t *term;
    int i;

    // only supporting camera-type input terminals
    int wTerminalType = swToShort(block, 4);
    if (wTerminalType != uvc_it_type.UVC_ITT_CAMERA) {
      return (UVC_SUCCESS, null);
    }

    int bTerminalID = block[3];
    int wObjectiveFocalLengthMin = swToShort(block, 8);
    int wObjectiveFocalLengthMax = swToShort(block, 10);
    int wOcularFocalLength = swToShort(block, 12);

    int bmControls = 0;
    for (i = 14 + block[14]; i >= 15; --i) {
      bmControls = block[i] + (bmControls << 8);
    }

    final term = uvc_input_terminal(
      bTerminalID: bTerminalID,
      wTerminalType: wTerminalType,
      wObjectiveFocalLengthMin: wObjectiveFocalLengthMin,
      wObjectiveFocalLengthMax: wObjectiveFocalLengthMax,
      wOcularFocalLength: wOcularFocalLength,
      bmControls: bmControls,
    );

    return (UVC_SUCCESS, term);
  }
}

extension UsbInterfaceDescriptorExt on UsbInterfaceDescriptor {
  static UsbInterfaceDescriptor? from(libusb_interface_descriptor ifDesc) {
    final interfaceDescriptor = UsbInterfaceDescriptor(
      bLength: ifDesc.bLength,
      bDescriptorType: ifDesc.bDescriptorType,
      bInterfaceNumber: ifDesc.bInterfaceNumber,
      bAlternateSetting: ifDesc.bAlternateSetting,
      bNumEndpoints: ifDesc.bNumEndpoints,
      bInterfaceClass: ifDesc.bInterfaceClass,
      bInterfaceSubClass: ifDesc.bInterfaceSubClass,
      bInterfaceProtocol: ifDesc.bInterfaceProtocol,
      iInterface: ifDesc.iInterface,
      endpoint: [], // UsbEndpointDescriptor.from(ifDesc.endpoint),
      extra: ifDesc.extra.asTypedList(ifDesc.extra_length),
    );
    return interfaceDescriptor;
  }
}

extension UsbEndpointDescriptorExt on UsbEndpointDescriptor {
  static UsbEndpointDescriptor? from(libusb_endpoint_descriptor endDesc) {
    final endpointDescriptor = UsbEndpointDescriptor(
      bLength: endDesc.bLength,
      bDescriptorType: endDesc.bDescriptorType,
      bEndpointAddress: endDesc.bEndpointAddress,
      bmAttributes: endDesc.bmAttributes,
      wMaxPacketSize: endDesc.wMaxPacketSize,
      bInterval: endDesc.bInterval,
      bRefresh: endDesc.bRefresh,
      bSynchAddress: endDesc.bSynchAddress,
      extra: endDesc.extra.asTypedList(endDesc.extra_length),
      extraLength: endDesc.extra_length,
    );
    return endpointDescriptor;
  }
}
